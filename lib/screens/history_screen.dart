import 'package:flutter/material.dart';

import '../models/hydration_stats.dart';
import '../repositories/hydration_repository.dart';
import '../services/hydration_history_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/history_intake_chart.dart';
import '../widgets/history_summary_cards.dart';

/// Screen showing weekly and monthly hydration history with charts.
class HistoryScreen extends StatefulWidget {
  /// Creates the history screen.
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final HydrationHistoryService _historyService = HydrationHistoryService();
  final HydrationRepository _repository = HydrationRepository();

  late final TabController _tabController;
  late HydrationStats _weekStats;
  late HydrationStats _monthStats;
  late int _goalMl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _weekStats = _historyService.loadStats(HistoryPeriod.week);
    _monthStats = _historyService.loadStats(HistoryPeriod.month);
    _goalMl = _repository.loadDailyGoalMl();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Hydration History'),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _HistoryPeriodView(
              stats: _weekStats,
              goalMl: _goalMl,
              subtitle: 'Last 7 days',
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            _HistoryPeriodView(
              stats: _monthStats,
              goalMl: _goalMl,
              subtitle: 'Last 30 days',
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryPeriodView extends StatelessWidget {
  const _HistoryPeriodView({
    required this.stats,
    required this.goalMl,
    required this.subtitle,
    required this.textTheme,
    required this.colorScheme,
  });

  final HydrationStats stats;
  final int goalMl;
  final String subtitle;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        final horizontal = wide ? constraints.maxWidth * 0.14 : 20.0;

        return ListView(
          padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 28),
          children: [
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            HistorySummaryCards(stats: stats),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.fromLTRB(12, 18, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Intake chart',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily water logged vs goal',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  HistoryIntakeChart(stats: stats, goalMl: goalMl),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Current streak: ${stats.currentStreak == 1 ? '1 day' : '${stats.currentStreak} days'}',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
