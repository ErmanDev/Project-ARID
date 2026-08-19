import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/enums.dart';
import '../../../data/models/report.dart';
import '../../../data/repositories/config_repository.dart';
import '../../../providers.dart';
import '../../../services/map/hotspots.dart';
import '../../../services/map/tile_cache.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _controller = MapController();
  RiskLevel? _riskFilter;
  DateTimeRange? _dateFilter;
  bool _showMarkers = true;
  bool _showHeatmap = false;
  bool _showHotspots = true;
  bool _downloading = false;
  bool _centering = false;
  bool _mapReady = false;
  TileDownloadProgress? _progress;
  LatLng? _userLocation;

  static const _fallbackCenter = LatLng(14.5995, 120.9842);
  static const _userZoom = 16.0;
  static const _whiteLabel = TextStyle(color: Colors.white, fontSize: 13);
  static const _tileContrast = ColorFilter.matrix(<double>[
    1.45, 0, 0, 0, 22,
    0, 1.45, 0, 0, 22,
    0, 0, 1.45, 0, 22,
    0, 0, 0, 1, 0,
  ]);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _centerOnUser({bool announce = false, bool move = true}) async {
    if (_centering) return;
    setState(() => _centering = true);
    try {
      await ref.read(locationServiceProvider).requestPermission();
      final fix = await ref.read(locationServiceProvider).currentFix();
      if (!mounted) return;
      if (fix == null) {
        if (announce) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not read GPS. Turn on location or wait for a signal.',
              ),
            ),
          );
        }
        return;
      }
      final point = LatLng(fix.latitude, fix.longitude);
      setState(() => _userLocation = point);
      if (move) _controller.move(point, _userZoom);
    } catch (_) {
      if (announce && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not move the map to your location.')),
        );
      }
    } finally {
      if (mounted) setState(() => _centering = false);
    }
  }

  List<Report> _applyFilters(List<Report> reports) {
    return reports.where((report) {
      if (_riskFilter != null && report.riskLevel != _riskFilter) return false;
      if (_dateFilter != null) {
        final day = DateTime(
          report.capturedAt.year,
          report.capturedAt.month,
          report.capturedAt.day,
        );
        if (day.isBefore(_dateFilter!.start) || day.isAfter(_dateFilter!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _selectRisk(RiskLevel? level) {
    setState(() => _riskFilter = level);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reports = ref.read(reportsProvider).valueOrNull ?? const <Report>[];
      _fitToReports(_applyFilters(reports));
    });
  }

  void _fitToReports(List<Report> reports) {
    if (!_mapReady || reports.isEmpty) return;
    final points = [
      for (final report in reports) LatLng(report.latitude, report.longitude),
    ];
    if (points.length == 1) {
      _controller.move(points.first, 15);
      return;
    }
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(48),
        maxZoom: 16,
      ),
    );
  }

  Future<void> _onMapReady() async {
    _mapReady = true;
    await _centerOnUser(move: false);
    if (!mounted) return;
    final reports = ref.read(reportsProvider).valueOrNull ?? const <Report>[];
    final visible = _applyFilters(reports);
    if (visible.isNotEmpty) {
      _fitToReports(visible);
    } else {
      await _centerOnUser(move: true);
    }
  }

  List<CircleMarker> _heatCircles(List<Report> reports) {
    return [
      for (final report in reports) ...[
        CircleMarker(
          point: LatLng(report.latitude, report.longitude),
          radius: switch (report.riskLevel) {
            RiskLevel.red => 220,
            RiskLevel.yellow => 170,
            RiskLevel.green => 130,
          },
          useRadiusInMeter: true,
          color: _riskColor(report.riskLevel).withValues(alpha: 0.12),
        ),
        CircleMarker(
          point: LatLng(report.latitude, report.longitude),
          radius: switch (report.riskLevel) {
            RiskLevel.red => 110,
            RiskLevel.yellow => 85,
            RiskLevel.green => 60,
          },
          useRadiusInMeter: true,
          color: _riskColor(report.riskLevel).withValues(alpha: 0.32),
        ),
      ],
    ];
  }

  List<CircleMarker> _hotspotCircles(List<BreedingHotspot> hotspots) {
    return [
      for (final spot in hotspots) ...[
        CircleMarker(
          point: spot.center,
          radius: spot.radiusMeters * 1.28,
          useRadiusInMeter: true,
          color: AppColors.riskRed.withValues(alpha: 0.08),
          borderStrokeWidth: 2,
          borderColor: AppColors.riskRed.withValues(alpha: 0.55),
        ),
        CircleMarker(
          point: spot.center,
          radius: spot.radiusMeters,
          useRadiusInMeter: true,
          color: AppColors.riskRed.withValues(alpha: 0.2),
          borderStrokeWidth: 2.5,
          borderColor: AppColors.riskRed,
        ),
      ],
    ];
  }

  Color _riskColor(RiskLevel level) {
    return switch (level) {
      RiskLevel.red => AppColors.riskRed,
      RiskLevel.yellow => AppColors.riskYellow,
      RiskLevel.green => AppColors.riskGreen,
    };
  }

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportsProvider).valueOrNull ?? const <Report>[];
    final filtered = _applyFilters(reports);
    final highCount = reports.where((r) => r.riskLevel == RiskLevel.red).length;
    final moderateCount =
        reports.where((r) => r.riskLevel == RiskLevel.yellow).length;
    final lowCount = reports.where((r) => r.riskLevel == RiskLevel.green).length;
    final hotspots = buildBreedingHotspots(filtered);
    final cache = ref.watch(tileCacheProvider);

    return Scaffold(
      backgroundColor: AppColors.mapBackground,
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            tooltip: 'Download this area for offline use',
            onPressed: _downloading ? null : () => _downloadVisible(cache),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'map_my_location',
        tooltip: 'My location',
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        onPressed: _centering ? null : () => _centerOnUser(announce: true),
        child: _centering
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
      ),
      body: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              chipTheme: ChipTheme.of(context).copyWith(
                backgroundColor: AppColors.mapChrome,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: _whiteLabel,
                secondaryLabelStyle: _whiteLabel,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
              ),
            ),
            child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text('All (${reports.length})', style: _whiteLabel),
                  selected: _riskFilter == null,
                  onSelected: (_) => _selectRisk(null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('High ($highCount)', style: _whiteLabel),
                  selected: _riskFilter == RiskLevel.red,
                  onSelected: (_) => _selectRisk(RiskLevel.red),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Moderate ($moderateCount)', style: _whiteLabel),
                  selected: _riskFilter == RiskLevel.yellow,
                  onSelected: (_) => _selectRisk(RiskLevel.yellow),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Low ($lowCount)', style: _whiteLabel),
                  selected: _riskFilter == RiskLevel.green,
                  onSelected: (_) => _selectRisk(RiskLevel.green),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(
                    _dateFilter == null
                        ? 'Dates'
                        : '${DateFormat.MMMd().format(_dateFilter!.start)}–${DateFormat.MMMd().format(_dateFilter!.end)}',
                    style: _whiteLabel,
                  ),
                  onPressed: _pickDates,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Markers', style: _whiteLabel),
                  selected: _showMarkers,
                  onSelected: (value) => setState(() => _showMarkers = value),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Heatmap', style: _whiteLabel),
                  selected: _showHeatmap,
                  onSelected: (value) => setState(() => _showHeatmap = value),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(
                    'Hotspots (${hotspots.length})',
                    style: _whiteLabel,
                  ),
                  selected: _showHotspots,
                  onSelected: (value) => setState(() => _showHotspots = value),
                ),
              ],
            ),
            ),
          ),
          if (_progress != null)
            LinearProgressIndicator(value: _progress!.fraction),
          Expanded(
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                backgroundColor: AppColors.mapBackground,
                initialCenter: _userLocation ??
                    (filtered.isNotEmpty
                        ? LatLng(
                            filtered.first.latitude,
                            filtered.first.longitude,
                          )
                        : _fallbackCenter),
                initialZoom: _userLocation != null ? _userZoom : 13,
                onMapReady: _onMapReady,
              ),
              children: [
                TileLayer(
                  urlTemplate: TileCacheService.urlTemplate,
                  userAgentPackageName: 'ph.arid.arid',
                  tileProvider: FileCachedTileProvider(cache),
                  tileBuilder: (context, tileWidget, tile) {
                    return ColorFiltered(
                      colorFilter: _tileContrast,
                      child: tileWidget,
                    );
                  },
                ),
                if (_showHeatmap)
                  CircleLayer(
                    optimizeRadiusInMeters: true,
                    circles: _heatCircles(filtered),
                  ),
                if (_showHotspots)
                  CircleLayer(
                    optimizeRadiusInMeters: true,
                    circles: _hotspotCircles(hotspots),
                  ),
                MarkerLayer(
                  markers: [
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 28,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_showMarkers)
                      for (final report in filtered)
                        Marker(
                          point: LatLng(report.latitude, report.longitude),
                          width: 36,
                          height: 36,
                          child: GestureDetector(
                            onTap: () => _showDetail(report),
                            child: Icon(
                              Icons.location_on,
                              color: switch (report.riskLevel) {
                                RiskLevel.red => AppColors.riskRed,
                                RiskLevel.yellow => AppColors.riskYellow,
                                RiskLevel.green => AppColors.riskGreen,
                              },
                              size: 36,
                            ),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _dateFilter,
    );
    if (range != null) {
      setState(() => _dateFilter = range);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final reports = ref.read(reportsProvider).valueOrNull ?? const <Report>[];
        _fitToReports(_applyFilters(reports));
      });
    }
  }

  Future<void> _downloadVisible(TileCacheService cache) async {
    final camera = _controller.camera;
    final bounds = camera.visibleBounds;
    final config = ref.read(configRepositoryProvider);
    final minZ = await config.getInt(ConfigKeys.tileMinZoom, fallback: 12);
    final maxZ = await config.getInt(ConfigKeys.tileMaxZoom, fallback: 16);
    setState(() {
      _downloading = true;
      _progress = const TileDownloadProgress(
        completed: 0,
        total: 1,
        skipped: 0,
        failed: 0,
      );
    });
    try {
      await for (final progress in cache.downloadStudyArea(
        area: StudyArea(
          south: bounds.south,
          west: bounds.west,
          north: bounds.north,
          east: bounds.east,
        ),
        minZoom: minZ,
        maxZoom: maxZ.clamp(minZ, camera.zoom.round() + 2),
      )) {
        if (!mounted) return;
        setState(() => _progress = progress);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiles saved for offline use.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tile download failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _progress = null;
        });
      }
    }
  }

  void _showDetail(Report report) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ReportDetailSheet(report: report),
    );
  }
}

class ReportDetailSheet extends StatelessWidget {
  const ReportDetailSheet({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (File(report.imagePath).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(report.imagePath),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              RiskBadge(level: report.riskLevel),
              const Spacer(),
              SyncStatusChip(status: report.syncStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.classification == Classification.breeding
                ? 'Breeding site'
                : 'Non-breeding',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Confidence ${(report.confidenceScore * 100).toStringAsFixed(1)}%  ·  '
            '${DateFormat('MMM d, y h:mm a').format(report.capturedAt)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
