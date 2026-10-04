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

  const CustomScaffold({super.key, required this.title, required this.body, this.currentIndex = 0, this.onBottomNavTap, this.bottomItems, this.showBottomNavigation = true, this.floatingActionButton});

  static const green = Color(0xFF00A878);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      drawerEnableOpenDragGesture: true,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu_rounded, size: 28), tooltip: 'Menu', onPressed: () => Scaffold.of(context).openDrawer())),
      ),
      drawer: const _TalibDrawer(),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNavigation && bottomItems != null ? BottomNavigationBar(currentIndex: currentIndex, onTap: onBottomNavTap, type: BottomNavigationBarType.fixed, selectedItemColor: const Color(0xFF009B76), unselectedItemColor: Colors.grey, backgroundColor: Colors.white, elevation: 8, items: bottomItems!) : null,
    );
  }
}

class _TalibDrawer extends StatelessWidget {
  const _TalibDrawer();
  static const green = Color(0xFF00563F);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true ? user!.displayName!.trim() : 'Talib User';
    final email = user?.email?.trim().isNotEmpty == true ? user!.email!.trim() : 'Guest User';

    return Drawer(
      width: MediaQuery.of(context).size.width * .84,
      backgroundColor: green,
      child: SafeArea(
        child: Column(children: [
          UserAccountsDrawerHeader(
            margin: EdgeInsets.zero,
            decoration: const BoxDecoration(color: green),
            accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(email, style: const TextStyle(color: Colors.white70)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null ? const Icon(Icons.person, size: 50, color: green) : null,
            ),
          ),
          Expanded(child: ListView(padding: EdgeInsets.zero, children: [
            _item(context, Icons.home_rounded, 'Home', '/'),
            _item(context, Icons.person_outline_rounded, 'Profile', '/profile'),
            _item(context, Icons.person_add_alt_1_rounded, 'Invite a friend', null, _invite),
            _item(context, Icons.report_problem_outlined, 'Report an issue', null, _report),
            _item(context, Icons.help_outline_rounded, 'Help & FAQs', null, _help),
            _item(context, Icons.star_border_rounded, 'Rate us', null, _rate),
            const Divider(color: Colors.white24, indent: 16, endIndent: 16),
            _item(context, Icons.groups_outlined, 'Study Groups', '/groups'),
            _item(context, Icons.menu_book_outlined, 'Study Resources', '/resources'),
            _item(context, Icons.chat_bubble_outline_rounded, 'Messages', '/messages'),
            const Divider(color: Colors.white24, indent: 16, endIndent: 16),
            _item(context, Icons.settings_outlined, 'Settings', null, _settings),
            _item(context, Icons.logout_rounded, 'Logout', null, () async { await FirebaseAuth.instance.signOut(); }),
          ])),
        ]),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, String? route, [VoidCallback? action]) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.white.withOpacity(.94), size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w500)),
      onTap: () { Navigator.pop(context); if (route != null) context.push(route); if (action != null) action(); },
    );
  }
  static void _invite() {}
  static void _report() {}
  static void _help() {}
  static void _rate() {}
  static void _settings() {}
}
