import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static bool get isConfigured =>
      android.apiKey.startsWith('AIza') && ios.apiKey.startsWith('AIza');

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('A.R.I.D. mobile is not a web app. Use /dashboard.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported on this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD5jkh19PsnHeRghvnnrxmQDmVxU-4pCd4',
    appId: '1:946423882010:android:9782b79ff5f4425b538ca3',
    messagingSenderId: '946423882010',
    projectId: 'arid-dengue-mapping',
    storageBucket: 'arid-dengue-mapping.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBQVq_vL4GNpLemvq6bCiaYaC_oj_q-Wjo',
    appId: '1:946423882010:ios:4018dd81f28119d1538ca3',
    messagingSenderId: '946423882010',
    projectId: 'arid-dengue-mapping',
    storageBucket: 'arid-dengue-mapping.firebasestorage.app',
    iosBundleId: 'ph.arid.arid',
  );
}
