import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static bool initialized = false;
  static Object? initializationError;

  static Future<void> tryInitialize() async {
    if (initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      initialized = true;
      initializationError = null;
    } catch (e) {
      initialized = false;
      initializationError = e;
    }
  }

  static String get initializationErrorMessage =>
      initializationError?.toString() ?? 'Firebase is not initialized.';
}
