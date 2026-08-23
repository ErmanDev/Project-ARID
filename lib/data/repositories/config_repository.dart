import 'package:isar_community/isar.dart';

import '../models/app_config.dart';
import '../../services/rewards/points_rules.dart';

class ConfigRepository {
  ConfigRepository(this._isar);

  final Isar _isar;

  static const _defaults = {
    ConfigKeys.highConfidenceThreshold: '0.70',
    ConfigKeys.completeReportPoints: '10',
    ConfigKeys.breedingBonus: '5',
    ConfigKeys.highConfidenceBonus: '5',
    ConfigKeys.redRiskBonus: '3',
    ConfigKeys.streakBonus: '2',
    ConfigKeys.maxSyncRetries: '8',
    ConfigKeys.tileMinZoom: '12',
    ConfigKeys.tileMaxZoom: '16',
    ConfigKeys.studySouth: '14.5500',
    ConfigKeys.studyWest: '120.9700',
    ConfigKeys.studyNorth: '14.7000',
    ConfigKeys.studyEast: '121.0800',
    ConfigKeys.cloudinaryCloudName: 'dhoi760j1',
    ConfigKeys.cloudinaryUploadPreset: 'arid_unsigned',
    ConfigKeys.themeMode: 'system',
  };

  Future<void> ensureDefaults() async {
    await _isar.writeTxn(() async {
      for (final entry in _defaults.entries) {
        final existing = await _isar.appConfigs
            .filter()
            .keyEqualTo(entry.key)
            .findFirst();
        if (existing == null) {
          await _isar.appConfigs.put(
            AppConfig()
              ..key = entry.key
              ..value = entry.value,
          );
        }
      }
    });
  }

  Future<String> get(String key, {String fallback = ''}) async {
    final row = await _isar.appConfigs.filter().keyEqualTo(key).findFirst();
    return row?.value ?? _defaults[key] ?? fallback;
  }

  Future<double> getDouble(String key, {double fallback = 0}) async {
    return double.tryParse(await get(key)) ?? fallback;
  }

  Future<int> getInt(String key, {int fallback = 0}) async {
    return int.tryParse(await get(key)) ?? fallback;
  }

  Future<void> set(String key, String value) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.appConfigs
          .filter()
          .keyEqualTo(key)
          .findFirst();
      if (existing == null) {
        await _isar.appConfigs.put(
          AppConfig()
            ..key = key
            ..value = value,
        );
      } else {
        existing.value = value;
        await _isar.appConfigs.put(existing);
      }
    });
  }

  Future<PointsRules> loadPointsRules() async {
    return PointsRules(
      highConfidenceThreshold: await getDouble(
        ConfigKeys.highConfidenceThreshold,
        fallback: 0.70,
      ),
      completeReport: await getInt(
        ConfigKeys.completeReportPoints,
        fallback: 10,
      ),
      breedingBonus: await getInt(ConfigKeys.breedingBonus, fallback: 5),
      highConfidenceBonus: await getInt(
        ConfigKeys.highConfidenceBonus,
        fallback: 5,
      ),
      redRiskBonus: await getInt(ConfigKeys.redRiskBonus, fallback: 3),
      streakBonus: await getInt(ConfigKeys.streakBonus, fallback: 2),
    );
  }

  Future<Map<String, String>> all() async {
    final rows = await _isar.appConfigs.where().findAll();
    return {for (final row in rows) row.key: row.value};
  }
}

class ConfigKeys {
  ConfigKeys._();

  static const highConfidenceThreshold =
      'classification.highConfidenceThreshold';
  static const completeReportPoints = 'points.completeReport';
  static const breedingBonus = 'points.breedingBonus';
  static const highConfidenceBonus = 'points.highConfidenceBonus';
  static const redRiskBonus = 'points.redRiskBonus';
  static const streakBonus = 'points.streakBonus';
  static const maxSyncRetries = 'sync.maxRetries';
  static const tileMinZoom = 'map.tileMinZoom';
  static const tileMaxZoom = 'map.tileMaxZoom';
  static const studySouth = 'map.studySouth';
  static const studyWest = 'map.studyWest';
  static const studyNorth = 'map.studyNorth';
  static const studyEast = 'map.studyEast';
  static const cloudinaryCloudName = 'media.cloudinaryCloudName';
  static const cloudinaryUploadPreset = 'media.cloudinaryUploadPreset';
  static const locationOnboardingDone = 'onboarding.locationDone';
  static const mockSeedVersion = 'mock.seedVersion';
  static const themeMode = 'appearance.themeMode';
}
