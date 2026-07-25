import 'package:flutter/material.dart';

import '../models/daily_intake.dart';
import '../models/hydration_stats.dart';
import '../models/intake_entry.dart';
import '../repositories/hydration_repository.dart';
import '../services/hydration_history_service.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/app_refresh_bridge.dart';
import '../widgets/activity_carousel.dart';
import '../widgets/capsule_nav_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/history_intake_chart.dart';
import '../widgets/section_title.dart';

/// Analytics hub: today stats, charts, calendar, history, streaks.
class InsightsScreen extends StatefulWidget {
  /// Creates the insights screen.
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final HydrationHistoryService _historyService = HydrationHistoryService();
  final HydrationRepository _repository = HydrationRepository();

  late HydrationStats _weekStats;
  late HydrationStats _monthStats;
  late int _goalMl;
  late int _consumedMl;
  late int _streak;
  late List<IntakeEntry> _todayEntries;
  late Map<String, int> _history;
  late DateTime _calendarMonth;
  HistoryPeriod _chartPeriod = HistoryPeriod.week;

  @override
  void initState() {
    super.initState();
    AppRefreshBridge.bind(_reload);
    _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _load();
  }

  @override
  void dispose() {
    AppRefreshBridge.unbind(_reload);
    super.dispose();
  }

  void _load() {
    _weekStats = _historyService.loadStats(HistoryPeriod.week);
    _monthStats = _historyService.loadStats(HistoryPeriod.month);
    _goalMl = _repository.loadDailyGoalMl();
    _consumedMl = _repository.loadTodayIntake();
    _streak = _repository.loadCurrentStreak();
    _todayEntries = _repository.loadTodayEntries();
    _history = _repository.loadHistoryMap();
  }

  void _reload() {
    if (!mounted) return;
    setState(_load);
  }

  int get _remainingMl => (_goalMl - _consumedMl).clamp(0, _goalMl);

  double get _todayProgress =>
      _goalMl <= 0 ? 0 : (_consumedMl / _goalMl).clamp(0.0, 1.0);

  HydrationStats get _activeStats =>
      _chartPeriod == HistoryPeriod.week ? _weekStats : _monthStats;

  int _goalCompletionPercent(HydrationStats stats) {
    if (stats.entries.isEmpty || _goalMl <= 0) return 0;
    final met = stats.entries.where((e) => e.consumedMl >= _goalMl).length;
    return ((met / stats.entries.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 600;
              final horizontal = wide
                  ? constraints.maxWidth * 0.12
                  : AppSpacing.xl;

              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    AppSpacing.lg,
                    horizontal,
                    CapsuleNavBar.contentBottomPadding,
                  ),
                  children: [
                    Text('Insights', style: textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Your hydration at a glance',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    GlassCard(
                      child: _TodaySnapshot(
                        goalMl: _goalMl,
                        consumedMl: _consumedMl,
                        remainingMl: _remainingMl,
                        progress: _todayProgress,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const SectionTitle(title: 'Charts'),
                    SegmentedButton<HistoryPeriod>(
                      segments: const [
                        ButtonSegment(
                          value: HistoryPeriod.week,
                          label: Text('Weekly'),
                        ),
                        ButtonSegment(
                          value: HistoryPeriod.month,
                          label: Text('Monthly'),
                        ),
                      ],
                      selected: {_chartPeriod},
                      onSelectionChanged: (value) {
                        setState(() => _chartPeriod = value.first);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _chartPeriod == HistoryPeriod.week
                                ? 'Weekly Chart'
                                : 'Monthly Chart',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Daily intake vs goal',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          RepaintBoundary(
                            child: HistoryIntakeChart(
                              stats: _activeStats,
                              goalMl: _goalMl,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SectionTitle(
                      title: _chartPeriod == HistoryPeriod.week
                          ? 'Weekly Summary'
                          : 'Monthly Summary',
                    ),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        children: [
                          _StatRow(
                            label: 'Average intake',
                            value: '${_activeStats.averageMl} ml',
                          ),
                          _StatRow(
                            label: 'Longest streak',
                            value: _activeStats.longestStreak == 1
                                ? '1 day'
                                : '${_activeStats.longestStreak} days',
                          ),
                          _StatRow(
                            label: 'Current streak',
                            value: _streak == 1 ? '1 day' : '$_streak days',
                          ),
                          _StatRow(
                            label: 'Goal %',
                            value: '${_goalCompletionPercent(_activeStats)}%',
                          ),
                          _StatRow(
                            label: _chartPeriod == HistoryPeriod.week
                                ? 'Weekly total'
                                : 'Monthly total',
                            value: '${_activeStats.totalMl} ml',
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const SectionTitle(title: 'Calendar'),
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _MonthCalendar(
                        month: _calendarMonth,
                        history: _history,
                        goalMl: _goalMl,
                        onPrev: () {
                          setState(() {
                            _calendarMonth = DateTime(
                              _calendarMonth.year,
                              _calendarMonth.month - 1,
                            );
                          });
                        },
                        onNext: () {
                          setState(() {
                            _calendarMonth = DateTime(
                              _calendarMonth.year,
                              _calendarMonth.month + 1,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const SectionTitle(
                      title: 'History',
                      subtitle: "Today's drinks",
                    ),
                    if (_todayEntries.isEmpty)
                      const EmptyState(
                        message: 'No drinks logged yet today.',
                        icon: Icons.history_rounded,
                      )
                    else
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: ActivityCarousel(
                          entries: _todayEntries.reversed.take(5).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TodaySnapshot extends StatelessWidget {
  const _TodaySnapshot({
    required this.goalMl,
    required this.consumedMl,
    required this.remainingMl,
    required this.progress,
  });

  final int goalMl;
  final int consumedMl;
  final int remainingMl;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Daily Summary', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _StatRow(label: "Today's Goal", value: '$goalMl ml'),
        _StatRow(label: "Today's Intake", value: '$consumedMl ml'),
        _StatRow(
          label: 'Remaining',
          value: remainingMl == 0 ? 'Goal reached' : '$remainingMl ml',
          showDivider: false,
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.capsuleAll,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(progress * 100).round()}%',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: Text(label, style: textTheme.bodyMedium)),
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(color: colorScheme.outline.withValues(alpha: 0.12)),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.history,
    required this.goalMl,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final Map<String, int> history;
  final int goalMl;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = (first.weekday + 6) % 7;
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                '${_months[month.month - 1]} ${month.year}',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (final day in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: startOffset + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox.shrink();
            final day = index - startOffset + 1;
            final date = DateTime(month.year, month.month, day);
            final key = DailyIntake.toDateKey(date);
            final ml = history[key] ?? 0;
            final isToday =
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final metGoal = goalMl > 0 && ml >= goalMl;
            final hasIntake = ml > 0;

            return DecoratedBox(
              decoration: BoxDecoration(
                color: metGoal
                    ? colorScheme.tertiary.withValues(alpha: 0.22)
                    : hasIntake
                    ? colorScheme.primary.withValues(alpha: 0.16)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: colorScheme.primary, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _LegendDot(color: colorScheme.primary.withValues(alpha: 0.16)),
            const SizedBox(width: 6),
            Text('Logged', style: textTheme.bodySmall),
            const SizedBox(width: AppSpacing.md),
            _LegendDot(color: colorScheme.tertiary.withValues(alpha: 0.22)),
            const SizedBox(width: 6),
            Text('Goal met', style: textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
