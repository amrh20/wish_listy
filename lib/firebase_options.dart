// File generated using data from google-services.json
// apiKey MUST match: AIzaSyBt8xH6o3nEoMpj34zvqvI1iITI4-O4m9c

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBt8xH6o3nEoMpj34zvqvI1iITI4-O4m9c',
    appId: '1:612667986143:android:fb30c863c3d40b69f1196a',
    messagingSenderId: '612667986143',
    projectId: 'wish-listy-7427e',
    storageBucket: 'wish-listy-7427e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBt8xH6o3nEoMpj34zvqvI1iITI4-O4m9c',
    appId: '1:612667986143:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '612667986143',
    projectId: 'wish-listy-7427e',
    storageBucket: 'wish-listy-7427e.firebasestorage.app',
    iosBundleId: 'com.example.wishListy',
  );
}
