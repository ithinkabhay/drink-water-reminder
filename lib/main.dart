import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/reminder_provider.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

/// Application entry point.
///
/// Initializes Flutter bindings, Hive, and local notifications before
/// launching the UI so storage and reminders are ready on the first frame.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await StorageService.init();

  final notifications = NotificationService();
  final reminderProvider = ReminderProvider(notifications: notifications);
  // Wire notifications first, then ask for permission. Full schedule (including
  // the 10s ringtone alarms) runs after the first frame when the platform
  // channel is attached — see [DrinkWaterApp].
  await reminderProvider.init(scheduleReminders: false);
  await notifications.requestPermission();

  runApp(DrinkWaterApp(reminderProvider: reminderProvider));
}
