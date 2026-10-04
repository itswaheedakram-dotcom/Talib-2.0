import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/auth_service.dart';
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});
  @override
  Widget build(BuildContext context) {
    if (!FirebaseService.initialized) {
      return Scaffold(appBar: AppBar(title: const Text('Sign In')), body: const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Sign in is unavailable until Firebase is configured for this Android app.', textAlign: TextAlign.center))));
    }
    final email = TextEditingController();
    final password = TextEditingController();
    return Scaffold(
    appBar: AppBar(title: const Text('Sign In')),
    body: Padding(padding: const EdgeInsets.all(20),child: Column(children: [
      TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
      const SizedBox(height: 12),
      TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity,child: FilledButton(onPressed: () async {
        try { await AuthService().signIn(email.text.trim(), password.text); if (context.mounted) context.go('/'); }
        catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in failed. Check your email and password.'))); }
      },child: const Text('Sign In'))),
      TextButton(onPressed: () => context.push('/register'),child: const Text('Create an account')),
    ])),
  );
  }
