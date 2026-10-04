import 'package:flutter/material.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../community/presentation/screens/community_screen.dart';
import '../../../common/presentation/screens/bookmarks_screen.dart';
import '../../../common/presentation/widgets/custom_scaffold.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    SearchScreen(),
    CommunityScreen(),
    BookmarksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A878),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Talib 2.0',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: Builder(
          builder: (drawerContext) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28),
            tooltip: 'Open menu',
            onPressed: () => Scaffold.of(drawerContext).openDrawer(),
          ),
        ),
      ),
      drawer: const TalibDrawer(),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (value) => setState(() => index = value),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF009B76),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), activeIcon: Icon(Icons.bookmark), label: 'Bookmarks'),
        ],
      ),
    );
  }
}
