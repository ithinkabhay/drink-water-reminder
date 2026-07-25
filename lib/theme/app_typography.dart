import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Manrope typography limited to three sizes: large / medium / small.
class AppTypography {
  const AppTypography._();

  /// Greeting / hero titles.
  static const double large = 30;

  /// Main numbers and section titles.
  static const double medium = 18;

  /// Descriptions and meta text.
  static const double small = 14;

  static TextStyle largeStyle(Color color) => GoogleFonts.manrope(
        fontSize: large,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.2,
        color: color,
      );

  static TextStyle mediumStyle(Color color) => GoogleFonts.manrope(
        fontSize: medium,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.25,
        color: color,
      );

  static TextStyle smallStyle(Color color) => GoogleFonts.manrope(
        fontSize: small,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.35,
        color: color,
      );

  /// Builds a Material [TextTheme] mapped onto the three-size system.
  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) {
    final base = GoogleFonts.manropeTextTheme();
    return base.copyWith(
      headlineLarge: largeStyle(primary),
      headlineMedium: largeStyle(primary),
      headlineSmall: largeStyle(primary).copyWith(fontSize: 26),
      titleLarge: mediumStyle(primary),
      titleMedium: mediumStyle(primary),
      titleSmall: mediumStyle(primary).copyWith(fontSize: 16),
      displaySmall: mediumStyle(primary).copyWith(fontSize: 28),
      bodyLarge: smallStyle(primary).copyWith(fontSize: 15, height: 1.45),
      bodyMedium: smallStyle(secondary).copyWith(height: 1.4),
      bodySmall: smallStyle(secondary).copyWith(fontSize: 12),
      labelLarge: smallStyle(primary).copyWith(fontWeight: FontWeight.w600),
      labelMedium: smallStyle(secondary),
      labelSmall: smallStyle(secondary).copyWith(fontSize: 11),
    );
  }
}
