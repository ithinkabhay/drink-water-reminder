/// A single day's water intake record.
class DailyIntake {
  /// Creates a daily intake entry for [date] with [consumedMl] milliliters.
  const DailyIntake({
    required this.date,
    required this.consumedMl,
  });

  /// Calendar day for this entry (time portion ignored).
  final DateTime date;

  /// Milliliters of water logged on [date].
  final int consumedMl;

  /// ISO calendar key (yyyy-MM-dd).
  String get dateKey => DailyIntake.toDateKey(date);

  /// Formats [date] as yyyy-MM-dd.
  static String toDateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Parses an ISO calendar key into a [DateTime] at midnight local.
  static DateTime parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Creates a copy with optional field overrides.
  DailyIntake copyWith({
    DateTime? date,
    int? consumedMl,
  }) {
    return DailyIntake(
      date: date ?? this.date,
      consumedMl: consumedMl ?? this.consumedMl,
    );
  }
}
