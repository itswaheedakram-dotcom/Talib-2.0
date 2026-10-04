import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared simple drawer used by the main app screens.
class TalibDrawer extends StatelessWidget {
  const TalibDrawer({super.key});

  static const green = Color(0xFF00563F);
  static const accent = Color(0xFF00A878);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final signedIn = user != null;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Talib User';
    final email = user?.email?.trim().isNotEmpty == true
        ? user!.email!.trim()
        : 'Guest User';

    return Drawer(
      width: MediaQuery.sizeOf(context).width * .84,
      backgroundColor: green,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 18),
              decoration: const BoxDecoration(color: green),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null
                        ? const Icon(Icons.person, size: 34, color: green)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signedIn ? name : 'Welcome to Talib',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          signedIn ? email : 'Guest User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 6, bottom: 18),
                children: [
                  _section('MAIN'),
                  _item(context, Icons.home_rounded, 'Home', '/'),
                  _item(context, Icons.person_outline_rounded, 'Profile', '/profile'),
                  _item(context, Icons.article_outlined, 'News Feed', '/newsfeed'),
                  _item(context, Icons.notifications_none_rounded, 'Notifications', '/notifications'),
                  _item(context, Icons.search_rounded, 'Search', '/search'),
                  _item(context, Icons.bookmark_border_rounded, 'Bookmarks', '/bookmarks'),
                  _item(context, Icons.groups_outlined, 'Community', '/community'),

                  _section('EDUCATION'),
                  _item(context, Icons.account_balance_outlined, 'All Institutes', '/institutes'),
                  _item(context, Icons.manage_search_rounded, 'Find Institute', '/find'),
                  _actionItem(context, Icons.add_business_outlined, 'Add Institute',
                      () => _chooseInstituteType(context)),
                  _item(context, Icons.school_outlined, 'Scholarships', '/scholarships'),
                  _item(context, Icons.book_outlined, 'Courses', '/courses'),
                  _item(context, Icons.event_outlined, 'Seminars', '/seminars'),
                  _item(context, Icons.hotel_outlined, 'Hostels', '/hostels'),

                  _section('CAREER & COMMUNITY'),
                  _item(context, Icons.groups_rounded, 'Study Groups', '/groups'),
                  _item(context, Icons.menu_book_outlined, 'Study Resources', '/resources'),
                  _item(context, Icons.chat_bubble_outline_rounded, 'Messages', '/messages'),
                  _item(context, Icons.work_outline_rounded, 'Internships', '/internships'),
                  _item(context, Icons.work_rounded, 'Jobs', '/jobs'),

                  _section('ACCOUNT & SUPPORT'),
                  if (!signedIn) ...[
                    _item(context, Icons.login_rounded, 'Sign In', '/signin'),
                    _item(context, Icons.person_add_alt_1_rounded, 'Sign Up', '/register'),
                  ],
                  _actionItem(context, Icons.person_add_alt_1_rounded, 'Invite a friend', _invite),
                  _actionItem(context, Icons.report_problem_outlined, 'Report an issue', _report),
                  _actionItem(context, Icons.help_outline_rounded, 'Help & FAQs', _help),
                  _actionItem(context, Icons.star_border_rounded, 'Rate us', _rate),
                  _actionItem(context, Icons.settings_outlined, 'Settings', _settings),
                  if (signedIn)
                    _actionItem(
                      context,
                      Icons.logout_rounded,
                      'Logout',
                      () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) context.go('/signin');
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 15, 16, 5),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _item(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
    );
  }

  Widget _actionItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback action,
  ) {
    return ListTile(
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        action();
      },
    );
  }

  static void _chooseInstituteType(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Institute',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the institute type to continue.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              for (final type in const [
                ('university', 'University', Icons.account_balance),
                ('college', 'College', Icons.school),
                ('school', 'School', Icons.menu_book),
              ])
                ListTile(
                  title: Text(type.$2),
                  leading: Icon(type.$3, color: green),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).pop();
                    context.go('/add-institute/${type.$1}');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  static void _invite() {}
  static void _report() {}
  static void _help() {}
  static void _rate() {}
  static void _settings() {}
}
