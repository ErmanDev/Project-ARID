import 'package:isar_community/isar.dart';

import 'enums.dart';

part 'user_profile.g.dart';

@collection
class UserProfile {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late String displayName;

  /// Instant on-device total (provisional + verified).
  late int totalPoints;

  /// Confirmed after a successful cloud sync.
  late int verifiedPoints;

  late int reportCount;
  late int currentStreak;
  DateTime? lastReportDate;

  String? firebaseUid;

  @enumerated
  late SyncStatus syncStatus;
}
