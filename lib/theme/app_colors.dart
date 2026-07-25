import 'package:flutter/material.dart';

/// Waterly color tokens. Prefer [ThemeData.colorScheme] in widgets.
class AppColors {
  const AppColors._();

  // ── Dark (hero palette) ─────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF07131F);
  static const Color surfaceDark = Color(0xFF101C2D);
  static const Color surfaceElevatedDark = Color(0xFF152536);
  static const Color surfaceContainerDark = Color(0xFF162338);

  // ── Light companion ─────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF4F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLight = Color(0xFFE8EEF5);

  // ── Brand & semantic ────────────────────────────────────────────────
  static const Color primary = Color(0xFF5DB8FF);
  static const Color accent = Color(0xFF7ED6FF);
  static const Color success = Color(0xFF3DDC84);
  static const Color warning = Color(0xFFFFC857);
  static const Color error = Color(0xFFFF5A5F);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color primaryTextDark = Color(0xFFFFFFFF);
  static const Color secondaryTextDark = Color(0xFF9AA8B8);
  static const Color primaryTextLight = Color(0xFF0B1A2A);
  static const Color secondaryTextLight = Color(0xFF5A6B7D);

  /// Soft shadow tint for elevated surfaces.
  static Color softShadow(Brightness brightness) => brightness == Brightness.dark
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.black.withValues(alpha: 0.08);
}
