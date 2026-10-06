import 'dart:async';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TalibApp());
  unawaited(FirebaseService.initialize().timeout(const Duration(seconds: 8), onTimeout: () => false));
}
