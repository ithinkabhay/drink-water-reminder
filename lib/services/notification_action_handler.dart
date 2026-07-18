import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../repositories/hydration_repository.dart';
import '../services/notification_service.dart';
import '../services/ringtone_picker_service.dart';
import '../services/storage_service.dart';
import '../utils/app_refresh_bridge.dart';
import '../utils/constants.dart';

/// Handles notification taps and action buttons for the hydration assistant.
///
/// Safe to call from the UI isolate and from the background notification
/// isolate (after Hive has been initialized).
class NotificationActionHandler {
  /// Private constructor — static API only.
  const NotificationActionHandler._();

  /// Optional UI hook: request showing the snooze duration picker.
  static void Function()? onRequestSnoozePicker;

  /// Optional UI hook: request the alarm-style full-screen reminder.
  static void Function()? onRequestFullScreenReminder;

  /// Optional UI hook: refresh home stats after a background "Drank Water".
  static void Function()? onIntakeChanged;

  /// Guards against double-handling the same launch response.
  static String? _lastHandledKey;
  static DateTime? _lastHandledAt;

  /// Dispatches [response] to the appropriate action.
  static Future<void> handle(NotificationResponse response) async {
    final actionId = response.actionId;
    final payload = response.payload;
    final key =
        '${response.id}|$actionId|$payload|${response.notificationResponseType}';

    // Deduplicate cold-start + foreground double delivery (short window).
    final now = DateTime.now();
    if (_lastHandledKey == key &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastHandledKey = key;
    _lastHandledAt = now;

    if (actionId == AppConstants.actionDrankWater) {
      await RingtonePickerService.stopPreview();
      await onDrankWater(notificationId: response.id);
      return;
    }

    if (actionId == AppConstants.actionRemindLater ||
        payload == AppConstants.payloadSnooze) {
      await RingtonePickerService.stopPreview();
      onRequestSnoozePicker?.call();
      return;
    }

    // Body tap or full-screen intent (plugin treats FSI like a tap).
    final isSelected = response.notificationResponseType ==
        NotificationResponseType.selectedNotification;
    if (isSelected &&
        (payload == null ||
            payload == AppConstants.payloadReminder ||
            payload.isEmpty)) {
      onRequestFullScreenReminder?.call();
    }
  }

  /// Adds the default quick-add amount, persists via Hive, and reschedules.
  ///
  /// Works whether the app is open, backgrounded, or terminated.
  static Future<void> onDrankWater({int? notificationId}) async {
    await ensureStorageReady();

    final repository = HydrationRepository();
    final settings = repository.loadReminderSettings();
    final amount = settings.defaultQuickAddMl.clamp(
      AppConstants.minCustomAmountMl,
      AppConstants.maxCustomAmountMl,
    );

    final total = await repository.addIntake(amount);
    final goal = repository.loadDailyGoalMl();
    final lastIntake = repository.loadLastIntakeTimestamp();
    final goalMet = total >= goal;

    final notifications = NotificationService();
    await notifications.init(
      onAction: handleForeground,
      onBackgroundAction: notificationTapBackground,
    );

    // Dismiss the tapped notification (or clear all if id unknown).
    if (notificationId != null) {
      await notifications.cancel(notificationId);
    } else {
      await notifications.cancelAll();
    }

    await notifications.reschedule(
      settings,
      consumedMl: total,
      goalMl: goal,
      lastIntakeAt: lastIntake,
      goalAlreadyMet: goalMet && settings.stopAfterGoalCompleted,
    );

    onIntakeChanged?.call();
    AppRefreshBridge.notify();
  }

  /// Schedules a snooze reminder for [delayMinutes] without adding intake.
  ///
  /// Also reschedules interval reminders to start after the snooze fires so
  /// the user does not get a duplicate alert from the next slot.
  static Future<void> onSnooze(int delayMinutes) async {
    await ensureStorageReady();

    final repository = HydrationRepository();
    final settings = repository.loadReminderSettings();
    final consumed = repository.loadTodayIntake();
    final goal = repository.loadDailyGoalMl();
    final lastIntake = repository.loadLastIntakeTimestamp();
    final goalMet = consumed >= goal;
    final snoozeUntil = DateTime.now().add(Duration(minutes: delayMinutes));

    final notifications = NotificationService();
    await notifications.init(
      onAction: handleForeground,
      onBackgroundAction: notificationTapBackground,
    );
    await notifications.reschedule(
      settings,
      consumedMl: consumed,
      goalMl: goal,
      lastIntakeAt: lastIntake,
      goalAlreadyMet: goalMet && settings.stopAfterGoalCompleted,
      forceSkipUntil: snoozeUntil,
    );
    await notifications.scheduleSnooze(
      settings: settings,
      delayMinutes: delayMinutes,
      consumedMl: consumed,
      goalMl: goal,
    );
  }

  /// Ensures Flutter bindings + Hive are ready (background isolate safe).
  static Future<void> ensureStorageReady() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      if (!Hive.isBoxOpen(AppConstants.hiveBoxName)) {
        await Hive.initFlutter();
        await StorageService.init();
      }
    } catch (_) {
      await Hive.initFlutter();
      await StorageService.init();
    }
  }

  /// Foreground / opened-app action entry used by [NotificationService.init].
  static void handleForeground(NotificationResponse response) {
    // Keep the isolate alive until async work finishes.
    handle(response).catchError((Object error, StackTrace stack) {
      debugPrint('Notification action failed: $error\n$stack');
    });
  }
}

/// Background isolate entry point required by flutter_local_notifications.
///
/// Must be top-level and annotated so the VM keeps the entry point for
/// background action callbacks when the app is terminated or backgrounded.
@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  await NotificationActionHandler.handle(response);
}
