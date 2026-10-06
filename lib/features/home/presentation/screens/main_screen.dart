import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../community/presentation/screens/community_screen.dart';
import '../../../common/presentation/widgets/custom_scaffold.dart';
import '../../../../app/theme.dart';
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.legacyCream,
      drawer: const TalibDrawer(),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Material(
          color: AppColors.white,
          elevation: 10,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 64,
            child: BottomNavigationBar(
              currentIndex: index,
              onTap: (value) => setState(() => index = value),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.white,
              elevation: 0,
              selectedItemColor: AppColors.homeGreen,
              unselectedItemColor: AppColors.mutedText,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              iconSize: 27,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
                BottomNavigationBarItem(icon: Icon(Icons.groups_outlined, size: 30), activeIcon: Icon(Icons.groups_rounded, size: 30), label: 'Community'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
