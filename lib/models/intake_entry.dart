/// A single water-intake log with amount and when it was recorded.
class IntakeEntry {
  /// Creates an intake entry.
  const IntakeEntry({
    required this.amountMl,
    required this.timestamp,
    required this.date,
  });

  /// Milliliters added in this log.
  final int amountMl;

  /// Exact time the intake was recorded.
  final DateTime timestamp;

  /// Calendar day for the entry (time portion ignored).
  final DateTime date;

  /// ISO calendar key (yyyy-MM-dd) for [date].
  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Serializes this entry for Hive JSON storage.
  Map<String, dynamic> toJson() => {
        'amount': amountMl,
        'timestamp': timestamp.toIso8601String(),
        'date': dateKey,
      };

  /// Deserializes an entry from Hive JSON.
  factory IntakeEntry.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date'] as String? ?? '';
    final dateParts = dateRaw.split('-');
    final date = dateParts.length == 3
        ? DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          )
        : DateTime.now();

    return IntakeEntry(
      amountMl: (json['amount'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      date: date,
    );
  }

  /// Builds an entry for [amountMl] recorded at [now] (defaults to now).
  factory IntakeEntry.now(int amountMl, {DateTime? now}) {
    final recorded = now ?? DateTime.now();
    return IntakeEntry(
      amountMl: amountMl,
      timestamp: recorded,
      date: DateTime(recorded.year, recorded.month, recorded.day),
    );
  }
}
