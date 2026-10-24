import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF0866FF);
  static const Color lightBg = Color(0xFFF0F2F5);
  static const Color darkBg = Color(0xFF18191A);
  static const Color darkSurface = Color(0xFF242526);
  static const Color darkCard = Color(0xFF3A3B3C);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    primaryColor: primaryBlue,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: Color(0xFF42A5F5),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: Color(0xFF050505),
      onSurfaceVariant: Color(0xFF65676B),
      surfaceContainerHighest: Color(0xFFE4E6EB),
      outline: Color(0xFF65676B),
      error: Color(0xFFE41E3F),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF050505),
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Color(0xFF65676B),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE4E6EB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF050505)),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF050505)),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF050505)),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF050505)),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF050505)),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF050505)),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF050505)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF050505)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF65676B)),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF050505)),
      labelSmall: TextStyle(fontSize: 12, color: Color(0xFF65676B)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: primaryBlue,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: Color(0xFF42A5F5),
      surface: darkSurface,
      onPrimary: Colors.white,
      onSurface: Color(0xFFE4E6EB),
      onSurfaceVariant: Color(0xFFB0B3B8),
      surfaceContainerHighest: Color(0xFF3A3B3C),
      outline: Color(0xFFB0B3B8),
      error: Color(0xFFE41E3F),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Color(0xFFE4E6EB),
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: darkSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Color(0xFFB0B3B8),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF3A3B3C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFE4E6EB)),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFE4E6EB)),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFE4E6EB)),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFE4E6EB)),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE4E6EB)),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE4E6EB)),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE4E6EB)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFE4E6EB)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFFB0B3B8)),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE4E6EB)),
      labelSmall: TextStyle(fontSize: 12, color: Color(0xFFB0B3B8)),
    ),
  );
}
