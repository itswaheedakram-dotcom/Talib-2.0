import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App drawer navigation.
/// Keeps the existing modules/actions while matching the compact visual
/// language used throughout the Talib UI.
class TalibDrawer extends StatelessWidget {
  const TalibDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = colors.primary;
    final onPrimary = colors.onPrimary;

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.78,
      backgroundColor: primary,
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 18, 22),
              child: Row(
                children: [
                  Icon(Icons.school_rounded, color: onPrimary, size: 38),
                  const SizedBox(width: 14),
                  Text(
                    'Taalib',
                    style: TextStyle(
                      color: onPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: onPrimary.withValues(alpha: 0.16),
              indent: 20,
              endIndent: 20,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                children: [
                  _item(context, Icons.home_rounded, 'Home', '/'),
                  _item(context, Icons.person_rounded, 'Profile', '/profile'),
                  _item(context, Icons.person_add_alt_1_rounded, 'Invite a friend', null),
                  _item(context, Icons.report_gmailerrorred_rounded, 'Report an issue', null),
                  _item(context, Icons.help_rounded, 'Help & FAQs', null),
                  _item(context, Icons.star_rounded, 'Rate us', null),
                  const SizedBox(height: 18),
                  Divider(color: onPrimary.withValues(alpha: 0.16)),
                  const SizedBox(height: 10),
                  _item(context, Icons.settings_rounded, 'Settings', null),
                  _item(context, Icons.login_rounded, 'Sign in', '/signin'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    String? route,
  ) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).pop();
            if (route != null) {
              context.go(route);
            }
          },
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, color: onPrimary.withValues(alpha: 0.92), size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
