import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'app.dart';
import 'config/mock_flags.dart';
import 'data/local/isar_service.dart';
import 'data/mock/mock_seed.dart';
import 'data/repositories/config_repository.dart';
import 'data/repositories/repositories.dart';
import 'providers.dart';
import 'services/map/tile_cache.dart';
import 'sync/workmanager_tasks.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isar = await IsarService.open();
  final deviceId = await _loadOrCreateDeviceId();
  await UserRepository(isar).ensureLocalProfile(deviceId);
  final config = ConfigRepository(isar);
  await config.ensureDefaults();
  if (kUseMockData) {
    await MockDataSeeder(isar, config).seedIfNeeded();
  }
  final tiles = TileCacheService();
  await tiles.cacheDir();

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await WorkmanagerTasks.register();
    } catch (_) {
      // Background sync is optional; foreground + connectivity still work.
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        deviceIdProvider.overrideWithValue(deviceId),
        tileCacheProvider.overrideWithValue(tiles),
      ],
      child: const AridRoot(),
    ),
  );
}

Future<String> _loadOrCreateDeviceId() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/device_id.txt');
  if (await file.exists()) {
    final existing = (await file.readAsString()).trim();
    if (existing.isNotEmpty) return existing;
  }
  final id = const Uuid().v4();
  await file.writeAsString(id, flush: true);
  return id;
}
