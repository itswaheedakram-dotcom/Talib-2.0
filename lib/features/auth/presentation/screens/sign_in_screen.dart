import 'package:flutter/material.dart';
import 'auth_entry_screen.dart';
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});
  @override Widget build(BuildContext context) => const AuthEntryScreen(registering: false);
}
