import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';

/// App drawer navigation.
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
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppColors.drawerGreen,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Taalib',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 25,
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
              indent: 18,
              endIndent: 18,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                children: [
                  _item(context, Icons.person_rounded, 'Profile', '/profile'),
                  _item(context, Icons.bookmark_rounded, 'Bookmarks', '/bookmarks'),
                  _item(context, Icons.folder_rounded, 'Resources', '/resources'),
                  _item(context, Icons.person_add_alt_1_rounded, 'Invite a friend', null),
                  _item(context, Icons.report_gmailerrorred_rounded, 'Report an issue', '/report-issue'),
                  _item(context, Icons.help_rounded, 'Help & FAQs', '/help-faqs'),
                  _item(context, Icons.star_rounded, 'Rate us', null),
                  const SizedBox(height: 4),
                  const Divider(color: AppColors.drawerDivider),
                  const SizedBox(height: 4),
                  _item(context, Icons.settings_rounded, 'Settings', '/settings'),
                  _item(context, Icons.login_rounded, 'Sign in', '/signin'),
                  _item(context, Icons.person_add_rounded, 'Sign up', '/register'),
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
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pop();
            if (route != null) {
              context.go(route);
            }
          },
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.drawerIcon, size: 22),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.drawerDivider,
                    size: 18,
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
