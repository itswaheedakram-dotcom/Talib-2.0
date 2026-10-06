import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _privateProfile = false;
  bool _loadingPreferences = true;
  bool _savingPreference = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = _user;
    if (user == null) {
      if (mounted) setState(() => _loadingPreferences = false);
      return;
    }

    try {
      final data = (await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get())
          .data();

      if (!mounted) return;
      setState(() {
        _notifications = data?['notificationsEnabled'] as bool? ?? true;
        _privateProfile = data?['privateProfile'] as bool? ?? false;
        _loadingPreferences = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPreferences = false);
    }
  }

  Future<void> _savePreference(String field, bool value) async {
    final user = _user;
    if (user == null || _savingPreference) return;

    setState(() => _savingPreference = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      if (!mounted) return;
      if (field == 'notificationsEnabled') {
        setState(() => _notifications = !value);
      } else {
        setState(() => _privateProfile = !value);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this setting. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _savingPreference = false);
    }
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();

    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (current.text.isEmpty ||
                  next.text.length < 6 ||
                  next.text != confirm.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Use a 6+ character password and make sure both new passwords match.'),
                  ),
                );
                return;
              }
              context.pop([current.text, next.text]);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    final oldPassword = values?[0];
    final newPassword = values?[1];
    current.dispose();
    next.dispose();
    confirm.dispose();

    if (oldPassword == null || newPassword == null) return;

    try {
      await AuthService().changePassword(
        currentPassword: oldPassword,
        newPassword: newPassword,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'wrong-password' || 'invalid-credential' =>
          'Current password is incorrect.',
        'password-not-supported' =>
          'This account does not use an email and password sign-in.',
        'requires-recent-login' =>
          'Please sign in again, then change your password.',
        _ => e.message ?? 'Could not update your password.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update your password. Please try again.')),
        );
      }
    }
  }

  Future<void> _showAccountInfo() async {
    final u = _user;
    if (u == null) return;
    final providers = u.providerData.map((p) => p.providerId == 'password' ? 'Email & password' : p.providerId).join(', ');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account information'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _infoRow('Name', u.displayName?.trim().isNotEmpty == true ? u.displayName! : 'Not set'),
          _infoRow('Email', u.email ?? 'Not available'),
          _infoRow('Sign-in method', providers.isEmpty ? 'Unknown' : providers),
        ]),
        actions: [TextButton(onPressed: () => context.pop(), child: const Text('Close'))],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 105, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
      Expanded(child: Text(value)),
    ]),
  );

  Future<void> _deleteAccount() async {
    final u = _user;
    if (u == null) return;
    final confirm = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('This permanently deletes your account. This action cannot be undone.'),
          const SizedBox(height: 14),
          TextField(controller: confirm, decoration: const InputDecoration(labelText: 'Type DELETE to confirm')),
        ]),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => context.pop(confirm.text.trim().toUpperCase() == 'DELETE'), child: const Text('Delete')),
        ],
      ),
    );
    confirm.dispose();
    if (confirmed != true) return;
    try {
      await u.delete();
      if (mounted) context.go('/signin');
    } on FirebaseAuthException catch (e) {
      final message = e.code == 'requires-recent-login'
          ? 'Please sign in again, then delete your account.'
          : (e.message ?? 'Could not delete the account.');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete the account. Please try again.')));
    }
  }

  Future<void> _setAppearance() async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Appearance'),
        children: [
          _modeTile(ThemeMode.system, 'System default', Icons.brightness_auto_outlined),
          _modeTile(ThemeMode.light, 'Light', Icons.light_mode_outlined),
          _modeTile(ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
        ],
      ),
    );
    if (selected != null) ThemeController.instance.setMode(selected);
  }

  Widget _modeTile(ThemeMode mode, String title, IconData icon) => SimpleDialogOption(
    onPressed: () => Navigator.of(context).pop(mode),
    child: Row(children: [Icon(icon, color: AppColors.primaryGreen), const SizedBox(width: 14), Text(title)]),
  );

  Future<void> _setPrivateProfile(bool value) async {
    setState(() => _privateProfile = value);
    await _savePreference('privateProfile', value);
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notifications = value);
    await _savePreference('notificationsEnabled', value);
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (mounted) context.go('/signin');
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access your account.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => context.pop(true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) await _signOut();
  }

  void _comingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title settings will be available soon.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 28), children: [
      _sectionTitle('Account & Security'),
      _tile(Icons.person_outline_rounded, 'Account settings', 'Manage your profile and account information', () => context.push('/profile')),
      _tile(Icons.badge_outlined, 'Account information', 'View your account details', _showAccountInfo),
      _tile(Icons.lock_outline_rounded, 'Change password', 'Update your account password', _changePassword),
      _tile(Icons.block_outlined, 'Blocked users', 'Manage users you have blocked', () => context.push('/blocked-users')),
      _tile(Icons.delete_outline_rounded, 'Delete account', 'Permanently remove your account', _deleteAccount),
      const SizedBox(height: 18),
      _sectionTitle('Privacy'),
      _switchTile(Icons.visibility_off_outlined, 'Private profile', 'Limit who can view your profile', _privateProfile, _loadingPreferences ? null : _setPrivateProfile),
      const SizedBox(height: 18),
      _sectionTitle('Notifications'),
      _switchTile(Icons.notifications_none_rounded, 'Notifications', 'Receive app notifications', _notifications, _loadingPreferences ? null : _setNotifications),
      const SizedBox(height: 18),
      _sectionTitle('Appearance'),
      _tile(Icons.palette_outlined, 'Appearance', _appearanceLabel, _setAppearance),
      const SizedBox(height: 18),
      _sectionTitle('Session'),
      _tile(Icons.logout_rounded, 'Sign out', 'Sign out of this account', _confirmSignOut),
    ]),
  );

  String get _appearanceLabel => switch (ThemeController.instance.mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System default',
  };

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(title, style: const TextStyle(color: AppColors.primaryGreen, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: .3)),
  );

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primaryGreen)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
      onTap: onTap,
    ),
  );

  Widget _switchTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool>? onChanged) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primaryGreen)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primaryGreen),
    ),
  );
}
