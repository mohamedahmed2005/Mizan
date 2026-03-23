import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';

class AppColors {
  static bool get _isDark => AppState.instance.isDarkMode;

  // Backgrounds & Surfaces
  static Color get background => _isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F2F5);
  static Color get surface => _isDark ? const Color(0xFF161B22) : const Color(0xFFFFFFFF);
  static Color get card => _isDark ? const Color(0xFF1E2530) : const Color(0xFFFFFFFF);
  static Color get border => _isDark ? const Color(0xFF30363D) : const Color(0xFFDDE1E7);

  // Brand & Accents
  static const Color teal = Color(0xFF00897B);   // slightly deeper teal for light mode readability
  static const Color tealLight = Color(0xFF1DE9B6);
  static Color get gold => _isDark ? const Color(0xFFFFD700) : const Color(0xFFB8860B); // darker gold on light
  static const Color purple = Color(0xFF7C4DFF);
  static const Color purpleLight = Color(0xFFB388FF);
  static const Color green = Color(0xFF2E7D32);  // deeper green for light mode
  static const Color orange = Color(0xFFE65100); // deeper orange for light mode
  static const Color red = Color(0xFFD32F2F);    // deeper red for light mode
  static const Color blue = Color(0xFF1565C0);   // deeper blue for light mode

  // Text Colors
  static Color get textPrimary => _isDark ? const Color(0xFFE6EDF3) : const Color(0xFF0F172A);
  static Color get textSecondary => _isDark ? const Color(0xFF8B949E) : const Color(0xFF475569);
  static Color get textMuted => _isDark ? const Color(0xFF484F58) : const Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData get currentTheme {
    final isDark = AppState.instance.isDarkMode;
    
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.teal,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: AppColors.teal,
        onPrimary: Colors.white,
        secondary: AppColors.purple,
        onSecondary: Colors.white,
        error: AppColors.red,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: isDark ? 0 : 2, // Slight shadow in light mode looks good
        shadowColor: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark ? BorderSide(color: AppColors.border, width: 1) : BorderSide.none,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 2),
        ),
        hintStyle: TextStyle(color: AppColors.textMuted),
        labelStyle: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
