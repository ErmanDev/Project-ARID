import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';

import 'data/models/enums.dart';
import 'data/models/report.dart';
import 'data/models/user_profile.dart';
import 'data/repositories/config_repository.dart';
import 'data/repositories/repositories.dart';
import 'services/camera/image_service.dart';
import 'services/classification/classification_result.dart';
import 'services/classification/classifier_service.dart';
import 'services/export/evaluation_export_service.dart';
import 'services/location/location_service.dart';
import 'services/map/tile_cache.dart';
import 'services/rewards/points_rules.dart';
import 'sync/connectivity_watcher.dart';
import 'sync/firebase_backend.dart';
import 'sync/sync_service.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in main()');
});

final deviceIdProvider = Provider<String>((ref) {
  throw UnimplementedError('deviceIdProvider must be overridden in main()');
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(isarProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(isarProvider));
});

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  return SyncQueueRepository(ref.watch(isarProvider));
});

final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return ConfigRepository(ref.watch(isarProvider));
});

final classifierProvider = Provider<ClassifierService>((ref) {
  final service = ClassifierService();
  ref.onDispose(service.dispose);
  return service;
});

final imageServiceProvider = Provider<ImageService>((ref) => ImageService());

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final tileCacheProvider = Provider<TileCacheService>((ref) {
  throw UnimplementedError('tileCacheProvider must be overridden in main()');
});

final evaluationExportProvider = Provider<EvaluationExportService>(
  (ref) => EvaluationExportService(),
);

final firebaseBackendProvider = Provider<FirebaseBackend>((ref) {
  return FirebaseBackend();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    reports: ref.watch(reportRepositoryProvider),
    users: ref.watch(userRepositoryProvider),
    queue: ref.watch(syncQueueRepositoryProvider),
    config: ref.watch(configRepositoryProvider),
    backend: ref.watch(firebaseBackendProvider),
  );
});

final isOnlineProvider = StateProvider<bool>((ref) => true);

final connectivityBootstrapProvider = Provider<void>((ref) {
  ConnectivityStatus.current().then((online) {
    ref.read(isOnlineProvider.notifier).state = online;
  });
  final sub = ConnectivityStatus.watch().listen((online) {
    ref.read(isOnlineProvider.notifier).state = online;
    if (online) {
      unawaited(ref.read(syncServiceProvider).syncPending());
    }
  });
  ref.onDispose(sub.cancel);
});

final reportsProvider = StreamProvider<List<Report>>((ref) {
  return ref.watch(reportRepositoryProvider).watchAll();
});

final profileProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(userRepositoryProvider).watch();
});

final pointsRulesProvider = FutureProvider<PointsRules>((ref) {
  return ref.watch(configRepositoryProvider).loadPointsRules();
});

final locationOnboardingDoneProvider = FutureProvider<bool>((ref) async {
  final config = ref.watch(configRepositoryProvider);
  final stored = await config.get(ConfigKeys.locationOnboardingDone);
  if (stored == 'true') return true;
  if (await ref.read(locationServiceProvider).isWhenInUseGranted()) {
    await config.set(ConfigKeys.locationOnboardingDone, 'true');
    return true;
  }
  return false;
});

class CaptureInput {
  const CaptureInput({
    required this.sourceFile,
    this.manualFix,
  });

  final File sourceFile;
  final GpsFix? manualFix;
}

class CaptureOutcome {
  const CaptureOutcome({
    required this.report,
    required this.breakdown,
    required this.usedOnDeviceModel,
  });

  final Report report;
  final List<String> breakdown;
  final bool usedOnDeviceModel;
}

final submitReportProvider =
    Provider<Future<CaptureOutcome> Function(CaptureInput)>((ref) {
  return (input) async {
    final reports = ref.read(reportRepositoryProvider);
    final users = ref.read(userRepositoryProvider);
    final images = ref.read(imageServiceProvider);
    final classifier = ref.read(classifierProvider);
    final location = ref.read(locationServiceProvider);
    final rules = await ref.read(pointsRulesProvider.future);
    final profile = await users.get();
    if (profile == null) {
      throw StateError('Local profile missing');
    }

    final id = const Uuid().v4();
    final persisted = await images.persistReportImage(
      source: input.sourceFile,
      reportId: id,
    );

    final classificationFuture = classifier.classify(persisted);
    final gpsFuture = input.manualFix != null
        ? Future.value(input.manualFix)
        : location.currentFix();

    final classified = await classificationFuture;
    var gps = await gpsFuture;
    gps ??= input.manualFix;
    if (gps == null) {
      throw const GpsRequiredException();
    }

    final risk = RiskMapper(
      highConfidenceThreshold: rules.highConfidenceThreshold,
    ).map(
      classification: classified.classification,
      confidence: classified.confidenceScore,
    );

    final award = PointsEngine(rules).award(
      classification: classified.classification,
      confidence: classified.confidenceScore,
      riskLevel: risk,
      profile: profile,
      capturedAt: DateTime.now(),
    );

    final report = Report()
      ..id = id
      ..imagePath = persisted.path
      ..classification = classified.classification
      ..confidenceScore = classified.confidenceScore
      ..riskLevel = risk
      ..latitude = gps.latitude
      ..longitude = gps.longitude
      ..gpsAccuracy = gps.accuracy
      ..capturedAt = DateTime.now()
      ..userId = profile.id
      ..pointsAwarded = award.points
      ..pointsStatus = PointsStatus.provisional
      ..syncStatus = SyncStatus.pendingUpload
      ..groundTruth = GroundTruth.unlabeled
      ..gpsManual = gps.manual;

    await reports.saveAndEnqueue(report);
    await users.applyNewReport(
      points: award.points,
      capturedAt: report.capturedAt,
    );

    return CaptureOutcome(
      report: report,
      breakdown: award.breakdown,
      usedOnDeviceModel: classified.usedOnDeviceModel,
    );
  };
});

class GpsRequiredException implements Exception {
  const GpsRequiredException();
}
