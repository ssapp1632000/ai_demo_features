import 'package:flutter/material.dart';

// Centralized Color Definitions
// Change these colors to update the entire app's color scheme
class AppColors {
  // Primary Colors
  static const Color primary = Colors.deepOrangeAccent;
  static const Color primaryVariant = Colors.deepOrange;
  static const Color secondary = Colors.orangeAccent;
  static const Color accent = Colors.orangeAccent;

  // Background Colors - Light Theme
  static const Color backgroundLight = Colors.white;
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Colors.white;

  // Background Colors - Dark Theme
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2A2A2A);

  // Text Colors - Light Theme
  static const Color textPrimaryLight = Colors.black87;
  static const Color textSecondaryLight = Colors.black54;

  // Text Colors - Dark Theme
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Colors.white70;

  // Status Colors
  static const Color error = Colors.red;
  static const Color errorDark = Colors.redAccent;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;

  // Neutral Colors
  static const Color grey = Colors.grey;
  static final Color greyLight = Colors.grey.shade300;
  static const Color greyDark = Colors.grey;
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Divider Colors
  static final Color dividerLight = Colors.grey.shade300;
  static const Color dividerDark = Colors.white24;

  // Recording/Active State
  static const Color recording = Colors.red;
}

class AppThemes {
  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.textPrimaryLight,
      onError: AppColors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 4,
      iconTheme: IconThemeData(color: AppColors.white),
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundLight,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: AppColors.textPrimaryLight,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textPrimaryLight,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimaryLight,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimaryLight,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    dividerColor: AppColors.dividerLight,
    floatingActionButtonTheme:
        FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    iconTheme: IconThemeData(color: AppColors.white),
    primaryIconTheme: IconThemeData(color: AppColors.white),
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceDark,
      error: AppColors.errorDark,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.textPrimaryDark,
      onError: AppColors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      elevation: 4,
      iconTheme: IconThemeData(color: AppColors.white),
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      bodySmall: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      titleSmall: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      labelLarge: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      labelMedium: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      labelSmall: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      displayLarge: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      displayMedium: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      displaySmall: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      headlineLarge: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
      headlineSmall: TextStyle(
        color: AppColors.textPrimaryDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: TextStyle(color: Colors.white54),
      labelStyle: TextStyle(color: AppColors.white),
    ),
    dividerColor: AppColors.dividerDark,
    floatingActionButtonTheme:
        FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
        ),
  );
}
