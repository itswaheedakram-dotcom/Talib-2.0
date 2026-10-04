import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';
class TalibApp extends StatelessWidget {
  const TalibApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Talib 2.0',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routerConfig: appRouter,
  );
}
