import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../data/local/isar_service.dart';
import '../data/repositories/config_repository.dart';
import '../data/repositories/repositories.dart';
import 'firebase_backend.dart';
import 'sync_service.dart';

const aridPeriodicSyncTask = 'arid.periodicSync';

@pragma('vm:entry-point')
void aridWorkmanagerDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final isar = await IsarService.openForBackground();
      final sync = SyncService(
        reports: ReportRepository(isar),
        users: UserRepository(isar),
        queue: SyncQueueRepository(isar),
        config: ConfigRepository(isar),
        backend: FirebaseBackend(),
      );
      await sync.syncPending();
      return true;
    } catch (_) {
      return false;
    }
  });
}

class WorkmanagerTasks {
  static Future<void> register() async {
    await Workmanager().initialize(aridWorkmanagerDispatcher);
    await Workmanager().registerPeriodicTask(
      aridPeriodicSyncTask,
      aridPeriodicSyncTask,
      frequency: const Duration(minutes: 30),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
