import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../config/mock_flags.dart';
import '../models/enums.dart';
import '../models/report.dart';
import '../repositories/config_repository.dart';

/// Loads [assets/mock/arid_mock.json] — the same file the web dashboard uses.
class MockDataSeeder {
  MockDataSeeder(this._isar, this._config);

  final Isar _isar;
  final ConfigRepository _config;

  static const assetPath = 'assets/mock/arid_mock.json';

  /// Sample photos from the detector test set, assigned to mock reports by
  /// classification so a breeding report shows a container, not a clean scene.
  static final _breedingPhotos = [
    for (var i = 1; i <= 10; i++)
      'assets/mock/images/breeding_${i.toString().padLeft(2, '0')}.jpg',
  ];
  static final _cleanPhotos = [
    for (var i = 1; i <= 6; i++)
      'assets/mock/images/clean_${i.toString().padLeft(2, '0')}.jpg',
  ];

  Future<void> seedIfNeeded() async {
    if (!kUseMockData) return;
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final version = '${decoded['version'] ?? 1}';
    final already = await _config.get(ConfigKeys.mockSeedVersion);
    if (already == version) {
      final existing = await _isar.reports.where().findAll();
      final mocks = existing.where((r) => r.id.startsWith('mock-'));
      // Earlier seeds had no photos; reseed until every mock has one on disk.
      if (mocks.isNotEmpty &&
          mocks.every(
            (r) => r.imagePath.isNotEmpty && File(r.imagePath).existsSync(),
          )) {
        return;
      }
    }

    final rows = (decoded['reports'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final photoDir = await _photoDir();
    var breeding = 0, clean = 0;
    final reports = <Report>[];
    for (final row in rows) {
      final report = _toReport(row);
      final asset = report.classification == Classification.breeding
          ? _breedingPhotos[breeding++ % _breedingPhotos.length]
          : _cleanPhotos[clean++ % _cleanPhotos.length];
      report.imagePath = await _copyPhoto(asset, photoDir);
      reports.add(report);
    }

    await _isar.writeTxn(() async {
      final current = await _isar.reports.where().findAll();
      for (final report in current) {
        if (report.id.startsWith('mock-')) {
          await _isar.reports.delete(report.isarId);
        }
      }
      for (final report in reports) {
        await _isar.reports.put(report);
      }
    });
    await _config.set(ConfigKeys.mockSeedVersion, version);
  }

  Future<void> purgeIfDisabled() async {
    if (kUseMockData) return;
    await _isar.writeTxn(() async {
      final current = await _isar.reports.where().findAll();
      for (final report in current) {
        if (report.id.startsWith('mock-')) {
          await _isar.reports.delete(report.isarId);
        }
      }
    });
    final docs = await getApplicationDocumentsDirectory();
    final photos = Directory('${docs.path}/mock_photos');
    if (await photos.exists()) await photos.delete(recursive: true);
  }

  Future<Directory> _photoDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/mock_photos').create(recursive: true);
  }

  Future<String> _copyPhoto(String asset, Directory dir) async {
    final file = File('${dir.path}/${asset.split('/').last}');
    if (!await file.exists()) {
      final data = await rootBundle.load(asset);
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return file.path;
  }

  Report _toReport(Map<String, dynamic> row) {
    final hoursAgo = (row['hoursAgo'] as num?)?.toInt() ?? 0;
    final classification = row['classification'] == 'nonBreeding'
        ? Classification.nonBreeding
        : Classification.breeding;
    final riskRaw = row['riskLevel'] as String? ?? 'yellow';
    final risk = switch (riskRaw) {
      'red' => RiskLevel.red,
      'green' || 'blue' => RiskLevel.green,
      _ => RiskLevel.yellow,
    };
    final imageUrl = row['imageUrl'] as String?;
    return Report()
      ..id = row['id'] as String
      ..imagePath = ''
      ..imageRemoteUrl = imageUrl
      ..classification = classification
      ..confidenceScore = (row['confidenceScore'] as num?)?.toDouble() ?? 0
      ..riskLevel = risk
      ..latitude = (row['latitude'] as num).toDouble()
      ..longitude = (row['longitude'] as num).toDouble()
      ..gpsAccuracy = (row['gpsAccuracy'] as num?)?.toDouble() ?? 0
      ..capturedAt = DateTime.now().subtract(Duration(hours: hoursAgo))
      ..userId = row['userId'] as String
      ..pointsAwarded = (row['pointsAwarded'] as num?)?.toInt() ?? 0
      ..pointsStatus = PointsStatus.verified
      ..syncStatus = SyncStatus.synced
      ..groundTruth = GroundTruth.unlabeled
      ..gpsManual = row['gpsManual'] == true;
  }
}
