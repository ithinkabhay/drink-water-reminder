import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/drink_button.dart';
import '../widgets/goal_section.dart';
import '../widgets/water_progress.dart';

/// Home screen showing today's hydration goal and a quick-add drink button.
class HomeScreen extends StatefulWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Holds intake state and builds the home screen layout.
class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();

  /// How much water the user has logged today, in milliliters.
  int _consumedMl = 0;

  /// Progress toward the daily goal as a value between 0.0 and 1.0.
  double get _progress =>
      (_consumedMl / AppConstants.dailyGoalMl).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    // Restore today's intake (or zero if the calendar day rolled over).
    _consumedMl = _storage.loadTodayIntake();
  }

  /// Adds [AppConstants.drinkAmountMl] toward today's goal and persists it.
  Future<void> _drinkWater() async {
    final updated = (_consumedMl + AppConstants.drinkAmountMl)
        .clamp(0, AppConstants.dailyGoalMl);

    setState(() {
      _consumedMl = updated;
    });

    await _storage.saveTodayIntake(_consumedMl);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(AppConstants.appTitle),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Water drop emoji as the visual focal point.
              const Text(
                '💧',
                style: TextStyle(fontSize: AppConstants.waterEmojiSize),
              ),
              const SizedBox(height: 32),

              GoalSection(
                consumedMl: _consumedMl,
                goalMl: AppConstants.dailyGoalMl,
              ),
              const SizedBox(height: 40),

              WaterProgress(progress: _progress),

              const Spacer(flex: 2),

              DrinkButton(
                onPressed:
                    _consumedMl >= AppConstants.dailyGoalMl
                        ? null
                        : _drinkWater,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
