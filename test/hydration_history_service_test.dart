import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:drink_water_reminder/models/daily_intake.dart';
import 'package:drink_water_reminder/models/hydration_stats.dart';
import 'package:drink_water_reminder/repositories/hydration_repository.dart';
import 'package:drink_water_reminder/services/hydration_history_service.dart';
import 'package:drink_water_reminder/services/storage_service.dart';
import 'package:drink_water_reminder/utils/constants.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('hive_history_');
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

  setUp(() async {
    await Hive.box(AppConstants.hiveBoxName).clear();
  });

  test('saves daily history and computes weekly stats', () async {
    final repository = HydrationRepository();
    final historyService = HydrationHistoryService(repository: repository);

    await repository.saveTodayIntake(750);

    final history = repository.loadHistoryMap();
    final todayKey = DailyIntake.toDateKey(DateTime.now());
    expect(history[todayKey], 750);

    final week = historyService.loadStats(HistoryPeriod.week);
    expect(week.entries.length, 7);
    expect(week.totalMl, 750);
    expect(week.averageMl, (750 / 7).round());
    expect(week.entries.last.consumedMl, 750);
  });

  test('computes longest streak from history', () async {
    final box = Hive.box(AppConstants.hiveBoxName);
    final today = DateTime.now();
    final history = <String, int>{
      DailyIntake.toDateKey(today.subtract(const Duration(days: 4))): 500,
      DailyIntake.toDateKey(today.subtract(const Duration(days: 3))): 1000,
      DailyIntake.toDateKey(today.subtract(const Duration(days: 2))): 800,
      DailyIntake.toDateKey(today.subtract(const Duration(days: 1))): 0,
      DailyIntake.toDateKey(today): 250,
    };
    await box.put(AppConstants.keyDailyHistory, jsonEncode(history));

    final stats = HydrationHistoryService().loadStats(HistoryPeriod.month);
    expect(stats.longestStreak, 3);
    expect(stats.totalMl, greaterThan(0));
  });

  test('monthly stats include thirty days', () async {
    final stats = HydrationHistoryService().loadStats(HistoryPeriod.month);
    expect(stats.entries.length, 30);
    expect(stats.totalMl, 0);
    expect(stats.averageMl, 0);
  });
}
