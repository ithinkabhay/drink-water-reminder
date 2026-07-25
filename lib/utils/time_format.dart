import 'package:flutter/material.dart';

import '../models/reminder_settings.dart';

/// Helpers for greetings, relative times, and reminder scheduling displays.
class TimeFormat {
  /// Private constructor — this class is not meant to be instantiated.
  const TimeFormat._();

  /// Time-of-day greeting: Good Morning / Afternoon / Evening / Night.
  ///
  /// Windows: Morning 5–11:59, Afternoon 12–16:59, Evening 17–19:59,
  /// Night 20–4:59.
  static String greeting({DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 20) return 'Good Evening';
    return 'Good Night';
  }

  /// Emoji that matches [greeting] for the current time of day.
  static String greetingIcon({DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 12) return '🌅';
    if (hour >= 12 && hour < 17) return '☀️';
    if (hour >= 17 && hour < 20) return '🌇';
    return '🌙';
  }

  /// Combined icon + greeting, e.g. `🌅 Good Morning`.
  static String greetingWithIcon({DateTime? now}) {
    return '${greetingIcon(now: now)} ${greeting(now: now)}';
  }

  /// Relative label such as "Just now", "2 hours ago".
  static String relative(DateTime from, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = current.difference(from);

    if (diff.isNegative || diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return m == 1 ? '1 min ago' : '$m min ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return h == 1 ? '1 hour ago' : '$h hours ago';
    }
    final d = diff.inDays;
    return d == 1 ? '1 day ago' : '$d days ago';
  }

  /// Formats a [DateTime] as a 12-hour clock string (e.g. `3:45 PM`).
  static String clock(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Formats a [TimeOfDay] as a 12-hour clock string.
  static String timeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Next reminder slot from [settings], or `null` when reminders are off.
  ///
  /// After a drink (when [lastIntakeAt] is set and skip-if-recent is on), the
  /// next alert is [lastIntakeAt] + [ReminderSettings.intervalMinutes], then
  /// every interval within the active window — not a fixed 20-minute skip.
  static DateTime? nextReminder(
    ReminderSettings settings, {
    DateTime? now,
    DateTime? lastIntakeAt,
    bool goalAlreadyMet = false,
  }) {
    if (!settings.enabled) return null;

    final current = now ?? DateTime.now();
    final skipToday = goalAlreadyMet && settings.stopAfterGoalCompleted;

    DateTime? anchor;
    if (lastIntakeAt != null && settings.skipIfRecentlyLogged) {
      anchor = lastIntakeAt.add(
        Duration(minutes: settings.intervalMinutes),
      );
    }

    for (var dayOffset = 0; dayOffset < 2; dayOffset++) {
      if (skipToday && dayOffset == 0) continue;

      final day = current.add(Duration(days: dayOffset));
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        settings.startHour,
        settings.startMinute,
      );
      final end = DateTime(
        day.year,
        day.month,
        day.day,
        settings.endHour,
        settings.endMinute,
      );

      if (end.isBefore(start)) continue;

      // Anchor inside this day's window → start the interval chain there.
      // Otherwise walk the normal window grid from [start].
      DateTime slot;
      if (anchor != null) {
        if (anchor.isAfter(end)) continue;
        slot = anchor.isBefore(start) ? start : anchor;
      } else {
        slot = start;
      }

      while (!slot.isAfter(end)) {
        final afterNow = slot.isAfter(current);
        final afterAnchor = anchor == null || !slot.isBefore(anchor);
        if (afterNow && afterAnchor) return slot;
        slot = slot.add(Duration(minutes: settings.intervalMinutes));
      }
    }

    return null;
  }
}
