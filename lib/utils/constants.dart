import 'package:flutter/material.dart';

/// Shared constants used across the Drink Water Reminder app.
///
/// Keeps magic numbers and strings in one place for easy maintenance.
class AppConstants {
  /// Private constructor — this class is not meant to be instantiated.
  const AppConstants._();

  /// Display name shown in the system and the app bar.
  static const String appTitle = 'Drink Water Reminder';

  /// Label above the intake / goal values.
  static const String todaysGoalLabel = "Today's Goal";

  /// Label on the primary drink action button.
  static const String drinkButtonLabel = 'Drink 250 ml';

  /// Daily water intake goal in milliliters.
  static const int dailyGoalMl = 3000;

  /// Amount added each time the user taps the drink button.
  static const int drinkAmountMl = 250;

  /// Water-inspired seed color for the Material 3 color scheme.
  static const Color seedColor = Color(0xFF2196F3);

  /// Font size for the water drop emoji.
  static const double waterEmojiSize = 72;

  /// Diameter of the circular progress indicator.
  static const double progressSize = 180;

  /// Stroke width of the circular progress indicator.
  static const double progressStrokeWidth = 12;

  /// Height of the primary drink button.
  static const double drinkButtonHeight = 56;

  /// Corner radius of the primary drink button.
  static const double drinkButtonRadius = 16;

  // ── Hive storage keys ──────────────────────────────────────────────

  /// Name of the Hive box used for water-intake persistence.
  static const String hiveBoxName = 'water_intake';

  /// Key for the stored milliliters consumed today.
  static const String keyConsumedMl = 'consumed_ml';

  /// Key for the ISO date string (yyyy-MM-dd) of the last save.
  static const String keySavedDate = 'saved_date';
}
