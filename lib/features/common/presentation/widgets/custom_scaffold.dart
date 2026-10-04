import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final ValueChanged<int>? onBottomNavTap;
  final List<BottomNavigationBarItem>? bottomItems;
  final bool showBottomNavigation;
  final Widget? floatingActionButton;

  const CustomScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentIndex = 0,
    this.onBottomNavTap,
    this.bottomItems,
    this.showBottomNavigation = true,
    this.floatingActionButton,
  });

  static const green = Color(0xFF006B4F);
  static const mint = Color(0xFF00C98D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF8),
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const _TalibDrawer(),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNavigation && bottomItems != null
          ? BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onBottomNavTap,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: mint,
              unselectedItemColor: Colors.grey,
              items: bottomItems!,
            )
          : null,
    );
  }
}

class _TalibDrawer extends StatelessWidget {
  const _TalibDrawer();
  static const green = Color(0xFF00563F);
  static const mint = Color(0xFF00C98D);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Guest User';

    return Drawer(
      width: MediaQuery.of(context).size.width * .84,
      backgroundColor: green,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        const Text('Talib Student', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _item(context, Icons.home_rounded, 'Home', '/'),
                  _item(context, Icons.person_outline_rounded, 'Profile', '/profile'),
                  _item(context, Icons.person_add_alt_1_rounded, 'Invite a friend', null, _invite),
                  _item(context, Icons.report_problem_outlined, 'Report an issue', null, _report),
                  _item(context, Icons.help_outline_rounded, 'Help & FAQs', null, _help),
                  _item(context, Icons.star_border_rounded, 'Rate us', null, _rate),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Divider(color: Colors.white24)),
                  _item(context, Icons.groups_outlined, 'Study Groups', '/groups'),
                  _item(context, Icons.menu_book_outlined, 'Study Resources', '/resources'),
                  _item(context, Icons.chat_bubble_outline_rounded, 'Messages', '/messages'),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            _item(context, Icons.settings_outlined, 'Settings', null, _settings),
            _item(context, Icons.logout_rounded, 'Sign out', null, () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pop(context);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, String? route, [VoidCallback? action]) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: Colors.white.withOpacity(.92), size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        if (route != null) context.push(route);
        else if (action != null) action();
      },
    );
  }

  static void _invite() {}
  static void _report() {}
  static void _help() {}
  static void _rate() {}
  static void _settings() {}
}
