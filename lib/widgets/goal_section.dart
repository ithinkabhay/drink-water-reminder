import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Displays today's water intake against the daily goal.
class GoalSection extends StatelessWidget {
  /// Creates a goal section showing [consumedMl] of [goalMl].
  const GoalSection({
    super.key,
    required this.consumedMl,
    required this.goalMl,
  });

  /// Milliliters of water logged so far today.
  final int consumedMl;

  /// Daily water intake target in milliliters.
  final int goalMl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          AppConstants.todaysGoalLabel,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$consumedMl / $goalMl ml',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
