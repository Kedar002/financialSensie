import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Steve Jobs approved theme.
/// Minimalist. Clean. Only black, white, and subtle grays.
/// "Design is not just what it looks like. Design is how it works."
class AppTheme {
  // Colors - Only these. Nothing else.
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFE5E5E5);
  static const Color gray300 = Color(0xFFD4D4D4);
  static const Color gray400 = Color(0xFF9E9E9E);
  static const Color gray500 = Color(0xFF757575);
  static const Color gray600 = Color(0xFF616161);

  // Spacing - 8px base unit
  static const double spacing4 = 4;
  static const double spacing6 = 6;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing48 = 48;
  static const double spacing64 = 64;

  // Border radius - subtle, consistent
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: white,
        colorScheme: const ColorScheme.light(
          primary: black,
          onPrimary: white,
          secondary: gray600,
          onSecondary: white,
          surface: white,
          onSurface: black,
          error: Color(0xFFB00020),
          onError: white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: white,
          foregroundColor: black,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            color: black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        textTheme: const TextTheme(
          // Large display - for the main number (safe-to-spend)
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            color: black,
            letterSpacing: -2,
            height: 1.1,
          ),
          // Medium display
          displayMedium: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: black,
            letterSpacing: -1,
            height: 1.2,
          ),
          // Section headers
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: black,
            letterSpacing: -0.5,
          ),
          // Card titles
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: black,
            letterSpacing: -0.3,
          ),
          // Body text
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: black,
            height: 1.5,
          ),
          // Secondary text
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: gray600,
            height: 1.5,
          ),
          // Small labels
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: gray400,
            letterSpacing: 0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: black,
            foregroundColor: white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: spacing24,
              vertical: spacing16,
            ),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: spacing24,
              vertical: spacing16,
            ),
            minimumSize: const Size(double.infinity, 56),
            side: const BorderSide(color: gray200, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: black,
            padding: const EdgeInsets.symmetric(
              horizontal: spacing16,
              vertical: spacing12,
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: gray100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: const BorderSide(color: black, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: const BorderSide(color: Color(0xFFB00020), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing16,
          ),
          hintStyle: const TextStyle(
            color: gray400,
            fontSize: 16,
          ),
        ),
        cardTheme: CardThemeData(
          color: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            side: const BorderSide(color: gray200, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: gray200,
          thickness: 1,
          space: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: white,
          selectedItemColor: black,
          unselectedItemColor: gray400,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
}
