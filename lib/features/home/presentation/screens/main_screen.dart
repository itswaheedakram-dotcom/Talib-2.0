import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/admin_access_service.dart';
import '../../../admin/presentation/screens/admin_panel_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../community/presentation/screens/community_screen.dart';
import '../../../common/presentation/widgets/custom_scaffold.dart';
import '../../../messages/presentation/screens/messages_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;
  final access = AdminAccessService.instance;

  @override
  void initState() {
    super.initState();
    access.start();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: access,
      builder: (context, _) {
        final pages = <Widget>[
          const HomeScreen(),
          const SearchScreen(),
          const CommunityScreen(),
          const MessagesScreen(),
          if (access.canOpenPanel) const AdminPanelScreen(),
        ];
        final items = <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined, size: 28),
            activeIcon: Icon(Icons.groups_rounded, size: 28),
            label: 'Community',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages & Groups',
          ),
          if (access.canOpenPanel)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings_rounded),
              label: 'Admin Panel',
            ),
        ];
        final safeIndex = index < pages.length ? index : 0;
        return Scaffold(
          backgroundColor: AppColors.legacyCream,
          drawer: const TalibDrawer(),
          body: IndexedStack(index: safeIndex, children: pages),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Material(
              color: AppColors.white,
              elevation: 10,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: 64,
                child: BottomNavigationBar(
                  currentIndex: safeIndex,
                  onTap: (value) => setState(() => index = value),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: AppColors.white,
                  elevation: 0,
                  selectedItemColor: AppColors.homeGreen,
                  unselectedItemColor: AppColors.mutedText,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  iconSize: 25,
                  items: items,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
