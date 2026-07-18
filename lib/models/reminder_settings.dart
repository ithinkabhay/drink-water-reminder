import 'package:flutter/material.dart';

/// User-configurable reminder preferences for local notifications.
class ReminderSettings {
  /// Creates reminder settings.
  const ReminderSettings({
    required this.enabled,
    required this.intervalMinutes,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  /// Whether drink reminders are currently active.
  final bool enabled;

  /// Minutes between consecutive reminders (30, 60, or 120).
  final int intervalMinutes;

  /// Hour component of the daily reminder window start (0–23).
  final int startHour;

  /// Minute component of the daily reminder window start (0–59).
  final int startMinute;

  /// Hour component of the daily reminder window end (0–23).
  final int endHour;

  /// Minute component of the daily reminder window end (0–59).
  final int endMinute;

  /// Default settings: enabled, every 1 hour, 8:00 AM – 10:00 PM.
  factory ReminderSettings.defaults() {
    return const ReminderSettings(
      enabled: true,
      intervalMinutes: 60,
      startHour: 8,
      startMinute: 0,
      endHour: 22,
      endMinute: 0,
    );
  }

  /// Start of the reminder window as a [TimeOfDay].
  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);

  /// End of the reminder window as a [TimeOfDay].
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  /// Returns a copy with the given fields replaced.
  ReminderSettings copyWith({
    bool? enabled,
    int? intervalMinutes,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
    );
  }
}
