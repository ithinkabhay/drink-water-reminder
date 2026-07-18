import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Alarm-style full-screen UI shown when a hydration reminder fires
/// (full-screen intent / notification body tap).
class FullScreenReminderScreen extends StatelessWidget {
  /// Creates the full-screen reminder.
  const FullScreenReminderScreen({
    super.key,
    required this.onDrankWater,
    required this.onRemindLater,
  });

  /// Logs the default quick-add amount and dismisses the reminder.
  final Future<void> Function() onDrankWater;

  /// Opens the snooze picker without logging water.
  final VoidCallback onRemindLater;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    tooltip: 'Dismiss',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.water_drop_rounded,
                  size: 88,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 28),
                Text(
                  AppConstants.fullScreenReminderTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppConstants.fullScreenReminderBody,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () async {
                    await onDrankWater();
                    if (context.mounted) {
                      Navigator.of(context).maybePop();
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('✅ Drank Water'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).maybePop();
                    onRemindLater();
                  },
                  icon: const Icon(Icons.schedule_rounded),
                  label: const Text('⏰ Remind Later'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
