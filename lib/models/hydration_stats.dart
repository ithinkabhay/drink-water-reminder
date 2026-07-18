import 'daily_intake.dart';

/// Supported history chart ranges.
enum HistoryPeriod {
  /// Last 7 calendar days including today.
  week,

  /// Last 30 calendar days including today.
  month,
}

/// Aggregated hydration stats for a selected [HistoryPeriod].
class HydrationStats {
  /// Creates a stats snapshot for [period].
  const HydrationStats({
    required this.period,
    required this.entries,
    required this.totalMl,
    required this.averageMl,
    required this.longestStreak,
    required this.currentStreak,
  });

  /// Range these stats cover.
  final HistoryPeriod period;

  /// Daily entries in chronological order (oldest → newest).
  final List<DailyIntake> entries;

  /// Sum of intake across [entries].
  final int totalMl;

  /// Mean daily intake across [entries] (rounded).
  final int averageMl;

  /// Longest consecutive active days in all known history.
  final int longestStreak;

  /// Current consecutive active-day streak.
  final int currentStreak;

  /// Number of days covered by this period.
  int get dayCount => entries.length;
}
