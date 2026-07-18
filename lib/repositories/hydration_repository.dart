import '../models/daily_intake.dart';
import '../models/reminder_settings.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

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

  /// Reminder preferences.
  ReminderSettings loadReminderSettings() => _storage.loadReminderSettings();

  /// Persists reminder preferences.
  Future<void> saveReminderSettings(ReminderSettings settings) =>
      _storage.saveReminderSettings(settings);

  /// Daily goal in milliliters.
  int get dailyGoalMl => AppConstants.dailyGoalMl;
}
