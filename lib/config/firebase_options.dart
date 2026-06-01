import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // Android config from google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBm4xo5u8TSPEWXWgoU6zFG359zKRUaWPU',
    appId: '1:255881779850:android:0ab61d16dff904df182b73',
    messagingSenderId: '255881779850',
    projectId: 'usto1-17806',
    storageBucket: 'usto1-17806.firebasestorage.app',
  );

  // Web config from Firebase Console Web App registration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBt14MShngpxVR9BemmzcP1M2qvkBSOkGU',
    appId: '1:255881779850:web:0a633aa3ffc9c0a0182b73',
    messagingSenderId: '255881779850',
    projectId: 'usto1-17806',
    storageBucket: 'usto1-17806.firebasestorage.app',
    authDomain: 'usto1-17806.firebaseapp.com',
    measurementId: 'G-ZXD3K17GFN',
  );

  // iOS placeholder
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBm4xo5u8TSPEWXWgoU6zFG359zKRUaWPU',
    appId: '1:255881779850:android:0ab61d16dff904df182b73',
    messagingSenderId: '255881779850',
    projectId: 'usto1-17806',
    storageBucket: 'usto1-17806.firebasestorage.app',
    iosBundleId: 'com.ustoconnect.connect',
  );
}
