import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static bool initialized = false;
  static Object? initializationError;

  static String get initializationErrorMessage {
    final error=initializationError;
    if(error==null) return '';
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  static Future<void> tryInitialize() async {
    try {
      await Firebase.initializeApp();
      initialized=true;
      initializationError=null;
    } catch(error) {
      initialized=false;
      initializationError=error;
    }
  }
}
