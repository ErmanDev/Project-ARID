import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar_community/isar.dart';

import '../../data/models/enums.dart';
import '../../data/models/report.dart';
import '../../data/models/sync_queue_item.dart';
import '../../data/repositories/repositories.dart';
import '../../sync/firebase_backend.dart';

/// Shown when sign-in or registration fails for a reason the user can act on.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A signed-in account that is allowed to use the app.
class AppAccount {
  const AppAccount({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.role,
  });

  final String uid;
  final String username;
  final String displayName;

  /// `staff` for every mobile sign-up, or `admin`.
  final String role;

  bool get isAdmin => role == 'admin';
}

/// Username and password accounts, shared with the web dashboard.
///
/// Firebase Auth needs an email, so each username signs in as
/// `<username>@arid.local`. No mail is ever sent to that address. The account's
/// role and verification live in Firestore `users/{uid}`.
class AuthService {
  AuthService({required Isar isar, required this._backend})
    : _isar = isar,
      _users = UserRepository(isar);

  static const usernameDomain = 'arid.local';
  static const minPasswordLength = 6;
  static const minimumAge = 15;

  final Isar _isar;
  final UserRepository _users;
  final FirebaseBackend _backend;

  static String normalizeUsername(String value) => value.trim().toLowerCase();

  static String emailFor(String username) =>
      '${normalizeUsername(username)}@$usernameDomain';

  /// A problem with [value] as a new username, or null when it is usable.
  static String? usernameProblem(String value) {
    final username = normalizeUsername(value);
    if (username.length < 3) return 'Use at least 3 characters.';
    if (username.length > 30) return 'Use 30 characters or fewer.';
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(username)) {
      return 'Use letters, numbers, dots, dashes, or underscores.';
    }
    return null;
  }

  /// Whole years from [birthDate] to [today].
  static int ageOn(DateTime birthDate, DateTime today) {
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age -= 1;
    }
    return age;
  }

  /// "YYYY-MM-DD", the format stored in Firestore.
  static String formatBirthDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// "Juan D. Dela Cruz".
  static String displayNameFor(String first, String middle, String last) => [
    first.trim(),
    if (middle.trim().isNotEmpty) '${middle.trim()[0].toUpperCase()}.',
    last.trim(),
  ].join(' ');

  static DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  /// The account for [user] when it may use the app, or a reason it may not.
  static Future<({AppAccount? account, String? problem})> check(
    User user,
  ) async {
    final snap = await _profileRef(user.uid).get();
    final data = snap.data();
    if (data == null) {
      return (
        account: null,
        problem: 'This account has no A.R.I.D. profile. Register again.',
      );
    }
    switch (data['status']) {
      case 'verified':
        break;
      case 'rejected':
        return (
          account: null,
          problem:
              'Your registration was not approved. Contact your '
              'administrator.',
        );
      default:
        return (
          account: null,
          problem:
              'Your account is waiting for approval. You can sign in once an '
              'admin verifies it.',
        );
    }
    return (
      account: AppAccount(
        uid: user.uid,
        username: (data['username'] as String?) ?? '',
        displayName: (data['displayName'] as String?) ?? '',
        role: (data['role'] as String?) ?? 'staff',
      ),
      problem: null,
    );
  }

  Future<void> signIn(String username, String password) async {
    await _ensureFirebase();
    final auth = FirebaseAuth.instance;
    final UserCredential credential;
    try {
      credential = await auth.signInWithEmailAndPassword(
        email: emailFor(username),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_message(error));
    }

    final result = await _checkOrSignOut(credential.user!);
    await _adoptAccount(result);
  }

  /// Submits a staff registration. The account stays pending, and signed out,
  /// until an admin verifies it on the dashboard.
  Future<void> register({
    required String firstName,
    required String middleName,
    required String lastName,
    required DateTime birthDate,
    required String username,
    required String password,
  }) async {
    await _ensureFirebase();
    final normalized = normalizeUsername(username);
    final auth = FirebaseAuth.instance;

    User user;
    try {
      user = (await auth.createUserWithEmailAndPassword(
        email: emailFor(normalized),
        password: password,
      )).user!;
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') {
        throw AuthFailure(_message(error));
      }
      // An admin may have deleted this person's earlier request. The login
      // still exists, so let its owner (who knows the password) register again.
      user = await _reclaimDeletedRegistration(normalized, password);
    }

    try {
      await _profileRef(user.uid).set({
        'username': normalized,
        'firstName': firstName.trim(),
        'middleName': middleName.trim(),
        'lastName': lastName.trim(),
        'displayName': displayNameFor(firstName, middleName, lastName),
        'birthDate': formatBirthDate(birthDate),
        'role': 'staff',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'totalPoints': 0,
        'verifiedPoints': 0,
        'reportCount': 0,
      });
    } catch (_) {
      throw const AuthFailure(
        'Couldn’t submit your registration. Check your connection and try '
        'again.',
      );
    } finally {
      await auth.signOut();
    }
  }

  Future<User> _reclaimDeletedRegistration(
    String username,
    String password,
  ) async {
    const taken = AuthFailure('That username is already taken.');
    final auth = FirebaseAuth.instance;
    final User user;
    try {
      user = (await auth.signInWithEmailAndPassword(
        email: emailFor(username),
        password: password,
      )).user!;
    } on FirebaseAuthException {
      throw taken;
    }
    final existing = await _profileRef(user.uid).get();
    if (existing.exists) {
      await auth.signOut();
      throw taken;
    }
    return user;
  }

  /// Local reports stay on the phone until a different account signs in.
  Future<void> signOut() => FirebaseAuth.instance.signOut();

  /// Reports saved on this phone that have not reached the cloud yet.
  Future<int> unsyncedReportCount() =>
      _isar.reports.filter().not().syncStatusEqualTo(SyncStatus.synced).count();

  Future<void> _ensureFirebase() async {
    if (!await _backend.tryInit()) {
      throw const AuthFailure('Sign-in is not available in this build.');
    }
  }

  Future<AppAccount> _checkOrSignOut(User user) async {
    final ({AppAccount? account, String? problem}) result;
    try {
      result = await check(user);
    } catch (_) {
      await FirebaseAuth.instance.signOut();
      throw const AuthFailure(
        'Couldn’t load your account. Check your connection and try again.',
      );
    }
    if (result.account == null) {
      await FirebaseAuth.instance.signOut();
      throw AuthFailure(result.problem!);
    }
    return result.account!;
  }

  /// Binds the local profile to [account]. A different account than the one
  /// that last used this phone starts from a clean slate, so one person's
  /// reports and points never sync under another person's account.
  Future<void> _adoptAccount(AppAccount account) async {
    final profile = await _users.get();
    if (profile == null) return;

    final previousUid = profile.firebaseUid;
    if (previousUid != null && previousUid != account.uid) {
      await _isar.writeTxn(() async {
        await _isar.reports.clear();
        await _isar.syncQueueItems.clear();
      });
      profile
        ..totalPoints = 0
        ..verifiedPoints = 0
        ..reportCount = 0
        ..currentStreak = 0
        ..lastReportDate = null;
    }

    profile
      ..firebaseUid = account.uid
      ..displayName = account.displayName.trim().isEmpty
          ? account.username
          : account.displayName.trim();
    await _users.save(profile);
  }

  static String _message(FirebaseAuthException error) => switch (error.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-email' => 'Wrong username or password.',
    'email-already-in-use' => 'That username is already taken.',
    'weak-password' =>
      'Use a password with at least $minPasswordLength characters.',
    'user-disabled' =>
      'This account has been disabled. Contact your administrator.',
    'too-many-requests' =>
      'Too many attempts. Wait a few minutes, then try again.',
    'network-request-failed' =>
      'You’re offline. Connect to the internet to sign in.',
    _ => 'Sign-in failed (${error.code}). Try again.',
  };
}
