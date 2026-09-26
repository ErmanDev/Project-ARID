import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:isar_community/isar.dart';

import '../../data/models/enums.dart';
import '../../data/models/report.dart';
import '../../data/models/sync_queue_item.dart';
import '../../data/repositories/repositories.dart';
import '../../sync/firebase_backend.dart';

/// Shown when sign-in fails for a reason the user can act on.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Google sign-in for the mobile app, matching the web dashboard's account
/// model: one Firebase Auth user per Google account.
class AuthService {
  AuthService({required Isar isar, required this._backend})
    : _isar = isar,
      _users = UserRepository(isar);

  /// OAuth "Web client" of the arid-dengue-mapping Firebase project
  /// (client_type 3 in android/app/google-services.json). Firebase Auth needs
  /// an ID token issued for this client.
  static const serverClientId =
      '946423882010-orm220bvkki08uk5nchfmmf2iv6i02qo.apps.googleusercontent.com';

  final Isar _isar;
  final UserRepository _users;
  final FirebaseBackend _backend;

  static Future<void>? _googleInit;

  Future<void> _ensureGoogle() =>
      _googleInit ??= GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
      );

  /// Returns null when the user closes the account picker.
  Future<User?> signInWithGoogle() async {
    if (!await _backend.tryInit()) {
      throw const AuthFailure('Sign-in is not available in this build.');
    }
    await _ensureGoogle();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthFailure(
        'Google sign-in failed. Check your connection and try again. '
        '(${error.code.name})',
      );
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthFailure('Google did not return an ID token.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final auth = FirebaseAuth.instance;

    UserCredential result;
    final current = auth.currentUser;
    try {
      // Earlier versions synced under an anonymous account. Linking keeps that
      // uid, so reports already on the map stay attached to this person.
      result = current != null && current.isAnonymous
          ? await current.linkWithCredential(credential)
          : await auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'credential-already-in-use' ||
          error.code == 'provider-already-linked') {
        result = await auth.signInWithCredential(credential);
      } else if (error.code == 'network-request-failed') {
        throw const AuthFailure(
          'You’re offline. Connect to the internet to sign in.',
        );
      } else {
        throw AuthFailure('Sign-in failed (${error.code}).');
      }
    }

    final user = result.user!;
    await _adoptAccount(user);
    return user;
  }

  /// Signs out of Firebase and Google so the next sign-in shows the account
  /// picker again. Local reports stay on the phone until a different account
  /// signs in.
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    try {
      await _ensureGoogle();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Firebase is already signed out, which is what gates the app.
    }
  }

  /// Reports saved on this phone that have not reached the cloud yet.
  Future<int> unsyncedReportCount() =>
      _isar.reports.filter().not().syncStatusEqualTo(SyncStatus.synced).count();

  /// Binds the local profile to [user]. A different account than the one that
  /// last used this phone starts from a clean slate, so one person's reports
  /// and points never sync under another person's account.
  Future<void> _adoptAccount(User user) async {
    final profile = await _users.get();
    if (profile == null) return;

    final previousUid = profile.firebaseUid;
    if (previousUid != null && previousUid != user.uid) {
      await _isar.writeTxn(() async {
        await _isar.reports.clear();
        await _isar.syncQueueItems.clear();
      });
      profile
        ..totalPoints = 0
        ..verifiedPoints = 0
        ..reportCount = 0
        ..currentStreak = 0
        ..lastReportDate = null
        ..displayName = 'Field worker';
    }

    profile.firebaseUid = user.uid;
    final googleName = user.displayName?.trim() ?? '';
    if (googleName.isNotEmpty &&
        (profile.displayName.trim().isEmpty ||
            profile.displayName == 'Field worker')) {
      profile.displayName = googleName;
    }
    await _users.save(profile);
  }
}
