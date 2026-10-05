import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!FirebaseService.initialized) {
      _message('Firebase is not configured yet.');
      return;
    }
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _message('Enter your email and password.');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService().signIn(_email.text, _password.text);
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      if (mounted) _message(_authMessage(e));
    } catch (_) {
      if (mounted) _message('Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _message('Enter your email first, then tap Forgot password.');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService().sendPasswordReset(email);
      if (mounted) _message('Password reset email sent. Check your inbox.');
    } on FirebaseAuthException catch (e) {
      if (mounted) _message(_authMessage(e));
    } catch (_) {
      if (mounted) _message('Could not send the reset email.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _anonymousSignIn() async {
    if (!FirebaseService.initialized) {
      _message('Firebase is not configured yet.');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService().signInAnonymously();
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      if (mounted) _message(_authMessage(e));
    } catch (_) {
      if (mounted) _message('Anonymous sign in failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00A66A);
    const darkGreen = Color(0xFF00543D);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            IconButton(
              onPressed: () => context.pop(),
              alignment: Alignment.centerLeft,
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sign in',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: darkGreen),
            ),
            const SizedBox(height: 4),
            Text('Welcome back!', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 28),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.phone_android_rounded, size: 88, color: green),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _forgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _busy ? null : _signIn,
                style: FilledButton.styleFrom(backgroundColor: green),
                child: Text(_busy ? 'Signing in...' : 'Sign in'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _anonymousSignIn,
              child: const Text('Continue as guest'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('or continue with'),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _message('Google sign-in requires Google provider setup in Firebase.'),
                  icon: const Icon(Icons.g_mobiledata, size: 32),
                ),
                IconButton(
                  onPressed: () => _message('Apple sign-in requires Apple provider setup in Firebase.'),
                  icon: const Icon(Icons.apple, size: 28),
                ),
                IconButton(
                  onPressed: () => _message('Facebook sign-in requires Facebook provider setup in Firebase.'),
                  icon: const Icon(Icons.facebook, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('Don’t have an account? Sign up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
