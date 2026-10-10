import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talib_2/app/theme.dart';
import 'package:talib_2/core/services/active_profile_controller.dart';
import 'package:talib_2/core/services/firebase_service.dart';
import 'package:talib_2/features/common/presentation/widgets/custom_scaffold.dart';

void main() {
  setUp(() { FirebaseService.initialized = false; ActiveProfileController.instance.clear(); });
  tearDown(() => ActiveProfileController.instance.clear());
  Future<GoRouter> openDrawer(WidgetTester tester, {bool dark = false, String route = '/'}) async {
    final router = GoRouter(initialLocation: route, routes: [
      for (final path in ['/', '/settings', '/signin', '/register', '/profile', '/resources'])
        GoRoute(path: path, builder: (context, state) => Scaffold(appBar: AppBar(title: Text('Page $path')), drawer: const TalibDrawer(), body: const SizedBox.shrink())),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router, theme: buildTheme(), darkTheme: buildDarkTheme(), themeMode: dark ? ThemeMode.dark : ThemeMode.light));
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    return router;
  }
  testWidgets('guest sees account actions and navigation closes the drawer', (tester) async {
    final router = await openDrawer(tester);
    addTearDown(router.dispose);
    expect(find.text('Welcome to Talib'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
    expect(find.text('Sign out'), findsNothing);
    expect(find.text('Invite a friend'), findsNothing);
    await tester.scrollUntilVisible(find.text('Sign in'), 160, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/signin');
    expect(find.text('Page /signin'), findsOneWidget);
    expect(tester.state<ScaffoldState>(find.byType(Scaffold)).isDrawerOpen, isFalse);
  });
  for (final dark in [false, true]) {
    testWidgets('drawer theme, selected page and demo identity work in ${dark ? "dark" : "light"} mode', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ActiveProfileController.instance.activate(temporaryProfiles[0]);
      final router = await openDrawer(tester, dark: dark, route: '/settings');
      addTearDown(router.dispose);
      expect(find.text('Ayesha Khan'), findsOneWidget);
      expect(find.text('ayesha'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
      final drawer = tester.widget<Drawer>(find.byType(Drawer));
      expect(drawer.backgroundColor, (dark ? buildDarkTheme() : buildTheme()).drawerTheme.backgroundColor);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('drawer-/settings')), 150, scrollable: find.byType(Scrollable).first);
      expect(tester.widget<ListTile>(find.byKey(const ValueKey('drawer-/settings'))).selected, isTrue);
      await tester.scrollUntilVisible(find.text('Exit demo'), 150, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Exit demo'));
      await tester.pumpAndSettle();
      expect(ActiveProfileController.instance.isDemo, isFalse);
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(tester.takeException(), isNull);
    });
  }
}
