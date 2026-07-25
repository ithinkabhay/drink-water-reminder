import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Centralized Material 3 theme for Waterly.
///
/// Typography is limited to three sizes (large / medium / small).
/// Colors come from [AppColors]; widgets should prefer Theme.of(context).
class AppTheme {
  const AppTheme._();

  // Compatibility aliases used by existing call sites.
  static const Color backgroundDark = AppColors.backgroundDark;
  static const Color surfaceDark = AppColors.surfaceDark;
  static const Color primary = AppColors.primary;
  static const Color accent = AppColors.accent;
  static const Color success = AppColors.success;
  static const Color primaryText = AppColors.primaryTextDark;
  static const Color secondaryText = AppColors.secondaryTextDark;
  static const Color backgroundLight = AppColors.backgroundLight;
  static const Color surfaceLight = AppColors.surfaceLight;
  static const Color primaryTextLight = AppColors.primaryTextLight;
  static const Color secondaryTextLight = AppColors.secondaryTextLight;

  /// Light theme.
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.primaryTextLight,
      tertiary: AppColors.success,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.primaryTextLight,
      onSurfaceVariant: AppColors.secondaryTextLight,
      outline: AppColors.secondaryTextLight.withValues(alpha: 0.35),
      surfaceContainerHighest: AppColors.surfaceContainerLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: AppTypography.smallStyle(AppColors.primaryTextLight).fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryTextLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.mediumStyle(AppColors.primaryTextLight),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        indicatorColor: AppColors.primary.withValues(alpha: 0.16),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.smallStyle(
            selected ? AppColors.primary : AppColors.secondaryTextLight,
          ).copyWith(fontWeight: FontWeight.w600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.secondaryTextLight,
            size: 24,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: AppTypography.smallStyle(AppColors.primaryTextDark),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumAll),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.secondaryTextLight.withValues(alpha: 0.18),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.28)),
        labelStyle: AppTypography.smallStyle(AppColors.primaryTextLight),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.capsuleAll),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      textTheme: AppTypography.textTheme(
        primary: AppColors.primaryTextLight,
        secondary: AppColors.secondaryTextLight,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumAll),
          textStyle: AppTypography.mediumStyle(Colors.white),
          minimumSize: const Size(48, 48),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 12,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        showDragHandle: true,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mediumAll,
          side: BorderSide(
            color: AppColors.secondaryTextLight.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }

  /// Dark theme.
  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.backgroundDark,
      secondary: AppColors.accent,
      onSecondary: AppColors.backgroundDark,
      tertiary: AppColors.success,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.primaryTextDark,
      onSurfaceVariant: AppColors.secondaryTextDark,
      outline: AppColors.secondaryTextDark.withValues(alpha: 0.35),
      surfaceContainerHighest: AppColors.surfaceContainerDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: AppTypography.smallStyle(AppColors.primaryTextDark).fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryTextDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.mediumStyle(AppColors.primaryTextDark),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.smallStyle(
            selected ? AppColors.primary : AppColors.secondaryTextDark,
          ).copyWith(fontWeight: FontWeight.w600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.secondaryTextDark,
            size: 24,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevatedDark,
        contentTextStyle: AppTypography.smallStyle(AppColors.primaryTextDark),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumAll),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.secondaryTextDark.withValues(alpha: 0.18),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primary.withValues(alpha: 0.22),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
        labelStyle: AppTypography.smallStyle(AppColors.primaryTextDark),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.capsuleAll),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      textTheme: AppTypography.textTheme(
        primary: AppColors.primaryTextDark,
        secondary: AppColors.secondaryTextDark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.backgroundDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumAll),
          textStyle: AppTypography.mediumStyle(AppColors.backgroundDark),
          minimumSize: const Size(48, 48),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 12,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        showDragHandle: true,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.largeAll),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mediumAll,
          side: BorderSide(
            color: AppColors.secondaryTextDark.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }

  /// Soft atmospheric backdrop colors (subtle, not heavy gradients).
  static List<Color> gradientColors(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        AppColors.backgroundDark,
        AppColors.backgroundDark,
        AppColors.surfaceDark,
        AppColors.backgroundDark,
      ];
    }
    return const [
      AppColors.backgroundLight,
      Color(0xFFEEF4FA),
      AppColors.backgroundLight,
      Color(0xFFE8F1FA),
    ];
  }
}
