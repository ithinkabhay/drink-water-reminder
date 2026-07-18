import 'package:flutter/material.dart';

import 'providers/reminder_provider.dart';
import 'repositories/hydration_repository.dart';
import 'screens/full_screen_reminder_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'widgets/snooze_duration_sheet.dart';

/// Root widget that configures [MaterialApp] for the Drink Water Reminder.
class DrinkWaterApp extends StatefulWidget {
  /// Creates the root application widget.
  const DrinkWaterApp({
    super.key,
    required this.reminderProvider,
  });

  /// Shared reminder settings + notification coordinator.
  final ReminderProvider reminderProvider;

  @override
  State<DrinkWaterApp> createState() => _DrinkWaterAppState();
}

class _DrinkWaterAppState extends State<DrinkWaterApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _showingSnooze = false;
  bool _showingFullScreen = false;

  @override
  void initState() {
    super.initState();
    widget.reminderProvider.addListener(_onReminderChanged);
    // Cold-start actions set pending flags before runApp, so the listener
    // alone would miss them — check once after the first frame.
    // Also restore schedules here so the 10s ringtone MethodChannel is live.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await widget.reminderProvider.restoreSchedules();
      } catch (_) {}
      _drainPendingUi();
    });
  }

  @override
  void dispose() {
    widget.reminderProvider.removeListener(_onReminderChanged);
    super.dispose();
  }

  void _onReminderChanged() {
    _drainPendingUi();
  }

  void _drainPendingUi() {
    if (widget.reminderProvider.pendingFullScreenReminder) {
      _presentFullScreenReminder();
    }
    if (widget.reminderProvider.pendingSnoozePicker) {
      _presentSnoozePicker();
    }
  }

  Future<void> _presentFullScreenReminder() async {
    if (_showingFullScreen) return;
    final nav = _navigatorKey.currentState;
    if (nav == null) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.reminderProvider.pendingFullScreenReminder) {
          return;
        }
        final retryNav = _navigatorKey.currentState;
        if (retryNav == null) {
          widget.reminderProvider.clearFullScreenReminderRequest();
          return;
        }
        _presentFullScreenReminder();
      });
      return;
    }

    _showingFullScreen = true;
    widget.reminderProvider.clearFullScreenReminderRequest();

    await nav.push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FullScreenReminderScreen(
          onDrankWater: widget.reminderProvider.handleDrankWater,
          onRemindLater: widget.reminderProvider.requestSnoozePicker,
        ),
      ),
    );

    _showingFullScreen = false;
  }

  Future<void> _presentSnoozePicker() async {
    if (_showingSnooze) return;
    final nav = _navigatorKey.currentState;
    if (nav == null) {
      if (!mounted) return;
      // Single deferred retry — avoid infinite post-frame loops in tests.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.reminderProvider.pendingSnoozePicker) return;
        final retryNav = _navigatorKey.currentState;
        if (retryNav == null) {
          widget.reminderProvider.clearSnoozePickerRequest();
          return;
        }
        _presentSnoozePicker();
      });
      return;
    }

    _showingSnooze = true;
    widget.reminderProvider.clearSnoozePickerRequest();

    final minutes = await SnoozeDurationSheet.show(nav.context);
    _showingSnooze = false;

    if (minutes != null) {
      await widget.reminderProvider.snoozeFor(minutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingComplete = HydrationRepository().isOnboardingComplete();

    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: onboardingComplete
          ? HomeScreen(reminderProvider: widget.reminderProvider)
          : OnboardingScreen(reminderProvider: widget.reminderProvider),
    );
  }
}
