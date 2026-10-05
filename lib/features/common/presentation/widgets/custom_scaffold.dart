import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';

/// App drawer navigation.
/// Existing modules/actions are preserved; only layout and interaction styling
/// are modernized. Reference palette remains unchanged.
class TalibDrawer extends StatelessWidget {
  const TalibDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.78,
      backgroundColor: AppColors.drawerGreen,
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 18, 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppColors.drawerGreen,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Taalib',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              color: AppColors.drawerDivider,
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
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.drawerDivider),
                  const SizedBox(height: 8),
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
                  Icon(icon, color: AppColors.drawerIcon, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.drawerDivider,
                    size: 20,
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
