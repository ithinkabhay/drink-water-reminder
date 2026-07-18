import 'package:flutter/material.dart';

import '../models/hydration_stats.dart';
import 'glass_card.dart';

/// Summary cards for total, average, and longest streak.
class HistorySummaryCards extends StatelessWidget {
  /// Creates summary cards from [stats].
  const HistorySummaryCards({
    super.key,
    required this.stats,
  });

  /// Stats to display.
  final HydrationStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.water_drop_rounded,
                label: 'Total intake',
                value: _formatMl(stats.totalMl),
                accent: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                icon: Icons.insights_rounded,
                label: 'Average',
                value: _formatMl(stats.averageMl),
                accent: const Color(0xFF26A69A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryTile(
          icon: Icons.emoji_events_rounded,
          label: 'Longest streak',
          value: stats.longestStreak == 1
              ? '1 day'
              : '${stats.longestStreak} days',
          accent: const Color(0xFFFF8A65),
          fullWidth: true,
        ),
      ],
    );
  }

  String _formatMl(int ml) {
    if (ml >= 1000) {
      final liters = ml / 1000;
      final text = ml % 1000 == 0
          ? liters.toStringAsFixed(0)
          : liters.toStringAsFixed(1);
      return '$text L';
    }
    return '$ml ml';
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: fullWidth ? 18 : 16,
        vertical: 16,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
