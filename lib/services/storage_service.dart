import 'package:hive_flutter/hive_flutter.dart';

import '../utils/constants.dart';

/// Handles persistent local storage of today's water intake via Hive.
///
/// Saves and loads milliliters consumed, and resets automatically when
/// the calendar date changes so yesterday's progress does not carry over.
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
  /// If the stored date is not today (or no data exists), returns `0`
  /// and clears any stale values so the new day starts fresh.
  int loadTodayIntake() {
    final savedDate = _box.get(AppConstants.keySavedDate) as String?;
    final today = _todayIso();

    if (savedDate != today) {
      // Memory is updated immediately; disk flush happens in the background.
      _box.put(AppConstants.keyConsumedMl, 0);
      _box.put(AppConstants.keySavedDate, today);
      return 0;
    }

    return (_box.get(AppConstants.keyConsumedMl) as int?) ?? 0;
  }

  /// Persists [consumedMl] together with today's date.
  Future<void> saveTodayIntake(int consumedMl) async {
    await _box.put(AppConstants.keyConsumedMl, consumedMl);
    await _box.put(AppConstants.keySavedDate, _todayIso());
  }

  /// Returns today's date as an ISO-8601 calendar string (yyyy-MM-dd).
  String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
