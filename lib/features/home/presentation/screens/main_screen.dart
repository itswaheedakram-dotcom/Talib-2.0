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
    return CustomScaffold(
      title: 'Talib 2.0',
      currentIndex: index,
      onBottomNavTap: (value) => setState(() => index = value),
      bottomItems: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Community'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), activeIcon: Icon(Icons.bookmark), label: 'Bookmarks'),
      ],
      body: IndexedStack(index: index, children: pages),
    );
  }
}
