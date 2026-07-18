import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:drink_water_reminder/app.dart';
import 'package:drink_water_reminder/services/storage_service.dart';
import 'package:drink_water_reminder/utils/constants.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await Hive.box(AppConstants.hiveBoxName).clear();
  });

  testWidgets('Home screen shows goal and drink button', (WidgetTester tester) async {
    await tester.pumpWidget(const DrinkWaterApp());

    expect(find.text('Drink Water Reminder'), findsOneWidget);
    expect(find.text("Today's Goal"), findsOneWidget);
    expect(find.text('0 / 3000 ml'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Drink 250 ml'), findsOneWidget);
  });

  testWidgets('Drink button persists intake across rebuilds', (WidgetTester tester) async {
    await tester.pumpWidget(const DrinkWaterApp());
    await tester.tap(find.text('Drink 250 ml'));
    await tester.pumpAndSettle();

    expect(find.text('250 / 3000 ml'), findsOneWidget);

    // Simulate a fresh app start by rebuilding with the same Hive box.
    await tester.pumpWidget(const DrinkWaterApp());
    await tester.pumpAndSettle();

    expect(find.text('250 / 3000 ml'), findsOneWidget);
  });
}
