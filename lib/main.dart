import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start the UI first so a Firebase/platform initialization problem
  // cannot prevent the application from launching.
  runApp(const TalibApp());

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await FirebaseService.tryInitialize();
  });
}
