import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Centralized Material 3 theme definitions for the app.
class AppTheme {
  /// Private constructor — this class is not meant to be instantiated.
  const AppTheme._();

  /// Light theme used throughout the Drink Water Reminder app.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.seedColor,
        brightness: Brightness.light,
      ),
    );
  }
}
