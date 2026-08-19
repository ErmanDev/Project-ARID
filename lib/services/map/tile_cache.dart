import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StudyArea {
  const StudyArea({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  LatLng get center => LatLng((south + north) / 2, (west + east) / 2);

  LatLngBounds get bounds =>
      LatLngBounds(LatLng(south, west), LatLng(north, east));
}

/// File-backed Carto Dark Matter tile cache. Schematic roads on black, not
/// photorealistic satellite. Browse-as-you-go plus optional bulk download.
/// Tiles remain available in Airplane Mode once cached.
class TileCacheService {
  TileCacheService();

  static const userAgent = 'ARID/1.0 (dengue-vector-mapping; thesis)';
  static const urlTemplate =
      'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
  static const attribution = '© OpenStreetMap contributors © CARTO';

  Directory? _cacheDir;

  Future<Directory> cacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'map_tiles_carto_dark'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  File tileFile(int z, int x, int y) {
    final dir = _cacheDir;
    if (dir == null) {
      throw StateError('Tile cache has not been initialized.');
    }
    return File(p.join(dir.path, '$z', '$x', '$y.png'));
  }

  String urlFor(int z, int x, int y) =>
      urlTemplate.replaceAll('{z}', '$z').replaceAll('{x}', '$x').replaceAll('{y}', '$y');

  Future<int> cachedTileCount() async {
    final dir = await cacheDir();
    if (!await dir.exists()) return 0;
    return dir
        .list(recursive: true)
        .where((entity) => entity is File && entity.path.endsWith('.png'))
        .length;
  }

  Stream<TileDownloadProgress> downloadStudyArea({
    required StudyArea area,
    required int minZoom,
    required int maxZoom,
  }) async* {
    await cacheDir();
    final jobs = <({int z, int x, int y})>[];
    for (var z = minZoom; z <= maxZoom; z++) {
      final minX = _lonToX(area.west, z);
      final maxX = _lonToX(area.east, z);
      final minY = _latToY(area.north, z);
      final maxY = _latToY(area.south, z);
      for (var x = minX; x <= maxX; x++) {
        for (var y = minY; y <= maxY; y++) {
          jobs.add((z: z, x: x, y: y));
        }
      }
    }

    var done = 0;
    var skipped = 0;
    var failed = 0;
    final client = http.Client();
    try {
      for (final job in jobs) {
        final file = tileFile(job.z, job.x, job.y);
        if (await file.exists()) {
          skipped += 1;
        } else {
          try {
            final response = await client.get(
              Uri.parse(urlFor(job.z, job.x, job.y)),
              headers: {'User-Agent': userAgent},
            );
            if (response.statusCode == 200) {
              await file.parent.create(recursive: true);
              await file.writeAsBytes(response.bodyBytes, flush: true);
            } else {
              failed += 1;
            }
          } catch (_) {
            failed += 1;
          }
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }
        done += 1;
        yield TileDownloadProgress(
          completed: done,
          total: jobs.length,
          skipped: skipped,
          failed: failed,
        );
      }
    } finally {
      client.close();
    }
  }

  int _lonToX(double lon, int z) {
    final n = math.pow(2, z).toDouble();
    return ((lon + 180.0) / 360.0 * n).floor().clamp(0, n.toInt() - 1);
  }

  int _latToY(double lat, int z) {
    final n = math.pow(2, z).toDouble();
    final latRad = lat * math.pi / 180;
    final y =
        (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n;
    return y.floor().clamp(0, n.toInt() - 1);
  }
}

class TileDownloadProgress {
  const TileDownloadProgress({
    required this.completed,
    required this.total,
    required this.skipped,
    required this.failed,
  });

  final int completed;
  final int total;
  final int skipped;
  final int failed;

  double get fraction => total == 0 ? 1 : completed / total;
}

class FileCachedTileProvider extends TileProvider {
  FileCachedTileProvider(this.cache);

  final TileCacheService cache;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedTileImage(
      url: cache.urlFor(coordinates.z.round(), coordinates.x.round(), coordinates.y.round()),
      file: cache.tileFile(
        coordinates.z.round(),
        coordinates.x.round(),
        coordinates.y.round(),
      ),
    );
  }
}

@immutable
class CachedTileImage extends ImageProvider<CachedTileImage> {
  const CachedTileImage({required this.url, required this.file});

  final String url;
  final File file;

  @override
  Future<CachedTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    CachedTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1,
      debugLabel: url,
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    Uint8List bytes;
    if (await file.exists()) {
      bytes = await file.readAsBytes();
    } else {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': TileCacheService.userAgent},
      );
      if (response.statusCode != 200) {
        throw HttpException('Tile HTTP ${response.statusCode}', uri: Uri.parse(url));
      }
      bytes = response.bodyBytes;
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    return other is CachedTileImage && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
