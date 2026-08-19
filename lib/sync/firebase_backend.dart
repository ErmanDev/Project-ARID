import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/models/enums.dart';
import '../data/models/report.dart';
import '../data/models/user_profile.dart';
import '../firebase_options.dart';

/// Firestore + Auth only. Images go to Cloudinary, never Firebase Storage.
class FirebaseBackend {
  bool _ready = false;

  bool get isReady => _ready;

  Future<bool> tryInit() async {
    if (_ready) return true;
    if (!DefaultFirebaseOptions.isConfigured) return false;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _ready = true;
      return true;
    } catch (_) {
      _ready = false;
      return false;
    }
  }

  Future<String> ensureAnonymousUser(UserProfile profile) async {
    if (profile.firebaseUid != null &&
        FirebaseAuth.instance.currentUser?.uid == profile.firebaseUid) {
      return profile.firebaseUid!;
    }
    final existing = FirebaseAuth.instance.currentUser;
    if (existing != null) return existing.uid;
    final cred = await FirebaseAuth.instance.signInAnonymously();
    return cred.user!.uid;
  }

  Future<void> upsertReport({
    required Report report,
    required String imageUrl,
    required String firebaseUid,
  }) async {
    await FirebaseFirestore.instance.collection('reports').doc(report.id).set({
      'id': report.id,
      'userId': firebaseUid,
      'localUserId': report.userId,
      'imageUrl': imageUrl,
      'classification': report.classification.name,
      'confidenceScore': report.confidenceScore,
      'riskLevel': report.riskLevel.name,
      'latitude': report.latitude,
      'longitude': report.longitude,
      'gpsAccuracy': report.gpsAccuracy,
      'gpsManual': report.gpsManual,
      'capturedAt': report.capturedAt.toIso8601String(),
      'pointsAwarded': report.pointsAwarded,
      'pointsStatus': PointsStatus.verified.name,
      'syncStatus': SyncStatus.synced.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertUser(UserProfile profile, String firebaseUid) async {
    await FirebaseFirestore.instance.collection('users').doc(firebaseUid).set({
      'localUserId': profile.id,
      'displayName': profile.displayName,
      'totalPoints': profile.totalPoints,
      'verifiedPoints': profile.verifiedPoints,
      'reportCount': profile.reportCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
