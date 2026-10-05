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
      backgroundColor: const Color(0xFFF8F8F2),
      drawer: const TalibDrawer(),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (value) => setState(() => index = value),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 12,
        selectedItemColor: const Color(0xFF00A878),
        unselectedItemColor: const Color(0xFF9E9E9E),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 30), activeIcon: Icon(Icons.home_rounded, size: 30), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded, size: 30), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined, size: 32), activeIcon: Icon(Icons.groups_rounded, size: 32), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border_rounded, size: 30), activeIcon: Icon(Icons.bookmark_rounded, size: 30), label: 'Bookmarks'),
        ],
      ),
    );
  }
}
