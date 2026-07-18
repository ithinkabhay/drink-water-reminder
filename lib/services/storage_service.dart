import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/daily_intake.dart';
import '../models/intake_entry.dart';
import '../models/reminder_settings.dart';
import '../models/user_profile.dart';
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
      _box.put(AppConstants.keyIntakeEntries, jsonEncode(<Map<String, dynamic>>[]));
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

  /// Returns today's intake log entries (oldest → newest).
  List<IntakeEntry> loadTodayEntries() {
    // Ensure day rollover runs before reading entries.
    loadTodayIntake();
    return _readEntries();
  }

  /// Appends [entry], updates today's total, and persists everything.
  ///
  /// Returns the new total consumed in milliliters.
  Future<int> addIntakeEntry(IntakeEntry entry) async {
    final current = loadTodayIntake();
    final entries = _readEntries()..add(entry);
    final total = current + entry.amountMl;
    await _writeEntries(entries);
    await saveTodayIntake(total);
    return total;
  }

  /// Removes the most recent intake entry and restores the previous total.
  ///
  /// Returns a record of `(removed, newTotal)`, or `null` when there is
  /// nothing to undo.
  Future<({IntakeEntry removed, int newTotal})?> undoLastIntakeEntry() async {
    final current = loadTodayIntake();
    final entries = _readEntries();
    if (entries.isEmpty) return null;

    final removed = entries.removeLast();
    final total = (current - removed.amountMl).clamp(0, current);
    await _writeEntries(entries);
    await saveTodayIntake(total);
    return (removed: removed, newTotal: total);
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
      soundEnabled: (_box.get(AppConstants.keyReminderSoundEnabled) as bool?) ??
          defaults.soundEnabled,
      vibrationEnabled:
          (_box.get(AppConstants.keyReminderVibrationEnabled) as bool?) ??
              defaults.vibrationEnabled,
      defaultQuickAddMl:
          (_box.get(AppConstants.keyDefaultQuickAddMl) as int?) ??
              defaults.defaultQuickAddMl,
      stopAfterGoalCompleted:
          (_box.get(AppConstants.keyStopAfterGoalCompleted) as bool?) ??
              defaults.stopAfterGoalCompleted,
      skipIfRecentlyLogged:
          (_box.get(AppConstants.keySkipIfRecentlyLogged) as bool?) ??
              defaults.skipIfRecentlyLogged,
      customRingtoneUri:
          _box.get(AppConstants.keyCustomRingtoneUri) as String?,
      customRingtoneTitle:
          _box.get(AppConstants.keyCustomRingtoneTitle) as String?,
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
    await _box.put(AppConstants.keyReminderSoundEnabled, settings.soundEnabled);
    await _box.put(
      AppConstants.keyReminderVibrationEnabled,
      settings.vibrationEnabled,
    );
    await _box.put(
      AppConstants.keyDefaultQuickAddMl,
      settings.defaultQuickAddMl,
    );
    await _box.put(
      AppConstants.keyStopAfterGoalCompleted,
      settings.stopAfterGoalCompleted,
    );
    await _box.put(
      AppConstants.keySkipIfRecentlyLogged,
      settings.skipIfRecentlyLogged,
    );
    if (settings.customRingtoneUri == null) {
      await _box.delete(AppConstants.keyCustomRingtoneUri);
      await _box.delete(AppConstants.keyCustomRingtoneTitle);
    } else {
      await _box.put(
        AppConstants.keyCustomRingtoneUri,
        settings.customRingtoneUri,
      );
      await _box.put(
        AppConstants.keyCustomRingtoneTitle,
        settings.customRingtoneTitle,
      );
    }
  }

  /// Timestamp of the most recent intake entry today, or `null` if none.
  DateTime? loadLastIntakeTimestamp() {
    final entries = loadTodayEntries();
    if (entries.isEmpty) return null;
    return entries.last.timestamp;
  }

  /// Returns the persisted daily goal in milliliters.
  ///
  /// Falls back to [AppConstants.defaultDailyGoalMl] when unset or invalid.
  int loadDailyGoalMl() {
    final stored = _box.get(AppConstants.keyDailyGoalMl);
    if (stored is int) {
      return stored.clamp(
        AppConstants.minDailyGoalMl,
        AppConstants.maxDailyGoalMl,
      );
    }
    if (stored is num) {
      return stored.toInt().clamp(
        AppConstants.minDailyGoalMl,
        AppConstants.maxDailyGoalMl,
      );
    }
    return AppConstants.defaultDailyGoalMl;
  }

  /// Persists the user's daily water goal in milliliters.
  Future<void> saveDailyGoalMl(int goalMl) async {
    final clamped = goalMl.clamp(
      AppConstants.minDailyGoalMl,
      AppConstants.maxDailyGoalMl,
    );
    await _box.put(AppConstants.keyDailyGoalMl, clamped);
  }

  /// Whether first-launch onboarding has been completed.
  bool isOnboardingComplete() {
    return (_box.get(AppConstants.keyOnboardingComplete) as bool?) ?? false;
  }

  /// Marks onboarding as finished so it is skipped on later launches.
  Future<void> setOnboardingComplete(bool complete) async {
    await _box.put(AppConstants.keyOnboardingComplete, complete);
  }

  /// Loads the saved user profile, or `null` when none exists.
  UserProfile? loadUserProfile() {
    final raw = _box.get(AppConstants.keyUserProfile);
    if (raw is! String || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return UserProfile.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  /// Persists [profile] as JSON in Hive.
  Future<void> saveUserProfile(UserProfile profile) async {
    await _box.put(
      AppConstants.keyUserProfile,
      jsonEncode(profile.toJson()),
    );
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

  List<IntakeEntry> _readEntries() {
    final raw = _box.get(AppConstants.keyIntakeEntries);
    if (raw is! String || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return [
      for (final item in decoded)
        if (item is Map)
          IntakeEntry.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<void> _writeEntries(List<IntakeEntry> entries) async {
    await _box.put(
      AppConstants.keyIntakeEntries,
      jsonEncode([for (final e in entries) e.toJson()]),
    );
  }

  /// Returns today's date as an ISO-8601 calendar string (yyyy-MM-dd).
  String _todayIso() => DailyIntake.toDateKey(DateTime.now());
}
