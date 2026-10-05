import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static bool initialized = false;
  static String? initializationError;

  static Future<void> tryInitialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      initialized = true;
      initializationError = null;
    } on FirebaseException catch (e) {
      initialized = false;
      initializationError = e.code + ': ' +
          (e.message ?? 'Firebase initialization failed.');
    } catch (e) {
      initialized = false;
      initializationError = e.toString();
    }
  }
}
