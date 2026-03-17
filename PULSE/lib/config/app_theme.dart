import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF10B981);
  static const Color secondary = Color(0xFF059669);
  static const Color accent = Color(0xFF34D399);
  static const Color background = Color(0xFFF5F7FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color emergency = Color(0xFFEF4444);
  static const Color corridorActive = Color(0xFF10B981);
  static const Color border = Color(0xFFE2E8F0);
  static const Color surfaceLight = Color(0xFFF0FDF4);
  static const Color dark = Color(0xFF0F172A);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get darkGradient => const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get emergencyGradient => const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class AppTextStyles {
  static TextStyle get title => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get micro => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      );
}

class AppSpacing {
  static const double grid = 8.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double cardRadius = 16.0;
  static const double cardPadding = 18.0;
  static const double buttonHeight = 52.0;
}

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          offset: const Offset(0, 4),
          blurRadius: 16,
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          offset: const Offset(0, 4),
          blurRadius: 20,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          offset: const Offset(0, 2),
          blurRadius: 6,
        ),
      ];

  static List<BoxShadow> get glow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.25),
          offset: const Offset(0, 4),
          blurRadius: 16,
        ),
      ];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.card,
        error: AppColors.emergency,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.title,
        headlineMedium: AppTextStyles.sectionTitle,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.micro,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
