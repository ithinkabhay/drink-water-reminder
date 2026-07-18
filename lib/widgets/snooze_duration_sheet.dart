import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Material 3 bottom sheet listing snooze durations after "Remind Me Later".
class SnoozeDurationSheet extends StatelessWidget {
  /// Creates the snooze duration sheet.
  const SnoozeDurationSheet({super.key});

  /// Shows the sheet and returns the selected minutes, or `null` if dismissed.
  static Future<int?> show(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (_) => const SnoozeDurationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Remind Me Later',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose when to be reminded again. No water will be logged.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final minutes in AppConstants.snoozeOptionsMinutes) ...[
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: Icon(
                  Icons.schedule_rounded,
                  color: colorScheme.primary,
                ),
                title: Text(
                  minutes == 1 ? '1 Minute' : '$minutes Minutes',
                ),
                onTap: () => Navigator.of(context).pop(minutes),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
