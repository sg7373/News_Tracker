import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyADOxNpH9zwmEPdKfCzT1gb4_2TpZ9fRsE',
    authDomain: 'news-web-7c134.firebaseapp.com',
    projectId: 'news-web-7c134',
    storageBucket: 'news-web-7c134.firebasestorage.app',
    messagingSenderId: '385757213775',
    appId: '1:385757213775:web:5896e65f8d4e4378c9a63a',
    measurementId: 'G-BM3MGC5TPL',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyADOxNpH9zwmEPdKfCzT1gb4_2TpZ9fRsE',
    appId: '1:385757213775:android:ba96dc0f993dc55896e65f',
    messagingSenderId: '385757213775',
    projectId: 'news-web-7c134',
    storageBucket: 'news-web-7c134.firebasestorage.app',
  );
}
