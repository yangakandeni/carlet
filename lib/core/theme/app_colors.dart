import 'package:flutter/material.dart';

/// Central color tokens for Carlet.
/// Kept independent of ThemeData so they can be reused across custom widgets.
class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF4A90E2);
  static const Color primaryDark = Color(0xFF2E5C8A);
  static const Color primaryLight = Color(0xFF7AB8F5);

  // Secondary Palette
  static const Color secondary = Color(0xFFFF9500);
  static const Color secondaryDark = Color(0xFFCC7700);
  static const Color secondaryLight = Color(0xFFFFB84D);

  // Semantic
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFD60A);

  // Neutral / surfaces
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkBackground = Color(0xFF000000);

  // Outline
  static const Color outline = Color(0xFFC6C6C8);
  static const Color outlineDark = Color(0xFF48484A);
}
