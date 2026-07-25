import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// User-configurable reminder preferences for the smart hydration assistant.
class ReminderSettings {
  /// Creates reminder settings.
  const ReminderSettings({
    required this.enabled,
    required this.intervalMinutes,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.defaultQuickAddMl,
    required this.stopAfterGoalCompleted,
    required this.skipIfRecentlyLogged,
    this.customRingtoneUri,
    this.customRingtoneTitle,
  });

  /// Whether drink reminders are currently active.
  final bool enabled;

  /// Minutes between consecutive reminders / delay after the last drink.
  final int intervalMinutes;

  /// Hour component of the daily reminder window start (0–23).
  final int startHour;

  /// Minute component of the daily reminder window start (0–59).
  final int startMinute;

  /// Hour component of the daily reminder window end (0–23).
  final int endHour;

  /// Minute component of the daily reminder window end (0–59).
  final int endMinute;

  /// Whether the notification sound should play.
  final bool soundEnabled;

  /// Whether the repeating vibration pattern should run.
  final bool vibrationEnabled;

  /// Default milliliters added when the user taps "Drank Water".
  final int defaultQuickAddMl;

  /// Cancel remaining reminders for the day once the daily goal is met.
  final bool stopAfterGoalCompleted;

  /// After logging water, wait [intervalMinutes] before the next reminder.
  final bool skipIfRecentlyLogged;

  /// Android content URI for a user-picked system ringtone, if any.
  final String? customRingtoneUri;

  /// Display name of [customRingtoneUri].
  final String? customRingtoneTitle;

  /// Whether [intervalMinutes] is outside the preset list (custom).
  bool get isCustomInterval =>
      !AppConstants.reminderIntervalPresetsMinutes.contains(intervalMinutes);

  /// Default settings: enabled, every 1 hour, 8:00 AM – 10:00 PM.
  factory ReminderSettings.defaults() {
    return const ReminderSettings(
      enabled: true,
      intervalMinutes: 45,
      startHour: 8,
      startMinute: 0,
      endHour: 22,
      endMinute: 0,
      soundEnabled: true,
      vibrationEnabled: true,
      defaultQuickAddMl: 250,
      stopAfterGoalCompleted: true,
      skipIfRecentlyLogged: true,
    );
  }

  /// Start of the reminder window as a [TimeOfDay].
  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);

  /// End of the reminder window as a [TimeOfDay].
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  /// Returns a copy with the given fields replaced.
  ///
  /// Pass [clearCustomRingtone] to remove a previously picked ringtone.
  ReminderSettings copyWith({
    bool? enabled,
    int? intervalMinutes,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? defaultQuickAddMl,
    bool? stopAfterGoalCompleted,
    bool? skipIfRecentlyLogged,
    String? customRingtoneUri,
    String? customRingtoneTitle,
    bool clearCustomRingtone = false,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      defaultQuickAddMl: defaultQuickAddMl ?? this.defaultQuickAddMl,
      stopAfterGoalCompleted:
          stopAfterGoalCompleted ?? this.stopAfterGoalCompleted,
      skipIfRecentlyLogged:
          skipIfRecentlyLogged ?? this.skipIfRecentlyLogged,
      customRingtoneUri: clearCustomRingtone
          ? null
          : (customRingtoneUri ?? this.customRingtoneUri),
      customRingtoneTitle: clearCustomRingtone
          ? null
          : (customRingtoneTitle ?? this.customRingtoneTitle),
    );
  }
}
