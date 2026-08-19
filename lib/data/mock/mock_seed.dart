import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';

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

  Future<void> seedIfNeeded() async {
    if (!kUseMockData) return;
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final version = '${decoded['version'] ?? 1}';
    final already = await _config.get(ConfigKeys.mockSeedVersion);
    if (already == version) {
      final existing = await _isar.reports.where().findAll();
      if (existing.any((report) => report.id.startsWith('mock-'))) return;
    }

    final rows = (decoded['reports'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    await _isar.writeTxn(() async {
      final current = await _isar.reports.where().findAll();
      for (final report in current) {
        if (report.id.startsWith('mock-')) {
          await _isar.reports.delete(report.isarId);
        }
      }
      for (final row in rows) {
        await _isar.reports.put(_toReport(row));
      }
    });
    await _config.set(ConfigKeys.mockSeedVersion, version);
  }

  Report _toReport(Map<String, dynamic> row) {
    final hoursAgo = (row['hoursAgo'] as num?)?.toInt() ?? 0;
    final classification = row['classification'] == 'nonBreeding'
        ? Classification.nonBreeding
        : Classification.breeding;
    final riskRaw = row['riskLevel'] as String? ?? 'yellow';
    final risk = switch (riskRaw) {
      'red' => RiskLevel.red,
      'green' => RiskLevel.green,
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
