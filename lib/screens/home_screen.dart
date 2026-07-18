import 'package:flutter/material.dart';

import '../models/intake_entry.dart';
import '../models/reminder_settings.dart';
import '../models/user_profile.dart';
import '../providers/reminder_provider.dart';
import '../repositories/hydration_repository.dart';
import '../utils/app_refresh_bridge.dart';
import '../utils/constants.dart';
import '../utils/time_format.dart';
import '../widgets/custom_amount_dialog.dart';
import '../widgets/daily_goal_sheet.dart';
import '../widgets/goal_section.dart';
import '../widgets/gradient_background.dart';
import '../widgets/home_cards.dart';
import '../widgets/hydration_stats_row.dart';
import '../widgets/quick_add_grid.dart';
import '../widgets/water_progress.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Home screen showing today's hydration goal and quick-add controls.
class HomeScreen extends StatefulWidget {
  /// Creates the home screen.
  const HomeScreen({
    super.key,
    required this.reminderProvider,
  });

  /// Shared reminder settings + notification coordinator.
  final ReminderProvider reminderProvider;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Holds intake state and builds the home screen layout.
class _HomeScreenState extends State<HomeScreen> {
  final HydrationRepository _repository = HydrationRepository();

  /// How much water the user has logged today, in milliliters.
  int _consumedMl = 0;

  /// User-configured daily goal in milliliters.
  int _goalMl = AppConstants.defaultDailyGoalMl;

  /// Consecutive-day hydration streak.
  int _streak = 0;

  /// Today's individual intake log entries (oldest → newest).
  List<IntakeEntry> _entries = const [];

  /// Reminder preferences for next-reminder display.
  ReminderSettings _reminderSettings = ReminderSettings.defaults();

  /// Loaded user profile (may be null for legacy installs).
  UserProfile? _profile;

  /// Progress toward the daily goal as a value between 0.0 and 1.0.
  double get _progress =>
      _goalMl <= 0 ? 0.0 : (_consumedMl / _goalMl).clamp(0.0, 1.0);

  /// Milliliters still needed to hit the daily goal.
  int get _remainingMl => (_goalMl - _consumedMl).clamp(0, _goalMl);

  IntakeEntry? get _lastDrink =>
      _entries.isEmpty ? null : _entries.last;

  @override
  void initState() {
    super.initState();
    widget.reminderProvider.addListener(_onReminderChanged);
    AppRefreshBridge.bind(_reload);
    _consumedMl = _repository.loadTodayIntake();
    _goalMl = _repository.loadDailyGoalMl();
    _streak = _repository.loadCurrentStreak();
    _entries = _repository.loadTodayEntries();
    _reminderSettings = _repository.loadReminderSettings();
    _profile = _repository.loadUserProfile();
  }

  @override
  void dispose() {
    widget.reminderProvider.removeListener(_onReminderChanged);
    AppRefreshBridge.unbind(_reload);
    super.dispose();
  }

  void _onReminderChanged() {
    if (!mounted) return;
    setState(() {
      _reminderSettings = widget.reminderProvider.settings;
    });
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _consumedMl = _repository.loadTodayIntake();
      _goalMl = _repository.loadDailyGoalMl();
      _streak = _repository.loadCurrentStreak();
      _entries = _repository.loadTodayEntries();
      _reminderSettings = _repository.loadReminderSettings();
      _profile = _repository.loadUserProfile();
    });
  }

  /// Adds [amountMl], updates progress, persists via Hive, and shows undo SnackBar.
  Future<void> _addWater(int amountMl) async {
    final updated = await _repository.addIntake(amountMl);

    if (!mounted) return;

    setState(() {
      _consumedMl = updated;
      _streak = _repository.loadCurrentStreak();
      _entries = _repository.loadTodayEntries();
    });

    await widget.reminderProvider.onWaterLogged();
    _showAddedSnackBar(amountMl);
  }

  /// Opens the custom amount dialog and adds the confirmed value.
  Future<void> _addCustomWater() async {
    final amount = await CustomAmountDialog.show(context);
    if (!mounted || amount == null) return;
    await _addWater(amount);
  }

  void _showAddedSnackBar(int amountMl) {
    final messenger = ScaffoldMessenger.of(context);
    // Ensure only one SnackBar is visible at a time.
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Added $amountMl ml'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            messenger.hideCurrentSnackBar();
            _undoLastAdd();
          },
        ),
      ),
    );
  }

  /// Removes the last intake entry and restores the previous total.
  Future<void> _undoLastAdd() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final result = await _repository.undoLastIntake();
    if (!mounted || result == null) return;

    setState(() {
      _consumedMl = result.newTotal;
      _streak = _repository.loadCurrentStreak();
      _entries = _repository.loadTodayEntries();
    });

    await widget.reminderProvider.onWaterLogged();
  }

  /// Opens the Set Daily Goal sheet and persists a confirmed selection.
  Future<void> _setDailyGoal() async {
    final selected = await DailyGoalSheet.show(
      context,
      currentGoalMl: _goalMl,
    );
    if (!mounted || selected == null || selected == _goalMl) return;

    setState(() => _goalMl = selected);
    await _repository.saveDailyGoalMl(selected);
    await widget.reminderProvider.onWaterLogged();
  }

  Future<void> _openProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ProfileScreen(),
      ),
    );
    if (!mounted) return;
    if (updated == true) {
      _reload();
      // Profile may have changed the daily goal — keep schedules in sync.
      await widget.reminderProvider.onWaterLogged();
    }
  }

  void _openSettings() {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          reminderProvider: widget.reminderProvider,
        ),
      ),
    )
        .then((_) {
      if (mounted) _reload();
    });
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HistoryScreen(),
      ),
    );
  }

  String get _nextReminderLabel {
    final goalMet = _consumedMl >= _goalMl;
    if (goalMet && _reminderSettings.stopAfterGoalCompleted) {
      return 'Done today';
    }
    final next = TimeFormat.nextReminder(
      _reminderSettings,
      lastIntakeAt: _lastDrink?.timestamp,
      goalAlreadyMet: goalMet,
    );
    if (next == null) return 'Off';
    return TimeFormat.clock(next);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final message = AppConstants.motivationalMessageFor(_progress);
    final name = _profile?.name.trim() ?? '';
    final greeting = TimeFormat.greeting();
    final completionPercent = (_progress * 100).round();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            AppConstants.appTitle,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Profile',
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: _openProfile,
            ),
            IconButton(
              tooltip: 'History',
              icon: const Icon(Icons.bar_chart_rounded),
              onPressed: _openHistory,
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: _openSettings,
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 600;
              final horizontal = wide ? constraints.maxWidth * 0.18 : 20.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: Text(
                          name.isEmpty ? greeting : '$greeting, $name',
                          key: ValueKey<String>('$greeting-$name'),
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stay refreshed throughout your day',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      WelcomeBackCard(name: name),
                      const SizedBox(height: 12),
                      LastDrinkCard(entry: _lastDrink),
                      const SizedBox(height: 12),
                      MotivationCard(message: message),
                      const SizedBox(height: 20),
                      Center(
                        child: WaterProgress(progress: _progress),
                      ),
                      const SizedBox(height: 28),
                      GoalSection(
                        consumedMl: _consumedMl,
                        goalMl: _goalMl,
                        onSetGoal: _setDailyGoal,
                      ),
                      const SizedBox(height: 12),
                      HydrationStatsRow(
                        streak: _streak,
                        remainingMl: _remainingMl,
                      ),
                      const SizedBox(height: 12),
                      HomeStatsGrid(
                        remainingMl: _remainingMl,
                        drinksToday: _entries.length,
                        completionPercent: completionPercent,
                        nextReminderLabel: _nextReminderLabel,
                      ),
                      const SizedBox(height: 28),
                      QuickAddGrid(
                        onAmountSelected: _addWater,
                        onCustomSelected: _addCustomWater,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
