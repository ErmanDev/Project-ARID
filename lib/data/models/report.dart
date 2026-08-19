import 'package:isar_community/isar.dart';

import 'enums.dart';

part 'report.g.dart';

@collection
class Report {
  Id isarId = Isar.autoIncrement;

  /// Client-generated UUID. This is the Firestore document key.
  @Index(unique: true)
  late String id;

  late String imagePath;
  String? imageRemoteUrl;

  @enumerated
  late Classification classification;

  late double confidenceScore;

  @Index()
  @enumerated
  late RiskLevel riskLevel;

  late double latitude;
  late double longitude;
  late double gpsAccuracy;

  @Index()
  late DateTime capturedAt;

  late String userId;
  late int pointsAwarded;

  @enumerated
  late PointsStatus pointsStatus;

  @Index()
  @enumerated
  late SyncStatus syncStatus;

  DateTime? lastSyncAttempt;

  @enumerated
  late GroundTruth groundTruth;

  late bool gpsManual;
}
