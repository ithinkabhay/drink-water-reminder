import 'package:flutter/material.dart';

import '../models/daily_intake.dart';
import '../models/intake_entry.dart';
import '../models/reminder_settings.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

/// Data-access boundary for hydration intake and reminder preferences.
///
/// Keeps UI and domain services independent of Hive details.
class HydrationRepository {
  /// Creates a repository backed by [storage].
  HydrationRepository({StorageService? storage})
      : _storage = storage ?? StorageService();

  final StorageService _storage;

  /// Today's logged intake in milliliters.
  int loadTodayIntake() => _storage.loadTodayIntake();

  /// Persists today's intake and mirrors it into daily history.
  Future<void> saveTodayIntake(int consumedMl) =>
      _storage.saveTodayIntake(consumedMl);

  /// Today's individual intake log entries (oldest → newest).
  List<IntakeEntry> loadTodayEntries() => _storage.loadTodayEntries();

  /// Logs [amountMl], persists the entry + updated total, returns new total.
  Future<int> addIntake(int amountMl) {
    return _storage.addIntakeEntry(IntakeEntry.now(amountMl));
  }

  /// Undoes the last intake entry. Returns `null` if there is nothing to undo.
  Future<({IntakeEntry removed, int newTotal})?> undoLastIntake() =>
      _storage.undoLastIntakeEntry();

  /// Current consecutive-day streak.
  int loadCurrentStreak() => _storage.loadStreak();

  /// Full map of date-key → milliliters for all saved days.
  Map<String, int> loadHistoryMap() => _storage.loadDailyHistory();

  /// Chronological list of all stored daily entries.
  List<DailyIntake> loadAllHistory() {
    final map = loadHistoryMap();
    final keys = map.keys.toList()..sort();
    return [
      for (final key in keys)
        DailyIntake(
          date: DailyIntake.parseDateKey(key),
          consumedMl: map[key] ?? 0,
        ),
    ];
  }

  /// Timestamp of the most recent intake entry today, or `null` if none.
  DateTime? loadLastIntakeTimestamp() {
    final entries = loadTodayEntries();
    if (entries.isEmpty) return null;
    return entries.last.timestamp;
  }

  /// Reminder preferences.
  ReminderSettings loadReminderSettings() => _storage.loadReminderSettings();

  /// Persists reminder preferences.
  Future<void> saveReminderSettings(ReminderSettings settings) =>
      _storage.saveReminderSettings(settings);

  /// Loads the user-configured daily goal in milliliters.
  int loadDailyGoalMl() => _storage.loadDailyGoalMl();

  /// Persists the daily goal in milliliters.
  Future<void> saveDailyGoalMl(int goalMl) => _storage.saveDailyGoalMl(goalMl);

  /// Whether first-launch onboarding has been completed.
  bool isOnboardingComplete() => _storage.isOnboardingComplete();

  /// Marks onboarding as finished.
  Future<void> setOnboardingComplete(bool complete) =>
      _storage.setOnboardingComplete(complete);

  /// Saved user profile, or `null` when unset.
  UserProfile? loadUserProfile() => _storage.loadUserProfile();

  /// Persists the user profile.
  Future<void> saveUserProfile(UserProfile profile) =>
      _storage.saveUserProfile(profile);

  /// Local profile avatar path, or `null` when unset.
  String? loadProfileAvatarPath() => _storage.loadProfileAvatarPath();

  /// Persists the profile avatar path (or clears it when `null`).
  Future<void> saveProfileAvatarPath(String? path) =>
      _storage.saveProfileAvatarPath(path);

  /// Completes onboarding by saving [profile], [dailyGoalMl], and the flag.
  Future<void> completeOnboarding({
    required UserProfile profile,
    required int dailyGoalMl,
  }) async {
    await saveUserProfile(profile);
    await saveDailyGoalMl(dailyGoalMl);
    await setOnboardingComplete(true);
  }

  /// Preferred [ThemeMode], defaulting to system.
  ThemeMode loadThemeMode() {
    switch (_storage.loadThemeModeKey()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Persists [mode].
  Future<void> saveThemeMode(ThemeMode mode) {
    final key = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    return _storage.saveThemeModeKey(key);
  }

  /// JSON export of local hydration data.
  Map<String, dynamic> exportData() => _storage.exportData();

  /// Restores data from an [exportData] snapshot.
  Future<void> importData(Map<String, dynamic> data) =>
      _storage.importData(data);

  /// Clears intake logs and history (keeps profile / settings).
  Future<void> resetHydrationData() => _storage.resetHydrationData();

  /// Full factory reset of the Hive box.
  Future<void> resetAllData() => _storage.resetAllData();
}
