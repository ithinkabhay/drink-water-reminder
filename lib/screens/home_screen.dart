import 'package:flutter/material.dart';

import '../repositories/hydration_repository.dart';
import '../utils/constants.dart';
import '../widgets/drink_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/goal_section.dart';
import '../widgets/gradient_background.dart';
import '../widgets/hydration_stats_row.dart';
import '../widgets/water_progress.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// Home screen showing today's hydration goal and a quick-add drink button.
class HomeScreen extends StatefulWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Holds intake state and builds the home screen layout.
class _HomeScreenState extends State<HomeScreen> {
  final HydrationRepository _repository = HydrationRepository();

  /// How much water the user has logged today, in milliliters.
  int _consumedMl = 0;

  /// Consecutive-day hydration streak.
  int _streak = 0;

  /// Progress toward the daily goal as a value between 0.0 and 1.0.
  double get _progress =>
      (_consumedMl / AppConstants.dailyGoalMl).clamp(0.0, 1.0);

  /// Milliliters still needed to hit the daily goal.
  int get _remainingMl =>
      (AppConstants.dailyGoalMl - _consumedMl).clamp(0, AppConstants.dailyGoalMl);

  @override
  void initState() {
    super.initState();
    _consumedMl = _repository.loadTodayIntake();
    _streak = _repository.loadCurrentStreak();
  }

  /// Adds [AppConstants.drinkAmountMl] toward today's goal and persists it.
  Future<void> _drinkWater() async {
    final updated = (_consumedMl + AppConstants.drinkAmountMl)
        .clamp(0, AppConstants.dailyGoalMl);

    setState(() {
      _consumedMl = updated;
    });

    await _repository.saveTodayIntake(_consumedMl);
    setState(() {
      _streak = _repository.loadCurrentStreak();
    });
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final message = AppConstants.motivationalMessageFor(_progress);

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
                      Text(
                        AppConstants.brandName,
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stay refreshed throughout your day',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: WaterProgress(progress: _progress),
                      ),
                      const SizedBox(height: 28),
                      GoalSection(
                        consumedMl: _consumedMl,
                        goalMl: AppConstants.dailyGoalMl,
                      ),
                      const SizedBox(height: 12),
                      HydrationStatsRow(
                        streak: _streak,
                        remainingMl: _remainingMl,
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tips_and_updates_outlined,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                message,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      DrinkButton(
                        onPressed: _consumedMl >= AppConstants.dailyGoalMl
                            ? null
                            : _drinkWater,
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
