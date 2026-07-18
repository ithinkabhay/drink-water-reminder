import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:drink_water_reminder/app.dart';
import 'package:drink_water_reminder/services/storage_service.dart';
import 'package:drink_water_reminder/utils/constants.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('hive_widget_');
    Hive.init(tempDir.path);
    await StorageService.init();
  });

  tearDownAll(() async {
    try {
      await Hive.close().timeout(const Duration(seconds: 2));
    } catch (_) {}
    if (tempDir.existsSync()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  testWidgets('Home screen shows goal and drink button', (WidgetTester tester) async {
    await tester.pumpWidget(const DrinkWaterApp());
    await tester.pump();

    expect(find.text(AppConstants.appTitle), findsOneWidget);
    expect(find.text(AppConstants.todaysGoalLabel), findsOneWidget);
    expect(find.textContaining(' / 3000 ml'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text(AppConstants.drinkButtonLabel), findsOneWidget);
    expect(find.text("Today's streak"), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('3000 ml'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('History screen opens from home', (WidgetTester tester) async {
    await tester.pumpWidget(const DrinkWaterApp());
    await tester.pump();

    await tester.tap(find.byTooltip('History'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Hydration History'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Total intake'), findsOneWidget);
    expect(find.text('Average'), findsOneWidget);
    expect(find.text('Longest streak'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
