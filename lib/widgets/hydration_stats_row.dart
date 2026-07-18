import 'package:flutter/material.dart';

import 'glass_card.dart';

/// Compact stats row for streak and remaining water.
class HydrationStatsRow extends StatelessWidget {
  /// Creates the streak + remaining water cards.
  const HydrationStatsRow({
    super.key,
    required this.streak,
    required this.remainingMl,
  });

  /// Consecutive days the user has logged water.
  final int streak;

  /// Milliliters still needed to reach today's goal.
  final int remainingMl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            label: "Today's streak",
            value: streak == 1 ? '1 day' : '$streak days',
            accent: const Color(0xFFFF8A65),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.opacity_rounded,
            label: 'Remaining',
            value: remainingMl <= 0 ? 'Done!' : '$remainingMl ml',
            accent: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
