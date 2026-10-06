import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class TalibApp extends StatelessWidget {
  const TalibApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) => MaterialApp.router(
        title: 'Talib 2.0',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeController.instance.mode,
        routerConfig: appRouter,
      ),
    );
  }
}