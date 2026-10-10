import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/widgets/user_identity.dart';

/// Shared account-aware drawer. Profile details come from the central identity source.
class TalibDrawer extends StatelessWidget {
  final String? currentRoute;
  const TalibDrawer({super.key, this.currentRoute});
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: ActiveProfileController.instance,
    builder: (context, _) => StreamBuilder<User?>(
      stream: FirebaseService.initialized ? FirebaseAuth.instance.authStateChanges() : null,
      initialData: FirebaseService.initialized ? FirebaseAuth.instance.currentUser : null,
      builder: (context, snapshot) {
        final demo = ActiveProfileController.instance.isDemo;
        final user = snapshot.data;
        final uid = demo ? ActiveProfileController.instance.effectiveUid : user != null && !user.isAnonymous ? user.uid : null;
        final theme = Theme.of(context);
        final background = theme.drawerTheme.backgroundColor ?? theme.colorScheme.surface;
        final foreground = theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : AppColors.white;
        final active = currentRoute ?? GoRouterState.of(context).uri.path;
        final router = GoRouter.of(context);
        void navigate(String route) { Scaffold.maybeOf(context)?.closeDrawer(); if (route != active) router.push(route); }
        Widget item(IconData icon, String label, String route) => _item(context, icon, label,
          foreground: foreground, selected: active == route || (route != '/' && active.startsWith('$route/')),
          onTap: () => navigate(route), key: ValueKey('drawer-$route'));
        Widget section(String title) => Padding(padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
          child: Text(title, style: TextStyle(color: foreground.withOpacity(.7), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .5)));
        return Drawer(width: math.min(360, MediaQuery.sizeOf(context).width * .82), backgroundColor: background, elevation: 0,
          child: SafeArea(child: Column(children: [Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(12, 16, 12, 12), children: [
            Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: foreground.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.school_rounded, color: foreground, size: 24)),
              const SizedBox(width: 12), Expanded(child: Text('Talib', style: TextStyle(color: foreground, fontSize: 24, fontWeight: FontWeight.w700))),
              IconButton(tooltip: 'Close menu', onPressed: () => Scaffold.maybeOf(context)?.closeDrawer(), icon: Icon(Icons.close, color: foreground)),
            ]),
            const SizedBox(height: 20),
            if (uid != null) ...[
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: UserIdentity(uid: uid,
                name: demo ? ActiveProfileController.instance.effectiveName ?? 'Student' : user?.displayName ?? 'Student', color: foreground)),
              if (demo) Padding(padding: const EdgeInsets.fromLTRB(8, 8, 8, 0), child: Text('Demo account', style: TextStyle(color: foreground.withOpacity(.7), fontSize: 12))),
            ] else Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome to Talib', style: TextStyle(color: foreground, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6), Text('Sign in to save resources and connect with students.', style: TextStyle(color: foreground.withOpacity(.8), height: 1.4)),
            ])),
            const SizedBox(height: 20), Divider(color: foreground.withOpacity(.18)),
            section('Explore'),
            item(Icons.home_outlined, 'Home', '/'),
            item(Icons.folder_outlined, 'Resources', '/resources'),
            if (uid != null) ...[
              section('Your account'),
              item(Icons.person_outline, 'Profile', '/profile'),
              item(Icons.bookmark_outline, 'Bookmarks', '/bookmarks'),
            ],
            section('Support'),
            item(Icons.report_gmailerrorred_outlined, 'Report an issue', '/report-issue'),
            item(Icons.help_outline, 'Help & FAQs', '/help-faqs'),
            section('Preferences'),
            item(Icons.settings_outlined, 'Settings', '/settings'),
            const SizedBox(height: 12), Divider(color: foreground.withOpacity(.18)),
            if (uid == null) ...[
              item(Icons.login_rounded, 'Sign in', '/signin'),
              item(Icons.person_add_outlined, 'Sign up', '/register'),
            ] else _item(context, Icons.logout_rounded, demo ? 'Exit demo' : 'Sign out', foreground: foreground,
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                Scaffold.maybeOf(context)?.closeDrawer();
                try {
                  if (demo) { ActiveProfileController.instance.clear(); }
                  else { await AuthService().signOut(); }
                  router.go('/');
                } catch (_) { messenger.showSnackBar(const SnackBar(content: Text('Could not sign out. Please try again.'))); }
              }),
          ])), Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text('Talib • Student community', style: TextStyle(color: foreground.withOpacity(.65), fontSize: 12))),
        ])));
      }));
  Widget _item(BuildContext context, IconData icon, String label, {required Color foreground,
    required VoidCallback onTap, bool selected = false, Key? key}) => Padding(padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(color: foreground.withOpacity(selected ? .14 : 0), borderRadius: BorderRadius.circular(12),
        child: ListTile(key: key, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          selected: selected, selectedColor: foreground, contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Icon(icon, color: foreground, size: 23),
          title: Text(label, style: TextStyle(color: foreground, fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          trailing: selected ? Icon(Icons.check_rounded, color: foreground, size: 18) : null, onTap: onTap)));
}
