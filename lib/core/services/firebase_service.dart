import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static bool initialized = false;
  static String? initializationError;

  static Future<bool> initialize() async {
    if (initialized) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      initialized = Firebase.apps.isNotEmpty;
      initializationError = initialized ? null : 'Firebase did not initialize.';
    } on FirebaseException catch (e) {
      initialized = false;
      initializationError = '${e.code}: ${e.message ?? 'Firebase initialization failed.'}';
    } catch (e) {
      initialized = false;
      initializationError = e.toString();
    }
    return initialized;
  }

  static Future<void> tryInitialize() async {
    await initialize();
  }
}