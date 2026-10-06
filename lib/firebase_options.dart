import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1mXCU4KytS7Ya0dFwCowdzjhaQVYJseQ',
    appId: '1:440279567447:android:25dd1161e76a1b298c6712',
    messagingSenderId: '440279567447',
    projectId: 'talib-b1b73',
    storageBucket: 'talib-b1b73.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform => android;
}
