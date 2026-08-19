import 'package:isar_community/isar.dart';

part 'sync_queue_item.g.dart';

@collection
class SyncQueueItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  @Index(unique: true)
  late String reportId;

  late int attemptCount;
  String? lastError;
  late DateTime enqueuedAt;
}
