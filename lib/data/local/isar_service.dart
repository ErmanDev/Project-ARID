import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_config.dart';
import '../models/report.dart';
import '../models/sync_queue_item.dart';
import '../models/user_profile.dart';

class IsarService {
  IsarService._();

  static Future<Isar> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        ReportSchema,
        UserProfileSchema,
        SyncQueueItemSchema,
        AppConfigSchema,
      ],
      directory: dir.path,
      name: 'arid',
    );
  }

  /// Used by the background isolate, which cannot share the UI isolate's Isar.
  static Future<Isar> openForBackground() async {
    if (Isar.getInstance('arid') case final existing?) {
      return existing;
    }
    return open();
  }
}
