import 'dart:async';

import '../config/cloudinary_options.dart';
import '../data/models/enums.dart';
import '../data/repositories/config_repository.dart';
import '../data/repositories/repositories.dart';
import 'cloudinary_store.dart';
import 'firebase_backend.dart';

class SyncResult {
  const SyncResult({
    this.uploaded = 0,
    this.failed = 0,
    this.skipped = 0,
    this.message,
  });

  final int uploaded;
  final int failed;
  final int skipped;
  final String? message;
}

/// Orchestrates Cloudinary image upload + Firestore metadata write.
/// UI never calls either cloud service directly.
class SyncService {
  SyncService({
    required this._reports,
    required this._users,
    required this._queue,
    required this._config,
    required this._backend,
  });

  final ReportRepository _reports;
  final UserRepository _users;
  final SyncQueueRepository _queue;
  final ConfigRepository _config;
  final FirebaseBackend _backend;

  bool _running = false;

  Future<SyncResult> syncPending() async {
    if (_running) {
      return const SyncResult(message: 'Sync already running');
    }
    _running = true;
    try {
      final ready = await _backend.tryInit();
      if (!ready) {
        return const SyncResult(
          message: 'Cloud is not configured yet. Local data is safe.',
        );
      }

      final cloudName = _firstNonEmpty([
        await _config.get(ConfigKeys.cloudinaryCloudName),
        CloudinaryOptions.compiledCloudName,
      ]);
      final preset = _firstNonEmpty([
        await _config.get(ConfigKeys.cloudinaryUploadPreset),
        CloudinaryOptions.compiledPreset,
      ]);
      if (!CloudinaryOptions.isConfigured(cloudName, preset)) {
        return const SyncResult(
          message:
              'Cloudinary is not set up yet. Photos stay on this device. Add your free cloud name and unsigned preset in Profile.',
        );
      }
      final media = CloudinaryStore(cloudName: cloudName, uploadPreset: preset);

      final profile = await _users.get();
      if (profile == null) {
        return const SyncResult(message: 'No local profile');
      }

      final firebaseUid = await _backend.ensureAnonymousUser(profile);
      if (profile.firebaseUid != firebaseUid) {
        profile.firebaseUid = firebaseUid;
        await _users.save(profile);
      }

      final maxRetries = await _config.getInt(
        ConfigKeys.maxSyncRetries,
        fallback: 8,
      );
      final items = await _queue.pending();
      var uploaded = 0;
      var failed = 0;
      var skipped = 0;

      for (final item in items) {
        if (item.attemptCount >= maxRetries) {
          skipped += 1;
          continue;
        }
        final report = await _reports.getById(item.reportId);
        if (report == null) {
          await _queue.remove(item.reportId);
          continue;
        }

        report.syncStatus = SyncStatus.uploading;
        report.lastSyncAttempt = DateTime.now();
        await _reports.update(report);

        try {
          final url = await media.upload(report);
          await _backend.upsertReport(
            report: report,
            imageUrl: url,
            firebaseUid: firebaseUid,
          );
          report.imageRemoteUrl = url;
          report.syncStatus = SyncStatus.synced;
          if (report.pointsStatus == PointsStatus.provisional) {
            report.pointsStatus = PointsStatus.verified;
            await _users.reconcileVerifiedPoints(report.pointsAwarded);
          }
          await _reports.update(report);
          await _queue.remove(report.id);
          uploaded += 1;
        } catch (error) {
          report.syncStatus = SyncStatus.failed;
          await _reports.update(report);
          await _queue.markAttempt(report.id, error: error.toString());
          failed += 1;
        }
      }

      await _backend.upsertUser(profile, firebaseUid);
      return SyncResult(uploaded: uploaded, failed: failed, skipped: skipped);
    } finally {
      _running = false;
    }
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}
