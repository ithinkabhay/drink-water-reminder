import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Calm empty-state block with icon and copy.
class EmptyState extends StatelessWidget {
  /// Creates an empty state.
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.water_drop_outlined,
    this.title,
  });

  /// Optional bold title above [message].
  final String? title;

  /// Supporting message.
  final String message;

  /// Leading Material Symbols Rounded-style icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
