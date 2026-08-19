import 'package:isar_community/isar.dart';

import '../models/enums.dart';
import '../models/report.dart';
import '../models/sync_queue_item.dart';
import '../models/user_profile.dart';

class ReportRepository {
  ReportRepository(this._isar);

  final Isar _isar;

  Stream<List<Report>> watchAll() {
    return _isar.reports
        .where()
        .sortByCapturedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<List<Report>> getAll() {
    return _isar.reports.where().sortByCapturedAtDesc().findAll();
  }

  Future<Report?> getById(String id) {
    return _isar.reports.filter().idEqualTo(id).findFirst();
  }

  Future<List<Report>> byRisk(RiskLevel risk) {
    return _isar.reports
        .filter()
        .riskLevelEqualTo(risk)
        .sortByCapturedAtDesc()
        .findAll();
  }

  Future<List<Report>> bySyncStatus(SyncStatus status) {
    return _isar.reports
        .filter()
        .syncStatusEqualTo(status)
        .sortByCapturedAtDesc()
        .findAll();
  }

  Future<List<Report>> inDateRange(DateTime start, DateTime end) {
    return _isar.reports
        .filter()
        .capturedAtBetween(start, end)
        .sortByCapturedAtDesc()
        .findAll();
  }

  Future<void> save(Report report) async {
    await _isar.writeTxn(() async {
      await _isar.reports.put(report);
    });
  }

  /// Local write + enqueue. Never touches the network.
  Future<void> saveAndEnqueue(Report report) async {
    await _isar.writeTxn(() async {
      await _isar.reports.put(report);
      final existing = await _isar.syncQueueItems
          .filter()
          .reportIdEqualTo(report.id)
          .findFirst();
      if (existing == null) {
        await _isar.syncQueueItems.put(
          SyncQueueItem()
            ..id = report.id
            ..reportId = report.id
            ..attemptCount = 0
            ..enqueuedAt = DateTime.now(),
        );
      }
    });
  }

  Future<void> update(Report report) async {
    await _isar.writeTxn(() async {
      await _isar.reports.put(report);
    });
  }

  Future<void> deleteLocal(String id) async {
    await _isar.writeTxn(() async {
      final report = await _isar.reports.filter().idEqualTo(id).findFirst();
      if (report == null) return;
      if (report.syncStatus == SyncStatus.synced) {
        throw StateError('Synced reports cannot be deleted locally.');
      }
      await _isar.reports.delete(report.isarId);
      final queue = await _isar.syncQueueItems
          .filter()
          .reportIdEqualTo(id)
          .findFirst();
      if (queue != null) {
        await _isar.syncQueueItems.delete(queue.isarId);
      }
    });
  }

  Future<int> count() => _isar.reports.count();

  Future<int> countByRisk(RiskLevel risk) {
    return _isar.reports.filter().riskLevelEqualTo(risk).count();
  }
}

class UserRepository {
  UserRepository(this._isar);

  final Isar _isar;

  Future<UserProfile> ensureLocalProfile(String deviceId) async {
    final existing = await _isar.userProfiles.filter().idEqualTo(deviceId).findFirst();
    if (existing != null) return existing;

    final profile = UserProfile()
      ..id = deviceId
      ..displayName = 'Field worker'
      ..totalPoints = 0
      ..verifiedPoints = 0
      ..reportCount = 0
      ..currentStreak = 0
      ..syncStatus = SyncStatus.pendingUpload;

    await _isar.writeTxn(() async {
      await _isar.userProfiles.put(profile);
    });
    return profile;
  }

  Future<UserProfile?> get() => _isar.userProfiles.where().findFirst();

  Stream<UserProfile?> watch() {
    return _isar.userProfiles
        .where()
        .watch(fireImmediately: true)
        .map((list) => list.isEmpty ? null : list.first);
  }

  Future<void> save(UserProfile profile) async {
    await _isar.writeTxn(() async {
      await _isar.userProfiles.put(profile);
    });
  }

  Future<void> applyNewReport({
    required int points,
    required DateTime capturedAt,
  }) async {
    await _isar.writeTxn(() async {
      final profile = await _isar.userProfiles.where().findFirst();
      if (profile == null) return;

      final last = profile.lastReportDate;
      final today = DateTime(capturedAt.year, capturedAt.month, capturedAt.day);
      if (last == null) {
        profile.currentStreak = 1;
      } else {
        final lastDay = DateTime(last.year, last.month, last.day);
        final difference = today.difference(lastDay).inDays;
        if (difference == 1) {
          profile.currentStreak += 1;
        } else if (difference > 1) {
          profile.currentStreak = 1;
        }
      }

      profile.totalPoints += points;
      profile.reportCount += 1;
      profile.lastReportDate = capturedAt;
      await _isar.userProfiles.put(profile);
    });
  }

  Future<void> reconcileVerifiedPoints(int additionalVerified) async {
    await _isar.writeTxn(() async {
      final profile = await _isar.userProfiles.where().findFirst();
      if (profile == null) return;
      profile.verifiedPoints += additionalVerified;
      await _isar.userProfiles.put(profile);
    });
  }
}

class SyncQueueRepository {
  SyncQueueRepository(this._isar);

  final Isar _isar;

  Future<List<SyncQueueItem>> pending() {
    return _isar.syncQueueItems.where().sortByEnqueuedAt().findAll();
  }

  Future<SyncQueueItem?> byReportId(String reportId) {
    return _isar.syncQueueItems.filter().reportIdEqualTo(reportId).findFirst();
  }

  Future<void> enqueue(String reportId) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.syncQueueItems
          .filter()
          .reportIdEqualTo(reportId)
          .findFirst();
      if (existing != null) return;
      await _isar.syncQueueItems.put(
        SyncQueueItem()
          ..id = reportId
          ..reportId = reportId
          ..attemptCount = 0
          ..enqueuedAt = DateTime.now(),
      );
    });
  }

  Future<void> markAttempt(String reportId, {String? error}) async {
    await _isar.writeTxn(() async {
      final item = await _isar.syncQueueItems
          .filter()
          .reportIdEqualTo(reportId)
          .findFirst();
      if (item == null) return;
      item.attemptCount += 1;
      item.lastError = error;
      await _isar.syncQueueItems.put(item);
    });
  }

  Future<void> remove(String reportId) async {
    await _isar.writeTxn(() async {
      final item = await _isar.syncQueueItems
          .filter()
          .reportIdEqualTo(reportId)
          .findFirst();
      if (item != null) {
        await _isar.syncQueueItems.delete(item.isarId);
      }
    });
  }
}
