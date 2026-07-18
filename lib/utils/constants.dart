import 'package:flutter/material.dart';

/// Shared constants used across the Drink Water Reminder app.
///
/// Keeps magic numbers and strings in one place for easy maintenance.
class AppConstants {
  /// Private constructor — this class is not meant to be instantiated.
  const AppConstants._();

  /// Display name shown in the system and the app bar.
  static const String appTitle = 'Drink Water Reminder';

  /// Short brand name used in the premium home header.
  static const String brandName = 'Hydrate';

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

  /// Diameter of the circular progress indicator.
  static const double progressSize = 220;

  /// Stroke width of the circular progress indicator.
  static const double progressStrokeWidth = 10;

  /// Height of the primary drink button.
  static const double drinkButtonHeight = 60;

  /// Corner radius of the primary drink button.
  static const double drinkButtonRadius = 20;

  /// Corner radius for glassmorphism cards.
  static const double glassCardRadius = 24;

  /// Motivational messages keyed by progress bands.
  static const List<String> motivationalMessages = [
    'Every sip counts — start strong today.',
    'Nice start! Keep the momentum flowing.',
    "You're halfway there. Stay refreshed!",
    'Almost at your goal — finish strong!',
    'Goal crushed! Your body thanks you.',
  ];

  // ── Hive storage keys ──────────────────────────────────────────────

  /// Name of the Hive box used for water-intake persistence.
  static const String hiveBoxName = 'water_intake';

  /// Key for the stored milliliters consumed today.
  static const String keyConsumedMl = 'consumed_ml';

  /// Key for the ISO date string (yyyy-MM-dd) of the last save.
  static const String keySavedDate = 'saved_date';

  /// Key for consecutive-day hydration streak count.
  static const String keyStreakCount = 'streak_count';

  /// Key for the ISO date of the last day the user logged water.
  static const String keyLastActiveDate = 'last_active_date';

  /// Key for the map of daily intake history (date → ml).
  static const String keyDailyHistory = 'daily_history';

  /// Key for whether reminders are enabled.
  static const String keyRemindersEnabled = 'reminders_enabled';

  /// Key for reminder interval in minutes.
  static const String keyReminderIntervalMinutes = 'reminder_interval_minutes';

  /// Key for reminder window start hour.
  static const String keyReminderStartHour = 'reminder_start_hour';

  /// Key for reminder window start minute.
  static const String keyReminderStartMinute = 'reminder_start_minute';

  /// Key for reminder window end hour.
  static const String keyReminderEndHour = 'reminder_end_hour';

  /// Key for reminder window end minute.
  static const String keyReminderEndMinute = 'reminder_end_minute';

  // ── Notifications ──────────────────────────────────────────────────

  /// Title shown on drink reminder notifications.
  static const String notificationTitle = '💧 Time to Drink Water';

  /// Body shown on drink reminder notifications.
  static const String notificationBody =
      'Stay hydrated! Drink a glass of water.';

  /// Android notification channel id.
  static const String notificationChannelId = 'water_reminders';

  /// Android notification channel name.
  static const String notificationChannelName = 'Water Reminders';

  /// Android notification channel description.
  static const String notificationChannelDescription =
      'Periodic reminders to drink water';

  /// How many days ahead to schedule reminder notifications.
  static const int scheduleDaysAhead = 7;

  /// Allowed reminder intervals in minutes.
  static const List<int> reminderIntervalsMinutes = [30, 60, 120];

  /// Returns a motivational line based on progress toward the daily goal.
  static String motivationalMessageFor(double progress) {
    if (progress >= 1.0) return motivationalMessages[4];
    if (progress >= 0.75) return motivationalMessages[3];
    if (progress >= 0.5) return motivationalMessages[2];
    if (progress >= 0.25) return motivationalMessages[1];
    return motivationalMessages[0];
  }
}
