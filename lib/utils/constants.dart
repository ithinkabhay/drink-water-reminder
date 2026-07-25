import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Shared constants used across the Waterly app.
///
/// Keeps magic numbers and strings in one place for easy maintenance.
/// Visual tokens (colors, spacing, radius, type) live under `lib/theme/`.
class AppConstants {
  /// Private constructor — this class is not meant to be instantiated.
  const AppConstants._();

  /// Display name shown in the system and the app bar.
  static const String appTitle = 'Waterly';

  /// Short brand name used in onboarding and about.
  static const String brandName = 'Waterly';

  /// Product tagline.
  static const String tagline = 'Stay Hydrated. Stay Healthy.';

  /// Label above the intake / goal values.
  static const String todaysGoalLabel = "Today's Goal";

  /// Default daily water intake goal in milliliters (used on first launch).
  static const int defaultDailyGoalMl = 3000;

  /// Lowest allowed custom daily goal in milliliters.
  static const int minDailyGoalMl = 500;

  /// Highest allowed custom daily goal in milliliters.
  static const int maxDailyGoalMl = 10000;

  /// Preset daily goals shown in the Set Daily Goal sheet.
  static const List<int> quickDailyGoalOptionsMl = [
    2000,
    2500,
    3000,
    3500,
    4000,
  ];

  /// Preset amounts shown in the Quick Add chip row (milliliters).
  static const List<int> quickAddAmountsMl = [
    100,
    250,
    500,
  ];

  /// Lowest allowed custom quick-add amount in milliliters.
  static const int minCustomAmountMl = 50;

  /// Highest allowed custom quick-add amount in milliliters.
  static const int maxCustomAmountMl = 5000;

  /// Label for the custom quick-add tile.
  static const String customAmountLabel = 'Custom';

  /// Water-inspired seed color for the Material 3 color scheme.
  static const Color seedColor = Color(0xFF5DB8FF);

  /// Diameter of the circular progress indicator.
  static const double progressSize = 260;

  /// Stroke width of the circular progress indicator.
  static const double progressStrokeWidth = 14;

  /// Height of each quick-add chip.
  static const double quickAddTileHeight = 48;

  /// Corner radius of quick-add chips.
  static const double quickAddTileRadius = AppRadius.capsule;

  /// Corner radius for filled primary buttons (theme-wide).
  static const double buttonRadius = AppRadius.medium;

  /// Corner radius for surface cards.
  static const double glassCardRadius = AppRadius.medium;

  /// Large typography size (greetings).
  static const double fontSizeLarge = AppTypography.large;

  /// Medium typography size (hydration circle / titles).
  static const double fontSizeMedium = AppTypography.medium;

  /// Small typography size (descriptions).
  static const double fontSizeSmall = AppTypography.small;

  /// Standard micro-interaction duration.
  static const Duration animFast = Duration(milliseconds: 220);

  /// Standard UI transition duration.
  static const Duration animNormal = Duration(milliseconds: 300);

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

  /// Key for the user-selected daily goal in milliliters.
  static const String keyDailyGoalMl = 'daily_goal_ml';

  /// Key for the ISO date string (yyyy-MM-dd) of the last save.
  static const String keySavedDate = 'saved_date';

  /// Key for consecutive-day hydration streak count.
  static const String keyStreakCount = 'streak_count';

  /// Key for the ISO date of the last day the user logged water.
  static const String keyLastActiveDate = 'last_active_date';

  /// Key for the map of daily intake history (date → ml).
  static const String keyDailyHistory = 'daily_history';

  /// Key for today's individual intake entries (JSON list).
  static const String keyIntakeEntries = 'intake_entries';

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

  /// Key for whether notification sound is enabled.
  static const String keyReminderSoundEnabled = 'reminder_sound_enabled';

  /// Key for whether notification vibration is enabled.
  static const String keyReminderVibrationEnabled =
      'reminder_vibration_enabled';

  /// Key for the user-selected system ringtone URI (Android).
  static const String keyCustomRingtoneUri = 'custom_ringtone_uri';

  /// Key for the display title of the selected ringtone.
  static const String keyCustomRingtoneTitle = 'custom_ringtone_title';

  /// Key for the default quick-add amount used by "Drank Water".
  static const String keyDefaultQuickAddMl = 'default_quick_add_ml';

  /// Key for stopping reminders after the daily goal is completed.
  static const String keyStopAfterGoalCompleted =
      'stop_after_goal_completed';

  /// Key for skipping reminders when water was logged recently.
  static const String keySkipIfRecentlyLogged = 'skip_if_recently_logged';

  /// Key for whether first-launch onboarding has been completed.
  static const String keyOnboardingComplete = 'onboarding_complete';

  /// Key for the persisted user profile JSON.
  static const String keyUserProfile = 'user_profile';

  /// Key for the preferred theme mode (`system` / `light` / `dark`).
  static const String keyThemeMode = 'theme_mode';

  /// Key for the local profile avatar file path.
  static const String keyProfileAvatarPath = 'profile_avatar_path';

  /// Lowest allowed age during onboarding / profile edit.
  static const int minAge = 5;

  /// Highest allowed age during onboarding / profile edit.
  static const int maxAge = 120;

  /// Lowest allowed weight in kilograms.
  static const double minWeightKg = 20;

  /// Highest allowed weight in kilograms.
  static const double maxWeightKg = 300;

  /// Lowest allowed height in centimeters.
  static const double minHeightCm = 80;

  /// Highest allowed height in centimeters.
  static const double maxHeightCm = 250;

  // ── Notifications ──────────────────────────────────────────────────

  /// Fallback title shown on drink reminder notifications.
  static const String notificationTitle = '💧 Time to Drink Water';

  /// Fallback body shown on drink reminder notifications.
  static const String notificationBody =
      "It's time to drink your next glass of water.";

  /// Full-screen reminder headline.
  static const String fullScreenReminderTitle = '💧 Time to Drink Water';

  /// Full-screen reminder supporting copy.
  static const String fullScreenReminderBody =
      "It's time to drink your next glass of water.";

  /// Android raw resource name (no extension) for the built-in chime fallback.
  ///
  /// File lives at `android/app/src/main/res/raw/water_chime.wav` and is
  /// also mirrored under `assets/sounds/` for bundling.
  static const String notificationSoundResource = 'water_chime';

  /// Base Android notification channel id prefix (v6 = max importance, lock
  /// screen public, silent channel + companion 10s foreground sound service).
  ///
  /// Channel settings are immutable on Android — [NotificationService]
  /// appends sound/vibration suffixes so toggles take effect.
  static const String notificationChannelIdPrefix = 'water_reminders_v6';

  /// Legacy alias kept for older references; prefer dynamic channel ids.
  static const String notificationChannelId = notificationChannelIdPrefix;

  /// Android notification channel name.
  static const String notificationChannelName = 'Water Reminders';

  /// Android notification channel description.
  static const String notificationChannelDescription =
      'High-priority hydration reminders with vibration, lock-screen '
      'visibility, and a companion 10-second ringtone alert';

  /// How long reminder sound / heads-up should run (milliseconds).
  static const int notificationAlertDurationMs = 10000;

  /// How many days ahead to schedule reminder notifications.
  ///
  /// Kept short so short intervals stay under Android's ~500 concurrent
  /// exact-alarm limit (also capped by [maxPendingReminders]).
  static const int scheduleDaysAhead = 2;

  /// Hard cap on pending interval reminders (Android limit is ~500 total).
  static const int maxPendingReminders = 80;

  /// Preset reminder intervals in minutes (excludes custom).
  static const List<int> reminderIntervalPresetsMinutes = [
    15,
    30,
    45,
  ];

  /// Legacy alias kept for any remaining callers.
  static const List<int> reminderIntervalsMinutes =
      reminderIntervalPresetsMinutes;

  /// Sentinel value used in UI selectors for a custom interval.
  static const int customIntervalSentinel = -1;

  /// Minimum custom reminder interval in minutes.
  static const int minCustomIntervalMinutes = 10;

  /// Maximum custom reminder interval in minutes.
  static const int maxCustomIntervalMinutes = 360;

  /// Snooze options shown after "Remind Me Later".
  static const List<int> snoozeOptionsMinutes = [10, 15, 30];

  /// Notification action id: log the default quick-add amount.
  static const String actionDrankWater = 'drank_water';

  /// Notification action id: open snooze duration picker.
  static const String actionRemindLater = 'remind_later';

  /// Payload used for regular scheduled hydration reminders.
  static const String payloadReminder = 'hydration_reminder';

  /// Payload used when launching the snooze picker.
  static const String payloadSnooze = 'snooze_picker';

  /// iOS / macOS notification action category identifier.
  static const String darwinReminderCategoryId = 'hydration_reminder';

  /// Notification id used for one-off snooze reminders.
  static const int snoozeNotificationId = 900001;

  /// Returns a motivational line based on progress toward the daily goal.
  static String motivationalMessageFor(double progress) {
    if (progress >= 1.0) return motivationalMessages[4];
    if (progress >= 0.75) return motivationalMessages[3];
    if (progress >= 0.5) return motivationalMessages[2];
    if (progress >= 0.25) return motivationalMessages[1];
    return motivationalMessages[0];
  }

  /// Human-readable label for a reminder interval in minutes.
  static String intervalLabel(int minutes) {
    if (minutes < 60) return 'Every $minutes minutes';
    if (minutes == 60) return 'Every 1 hour';
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return 'Every $hours hours';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return 'Every ${hours}h ${mins}m';
  }
}
