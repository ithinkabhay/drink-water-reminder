import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_settings.dart';
import '../utils/constants.dart';

/// Schedules and manages local drink-water reminder notifications.
///
/// Notifications are scheduled as individual timed alerts within the user's
/// daily window so they still fire when the app is closed.
class NotificationService {
  /// Shared plugin instance used for all notification operations.
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Whether the current platform supports local notifications.
  bool get _isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  /// Initializes the plugin and the local timezone database.
  ///
  /// Safe to call on unsupported platforms (no-op) and in tests (errors
  /// are swallowed so widget tests can still run).
  Future<void> init() async {
    _configureLocalTimeZone();

    if (!_isSupported) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(settings: settings);
    } catch (_) {
      // Plugin channels are unavailable in pure unit/widget tests.
    }
  }

  /// Requests notification (and exact-alarm) permission on first launch.
  Future<bool> requestPermission() async {
    if (!_isSupported) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.requestNotificationsPermission();
        await android?.requestExactAlarmsPermission();
        return granted ?? false;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final mac = _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
        final granted = await mac?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (_) {
      return false;
    }

    return true;
  }

  /// Cancels pending reminders and schedules new ones from [settings].
  ///
  /// When reminders are disabled, all pending notifications are cleared.
  Future<void> reschedule(ReminderSettings settings) async {
    if (!_isSupported) return;

    try {
      await _plugin.cancelAll();

      if (!settings.enabled) return;

      await _scheduleWindow(settings);
    } catch (_) {
      // Ignore scheduling failures on unsupported/test environments.
    }
  }

  /// Schedules reminders for the next [AppConstants.scheduleDaysAhead] days.
  Future<void> _scheduleWindow(ReminderSettings settings) async {
    final now = tz.TZDateTime.now(tz.local);
    var notificationId = 0;

    for (var dayOffset = 0;
        dayOffset < AppConstants.scheduleDaysAhead;
        dayOffset++) {
      final day = now.add(Duration(days: dayOffset));
      var slot = tz.TZDateTime(
        tz.local,
        day.year,
        day.month,
        day.day,
        settings.startHour,
        settings.startMinute,
      );
      final end = tz.TZDateTime(
        tz.local,
        day.year,
        day.month,
        day.day,
        settings.endHour,
        settings.endMinute,
      );

      while (!slot.isAfter(end)) {
        if (slot.isAfter(now)) {
          await _plugin.zonedSchedule(
            id: notificationId,
            title: AppConstants.notificationTitle,
            body: AppConstants.notificationBody,
            scheduledDate: slot,
            notificationDetails: _notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          notificationId++;
        }

        slot = slot.add(Duration(minutes: settings.intervalMinutes));
      }
    }
  }

  /// Shared visual style for reminder notifications.
  NotificationDetails get _notificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Initializes timezone data and picks a location matching the device offset.
  void _configureLocalTimeZone() {
    tz_data.initializeTimeZones();

    final offset = DateTime.now().timeZoneOffset;
    tz.Location? fallback;

    for (final location in tz.timeZoneDatabase.locations.values) {
      final localNow = tz.TZDateTime.now(location);
      if (localNow.timeZoneOffset != offset) continue;

      fallback ??= location;
      // Prefer named city zones over Etc/GMT* entries.
      if (!location.name.startsWith('Etc/')) {
        tz.setLocalLocation(location);
        return;
      }
    }

    if (fallback != null) {
      tz.setLocalLocation(fallback);
    }
  }
}
