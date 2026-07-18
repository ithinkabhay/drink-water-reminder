import 'package:flutter/material.dart';

import '../models/intake_entry.dart';
import '../utils/time_format.dart';
import 'glass_card.dart';

/// Friendly welcome card shown near the top of the home screen.
class WelcomeBackCard extends StatelessWidget {
  /// Creates the welcome-back card for [name].
  const WelcomeBackCard({super.key, required this.name});

  /// User's display name.
  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayName = name.trim().isEmpty ? 'friend' : name.trim();

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.waving_hand_rounded,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Glad to see you again, $displayName.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

/// Card summarizing the most recent drink logged today.
class LastDrinkCard extends StatelessWidget {
  /// Creates the last-drink card. Pass [entry] as `null` when none exist.
  const LastDrinkCard({super.key, this.entry});

  /// Most recent intake entry for today, if any.
  final IntakeEntry? entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (entry == null) {
      return GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.local_drink_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "You haven't logged any water today. Let's drink your first glass!",
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final last = entry!;
    return GlassCard(
      child: Row(
        children: [
          Icon(Icons.local_drink_rounded, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last drink',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${last.amountMl} ml · ${TimeFormat.clock(last.timestamp)}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  TimeFormat.relative(last.timestamp),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
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

/// Motivation card that animates when the message changes with progress.
class MotivationCard extends StatelessWidget {
  /// Creates a motivation card showing [message].
  const MotivationCard({super.key, required this.message});

  /// Motivational line for the current progress band.
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Text(
                message,
                key: ValueKey<String>(message),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of today's remaining water, drink count, completion %, and next reminder.
class HomeStatsGrid extends StatelessWidget {
  /// Creates the home overview stats grid.
  const HomeStatsGrid({
    super.key,
    required this.remainingMl,
    required this.drinksToday,
    required this.completionPercent,
    required this.nextReminderLabel,
  });

  /// Milliliters still needed to hit today's goal.
  final int remainingMl;

  /// Number of intake entries logged today.
  final int drinksToday;

  /// Goal completion as 0–100.
  final int completionPercent;

  /// Formatted next reminder time, or a disabled label.
  final String nextReminderLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.opacity_rounded,
                label: 'Remaining',
                value: remainingMl <= 0 ? 'Done!' : '$remainingMl ml',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.local_cafe_rounded,
                label: 'Drinks today',
                value: drinksToday == 1 ? '1 drink' : '$drinksToday drinks',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.flag_rounded,
                label: 'Goal complete',
                value: '$completionPercent%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.notifications_active_outlined,
                label: 'Next reminder',
                value: nextReminderLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Text(
              value,
              key: ValueKey<String>('$label-$value'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
