import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sign In')),
    body: Padding(padding: const EdgeInsets.all(20),child: Column(children: [
      const TextField(decoration: InputDecoration(labelText: 'Email')),
      const SizedBox(height: 12),
      const TextField(obscureText: true,decoration: InputDecoration(labelText: 'Password')),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity,child: FilledButton(onPressed: () {},child: const Text('Sign In'))),
      TextButton(onPressed: () => context.push('/register'),child: const Text('Create an account')),
    ])),
  );
}
