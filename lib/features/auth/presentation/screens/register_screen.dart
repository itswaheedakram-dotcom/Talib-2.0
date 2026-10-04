import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firebase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'Student';
  bool _busy = false;
  bool _obscure = true;

  @override void dispose() {
    _name.dispose(); _email.dispose(); _password.dispose(); super.dispose();
  }

  Future<void> _register() async {
    if (!FirebaseService.initialized) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firebase is not configured yet.')));
      return;
    }
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your name, a valid email and a password of at least 6 characters.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await AuthService().register(_email.text.trim(), _password.text);
      await result.user?.updateDisplayName(_name.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created successfully.')));
        context.go('/');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Registration failed.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed. Please try again.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override Widget build(BuildContext context) {
    const green = Color(0xFF00A66A);
    const darkGreen = Color(0xFF00543D);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            Row(children: [
              IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, size: 18)),
              const Spacer(),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Sign Up', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: darkGreen)),
                const SizedBox(height: 5),
                Text('Join Talib and start your educational journey.', style: TextStyle(color: Colors.grey.shade600)),
              ])),
              CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFFEAF8F2),
                child: Icon(_role == 'Student' ? Icons.person : Icons.business, size: 48, color: green),
              ),
            ]),
            const SizedBox(height: 22),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Student', label: Text('Student'), icon: Icon(Icons.person_outline)),
                ButtonSegment(value: 'Institute', label: Text('Institute'), icon: Icon(Icons.business_outlined)),
              ],
              selected: {_role},
              onSelectionChanged: (v) => setState(() => _role = v.first),
            ),
            const SizedBox(height: 18),
            _field(_name, 'Full Name', Icons.person_outline),
            _field(_email, 'Email or Username', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined)),
              ),
            ),
            const SizedBox(height: 12),
            Text('By signing up, you agree to our Terms & Conditions and Privacy Policy.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 18),
            SizedBox(height: 50, child: FilledButton(
              onPressed: _busy ? null : _register,
              style: FilledButton.styleFrom(backgroundColor: green),
              child: Text(_busy ? 'Creating account...' : 'Sign Up'),
            )),
            const SizedBox(height: 15),
            Row(children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or continue with')),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _social(Icons.g_mobiledata, 'Google'),
              const SizedBox(width: 10),
              _social(Icons.apple, 'Apple'),
              const SizedBox(width: 10),
              _social(Icons.facebook, 'Facebook'),
            ]),
            const SizedBox(height: 18),
            Center(child: TextButton(
              onPressed: () => context.push('/signin'),
              child: const Text('Already have an account? Sign in'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {TextInputType? keyboardType}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: c, keyboardType: keyboardType, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon))),
  );

  Widget _social(IconData icon, String label) => OutlinedButton(
    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label sign-in will be connected later.'))),
    child: Icon(icon),
  );
}
