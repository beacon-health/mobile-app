import 'package:flutter/material.dart';

class AppTheme {
  static const Color paynesGray = Color(0xFF536878);
  static const Color honeydew = Color(0xFFF0FFF0);
  static const Color resedaGreen = Color(0xFF6C7C59);
  static const Color khaki = Color(0xFFF0E68C);
  static const Color bittersweet = Color(0xFFFE6F5E);

  // Category colors
  static const Color healthCare = resedaGreen;
  static const Color mentalHealth = paynesGray;
  static const Color basicNeeds = bittersweet;
  static const Color housingShelter = Color.fromARGB(255, 53, 167, 238);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: resedaGreen,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkSurface = Color(0xFF1A1A2E);
    const darkCard = Color(0xFF222240);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: resedaGreen,
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkSurface,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkSurface,
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: bittersweet,
        unselectedItemColor: Colors.grey,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        fillColor: darkCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      dividerColor: Colors.grey[800],
    );
  }
}
