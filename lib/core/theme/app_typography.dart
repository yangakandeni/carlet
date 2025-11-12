import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central typography tokens using Google Fonts: Inter & Poppins.
/// Note: Built on demand to avoid invoking platform channels during background isolates.
class AppTypography {
  static TextTheme buildTextTheme() => TextTheme(
        displayLarge: GoogleFonts.poppins(fontSize: 57, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700),
        headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w500),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      );
}
