import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/hydration_stats.dart';

/// Bar chart visualizing daily intake for a history period.
class HistoryIntakeChart extends StatelessWidget {
  /// Creates a chart for [stats] with a horizontal [goalMl] reference line.
  const HistoryIntakeChart({
    super.key,
    required this.stats,
    required this.goalMl,
  });

  /// Aggregated stats whose [HydrationStats.entries] drive the bars.
  final HydrationStats stats;

  /// Daily goal used for the reference line and Y-axis scale.
  final int goalMl;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWeek = stats.period == HistoryPeriod.week;
    final maxY = _maxY(stats);

    return AspectRatio(
      aspectRatio: 1.55,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colorScheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = stats.entries[group.x.toInt()];
                final label =
                    '${_months[entry.date.month - 1]} ${entry.date.day}';
                return BarTooltipItem(
                  '$label\n${entry.consumedMl} ml',
                  TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _shortMl(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= stats.entries.length) {
                    return const SizedBox.shrink();
                  }
                  final date = stats.entries[index].date;
                  final label = isWeek
                      ? _weekdays[date.weekday - 1]
                      : (index % 5 == 0 ? '${date.day}' : '');
                  if (label.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outline.withValues(alpha: 0.18),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < stats.entries.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: stats.entries[i].consumedMl.toDouble(),
                    width: isWeek ? 18 : 6,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.55),
                        colorScheme.primary,
                      ],
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: colorScheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: goalMl.toDouble().clamp(0, maxY),
                color: colorScheme.tertiary.withValues(alpha: 0.7),
                strokeWidth: 1.2,
                dashArray: const [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                  labelResolver: (_) => 'Goal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _maxY(HydrationStats stats) {
    final peak = stats.entries.fold<int>(
      goalMl,
      (max, e) => e.consumedMl > max ? e.consumedMl : max,
    );
    return (peak * 1.15).clamp(500, double.infinity);
  }

  String _shortMl(double value) {
    if (value >= 1000) {
      final liters = value / 1000;
      return value % 1000 == 0
          ? '${liters.toStringAsFixed(0)}L'
          : '${liters.toStringAsFixed(1)}L';
    }
    return '${value.round()}';
  }
}
