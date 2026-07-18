import 'package:flutter/foundation.dart';

import '../models/reminder_settings.dart';
import '../repositories/hydration_repository.dart';
import '../services/notification_action_handler.dart';
import '../services/notification_service.dart';
import '../utils/app_refresh_bridge.dart';
import '../utils/constants.dart';

/// ChangeNotifier that owns reminder settings and notification scheduling.
///
/// UI screens listen via [ListenableBuilder]; background actions call into
/// [NotificationActionHandler], which updates Hive and then notifies this
/// provider when a refresh callback is registered.
class ReminderProvider extends ChangeNotifier {
  /// Creates a provider backed by [repository] and [notifications].
  ReminderProvider({
    HydrationRepository? repository,
    NotificationService? notifications,
  })  : _repository = repository ?? HydrationRepository(),
        _notifications = notifications ?? NotificationService();

  final HydrationRepository _repository;
  final NotificationService _notifications;

  ReminderSettings _settings = ReminderSettings.defaults();

  /// Whether the snooze duration sheet should be presented.
  bool _pendingSnoozePicker = false;

  /// Whether the full-screen reminder should be presented.
  bool _pendingFullScreenReminder = false;

  /// Current reminder preferences.
  ReminderSettings get settings => _settings;

  /// True when a "Remind Later" action requested the snooze UI.
  bool get pendingSnoozePicker => _pendingSnoozePicker;

  /// True when a full-screen intent / notification tap requested the alarm UI.
  bool get pendingFullScreenReminder => _pendingFullScreenReminder;

  /// Loads settings from Hive and wires notification action callbacks.
  ///
  /// Set [scheduleReminders] to false when the caller will request permission
  /// first, then call [restoreSchedules] afterward.
  Future<void> init({bool scheduleReminders = true}) async {
    _settings = _repository.loadReminderSettings();

    NotificationActionHandler.onRequestSnoozePicker = requestSnoozePicker;
    NotificationActionHandler.onRequestFullScreenReminder =
        requestFullScreenReminder;
    NotificationActionHandler.onIntakeChanged = () {
      refreshFromStorage();
      AppRefreshBridge.notify();
    };

    await _notifications.init(
      onAction: NotificationActionHandler.handleForeground,
      onBackgroundAction: notificationTapBackground,
    );

    try {
      final launch = await _notifications.getLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final response = launch!.notificationResponse;
        if (response != null) {
          await NotificationActionHandler.handle(response);
        }
      }
    } catch (_) {
      // Plugin unavailable in widget/unit tests.
    }

    if (scheduleReminders) {
      try {
        await restoreSchedules();
      } catch (_) {
        // Scheduling unavailable in widget/unit tests.
      }
    }
    notifyListeners();
  }

  /// Reloads settings from Hive without rescheduling.
  void refreshFromStorage() {
    _settings = _repository.loadReminderSettings();
    notifyListeners();
  }

  /// Marks that the snooze picker should be shown, then notifies listeners.
  void requestSnoozePicker() {
    _pendingSnoozePicker = true;
    notifyListeners();
  }

  /// Clears the pending snooze-picker flag after the UI has handled it.
  void clearSnoozePickerRequest() {
    if (!_pendingSnoozePicker) return;
    _pendingSnoozePicker = false;
    notifyListeners();
  }

  /// Marks that the full-screen reminder should be shown.
  void requestFullScreenReminder() {
    _pendingFullScreenReminder = true;
    notifyListeners();
  }

  /// Clears the pending full-screen flag after the UI has handled it.
  void clearFullScreenReminderRequest() {
    if (!_pendingFullScreenReminder) return;
    _pendingFullScreenReminder = false;
    notifyListeners();
  }

  /// Persists [updated] settings and immediately reschedules notifications.
  Future<void> updateSettings(ReminderSettings updated) async {
    _settings = updated;
    await _repository.saveReminderSettings(updated);
    await restoreSchedules();
    notifyListeners();
  }

  /// Convenience: toggle reminders on/off.
  Future<void> setEnabled(bool enabled) =>
      updateSettings(_settings.copyWith(enabled: enabled));

  /// Convenience: set interval (preset or custom minutes).
  Future<void> setIntervalMinutes(int minutes) =>
      updateSettings(_settings.copyWith(intervalMinutes: minutes));

  /// Restores schedules from current Hive intake + settings (restart / reboot).
  Future<void> restoreSchedules() async {
    final settings = _repository.loadReminderSettings();
    final consumed = _repository.loadTodayIntake();
    final goal = _repository.loadDailyGoalMl();
    final lastIntake = _repository.loadLastIntakeTimestamp();
    final goalMet = consumed >= goal;

    await _notifications.reschedule(
      settings,
      consumedMl: consumed,
      goalMl: goal,
      lastIntakeAt: lastIntake,
      goalAlreadyMet: goalMet && settings.stopAfterGoalCompleted,
    );
  }

  /// Called whenever water is logged from the UI so reminders stay in sync.
  Future<void> onWaterLogged() async {
    await restoreSchedules();
    notifyListeners();
  }

  /// Handles "Drank Water" from a notification action (or full-screen UI).
  Future<void> handleDrankWater() async {
    await NotificationActionHandler.onDrankWater();
    refreshFromStorage();
    AppRefreshBridge.notify();
    // onDrankWater already reschedules; refresh listeners only.
    notifyListeners();
  }

  /// Schedules a snooze for [delayMinutes] without adding intake.
  Future<void> snoozeFor(int delayMinutes) async {
    await NotificationActionHandler.onSnooze(delayMinutes);
    clearSnoozePickerRequest();
  }

  /// Validates and saves a custom interval in minutes.
  Future<String?> setCustomIntervalMinutes(int minutes) async {
    if (minutes < AppConstants.minCustomIntervalMinutes) {
      return 'Minimum interval is ${AppConstants.minCustomIntervalMinutes} minutes';
    }
    if (minutes > AppConstants.maxCustomIntervalMinutes) {
      return 'Maximum interval is ${AppConstants.maxCustomIntervalMinutes} minutes';
    }
    await setIntervalMinutes(minutes);
    return null;
  }
}
