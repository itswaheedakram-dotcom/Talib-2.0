import 'package:flutter/material.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../community/presentation/screens/community_screen.dart';
import '../../../common/presentation/screens/bookmarks_screen.dart';
import 'home_screen.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int index = 0;
  final pages = const [HomeScreen(), SearchScreen(), CommunityScreen(), BookmarksScreen()];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Community'),
        NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'Bookmarks'),
      ],
    ),
  );
}
