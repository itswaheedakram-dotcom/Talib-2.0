import 'package:firebase_core/firebase_core.dart';
class FirebaseService {
  static bool initialized = false;
  static Future<void> tryInitialize() async {
    try { await Firebase.initializeApp(); initialized = true; } catch (_) { initialized = false; }
  }
}
