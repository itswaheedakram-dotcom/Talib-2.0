import 'package:flutter/material.dart';

ThemeData buildTheme() {
  // Talib reference palette — keep the whole application on this same palette.
  const primaryGreen = Color(0xFF00A66A);
  const darkGreen = Color(0xFF00543D);
  const brightGreen = Color(0xFF00D99A);
  const cream = Color(0xFFFAF9F2);
  const softGreen = Color(0xFFEAF8F2);
  const mutedText = Color(0xFF8B8F8C);

  const swatch = MaterialColor(0xFF00A66A, <int, Color>{
    50: Color(0xFFEAFBF4),
    100: Color(0xFFC8F3E2),
    200: Color(0xFF9EE9CC),
    300: Color(0xFF70DEB5),
    400: Color(0xFF3FD39D),
    500: primaryGreen,
    600: Color(0xFF00945F),
    700: Color(0xFF008052),
    800: Color(0xFF006B45),
    900: darkGreen,
  });

  return ThemeData(
    useMaterial3: false,
    primarySwatch: swatch,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: cream,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: brightGreen,
      surface: Colors.white,
      background: cream,
      onPrimary: Colors.white,
      onSecondary: darkGreen,
      onSurface: darkGreen,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.all(6),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: softGreen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: const TextStyle(color: mutedText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: primaryGreen, width: 1.5),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: softGreen,
      selectedColor: primaryGreen,
      labelStyle: TextStyle(color: darkGreen),
      secondaryLabelStyle: TextStyle(color: Colors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryGreen,
      unselectedItemColor: mutedText,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFD8E8E1),
      thickness: 1,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkGreen),
      bodyMedium: TextStyle(color: darkGreen),
      titleLarge: TextStyle(color: darkGreen, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: darkGreen, fontWeight: FontWeight.w600),
    ),
  );
}
