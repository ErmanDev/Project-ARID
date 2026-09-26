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
import '../../widgets/glass.dart';
import '../../widgets/report_detail_sheet.dart';

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
  static const _userZoom = 18.0;
  static const _tileContrast = ColorFilter.matrix(<double>[
    1.45, 0, 0, 0, 22, //
    0, 1.45, 0, 0, 22, //
    0, 0, 1.45, 0, 22, //
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
      final fix = await ref.read(locationServiceProvider).freshFix();
      if (!mounted) return;
      if (fix == null) {
        if (announce) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No GPS signal yet. Turn on location, or move somewhere with '
                'a clearer view of the sky.',
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
          const SnackBar(content: Text('Couldn’t show your location.')),
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

  void _refit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reports = ref.read(reportsProvider).valueOrNull ?? const <Report>[];
      _fitToReports(_applyFilters(reports));
    });
  }

  void _selectRisk(RiskLevel? level) {
    setState(() => _riskFilter = level);
    _refit();
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
        padding: const EdgeInsets.fromLTRB(48, 140, 48, 160),
        maxZoom: 16,
      ),
    );
  }

  Future<void> _onMapReady() async {
    _mapReady = true;
    await _centerOnUser(move: true);
  }

  // Map tiles are always light, so markers use the light-appearance risk
  // colors in both appearances.
  Color _riskColor(RiskLevel level) => switch (level) {
    RiskLevel.red => AppColors.riskRed,
    RiskLevel.yellow => AppColors.riskYellow,
    RiskLevel.green => AppColors.riskGreen,
  };

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

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportsProvider).valueOrNull ?? const <Report>[];
    final filtered = _applyFilters(reports);
    int count(RiskLevel level) =>
        reports.where((r) => r.riskLevel == level).length;
    final hotspots = buildBreedingHotspots(filtered);
    final cache = ref.watch(tileCacheProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.mapBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                backgroundColor: AppColors.mapBackground,
                initialCenter:
                    _userLocation ??
                    (filtered.isNotEmpty
                        ? LatLng(
                            filtered.first.latitude,
                            filtered.first.longitude,
                          )
                        : _fallbackCenter),
                initialZoom: _userLocation != null ? _userZoom : 15,
                onMapReady: _onMapReady,
              ),
              children: [
                TileLayer(
                  urlTemplate: TileCacheService.urlTemplate,
                  userAgentPackageName: 'ph.arid.arid',
                  tileProvider: FileCachedTileProvider(cache),
                  tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                    colorFilter: _tileContrast,
                    child: tileWidget,
                  ),
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
                        child: const _UserDot(),
                      ),
                    if (_showMarkers)
                      for (final report in filtered)
                        Marker(
                          point: LatLng(report.latitude, report.longitude),
                          width: 48,
                          height: 48,
                          child: _RiskPin(
                            level: report.riskLevel,
                            color: _riskColor(report.riskLevel),
                            label: '${riskLabel(report.riskLevel)} report',
                            onTap: () => showReportDetail(context, report),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _RiskFilterBar(
                            selected: _riskFilter,
                            total: reports.length,
                            counts: {
                              for (final level in RiskLevel.values)
                                level: count(level),
                            },
                            onSelected: _selectRisk,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GlassIconButton(
                          icon: Icons.layers_rounded,
                          tooltip: 'Map layers and dates',
                          onPressed: () => _openLayers(hotspots.length),
                        ),
                      ],
                    ),
                    if (_dateFilter != null) ...[
                      const SizedBox(height: 8),
                      _DatePill(
                        range: _dateFilter!,
                        onClear: () {
                          setState(() => _dateFilter = null);
                          _refit();
                        },
                      ),
                    ],
                    if (_progress != null) ...[
                      const SizedBox(height: 8),
                      _DownloadPill(progress: _progress!),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: bottomInset + 12,
            child: Column(
              children: [
                GlassIconButton(
                  icon: Icons.download_for_offline_rounded,
                  tooltip: 'Save this area for offline use',
                  busy: _downloading,
                  onPressed: _downloading
                      ? null
                      : () => _downloadVisible(cache),
                ),
                const SizedBox(height: 10),
                GlassIconButton(
                  icon: Icons.near_me_rounded,
                  tooltip: 'Show my location',
                  busy: _centering,
                  selected: _userLocation != null,
                  onPressed: _centering
                      ? null
                      : () => _centerOnUser(announce: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLayers(int hotspotCount) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          void update(VoidCallback change) {
            setState(change);
            setSheet(() {});
          }

          final dates = _dateFilter;
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Map layers',
                      style: Theme.of(sheetContext).textTheme.headlineSmall,
                    ),
                  ),
                ),
                GroupedSection(
                  dividerIndent: 60,
                  children: [
                    _SwitchRow(
                      icon: Icons.place_rounded,
                      color: AppColors.primary,
                      title: 'Reports',
                      value: _showMarkers,
                      onChanged: (v) => update(() => _showMarkers = v),
                    ),
                    _SwitchRow(
                      icon: Icons.blur_on_rounded,
                      color: AppColors.amber,
                      title: 'Heat map',
                      value: _showHeatmap,
                      onChanged: (v) => update(() => _showHeatmap = v),
                    ),
                    _SwitchRow(
                      icon: Icons.radar_rounded,
                      color: AppColors.riskRed,
                      title: 'Hotspots',
                      subtitle: hotspotCount == 1
                          ? '1 cluster of high-risk sites'
                          : '$hotspotCount clusters of high-risk sites',
                      value: _showHotspots,
                      onChanged: (v) => update(() => _showHotspots = v),
                    ),
                  ],
                ),
                GroupedSection(
                  header: 'Dates',
                  children: [
                    GroupedRow(
                      title: 'Date range',
                      value: dates == null
                          ? 'All dates'
                          : '${DateFormat.MMMd().format(dates.start)} – '
                                '${DateFormat.MMMd().format(dates.end)}',
                      onTap: () async {
                        await _pickDates();
                        setSheet(() {});
                      },
                    ),
                    if (dates != null)
                      GroupedRow(
                        title: 'Show all dates',
                        accent: true,
                        onTap: () {
                          update(() => _dateFilter = null);
                          _refit();
                        },
                      ),
                  ],
                ),
              ],
            ),
          );
        },
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
      _refit();
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
        const SnackBar(content: Text('This area is saved for offline use.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Couldn’t save this area. Check your connection and try again.',
          ),
        ),
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
}

class _RiskFilterBar extends StatelessWidget {
  const _RiskFilterBar({
    required this.selected,
    required this.total,
    required this.counts,
    required this.onSelected,
  });

  final RiskLevel? selected;
  final int total;
  final Map<RiskLevel, int> counts;
  final ValueChanged<RiskLevel?> onSelected;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      floating: true,
      borderRadius: BorderRadius.circular(24),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.6,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              _FilterPill(
                label: 'All',
                count: total,
                selected: selected == null,
                onTap: () => onSelected(null),
              ),
              for (final level in [
                RiskLevel.red,
                RiskLevel.yellow,
                RiskLevel.green,
              ])
                _FilterPill(
                  label: switch (level) {
                    RiskLevel.red => 'High',
                    RiskLevel.yellow => 'Moderate',
                    RiskLevel.green => 'Non-breeding',
                  },
                  count: counts[level] ?? 0,
                  level: level,
                  selected: selected == level,
                  onTap: () => onSelected(level),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.level,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final RiskLevel? level;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final fg = selected ? p.onAccent : p.ink;
    return Semantics(
      selected: selected,
      button: true,
      label: '$label, $count reports',
      excludeSemantics: true,
      child: Material(
        color: selected ? p.accent : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (level != null) ...[
                    RiskGlyph(
                      level: level!,
                      size: 11,
                      color: selected ? p.onAccent : null,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: selected
                          ? p.onAccent.withValues(alpha: 0.85)
                          : p.secondaryInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.range, required this.onClear});

  final DateTimeRange range;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    return GlassSurface(
      floating: true,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_rounded, size: 18, color: p.secondaryInk),
            const SizedBox(width: 6),
            Text(
              '${DateFormat.MMMd().format(range.start)} – '
              '${DateFormat.MMMd().format(range.end)}',
              style: TextStyle(
                color: p.ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              tooltip: 'Show all dates',
              onPressed: onClear,
              icon: Icon(Icons.close_rounded, size: 18, color: p.secondaryInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadPill extends StatelessWidget {
  const _DownloadPill({required this.progress});

  final TileDownloadProgress progress;

  @override
  Widget build(BuildContext context) {
    final p = context.arid;
    final percent = (progress.fraction * 100).clamp(0, 100).round();
    return GlassSurface(
      floating: true,
      borderRadius: BorderRadius.circular(22),
      child: Semantics(
        liveRegion: true,
        label: 'Saving map area, $percent percent',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Saving area for offline use · $percent%',
                style: TextStyle(
                  color: p.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress.fraction,
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: GroupedRow(
        leading: IconTile(icon: icon, color: color),
        title: title,
        subtitle: subtitle,
        onTap: () => onChanged(!value),
        showChevron: false,
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}

/// A report on the map: the risk glyph in white on its risk color, so
/// shape and color both carry the level.
class _RiskPin extends StatelessWidget {
  const _RiskPin({
    required this.level,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final RiskLevel level;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: RiskGlyph(level: level, size: 12, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your location',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
