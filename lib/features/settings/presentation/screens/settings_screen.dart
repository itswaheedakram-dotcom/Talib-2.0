import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _privateProfile = false;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          _sectionTitle('Account'),
          _tile(
            icon: Icons.person_outline_rounded,
            title: 'Account settings',
            subtitle: 'Manage your profile and account information',
            onTap: () => context.push('/profile'),
          ),
          _tile(
            icon: Icons.lock_outline_rounded,
            title: 'Change password',
            subtitle: 'Update your account password',
            onTap: () => _comingSoon('Change password'),
          ),
          const SizedBox(height: 18),
          _sectionTitle('Notifications & privacy'),
          _switchTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Receive app notifications',
            value: _notifications,
            onChanged: (value) => setState(() => _notifications = value),
          ),
          _switchTile(
            icon: Icons.visibility_off_outlined,
            title: 'Private profile',
            subtitle: 'Limit who can view your profile',
            value: _privateProfile,
            onChanged: (value) => setState(() => _privateProfile = value),
          ),
          const SizedBox(height: 18),
          _sectionTitle('App'),
          _tile(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Theme and display preferences',
            onTap: () => _comingSoon('Appearance'),
          ),
          _tile(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: 'English',
            onTap: () => _comingSoon('Language'),
          ),
          const SizedBox(height: 18),
          _sectionTitle('Support'),
          _tile(
            icon: Icons.help_outline_rounded,
            title: 'Help & FAQs',
            subtitle: 'Get help with Taalib',
            onTap: () => _comingSoon('Help & FAQs'),
          ),
          _tile(
            icon: Icons.info_outline_rounded,
            title: 'About Taalib',
            subtitle: 'Version 1.0.0',
            onTap: () => _comingSoon('About Taalib'),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkGreen,
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.softGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryGreen),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
        onTap: onTap,
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.softGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryGreen),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryGreen,
        ),
      ),
    );
  }
}
