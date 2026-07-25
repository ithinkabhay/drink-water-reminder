import 'package:flutter/material.dart';

import 'providers/reminder_provider.dart';
import 'providers/theme_provider.dart';
import 'repositories/hydration_repository.dart';
import 'screens/full_screen_reminder_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'widgets/snooze_duration_sheet.dart';

/// Root widget that configures [MaterialApp] for Waterly.
class DrinkWaterApp extends StatefulWidget {
  /// Creates the root application widget.
  const DrinkWaterApp({
    super.key,
    required this.reminderProvider,
    required this.themeProvider,
  });

  /// Shared reminder settings + notification coordinator.
  final ReminderProvider reminderProvider;

  /// Theme preference controller.
  final ThemeProvider themeProvider;

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
    widget.themeProvider.addListener(_onThemeChanged);
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
    widget.themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onReminderChanged() {
    _drainPendingUi();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
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
      PageRouteBuilder<void>(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (_, animation, secondaryAnimation) => FullScreenReminderScreen(
          onDrankWater: widget.reminderProvider.handleDrankWater,
          onRemindLater: widget.reminderProvider.requestSnoozePicker,
        ),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );

    _showingFullScreen = false;
  }

  Future<void> _presentSnoozePicker() async {
    if (_showingSnooze) return;
    final nav = _navigatorKey.currentState;
    if (nav == null) {
      if (!mounted) return;
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
      themeMode: widget.themeProvider.themeMode,
      home: onboardingComplete
          ? MainShell(
              reminderProvider: widget.reminderProvider,
              themeProvider: widget.themeProvider,
            )
          : OnboardingScreen(
              reminderProvider: widget.reminderProvider,
              themeProvider: widget.themeProvider,
            ),
    );
  }
}
