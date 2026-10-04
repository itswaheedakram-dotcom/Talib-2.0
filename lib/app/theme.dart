import 'package:flutter/material.dart';

ThemeData buildTheme() {
  // Colors sampled visually from the original Talib screenshots in the FYP documentation.
  const green = Color(0xFF00A66A);
  const darkGreen = Color(0xFF00543D);
  const lightGreen = Color(0xFFEAF8F2);
  const softBackground = Color(0xFFF8FBF9);

  return ThemeData(
    useMaterial3: false,
    primarySwatch: Colors.green,
    primaryColor: green,
    scaffoldBackgroundColor: softBackground,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: green,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.light(
      primary: green,
      secondary: darkGreen,
      surface: Colors.white,
      background: softBackground,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      margin: const EdgeInsets.all(6),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGreen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: green, width: 1.5),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: lightGreen,
      selectedColor: green,
      labelStyle: TextStyle(color: darkGreen),
      secondaryLabelStyle: TextStyle(color: Colors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: green,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: green,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
