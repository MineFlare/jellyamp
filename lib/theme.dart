import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceElevated = Color(0xFF282828);
  static const Color accent = Color(0xFF1DB954);
  static const Color onAccent = Color(0xFF000000);
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color subtle = Color(0xFFB3B3B3);
  static const Color divider = Color(0xFF303030);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          onPrimary: onAccent,
          secondary: accent,
          onSecondary: onAccent,
          surface: surface,
          onSurface: onSurface,
          background: background,
          onBackground: onBackground,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: onBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF181818),
          selectedItemColor: onBackground,
          unselectedItemColor: subtle,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: onBackground,
          unselectedLabelColor: subtle,
          indicatorColor: accent,
          dividerColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceElevated,
          hintStyle: const TextStyle(color: subtle),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: onAccent,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: onBackground, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: onBackground),
          bodyMedium: TextStyle(color: subtle),
          labelSmall: TextStyle(color: subtle),
        ),
        dividerTheme: const DividerThemeData(color: divider, thickness: 1),
        iconTheme: const IconThemeData(color: onBackground),
      );
}
