import '../models/daily_intake.dart';
import '../models/hydration_stats.dart';
import '../repositories/hydration_repository.dart';

/// Domain logic for weekly/monthly hydration history and aggregates.
class HydrationHistoryService {
  /// Creates a history service using [repository].
  HydrationHistoryService({HydrationRepository? repository})
      : _repository = repository ?? HydrationRepository();

  final HydrationRepository _repository;

  /// Builds stats and filled daily series for [period].
  HydrationStats loadStats(HistoryPeriod period) {
    final history = _repository.loadHistoryMap();
    final today = _dateOnly(DateTime.now());
    final dayCount = period == HistoryPeriod.week ? 7 : 30;
    final start = today.subtract(Duration(days: dayCount - 1));

    final entries = <DailyIntake>[];
    for (var i = 0; i < dayCount; i++) {
      final day = start.add(Duration(days: i));
      final key = DailyIntake.toDateKey(day);
      entries.add(
        DailyIntake(
          date: day,
          consumedMl: history[key] ?? 0,
        ),
      );
    }

    final total = entries.fold<int>(0, (sum, e) => sum + e.consumedMl);
    final average = dayCount == 0 ? 0 : (total / dayCount).round();

    return HydrationStats(
      period: period,
      entries: entries,
      totalMl: total,
      averageMl: average,
      longestStreak: _longestStreak(history),
      currentStreak: _repository.loadCurrentStreak(),
    );
  }

  /// Longest run of consecutive days with any logged intake.
  int _longestStreak(Map<String, int> history) {
    if (history.isEmpty) return 0;

    final activeDays = history.entries
        .where((e) => e.value > 0)
        .map((e) => DailyIntake.parseDateKey(e.key))
        .toList()
      ..sort();

    if (activeDays.isEmpty) return 0;

    var longest = 1;
    var current = 1;

    for (var i = 1; i < activeDays.length; i++) {
      final gap = activeDays[i].difference(activeDays[i - 1]).inDays;
      if (gap == 1) {
        current += 1;
        if (current > longest) longest = current;
      } else if (gap > 1) {
        current = 1;
      }
    }

    return longest;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
