import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The app's single, simple navigation drawer.
/// It intentionally has no Firebase dependency so the drawer can never fail
/// just because authentication is unavailable.
class TalibDrawer extends StatelessWidget {
  const TalibDrawer({super.key});

  static const Color green = Color(0xFF00563F);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Always-rendered account header.
            Container(
              width: double.infinity,
              color: green,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 34, color: green),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Talib',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sign in to your account',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
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
                  _item(context, Icons.add_business_outlined, 'Add Institute', '/add-institute/university'),
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

                  const Divider(height: 18, indent: 16, endIndent: 16),

                  _section('ACCOUNT'),
                  _item(context, Icons.login_rounded, 'Sign In', '/signin'),
                  _item(context, Icons.person_add_alt_1_rounded, 'Sign Up', '/register'),
                  _item(context, Icons.person_add_alt_rounded, 'Invite a friend', null),
                  _item(context, Icons.report_problem_outlined, 'Report an issue', null),
                  _item(context, Icons.help_outline_rounded, 'Help & FAQs', null),
                  _item(context, Icons.star_border_rounded, 'Rate us', null),
                  _item(context, Icons.settings_outlined, 'Settings', null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
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
    return ListTile(
      dense: true,
      minLeadingWidth: 24,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: green, size: 23),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: route != null ? const Icon(Icons.chevron_right, size: 19) : null,
      onTap: () {
        Navigator.of(context).pop();
        if (route != null) {
          context.go(route);
        }
      },
    );
  }
}
