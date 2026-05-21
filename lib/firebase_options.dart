import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZ7w8cOsOsO9XggPkwk04X67hcPHetBMA',
    appId: '1:508106937166:android:6210f6e007690c4eaac41f',
    messagingSenderId: '508106937166',
    projectId: 'fitcoach-eaf71',
    storageBucket: 'fitcoach-eaf71.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAZ7w8cOsOsO9XggPkwk04X67hcPHetBMA',
    appId: '1:508106937166:android:6210f6e007690c4eaac41f',
    messagingSenderId: '508106937166',
    projectId: 'fitcoach-eaf71',
    storageBucket: 'fitcoach-eaf71.firebasestorage.app',
    authDomain: 'fitcoach-eaf71.firebaseapp.com',
  );
}
