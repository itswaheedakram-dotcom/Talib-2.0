import 'package:flutter/material.dart';

/// Single source of truth for the Talib reference palette.
/// Keep these values unchanged; screens should consume these semantic colors.
abstract final class AppColors {
  static const darkBackground = Color(0xFF10221C);
  static const darkSurface = Color(0xFF183129);
  static const darkInput = Color(0xFF214238);
  static const darkDivider = Color(0xFF315348);
  static const primaryGreen = Color(0xFF00A66A);
  static const darkGreen = Color(0xFF00543D);
  static const drawerGreen = Color(0xFF00563F);
  static const brightGreen = Color(0xFF00D99A);
  static const cream = Color(0xFFFAF9F2);
  static const legacyCream = Color(0xFFF8F8F2);
  static const softGreen = Color(0xFFEAF8F2);
  static const statusWarning = Color(0xFFFF9800);
  static const mutedText = Color(0xFF8B8F8C);
  static const homeGreen = Color(0xFF00A878);
  static const homeAccent = Color(0xFF22F1A5);
  static const authorAccent = Color(0xFF1EF0A1);
  static const actionAccent = Color(0xFF13E7A2);
  static const guidanceBubble = Color(0xFFBFECDD);
  static const homeMutedText = Color(0xFF8B8B8B);
  static const white = Color(0xFFFFFFFF);
  static const white70 = Color(0xB3FFFFFF);
  static const drawerDivider = Color(0x29FFFFFF);
  static const drawerIcon = Color(0xEBFFFFFF);
  static const cardShadow = Color(0x10000000);
  static const findBubble = Color(0x2233FFB0);
  static const divider = Color(0xFFD8E8E1);

  static const swatch = MaterialColor(0xFF00A66A, <int, Color>{
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
}

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final instance = ThemeController._();
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: false,
    primarySwatch: AppColors.swatch,
    primaryColor: AppColors.brightGreen,
    scaffoldBackgroundColor: AppColors.darkBackground,
    drawerTheme: const DrawerThemeData(backgroundColor: AppColors.darkSurface),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.darkGreen, foregroundColor: AppColors.white, elevation: 0, iconTheme: IconThemeData(color: AppColors.white)),
    colorScheme: const ColorScheme.dark(primary: AppColors.brightGreen, secondary: AppColors.primaryGreen, surface: AppColors.darkSurface, background: AppColors.darkBackground, onPrimary: AppColors.darkGreen, onSecondary: AppColors.white, onSurface: AppColors.white),
    cardTheme: CardThemeData(elevation: 0, margin: const EdgeInsets.all(6), color: AppColors.darkSurface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: AppColors.darkInput, hintStyle: TextStyle(color: AppColors.mutedText)),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: AppColors.darkSurface, selectedItemColor: AppColors.brightGreen, unselectedItemColor: AppColors.mutedText, type: BottomNavigationBarType.fixed, elevation: 8),
    dividerTheme: const DividerThemeData(color: AppColors.darkDivider, thickness: 1),
    textTheme: const TextTheme(bodyLarge: TextStyle(color: AppColors.white), bodyMedium: TextStyle(color: AppColors.white), titleLarge: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700), titleMedium: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
  );
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: false,
    primarySwatch: AppColors.swatch,
    primaryColor: AppColors.primaryGreen,
    scaffoldBackgroundColor: AppColors.cream,
    drawerTheme: const DrawerThemeData(backgroundColor: AppColors.drawerGreen),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.white),
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryGreen,
      secondary: AppColors.brightGreen,
      surface: AppColors.white,
      background: AppColors.cream,
      onPrimary: AppColors.white,
      onSecondary: AppColors.darkGreen,
      onSurface: AppColors.darkGreen,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.all(6),
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.softGreen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: const TextStyle(color: AppColors.mutedText),
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
        borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.5),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.softGreen,
      selectedColor: AppColors.primaryGreen,
      labelStyle: TextStyle(color: AppColors.darkGreen),
      secondaryLabelStyle: TextStyle(color: AppColors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: AppColors.mutedText,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkGreen),
      bodyMedium: TextStyle(color: AppColors.darkGreen),
      titleLarge: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w600),
    ),
  );
}
