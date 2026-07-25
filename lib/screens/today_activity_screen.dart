import 'package:flutter/material.dart';

import '../models/intake_entry.dart';
import '../theme/app_spacing.dart';
import '../widgets/activity_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';

/// Full list of today's intake entries.
class TodayActivityScreen extends StatelessWidget {
  /// Creates the full today's activity list.
  const TodayActivityScreen({
    super.key,
    required this.entries,
  });

  /// Today's entries (oldest → newest).
  final List<IntakeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final newestFirst = entries.reversed.toList();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Today's Activity"),
        ),
        body: newestFirst.isEmpty
            ? const Center(
                child: EmptyState(
                  message: 'Start your hydration journey today.',
                  icon: Icons.water_drop_outlined,
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xs,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                children: [
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        for (final entry in newestFirst)
                          ActivityTile(
                            timestamp: entry.timestamp,
                            amountMl: entry.amountMl,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
