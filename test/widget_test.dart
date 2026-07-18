import 'package:flutter_test/flutter_test.dart';

import 'package:drink_water_reminder/models/reminder_settings.dart';
import 'package:drink_water_reminder/services/notification_message_builder.dart';
import 'package:drink_water_reminder/utils/constants.dart';

void main() {
  group('ReminderSettings', () {
    test('defaults enable smart assistant options', () {
      final settings = ReminderSettings.defaults();
      expect(settings.enabled, isTrue);
      expect(settings.intervalMinutes, 60);
      expect(settings.soundEnabled, isTrue);
      expect(settings.vibrationEnabled, isTrue);
      expect(settings.defaultQuickAddMl, 250);
      expect(settings.stopAfterGoalCompleted, isTrue);
      expect(settings.skipIfRecentlyLogged, isTrue);
      expect(settings.isCustomInterval, isFalse);
    });

    test('detects custom intervals outside presets', () {
      final settings = ReminderSettings.defaults().copyWith(
        intervalMinutes: 33,
      );
      expect(settings.isCustomInterval, isTrue);
    });
  });

  group('NotificationMessageBuilder', () {
    test('uses progress-aware copy', () {
      expect(
        NotificationMessageBuilder.build(consumedMl: 0, goalMl: 2000).title,
        contains('Time to Drink Water'),
      );
      expect(
        NotificationMessageBuilder.build(consumedMl: 1000, goalMl: 2000).title,
        contains('halfway'),
      );
      expect(
        NotificationMessageBuilder.build(consumedMl: 1600, goalMl: 2000).title,
        contains('400 ml left'),
      );
      expect(
        NotificationMessageBuilder.build(consumedMl: 2000, goalMl: 2000).title,
        contains('Great job'),
      );
    });
  });

  group('AppConstants intervals', () {
    test('exposes presets and custom bounds', () {
      expect(AppConstants.reminderIntervalPresetsMinutes, containsAll([15, 60, 180]));
      expect(AppConstants.minCustomIntervalMinutes, 10);
      expect(AppConstants.maxCustomIntervalMinutes, 360);
      expect(AppConstants.snoozeOptionsMinutes, [10, 15, 30]);
      expect(AppConstants.intervalLabel(90), 'Every 1h 30m');
      expect(AppConstants.intervalLabel(120), 'Every 2 hours');
    });
  });
}
