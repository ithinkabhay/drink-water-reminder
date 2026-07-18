import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
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
  await notifications.init();
  await notifications.requestPermission();

  final storage = StorageService();
  await notifications.reschedule(storage.loadReminderSettings());

  runApp(const DrinkWaterApp());
}
