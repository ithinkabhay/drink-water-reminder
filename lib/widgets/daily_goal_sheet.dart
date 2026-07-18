import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'custom_goal_dialog.dart';

/// Material 3 bottom sheet for choosing a daily water goal.
///
/// Offers quick presets and a Custom path that opens [CustomGoalDialog].
class DailyGoalSheet extends StatelessWidget {
  /// Creates the goal picker sheet for [currentGoalMl].
  const DailyGoalSheet({
    super.key,
    required this.currentGoalMl,
  });

  /// Currently persisted daily goal.
  final int currentGoalMl;

  /// Shows the sheet and returns the selected goal, or `null` if dismissed.
  static Future<int?> show(
    BuildContext context, {
    required int currentGoalMl,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DailyGoalSheet(currentGoalMl: currentGoalMl),
    );
  }

  Future<void> _selectPreset(BuildContext context, int goalMl) async {
    Navigator.of(context).pop(goalMl);
  }

  Future<void> _selectCustom(BuildContext context) async {
    final custom = await CustomGoalDialog.show(
      context,
      initialGoalMl: currentGoalMl,
    );
    if (!context.mounted || custom == null) return;
    Navigator.of(context).pop(custom);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set Daily Goal',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Current: $currentGoalMl ml',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Quick Goal Options',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final goal in AppConstants.quickDailyGoalOptionsMl)
                ChoiceChip(
                  label: Text('$goal ml'),
                  selected: goal == currentGoalMl,
                  onSelected: (_) => _selectPreset(context, goal),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.tune_rounded,
              color: colorScheme.primary,
            ),
            title: const Text('Custom Goal'),
            subtitle: Text(
              '${AppConstants.minDailyGoalMl}–${AppConstants.maxDailyGoalMl} ml',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () => _selectCustom(context),
          ),
        ],
      ),
    );
  }
}
