import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../utils/time_format.dart';

/// Single intake activity row: time + amount.
class ActivityTile extends StatelessWidget {
  /// Creates an activity tile.
  const ActivityTile({
    super.key,
    required this.timestamp,
    required this.amountMl,
    this.dense = false,
  });

  /// When the intake was logged.
  final DateTime timestamp;

  /// Amount in milliliters.
  final int amountMl;

  /// Slightly tighter vertical padding.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final vertical = dense ? AppSpacing.xs : AppSpacing.sm;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            TimeFormat.clock(timestamp),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            '+${amountMl}ml',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
