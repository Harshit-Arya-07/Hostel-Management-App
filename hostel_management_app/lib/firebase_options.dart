// File generated manually for Firebase configuration.
// After running `flutterfire configure`, this file will be auto-generated
// with your actual Firebase project values.
//
// INSTRUCTIONS:
// Replace ALL placeholder values below with your real Firebase project values
// from the Firebase Console (https://console.firebase.google.com).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the current platform.
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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  🔴 REPLACE ALL VALUES BELOW WITH YOUR FIREBASE PROJECT INFO
  //     Found in: Firebase Console → Project Settings → Your apps
  // ═══════════════════════════════════════════════════════════════

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC_Yn7wcoElppNRRDID3mM2TU9YIaieQig',
    appId: '1:1081125043924:android:8df70479c9c9726c108541',
    messagingSenderId: '1081125043924',
    projectId: 'hostel-management-system-aedff',
    storageBucket: 'hostel-management-system-aedff.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-IOS-API-KEY',                          // e.g. AIzaSyB...
    appId: 'YOUR-IOS-APP-ID',                            // e.g. 1:123456789:ios:def456
    messagingSenderId: 'YOUR-MESSAGING-SENDER-ID',       // e.g. 123456789
    projectId: 'YOUR-PROJECT-ID',                        // e.g. hostel-management-app
    storageBucket: 'YOUR-STORAGE-BUCKET',                // e.g. hostel-management-app.appspot.com
    iosBundleId: 'com.example.hostelManagementApp',      // Your iOS bundle ID
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR-WEB-API-KEY',                          // e.g. AIzaSyC...
    appId: 'YOUR-WEB-APP-ID',                            // e.g. 1:123456789:web:ghi789
    messagingSenderId: 'YOUR-MESSAGING-SENDER-ID',       // e.g. 123456789
    projectId: 'YOUR-PROJECT-ID',                        // e.g. hostel-management-app
    authDomain: 'YOUR-AUTH-DOMAIN',                      // e.g. hostel-management-app.firebaseapp.com
    storageBucket: 'YOUR-STORAGE-BUCKET',                // e.g. hostel-management-app.appspot.com
  );
}