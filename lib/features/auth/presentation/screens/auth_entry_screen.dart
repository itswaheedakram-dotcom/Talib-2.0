import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/active_profile_controller.dart';
import 'auth_artwork.dart';
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
  final bio = TextEditingController();
  Uint8List? photo;
  bool busy = false, obscure = true, pickingPhoto = false;
  String role = 'student', action = '';
  bool get registering => widget.registering;
  @override void dispose() { bio.dispose(); name.dispose(); email.dispose(); password.dispose(); confirmation.dispose(); super.dispose(); }
  void message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  bool ready() {
    if (FirebaseService.initialized) return true;
    message('Account services are not available yet. You can continue browsing.');
    return false;
  }
  Future<void> submit() async {
    if (busy || pickingPhoto || !form.currentState!.validate() || !ready()) return;
    FocusScope.of(context).unfocus();
    setState(() { busy = true; action = registering ? 'Creating account…' : 'Signing in…'; });
    try {
      final auth = AuthService();
      if (registering) { await auth.register(email.text, password.text, name: name.text, role: role, bio: bio.text, photoBytes: photo); }
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
  Future<void> pickPhoto() async {
    if (busy || pickingPhoto) return;
    setState(() => pickingPhoto = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) { if (mounted) message('Choose a photo smaller than 5 MB.'); return; }
      if (mounted) setState(() => photo = bytes);
    } catch (_) { if (mounted) message('Could not open this photo. Please try another image.'); }
    finally { if (mounted) setState(() => pickingPhoto = false); }
  }
  ColorScheme get colors => Theme.of(context).colorScheme;
  Color get green => colors.primary;
  Color get ink => colors.onSurface;
  Color get muted => colors.onSurface.withOpacity(.65);
  Color get panel => Theme.of(context).inputDecorationTheme.fillColor ?? colors.surface;
  Color get divider => Theme.of(context).dividerTheme.color ?? colors.onSurface.withOpacity(.2);
  InputDecoration decoration(String label, IconData icon, {Widget? suffix, String? helper}) => InputDecoration(
    labelText: label, helperText: helper, prefixIcon: Icon(icon, color: green.withOpacity(.65)), suffixIcon: suffix,
    filled: true, fillColor: colors.surface, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
    labelStyle: TextStyle(color: muted),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: divider.withOpacity(.5))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: green, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: Theme.of(context).colorScheme.error)),
    errorMaxLines: 3, helperMaxLines: 2,
  );
  Widget get visibility => IconButton(tooltip: obscure ? 'Show password' : 'Hide password',
    onPressed: busy ? null : () => setState(() => obscure = !obscure),
    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: green));
  Widget header() => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(registering ? 'Sign Up' : 'Sign in', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: green, letterSpacing: -.8)),
      const SizedBox(height: 8),
      Text(registering ? 'Your next chapter\nstarts here.' : 'Welcome back!', style: TextStyle(fontSize: 17, color: muted, height: 1.5)),
    ])),
    const SizedBox(width: 8),
    if (registering) SizedBox(width: 104, height: 116, child: Stack(alignment: Alignment.center, children: [
      CircleAvatar(radius: 49, backgroundColor: panel, foregroundImage: photo == null ? null : MemoryImage(photo!),
        child: Icon(Icons.person_rounded, size: 78, color: green)),
      Positioned(right: 0, bottom: 5, child: Material(color: colors.surface, shape: const CircleBorder(), elevation: 3,
        child: IconButton(tooltip: 'Add profile photo', onPressed: busy || pickingPhoto ? null : pickPhoto,
          icon: Icon(pickingPhoto ? Icons.hourglass_top : Icons.add_a_photo_outlined, color: green)))),
    ])) else const SizedBox(width: 122, height: 148, child: AuthArtwork()),
  ]);
  @override Widget build(BuildContext context) => PopScope(canPop: !busy, child: Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SafeArea(child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
      child: AutofillGroup(child: Form(key: form, child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: busy ? null : back, tooltip: 'Back', icon: Icon(Icons.arrow_back, color: ink))),
      const SizedBox(height: 12), header(),
      if (registering && photo != null) Align(alignment: Alignment.centerRight, child: TextButton(
        onPressed: busy ? null : () => setState(() => photo = null), child: const Text('Remove photo'))),
      SizedBox(height: registering ? 28 : 38),
      if (registering) ...[
        Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(28)),
          child: Row(children: ['student', 'institute'].map((value) => Expanded(child: Semantics(selected: role == value,
            child: InkWell(borderRadius: BorderRadius.circular(24), onTap: busy ? null : () => setState(() => role = value),
              child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(color: role == value ? green : panel, borderRadius: BorderRadius.circular(24)),
                child: Text(value == 'student' ? 'Student' : 'Institute', textAlign: TextAlign.center,
                  style: TextStyle(color: role == value ? colors.onPrimary : ink, fontWeight: FontWeight.w600))))))).toList())),
        if (role == 'institute') Padding(padding: const EdgeInsets.only(top: 10), child: Text('Institute access requires an approved ownership claim.', style: TextStyle(color: ink, fontSize: 12))),
        const SizedBox(height: 24),
        TextFormField(controller: name, enabled: !busy, validator: AuthFormRules.name, maxLength: 80,
          textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.name],
          decoration: decoration('Full name', Icons.person_outline, helper: 'Your User ID is created automatically from your name.')),
        const SizedBox(height: 14),
        TextFormField(controller: bio, enabled: !busy, maxLength: 300, minLines: 1, maxLines: 3,
          textInputAction: TextInputAction.next, decoration: decoration('Bio (optional)', Icons.edit_note_outlined)),
        const SizedBox(height: 14),
      ],
      TextFormField(key: emailField, controller: email, enabled: !busy, validator: AuthFormRules.email,
        keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
        autocorrect: false, enableSuggestions: false, autofillHints: const [AutofillHints.email, AutofillHints.username],
        decoration: decoration('Email', Icons.mail_outline)),
      const SizedBox(height: 16),
      TextFormField(controller: password, enabled: !busy, obscureText: obscure,
        validator: (value) => AuthFormRules.password(value, registering: registering),
        autocorrect: false, enableSuggestions: false, textInputAction: registering ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: registering ? null : (_) => submit(), autofillHints: [registering ? AutofillHints.newPassword : AutofillHints.password],
        decoration: decoration('Password', Icons.lock_outline, helper: registering ? 'At least 8 characters' : null, suffix: visibility)),
      if (registering) ...[
        const SizedBox(height: 16),
        TextFormField(controller: confirmation, enabled: !busy, obscureText: obscure,
          autocorrect: false, enableSuggestions: false, textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => submit(), autofillHints: const [AutofillHints.newPassword],
          validator: (value) => value == null || value.isEmpty ? 'Confirm your password.' : value != password.text ? 'Passwords do not match.' : null,
          decoration: decoration('Confirm password', Icons.lock_outline)),
      ] else Padding(padding: const EdgeInsets.only(top: 8), child: Align(alignment: Alignment.centerRight,
        child: TextButton(onPressed: busy ? null : resetPassword, child: Text('Forgot password?', style: TextStyle(color: green))))),
      const SizedBox(height: 24),
      FilledButton(onPressed: busy || pickingPhoto ? null : submit,
        style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: colors.onPrimary, padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 2),
        child: Text(busy ? action : registering ? 'Sign up' : 'Sign in', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
      const SizedBox(height: 20),
      Row(children: [Expanded(child: Divider(color: divider)), Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('or', style: TextStyle(color: muted))), Expanded(child: Divider(color: divider))]),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: busy ? null : () { ActiveProfileController.instance.clear(); context.go('/'); },
        style: OutlinedButton.styleFrom(foregroundColor: ink, backgroundColor: panel, side: BorderSide.none,
          padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        icon: const Icon(Icons.person_outline), label: const Text('Continue browsing')),
      const SizedBox(height: 24),
      TextButton(onPressed: busy ? null : () => context.go(registering ? '/signin' : '/register'),
        child: Text(registering ? 'Already have an account? Sign in' : 'Don’t have an account? Sign up', textAlign: TextAlign.center,
          style: TextStyle(color: green, fontWeight: FontWeight.w600))),
    ])))))))));
}
