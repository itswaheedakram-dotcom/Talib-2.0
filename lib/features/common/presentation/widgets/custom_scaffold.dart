import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Original Talib drawer navigation.
/// Keep this drawer limited to the modules/actions that existed in the
/// original app design. Feature modules are presented on Home, not here.
class TalibDrawer extends StatelessWidget {
  const TalibDrawer({super.key});

  static const Color green = Color(0xFF00563F);
  static const Color text = Color(0xFFE7F1EE);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.88,
      backgroundColor: green,
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            // Original drawer header.
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 46, 28, 42),
              child: Row(
                children: [
                  const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 58,
                  ),
                  const SizedBox(width: 24),
                  const Text(
                    'Taalib',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
                children: [
                  _item(context, Icons.home_rounded, 'Home', '/'),
                  _item(context, Icons.person_rounded, 'Profile', '/profile'),
                  _item(context, Icons.person_add_alt_1_rounded, 'Invite a friend', null),
                  _item(context, Icons.report_gmailerrorred_rounded, 'Report an issue', null),
                  _item(context, Icons.help_rounded, 'Help & FAQs', null),
                  _item(context, Icons.star_rounded, 'Rate us', null),
                  const SizedBox(height: 78),
                  const Divider(
                    color: Colors.white30,
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 50),
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
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).pop();
          if (route != null) {
            context.go(route);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Icon(icon, color: text, size: 34),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: text,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
