import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../../data/models/enums.dart';
import '../../data/models/report.dart';

class BreedingHotspot {
  const BreedingHotspot({
    required this.key,
    required this.center,
    required this.count,
    required this.radiusMeters,
  });

  final String key;
  final LatLng center;
  final int count;
  final double radiusMeters;
}

/// Clusters nearby high-risk reports. Matches the web dashboard buckets.
List<BreedingHotspot> buildBreedingHotspots(List<Report> reports) {
  const distance = Distance();
  final buckets = <String, List<Report>>{};
  for (final report in reports) {
    if (report.riskLevel != RiskLevel.red) continue;
    final key =
        '${report.latitude.toStringAsFixed(3)},${report.longitude.toStringAsFixed(3)}';
    buckets.putIfAbsent(key, () => []).add(report);
  }

  final spots = <BreedingHotspot>[];
  for (final entry in buckets.entries) {
    if (entry.value.length < 2) continue;
    final list = entry.value;
    final lat =
        list.fold<double>(0, (sum, item) => sum + item.latitude) / list.length;
    final lng =
        list.fold<double>(0, (sum, item) => sum + item.longitude) / list.length;
    final center = LatLng(lat, lng);
    var span = 0.0;
    for (final item in list) {
      span = max(
        span,
        distance.as(
          LengthUnit.Meter,
          center,
          LatLng(item.latitude, item.longitude),
        ),
      );
    }
    spots.add(
      BreedingHotspot(
        key: entry.key,
        center: center,
        count: list.length,
        radiusMeters: max(220, span + 90) + (list.length - 2) * 40,
      ),
    );
  }
  return spots;
}
