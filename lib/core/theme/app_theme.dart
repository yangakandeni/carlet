import 'package:flutter/material.dart';
import 'package:carlet/core/theme/app_colors.dart';
import 'package:carlet/core/theme/app_typography.dart';
import 'package:carlet/utils/ui_constants.dart';

/// Builds light & dark ThemeData for the app using Material 3 and design tokens.
/// Avoids eager initialization to prevent platform channel usage in background isolates.
class AppTheme {
  // Base ColorSchemes using fromSeed for automatic tonal palette.
  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    surface: AppColors.lightSurface,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    error: AppColors.error,
  );

  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    surface: AppColors.darkSurface,
    primary: AppColors.primaryLight,
    secondary: AppColors.secondaryLight,
    error: AppColors.error,
  );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        textTheme: AppTypography.buildTextTheme(),
        scaffoldBackgroundColor: AppColors.lightBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: lightScheme.surface,
          foregroundColor: lightScheme.onSurface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.buildTextTheme().titleLarge,
        ),
        elevatedButtonTheme: _elevatedButtonTheme(lightScheme),
        outlinedButtonTheme: _outlinedButtonTheme(lightScheme),
        cardTheme: _cardTheme(lightScheme),
  inputDecorationTheme: _inputTheme(lightScheme),
        iconTheme: IconThemeData(size: 24, color: lightScheme.onSurface),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        textTheme: AppTypography.buildTextTheme(),
        scaffoldBackgroundColor: AppColors.darkBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: darkScheme.surface,
          foregroundColor: darkScheme.onSurface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.buildTextTheme().titleLarge,
        ),
        elevatedButtonTheme: _elevatedButtonTheme(darkScheme),
        outlinedButtonTheme: _outlinedButtonTheme(darkScheme),
        cardTheme: _cardTheme(darkScheme),
  inputDecorationTheme: _inputTheme(darkScheme),
        iconTheme: IconThemeData(size: 24, color: darkScheme.onSurface),
      );

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme scheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(double.infinity, UIConstants.kButtonMinHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.buildTextTheme().labelLarge,
        elevation: 1,
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme scheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: scheme.primary),
        foregroundColor: scheme.primary,
        minimumSize: const Size(double.infinity, UIConstants.kButtonMinHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.buildTextTheme().labelLarge,
      ),
    );
  }

  static CardThemeData _cardTheme(ColorScheme scheme) => CardThemeData(
        color: scheme.surface,
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  static InputDecorationTheme _inputTheme(ColorScheme scheme) => InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        filled: true,
        fillColor: scheme.surface,
        labelStyle: AppTypography.buildTextTheme().bodySmall,
        hintStyle: AppTypography.buildTextTheme().bodySmall?.apply(color: scheme.onSurface.withValues(alpha: 0.6)),
        contentPadding: UIConstants.kInputContentPadding,
      );
}
