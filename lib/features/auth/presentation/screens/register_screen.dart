import 'package:flutter/material.dart';
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Register')),
    body: Padding(padding: const EdgeInsets.all(20),child: Column(children: [
      const TextField(decoration: InputDecoration(labelText: 'Name')),
      const SizedBox(height: 12),
      const TextField(decoration: InputDecoration(labelText: 'Email')),
      const SizedBox(height: 12),
      const TextField(obscureText: true,decoration: InputDecoration(labelText: 'Password')),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity,child: FilledButton(onPressed: () => Navigator.pop(context),child: const Text('Register'))),
    ])),
  );
}
