import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';
import 'glass_card.dart';

/// Responsive grid of quick-add water amounts plus a Custom tile.
class QuickAddGrid extends StatelessWidget {
  /// Creates a quick-add grid.
  ///
  /// [onAmountSelected] is called with a preset milliliter value.
  /// [onCustomSelected] opens the custom amount flow.
  const QuickAddGrid({
    super.key,
    required this.onAmountSelected,
    required this.onCustomSelected,
  });

  /// Called when the user taps a preset amount tile.
  final ValueChanged<int> onAmountSelected;

  /// Called when the user taps the Custom tile.
  final VoidCallback onCustomSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final tiles = <_QuickAddTileData>[
      for (final amount in AppConstants.quickAddAmountsMl)
        _QuickAddTileData(
          label: '$amount ml',
          onTap: () => onAmountSelected(amount),
          isCustom: false,
        ),
      _QuickAddTileData(
        label: AppConstants.customAmountLabel,
        onTap: onCustomSelected,
        isCustom: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Add',
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 520
                ? 4
                : constraints.maxWidth >= 360
                    ? 3
                    : 2;
            final spacing = 10.0;
            final tileWidth =
                (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                    crossAxisCount;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final tile in tiles)
                  SizedBox(
                    width: tileWidth,
                    height: AppConstants.quickAddTileHeight,
                    child: _QuickAddTile(data: tile),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickAddTileData {
  const _QuickAddTileData({
    required this.label,
    required this.onTap,
    required this.isCustom,
  });

  final String label;
  final VoidCallback onTap;
  final bool isCustom;
}

class _QuickAddTile extends StatefulWidget {
  const _QuickAddTile({required this.data});

  final _QuickAddTileData data;

  @override
  State<_QuickAddTile> createState() => _QuickAddTileState();
}

class _QuickAddTileState extends State<_QuickAddTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1,
      value: 1,
    );
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.lightImpact();
    await _controller.reverse();
    await _controller.forward();
    widget.data.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isCustom = widget.data.isCustom;

    return ScaleTransition(
      scale: _scale,
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppConstants.quickAddTileRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(AppConstants.quickAddTileRadius),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppConstants.quickAddTileRadius),
                gradient: isCustom
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.18),
                          colorScheme.primary.withValues(alpha: 0.06),
                        ],
                      ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCustom
                          ? Icons.tune_rounded
                          : Icons.water_drop_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.data.label,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
