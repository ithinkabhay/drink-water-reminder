import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/daily_intake.dart';
import '../models/reminder_settings.dart';
import '../utils/constants.dart';

/// Handles persistent local storage of today's water intake, daily history,
/// and reminder settings via Hive.
///
/// Saves and loads milliliters consumed, archives previous days into history
/// when the calendar date changes, and resets today's progress automatically.
class StorageService {
  /// Creates a [StorageService] that reads/writes the given Hive [box].
  StorageService({Box? box}) : _box = box ?? Hive.box(AppConstants.hiveBoxName);

  final Box _box;

  /// Opens the Hive box used for water-intake data.
  ///
  /// Must be called once after [Hive.initFlutter] and before creating
  /// a [StorageService] that relies on the default box.
  static Future<void> init() async {
    await Hive.openBox(AppConstants.hiveBoxName);
  }

  /// Returns today's water intake in milliliters.
  ///
  /// If the stored date is not today (or no data exists), archives the
  /// previous day's intake into history, then returns `0` for the new day.
  int loadTodayIntake() {
    final savedDate = _box.get(AppConstants.keySavedDate) as String?;
    final today = _todayIso();

    if (savedDate != today) {
      if (savedDate != null) {
        final previous = (_box.get(AppConstants.keyConsumedMl) as int?) ?? 0;
        _writeHistoryEntry(savedDate, previous);
      }
      _box.put(AppConstants.keyConsumedMl, 0);
      _box.put(AppConstants.keySavedDate, today);
      return 0;
    }

    final consumed = (_box.get(AppConstants.keyConsumedMl) as int?) ?? 0;
    // Keep history in sync with the live today value.
    _writeHistoryEntry(today, consumed);
    return consumed;
  }

  /// Persists [consumedMl] together with today's date, history, and streak.
  Future<void> saveTodayIntake(int consumedMl) async {
    final today = _todayIso();
    await _box.put(AppConstants.keyConsumedMl, consumedMl);
    await _box.put(AppConstants.keySavedDate, today);
    await _upsertHistoryEntry(today, consumedMl);

    if (consumedMl > 0) {
      await _updateStreakOnDrink();
    }
  }

  /// Returns a copy of the stored daily history map (dateKey → ml).
  Map<String, int> loadDailyHistory() {
    final result = Map<String, int>.from(_readHistoryMap());

    // Ensure today's live value is reflected even before first drink today.
    final savedDate = _box.get(AppConstants.keySavedDate) as String?;
    final today = _todayIso();
    if (savedDate == today) {
      result[today] = (_box.get(AppConstants.keyConsumedMl) as int?) ?? 0;
    }

    return result;
  }

  /// Returns the current consecutive-day hydration streak.
  int loadStreak() {
    final lastActive = _box.get(AppConstants.keyLastActiveDate) as String?;
    final streak = (_box.get(AppConstants.keyStreakCount) as int?) ?? 0;
    if (lastActive == null || streak <= 0) return 0;

    final today = DateTime.now();
    final last = DateTime.tryParse(lastActive);
    if (last == null) return 0;

    final dayDiff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;

    // Streak is still valid if the user drank today or yesterday.
    if (dayDiff <= 1) return streak;
    return 0;
  }

  /// Marks today as an active hydration day and bumps the streak when needed.
  Future<void> _updateStreakOnDrink() async {
    final today = _todayIso();
    final lastActive = _box.get(AppConstants.keyLastActiveDate) as String?;
    final current = (_box.get(AppConstants.keyStreakCount) as int?) ?? 0;

    if (lastActive == today) return;

    int nextStreak = 1;
    if (lastActive != null) {
      final last = DateTime.tryParse(lastActive);
      final now = DateTime.now();
      if (last != null) {
        final dayDiff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(last.year, last.month, last.day))
            .inDays;
        if (dayDiff == 1) {
          nextStreak = current + 1;
        }
      }
    }

    await _box.put(AppConstants.keyStreakCount, nextStreak);
    await _box.put(AppConstants.keyLastActiveDate, today);
  }

  /// Loads reminder preferences, falling back to [ReminderSettings.defaults].
  ReminderSettings loadReminderSettings() {
    final defaults = ReminderSettings.defaults();

    return ReminderSettings(
      enabled: (_box.get(AppConstants.keyRemindersEnabled) as bool?) ??
          defaults.enabled,
      intervalMinutes:
          (_box.get(AppConstants.keyReminderIntervalMinutes) as int?) ??
              defaults.intervalMinutes,
      startHour: (_box.get(AppConstants.keyReminderStartHour) as int?) ??
          defaults.startHour,
      startMinute: (_box.get(AppConstants.keyReminderStartMinute) as int?) ??
          defaults.startMinute,
      endHour: (_box.get(AppConstants.keyReminderEndHour) as int?) ??
          defaults.endHour,
      endMinute: (_box.get(AppConstants.keyReminderEndMinute) as int?) ??
          defaults.endMinute,
    );
  }

  /// Persists [settings] so they survive app restarts.
  Future<void> saveReminderSettings(ReminderSettings settings) async {
    await _box.put(AppConstants.keyRemindersEnabled, settings.enabled);
    await _box.put(
      AppConstants.keyReminderIntervalMinutes,
      settings.intervalMinutes,
    );
    await _box.put(AppConstants.keyReminderStartHour, settings.startHour);
    await _box.put(AppConstants.keyReminderStartMinute, settings.startMinute);
    await _box.put(AppConstants.keyReminderEndHour, settings.endHour);
    await _box.put(AppConstants.keyReminderEndMinute, settings.endMinute);
  }

  Map<String, int> _readHistoryMap() {
    final raw = _box.get(AppConstants.keyDailyHistory);
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), (value as num).toInt()),
        );
      }
    }
    // Backward compatibility with older map-based storage.
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      );
    }
    return {};
  }

  void _writeHistoryEntry(String dateKey, int consumedMl) {
    final history = _readHistoryMap();
    history[dateKey] = consumedMl;
    _box.put(AppConstants.keyDailyHistory, jsonEncode(history));
  }

  Future<void> _upsertHistoryEntry(String dateKey, int consumedMl) async {
    final history = _readHistoryMap();
    history[dateKey] = consumedMl;
    await _box.put(AppConstants.keyDailyHistory, jsonEncode(history));
  }

  /// Returns today's date as an ISO-8601 calendar string (yyyy-MM-dd).
  String _todayIso() => DailyIntake.toDateKey(DateTime.now());
}
