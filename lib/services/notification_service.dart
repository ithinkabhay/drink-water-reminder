import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_settings.dart';
import '../utils/constants.dart';
import 'notification_message_builder.dart';
import 'ringtone_picker_service.dart';

/// Callback invoked when a notification action is selected (foreground or
/// background isolate). Must remain a top-level / static entry point.
typedef NotificationActionCallback = void Function(
  NotificationResponse response,
);

/// Schedules and manages smart hydration reminder notifications.
///
/// Supports high-priority alerts, a custom bundled sound, repeating vibration,
/// full-screen intents, action buttons, snooze, and goal-aware scheduling.
class NotificationService {
  /// Creates a notification service. Optionally inject a shared plugin.
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Shared plugin instance used for all notification operations.
  final FlutterLocalNotificationsPlugin _plugin;

  /// Serializes [reschedule] across all service instances (UI + background).
  static Future<void> _rescheduleGate = Future<void>.value();

  /// Whether [initialize] has been attempted in this isolate (shared).
  static bool _platformInitialized = false;

  /// Whether initialize completed against a real platform channel (shared).
  ///
  /// Shared so action handlers that construct a new [NotificationService]
  /// can still cancel / reschedule without re-calling [initialize].
  static bool _platformReady = false;

  /// Cached Android schedule mode (exact when permitted, else inexact).
  AndroidScheduleMode? _androidScheduleMode;

  /// Whether the current platform supports local notifications.
  bool get _isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  /// True when plugin calls are safe (not a headless test binding).
  bool get _canUsePlugin {
    if (!_isSupported || !_platformReady) return false;
    if (_isFlutterTest) return false;
    try {
      final bindingName = WidgetsBinding.instance.runtimeType.toString();
      if (bindingName.contains('TestWidgetsFlutterBinding') ||
          bindingName.contains('AutomatedTestWidgetsFlutterBinding')) {
        return false;
      }
    } catch (_) {
      return false;
    }
    return true;
  }

  /// Detects `flutter test` via the binding type (avoids dart:io on web).
  static bool get _isFlutterTest {
    try {
      final bindingName = WidgetsBinding.instance.runtimeType.toString();
      return bindingName.contains('TestWidgetsFlutterBinding') ||
          bindingName.contains('AutomatedTestWidgetsFlutterBinding');
    } catch (_) {
      return false;
    }
  }

  /// Initializes the plugin, timezone database, and action categories.
  ///
  /// Safe to call on unsupported platforms (no-op) and in tests (errors
  /// are swallowed so widget tests can still run). Safe to call repeatedly —
  /// only the first successful call registers platform callbacks.
  Future<void> init({
    NotificationActionCallback? onAction,
    NotificationActionCallback? onBackgroundAction,
  }) async {
    _configureLocalTimeZone();

    if (!_isSupported) {
      _platformInitialized = true;
      return;
    }

    if (_platformInitialized) return;

    // Avoid platform-channel hangs under widget/unit test bindings.
    try {
      final bindingName = WidgetsBinding.instance.runtimeType.toString();
      if (bindingName.contains('TestWidgetsFlutterBinding') ||
          bindingName.contains('AutomatedTestWidgetsFlutterBinding')) {
        _platformInitialized = true;
        _platformReady = false;
        return;
      }
    } catch (_) {
      _platformInitialized = true;
      _platformReady = false;
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          AppConstants.darwinReminderCategoryId,
          actions: [
            DarwinNotificationAction.plain(
              AppConstants.actionDrankWater,
              '✅ Drank Water',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              AppConstants.actionRemindLater,
              '⏰ Remind Later',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ],
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: onAction,
        onDidReceiveBackgroundNotificationResponse: onBackgroundAction,
      );
      _platformInitialized = true;
      _platformReady = true;
    } catch (_) {
      // Plugin channels are unavailable in pure unit/widget tests.
      _platformInitialized = true;
      _platformReady = false;
    }
  }

  /// Creates the high-importance Android channel for the current settings.
  ///
  /// Sound is intentionally off on the channel: Android only plays channel
  /// sounds once (~1s). A companion AlarmManager player loops the ringtone
  /// for [AppConstants.notificationAlertDurationMs] instead.
  Future<void> ensureAndroidChannel(ReminderSettings settings) async {
    if (!_canUsePlugin) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final pattern = settings.vibrationEnabled ? _vibrationPattern : null;
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          channelIdFor(settings),
          AppConstants.notificationChannelName,
          description: AppConstants.notificationChannelDescription,
          importance: Importance.max,
          playSound: false,
          enableVibration: settings.vibrationEnabled,
          vibrationPattern: pattern,
          audioAttributesUsage: AudioAttributesUsage.notification,
        ),
      );
    } catch (_) {}
  }

  /// Dynamic channel id so vibration changes take effect on Android.
  static String channelIdFor(ReminderSettings settings) {
    final vibe = settings.vibrationEnabled ? 'vibe' : 'novibe';
    // v6 = silent channel + companion 10s ringtone player
    return '${AppConstants.notificationChannelIdPrefix}_silent_$vibe';
  }

  static Int64List get _vibrationPattern => Int64List.fromList(const [
        0,
        500,
        200,
        500,
        200,
        500,
        200,
        500,
        200,
        500,
        200,
        500,
        200,
        500,
        200,
        500,
        200,
        500,
        200,
        500,
      ]);

  /// Requests notification, exact-alarm, and full-screen-intent permissions.
  Future<bool> requestPermission() async {
    if (!_canUsePlugin) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.requestNotificationsPermission();
        await android?.requestExactAlarmsPermission();
        await android?.requestFullScreenIntentPermission();
        _androidScheduleMode = null; // refresh on next schedule
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

  /// Returns the notification that launched the app, if any.
  Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    if (!_canUsePlugin) return null;
    try {
      return await _plugin.getNotificationAppLaunchDetails();
    } catch (_) {
      return null;
    }
  }

  /// Cancels every pending and displayed notification.
  Future<void> cancelAll() async {
    if (!_canUsePlugin) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
    await RingtonePickerService.cancelAllAlertSounds();
  }

  /// Cancels a single notification by [id].
  Future<void> cancel(int id) async {
    if (!_canUsePlugin) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  /// Cancels pending reminders and schedules new ones from [settings].
  ///
  /// When reminders are disabled, all pending notifications are cleared.
  /// When [goalAlreadyMet] is true and stop-after-goal is enabled, today is
  /// skipped and reminders resume from tomorrow's window.
  ///
  /// [forceSkipUntil] suppresses interval slots before that instant (used for
  /// snooze so interval alarms do not fire alongside the snooze).
  Future<void> reschedule(
    ReminderSettings settings, {
    int consumedMl = 0,
    int goalMl = AppConstants.defaultDailyGoalMl,
    DateTime? lastIntakeAt,
    bool goalAlreadyMet = false,
    DateTime? forceSkipUntil,
  }) {
    // Serialize across UI + background NotificationService instances.
    final previous = _rescheduleGate;
    final done = Completer<void>();
    _rescheduleGate = done.future;

    return previous.catchError((_) {}).then((_) async {
      try {
        await _rescheduleUnlocked(
          settings,
          consumedMl: consumedMl,
          goalMl: goalMl,
          lastIntakeAt: lastIntakeAt,
          goalAlreadyMet: goalAlreadyMet,
          forceSkipUntil: forceSkipUntil,
        );
      } finally {
        done.complete();
      }
    });
  }

  Future<void> _rescheduleUnlocked(
    ReminderSettings settings, {
    required int consumedMl,
    required int goalMl,
    required DateTime? lastIntakeAt,
    required bool goalAlreadyMet,
    required DateTime? forceSkipUntil,
  }) async {
    if (!_canUsePlugin) return;

    try {
      await _plugin.cancelAll();
      await RingtonePickerService.cancelAllAlertSounds();

      if (!settings.enabled) return;

      await ensureAndroidChannel(settings);

      // Stop today's reminders once the goal is met; resume tomorrow.
      final skipToday = goalAlreadyMet && settings.stopAfterGoalCompleted;

      await _scheduleWindow(
        settings,
        consumedMl: consumedMl,
        goalMl: goalMl,
        lastIntakeAt: lastIntakeAt,
        skipToday: skipToday,
        forceSkipUntil: forceSkipUntil,
      );
    } catch (error, stack) {
      debugPrint('Reminder reschedule failed: $error\n$stack');
    }
  }

  /// Schedules a one-off snooze reminder after [delayMinutes].
  ///
  /// Does not cancel interval reminders — callers should [reschedule] with
  /// [forceSkipUntil] set to the snooze fire time first.
  Future<void> scheduleSnooze({
    required ReminderSettings settings,
    required int delayMinutes,
    required int consumedMl,
    required int goalMl,
  }) async {
    if (!_canUsePlugin || !settings.enabled) return;

    // Honor stop-after-goal: do not snooze if today's goal is already met.
    if (settings.stopAfterGoalCompleted && consumedMl >= goalMl) return;

    await ensureAndroidChannel(settings);

    final when = tz.TZDateTime.now(tz.local).add(
      Duration(minutes: delayMinutes),
    );
    final message = NotificationMessageBuilder.build(
      consumedMl: consumedMl,
      goalMl: goalMl,
    );

    try {
      await _plugin.cancel(id: AppConstants.snoozeNotificationId);
      await _plugin.zonedSchedule(
        id: AppConstants.snoozeNotificationId,
        title: message.title,
        body: message.body,
        scheduledDate: when,
        notificationDetails: _notificationDetails(settings),
        androidScheduleMode: await _resolveAndroidScheduleMode(),
        payload: AppConstants.payloadReminder,
      );
      await _scheduleCompanionSound(
        settings: settings,
        notificationId: AppConstants.snoozeNotificationId,
        when: when,
      );
    } catch (error, stack) {
      debugPrint('Snooze schedule failed: $error\n$stack');
    }
  }

  /// Schedules reminders for the next [AppConstants.scheduleDaysAhead] days,
  /// capped at [AppConstants.maxPendingReminders] slots.
  ///
  /// After a water log (with skip-if-recent enabled), the next alert is
  /// [lastIntakeAt] + [ReminderSettings.intervalMinutes], then every interval
  /// inside the active window.
  Future<void> _scheduleWindow(
    ReminderSettings settings, {
    required int consumedMl,
    required int goalMl,
    required DateTime? lastIntakeAt,
    required bool skipToday,
    DateTime? forceSkipUntil,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var notificationId = 0;
    final scheduleMode = await _resolveAndroidScheduleMode();

    DateTime? anchor;
    if (settings.skipIfRecentlyLogged && lastIntakeAt != null) {
      anchor = lastIntakeAt.add(
        Duration(minutes: settings.intervalMinutes),
      );
    }
    if (forceSkipUntil != null) {
      if (anchor == null || forceSkipUntil.isAfter(anchor)) {
        anchor = forceSkipUntil;
      }
    }

    final message = NotificationMessageBuilder.build(
      consumedMl: consumedMl,
      goalMl: goalMl,
    );

    for (var dayOffset = 0;
        dayOffset < AppConstants.scheduleDaysAhead;
        dayOffset++) {
      if (skipToday && dayOffset == 0) continue;

      final day = now.add(Duration(days: dayOffset));
      final start = tz.TZDateTime(
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

      // Overnight windows (end before start) are invalid — skip the day.
      if (end.isBefore(start)) continue;

      late tz.TZDateTime slot;
      if (anchor != null) {
        final anchorTz = tz.TZDateTime.from(anchor, tz.local);
        if (anchorTz.isAfter(end)) continue;
        slot = anchorTz.isBefore(start) ? start : anchorTz;
      } else {
        slot = start;
      }

      // Day-0 contextual copy; later days use a fresh baseline message.
      final dayMessage = dayOffset == 0
          ? message
          : NotificationMessageBuilder.build(consumedMl: 0, goalMl: goalMl);

      while (!slot.isAfter(end)) {
        if (notificationId >= AppConstants.maxPendingReminders) return;

        final afterNow = slot.isAfter(now);
        final afterAnchor = anchor == null ||
            !slot.isBefore(tz.TZDateTime.from(anchor, tz.local));

        if (afterNow && afterAnchor) {
          try {
            await _plugin.zonedSchedule(
              id: notificationId,
              title: dayMessage.title,
              body: dayMessage.body,
              scheduledDate: slot,
              notificationDetails: _notificationDetails(settings),
              androidScheduleMode: scheduleMode,
              payload: AppConstants.payloadReminder,
            );
            await _scheduleCompanionSound(
              settings: settings,
              notificationId: notificationId,
              when: slot,
            );
            notificationId++;
          } catch (error, stack) {
            debugPrint(
              'Failed to schedule reminder #$notificationId: $error\n$stack',
            );
            // Stop further scheduling if Android alarm quota is exhausted.
            return;
          }
        }

        slot = slot.add(Duration(minutes: settings.intervalMinutes));
      }
    }
  }

  /// Schedules a looping ringtone for ~10s at the same instant as a reminder.
  Future<void> _scheduleCompanionSound({
    required ReminderSettings settings,
    required int notificationId,
    required DateTime when,
  }) async {
    if (!settings.soundEnabled) return;

    final custom = settings.customRingtoneUri;
    final uri = (custom != null && custom.isNotEmpty)
        ? custom
        : await RingtonePickerService.builtinSoundUri();
    if (uri == null || uri.isEmpty) return;

    await RingtonePickerService.scheduleAlertSound(
      triggerAt: when,
      uri: uri,
      notificationId: notificationId,
      durationMs: AppConstants.notificationAlertDurationMs,
    );
  }

  /// Picks exact alarms when permitted; otherwise inexact while-idle.
  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    if (_androidScheduleMode != null) return _androidScheduleMode!;

    var mode = AndroidScheduleMode.exactAllowWhileIdle;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final canExact = await android?.canScheduleExactNotifications();
        if (canExact == false) {
          mode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      } catch (_) {
        mode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }
    _androidScheduleMode = mode;
    return mode;
  }

  /// Max-importance notification; sound comes from the 10s companion player.
  NotificationDetails _notificationDetails(ReminderSettings settings) {
    final channelId = channelIdFor(settings);

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.reminder,
        icon: '@mipmap/ic_launcher',
        // Channel sound is a one-shot beep — real audio is the companion player.
        playSound: false,
        enableVibration: settings.vibrationEnabled,
        vibrationPattern: settings.vibrationEnabled ? _vibrationPattern : null,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        timeoutAfter: AppConstants.notificationAlertDurationMs,
        audioAttributesUsage: AudioAttributesUsage.notification,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            AppConstants.actionDrankWater,
            '✅ Drank Water',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            AppConstants.actionRemindLater,
            '⏰ Remind Later',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: settings.soundEnabled,
        categoryIdentifier: AppConstants.darwinReminderCategoryId,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: settings.soundEnabled,
        categoryIdentifier: AppConstants.darwinReminderCategoryId,
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
