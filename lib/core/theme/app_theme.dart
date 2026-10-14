import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Stitch Primary & Containers
  static const Color primary = Color(0xFF012D1D);
  static const Color primaryContainer = Color(0xFF1B4332);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF86AF99);
  static const Color primaryFixed = Color(0xFFC1ECD4);
  static const Color primaryFixedDim = Color(0xFFA5D0B9);

  // Stitch Secondary (Water & Fluidity)
  static const Color secondary = Color(0xFF006399);
  static const Color secondaryContainer = Color(0xFF67BAFD);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF004972);
  static const Color secondaryFixed = Color(0xFFCDE5FF);
  static const Color secondaryFixedDim = Color(0xFF94CCFF);

  // Tertiary & Warnings (Energy & Alerts)
  static const Color tertiary = Color(0xFF3E1E00);
  static const Color tertiaryContainer = Color(0xFF5E3000);
  static const Color warningOrange = Color(0xFFF48C24);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFF48C24);
  static const Color tertiaryFixed = Color(0xFFFFDCC3);
  static const Color tertiaryFixedDim = Color(0xFFFFB77D);

  // Status & Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFFFFFFFF);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEEF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDFE9FA);
  static const Color surfaceContainerHighest = Color(0xFFD9E3F4);

  // Text & Outline
  static const Color onBackground = Color(0xFF121C28);
  static const Color onSurface = Color(0xFF121C28);
  static const Color onSurfaceVariant = Color(0xFF414844);
  static const Color outline = Color(0xFF717973);
  static const Color outlineVariant = Color(0xFFC1C8C2);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        error: AppColors.error,
        onError: AppColors.onError,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          letterSpacing: -0.02,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
          letterSpacing: -0.01,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
          letterSpacing: 0.05,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.primary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
    );
  }
}
