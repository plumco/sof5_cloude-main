// File generated manually based on Firebase project: huliot-so-app
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return web; // fallback to web for now
      case TargetPlatform.iOS:
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBz5uUEJtELw_tjVBPK5fYWFy-N73ISB7I',
    appId: '1:167976306232:web:cf01800cf1dbbbbf5b88cd',
    messagingSenderId: '167976306232',
    projectId: 'huliot-so-app',
    authDomain: 'huliot-so-app.firebaseapp.com',
    storageBucket: 'huliot-so-app.firebasestorage.app',
  );
}
