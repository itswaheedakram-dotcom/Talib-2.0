import 'package:flutter/material.dart';
import 'auth_entry_screen.dart';
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override Widget build(BuildContext context) => const AuthEntryScreen(registering: true);
}
