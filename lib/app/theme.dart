import 'package:flutter/material.dart';

ThemeData buildTheme() {
  const green = Color(0xFF4CAF50);
  const darkGreen = Color(0xFF2E7D32);
  const lightGreen = Color(0xFFE8F5E9);
  return ThemeData(
    useMaterial3: false,
    primarySwatch: Colors.green,
    primaryColor: green,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(backgroundColor: green, foregroundColor: Colors.white, elevation: 2, centerTitle: true),
    colorScheme: const ColorScheme.light(primary: green, secondary: darkGreen, surface: Colors.white, background: Colors.white),
    cardTheme: CardThemeData(elevation: 2, margin: const EdgeInsets.all(8), color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: lightGreen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: green.withOpacity(.25))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: green.withOpacity(.25))),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(6)), borderSide: BorderSide(color: darkGreen, width: 1.5)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: green, foregroundColor: Colors.white),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(selectedItemColor: green, unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed),
  );
}