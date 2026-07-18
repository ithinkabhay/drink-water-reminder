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

  test('persists and loads daily goal', () async {
    final repository = HydrationRepository();

    expect(repository.loadDailyGoalMl(), AppConstants.defaultDailyGoalMl);

    await repository.saveDailyGoalMl(3500);
    expect(repository.loadDailyGoalMl(), 3500);

    await repository.saveDailyGoalMl(100);
    expect(repository.loadDailyGoalMl(), AppConstants.minDailyGoalMl);

    await repository.saveDailyGoalMl(50000);
    expect(repository.loadDailyGoalMl(), AppConstants.maxDailyGoalMl);
  });

  test('adds intake entries and supports undo', () async {
    final repository = HydrationRepository();

    expect(repository.loadTodayEntries(), isEmpty);

    final afterFirst = await repository.addIntake(250);
    expect(afterFirst, 250);
    expect(repository.loadTodayIntake(), 250);
    expect(repository.loadTodayEntries(), hasLength(1));
    expect(repository.loadTodayEntries().single.amountMl, 250);

    final afterSecond = await repository.addIntake(100);
    expect(afterSecond, 350);
    expect(repository.loadTodayEntries(), hasLength(2));

    final undone = await repository.undoLastIntake();
    expect(undone, isNotNull);
    expect(undone!.removed.amountMl, 100);
    expect(undone.newTotal, 250);
    expect(repository.loadTodayIntake(), 250);
    expect(repository.loadTodayEntries(), hasLength(1));
  });
}
