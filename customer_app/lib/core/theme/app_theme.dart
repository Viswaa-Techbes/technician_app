import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1E3A8A); // TechBes Blue
  static const Color secondaryColor = Color(0xFFEA580C); // TechBes Orange
  static const Color backgroundColor = Color(0xFFF8FAFC); // Very light grey/blue
  static const Color darkBackgroundColor = Color(0xFF0F172A); // Slate 900
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryColor = Color(0xFF64748B); // Slate 500
  static const Color borderColor = Color(0xFFE2E8F0); // Slate 200

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      fontFamily: 'Segoe UI',
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryColor,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textPrimaryColor, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimaryColor, letterSpacing: -0.3),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimaryColor),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimaryColor),
        bodyLarge: TextStyle(fontSize: 14, color: textPrimaryColor, height: 1.5),
        bodyMedium: TextStyle(fontSize: 13, color: textSecondaryColor, height: 1.4),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondaryColor),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimaryColor),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryColor,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.red)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      ),
    );
  }

  static BoxDecoration get heroGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  static BoxDecoration get orangeGradient {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}
