import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Circular progress ring that visualizes hydration progress.
class WaterProgress extends StatelessWidget {
  /// Creates a progress ring for the given [progress] (0.0 – 1.0).
  const WaterProgress({
    super.key,
    required this.progress,
  });

  /// Fraction of the daily goal completed, clamped between 0.0 and 1.0.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: AppConstants.progressSize,
      height: AppConstants.progressSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: AppConstants.progressSize,
            height: AppConstants.progressSize,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: AppConstants.progressStrokeWidth,
              backgroundColor: colorScheme.primaryContainer,
              color: colorScheme.primary,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Percentage label in the center of the ring.
          Text(
            '${(progress * 100).round()}%',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
