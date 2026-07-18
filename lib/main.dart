import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'services/storage_service.dart';

/// Application entry point.
///
/// Initializes Flutter bindings and Hive before launching the UI so
/// persistent storage is ready on the first frame.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await StorageService.init();

  runApp(const DrinkWaterApp());
}
