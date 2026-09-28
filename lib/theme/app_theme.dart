import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class AppTheme {
  // Light Palette
  static const Color scaffoldBackground = Color(0xFFF4F7FC);
  static const Color cardSurface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // Dark Palette
  static const Color darkScaffoldBackground = Color(0xFF0F172A);
  static const Color darkCardSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // Gamified Accent Colors
  static const Color primaryOrange = Color(0xFFFF9A44);
  static const Color primaryPink = Color(0xFFFC6076);
  static const Color electricBlue = Color(0xFF4FACFE);
  static const Color electricCyan = Color(0xFF00F2FE);
  static const Color mintGreen = Color(0xFF43E97B);
  static const Color neonGreen = Color(0xFF38F9D7);
  static const Color purpleStart = Color(0xFF6A11CB);
  static const Color purpleEnd = Color(0xFF2575FC);
  static const Color yellowAccent = Color(0xFFFFD166);
  static const Color amberGold = Color(0xFFFFB703);

  // Gradient Presets
  static const LinearGradient orangePinkGradient = LinearGradient(
    colors: [Color(0xFFFF9A44), Color(0xFFFC6076)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueCyanGradient = LinearGradient(
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenMintGradient = LinearGradient(
    colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleBlueGradient = LinearGradient(
    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunshineGradient = LinearGradient(
    colors: [Color(0xFFFFD200), Color(0xFFF7971E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient calmLavenderGradient = LinearGradient(
    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Autism Level Gradients
  static const LinearGradient severeGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient moderateGradient = LinearGradient(
    colors: [Color(0xFF4E65FF), Color(0xFF92EFFD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mildGradient = LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Color Scheme Helpers
  static Color getPrimaryColor(AppColorScheme scheme) {
    switch (scheme) {
      case AppColorScheme.blue:
        return const Color(0xFF3B82F6);
      case AppColorScheme.green:
        return const Color(0xFF10B981);
      case AppColorScheme.purple:
        return const Color(0xFF8B5CF6);
      case AppColorScheme.pink:
        return const Color(0xFFEC4899);
      case AppColorScheme.orange:
        return primaryOrange;
    }
  }

  static Color getSecondaryColor(AppColorScheme scheme) {
    switch (scheme) {
      case AppColorScheme.blue:
        return const Color(0xFF06B6D4);
      case AppColorScheme.green:
        return const Color(0xFF34D399);
      case AppColorScheme.purple:
        return const Color(0xFF6366F1);
      case AppColorScheme.pink:
        return const Color(0xFFF43F5E);
      case AppColorScheme.orange:
        return primaryPink;
    }
  }

  static LinearGradient getSchemeGradient(AppColorScheme scheme) {
    return LinearGradient(
      colors: [getPrimaryColor(scheme), getSecondaryColor(scheme)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Heavy Soft Drop Shadow Generators
  static List<BoxShadow> heavyShadow(
    Color color, {
    double opacity = 0.35,
    double blur = 20,
    double spread = 0,
    Offset offset = const Offset(0, 8),
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 6,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: const Color(0xFF1E293B).withValues(alpha: 0.07),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: const Color(0xFF1E293B).withValues(alpha: 0.03),
      blurRadius: 4,
      spreadRadius: 0,
      offset: const Offset(0, 1),
    ),
  ];

  static ThemeData get themeData => lightTheme();

  // Light Theme
  static ThemeData lightTheme({AppColorScheme scheme = AppColorScheme.orange}) {
    final primary = getPrimaryColor(scheme);
    final secondary = getSecondaryColor(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: scaffoldBackground,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary, width: 2.2),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Dark Theme
  static ThemeData darkTheme({AppColorScheme scheme = AppColorScheme.orange}) {
    final primary = getPrimaryColor(scheme);
    final secondary = getSecondaryColor(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkScaffoldBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: darkScaffoldBackground,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: darkScaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkCardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary, width: 2.2),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary, fontWeight: FontWeight.w500),
      ),
    );
  }
}
