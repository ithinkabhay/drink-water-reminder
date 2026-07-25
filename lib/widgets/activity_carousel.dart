import 'package:flutter/material.dart';

import '../models/intake_entry.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/time_format.dart';

/// Horizontal, snap-scrolling carousel of today's recent intake cards.
class ActivityCarousel extends StatelessWidget {
  /// Creates an activity carousel for [entries] (newest first, already truncated).
  const ActivityCarousel({
    super.key,
    required this.entries,
    this.onCardTap,
  });

  /// Newest-first entries to display (caller should limit to 5).
  final List<IntakeEntry> entries;

  /// Optional tap handler (e.g. open full today's activity).
  final ValueChanged<IntakeEntry>? onCardTap;

  static const double _cardWidth = 140;
  static const double _cardHeight = 132;
  static const double _gap = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const _SnapScrollPhysics(itemExtent: _cardWidth + _gap),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return ActivityCarouselCard(
            width: _cardWidth,
            amountMl: entry.amountMl,
            timestamp: entry.timestamp,
            onTap: onCardTap == null ? null : () => onCardTap!(entry),
          );
        },
      ),
    );
  }
}

/// Compact premium card for a single intake log.
class ActivityCarouselCard extends StatelessWidget {
  /// Creates a compact activity card.
  const ActivityCarouselCard({
    super.key,
    required this.amountMl,
    required this.timestamp,
    this.width = 140,
    this.onTap,
  });

  /// Amount in milliliters.
  final int amountMl;

  /// When the intake was logged.
  final DateTime timestamp;

  /// Fixed card width.
  final double width;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final relative = TimeFormat.relative(timestamp);
    final showRelative = DateTime.now().difference(timestamp).inHours < 1;

    return SizedBox(
      width: width,
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mediumAll,
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mediumAll,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  size: 22,
                  color: colorScheme.primary,
                ),
                const Spacer(),
                Text(
                  '$amountMl ml',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  TimeFormat.clock(timestamp),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (showRelative) ...[
                  const SizedBox(height: 2),
                  Text(
                    relative,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Snaps horizontal scrolling to card boundaries.
class _SnapScrollPhysics extends ScrollPhysics {
  const _SnapScrollPhysics({
    required this.itemExtent,
    super.parent,
  });

  /// Card width + gap between cards.
  final double itemExtent;

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnapScrollPhysics(
      itemExtent: itemExtent,
      parent: buildParent(ancestor),
    );
  }

  double _getPage(ScrollMetrics position) => position.pixels / itemExtent;

  double _getTargetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    var page = _getPage(position);
    if (velocity < -tolerance.velocity) {
      page = page.floorToDouble();
    } else if (velocity > tolerance.velocity) {
      page = page.ceilToDouble();
    } else {
      page = page.roundToDouble();
    }
    return page * itemExtent;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}
