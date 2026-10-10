import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/auth_form_rules.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firebase_service.dart';

class AuthEntryScreen extends StatefulWidget {
  final bool registering;
  const AuthEntryScreen({super.key, required this.registering});
  @override State<AuthEntryScreen> createState() => _AuthEntryScreenState();
}
class _AuthEntryScreenState extends State<AuthEntryScreen> {
  final form = GlobalKey<FormState>();
  final emailField = GlobalKey<FormFieldState<String>>();
  final name = TextEditingController(), email = TextEditingController();
  final password = TextEditingController(), confirmation = TextEditingController();
  bool busy = false, obscure = true;
  String role = 'student', action = '';
  bool get registering => widget.registering;
  @override void dispose() { name.dispose(); email.dispose(); password.dispose(); confirmation.dispose(); super.dispose(); }
  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  bool ready() {
    if (FirebaseService.initialized) return true;
    message('Account services are not available yet. You can continue browsing.');
    return false;
  }
  Future<void> submit() async {
    if (busy || !form.currentState!.validate() || !ready()) return;
    FocusScope.of(context).unfocus();
    setState(() { busy = true; action = registering ? 'Creating account…' : 'Signing in…'; });
    try {
      final auth = AuthService();
      if (registering) { await auth.register(email.text, password.text, name: name.text, role: role); }
      else { await auth.signIn(email.text, password.text); }
      TextInput.finishAutofillContext(shouldSave: true);
      if (mounted) { if (registering) message('Account created. Your User ID has been assigned automatically.'); context.go('/'); }
    } on AccountSetupIncomplete {
      if (mounted) message('Your account exists, but the profile could not be loaded. Check your connection, then sign in to retry.');
    } on FirebaseAuthException catch (error) {
      if (mounted) message(AuthFormRules.error(error.code));
    } catch (_) { if (mounted) message('Could not complete this action. Please try again.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> resetPassword() async {
    if (busy || !(emailField.currentState?.validate() ?? false) || !ready()) return;
    setState(() { busy = true; action = 'Sending reset instructions…'; });
    try {
      await AuthService().sendPasswordReset(email.text);
      if (mounted) message('If an account exists for this email, reset instructions will be sent. Check your inbox and spam folder.');
    } on FirebaseAuthException catch (error) {
      if (mounted) message(error.code == 'user-not-found'
        ? 'If an account exists for this email, reset instructions will be sent.' : AuthFormRules.error(error.code));
    } catch (_) { if (mounted) message('Could not send reset instructions. Please try again.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  void back() { if (context.canPop()) { context.pop(); } else { context.go('/'); } }
  @override Widget build(BuildContext context) => PopScope(canPop: !busy, child: Scaffold(
    appBar: AppBar(title: Text(registering ? 'Create account' : 'Sign in'),
      leading: IconButton(onPressed: busy ? null : back, tooltip: 'Back', icon: const Icon(Icons.arrow_back))),
    body: SafeArea(child: AutofillGroup(child: Form(key: form, child: ListView(
      padding: const EdgeInsets.all(24), children: [
      Text(registering ? 'Join Talib' : 'Welcome back', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text(registering ? 'Create your account to connect with students and universities.' : 'Sign in with your email and password.'),
      const SizedBox(height: 24),
      if (registering) ...[
        SegmentedButton<String>(segments: const [
          ButtonSegment(value: 'student', label: Text('Student'), icon: Icon(Icons.person_outline)),
          ButtonSegment(value: 'institute', label: Text('Institute'), icon: Icon(Icons.business_outlined)),
        ], selected: {role}, onSelectionChanged: busy ? null : (values) => setState(() => role = values.first)),
        if (role == 'institute') const Padding(padding: EdgeInsets.only(top: 8),
          child: Text('Institute access requires a separate approved ownership claim.')),
        const SizedBox(height: 16),
        TextFormField(controller: name, enabled: !busy, validator: AuthFormRules.name, maxLength: 80,
          textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))),
      ],
      TextFormField(key: emailField, controller: email, enabled: !busy, validator: AuthFormRules.email,
        keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
        autocorrect: false, enableSuggestions: false,
        autofillHints: const [AutofillHints.email, AutofillHints.username],
        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
      const SizedBox(height: 16),
      TextFormField(controller: password, enabled: !busy, obscureText: obscure,
        validator: (value) => AuthFormRules.password(value, registering: registering),
        autocorrect: false, enableSuggestions: false,
        textInputAction: registering ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: registering ? null : (_) => submit(),
        autofillHints: [registering ? AutofillHints.newPassword : AutofillHints.password],
        decoration: InputDecoration(labelText: 'Password', helperText: registering ? 'At least 8 characters' : null,
          prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(
            tooltip: obscure ? 'Show password' : 'Hide password',
            onPressed: busy ? null : () => setState(() => obscure = !obscure),
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined)))),
      if (registering) ...[
        const SizedBox(height: 16),
        TextFormField(controller: confirmation, enabled: !busy, obscureText: obscure,
          autocorrect: false, enableSuggestions: false, textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => submit(), autofillHints: const [AutofillHints.newPassword],
          validator: (value) => value == null || value.isEmpty ? 'Confirm your password.'
            : value != password.text ? 'Passwords do not match.' : null,
          decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline))),
      ] else Align(alignment: Alignment.centerRight, child: TextButton(onPressed: busy ? null : resetPassword,
        child: const Text('Forgot password?'))),
      const SizedBox(height: 24),
      FilledButton(onPressed: busy ? null : submit, child: Padding(padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(busy ? action : registering ? 'Create account' : 'Sign in'))),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: busy ? null : () { ActiveProfileController.instance.clear(); context.go('/'); },
        child: const Text('Continue browsing')),
      TextButton(onPressed: busy ? null : () => context.go(registering ? '/signin' : '/register'),
        child: Text(registering ? 'Already have an account? Sign in' : 'Don’t have an account? Sign up')),
    ]))))));
}
