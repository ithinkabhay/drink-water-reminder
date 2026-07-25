import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';
import '../utils/constants.dart';

/// Single capsule quick-add chip with press scale + haptic.
class QuickAddChip extends StatefulWidget {
  /// Creates a quick-add chip.
  const QuickAddChip({
    super.key,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  /// Chip label (e.g. `250 ml`, `Custom`).
  final String label;

  /// Called after the press animation.
  final VoidCallback onTap;

  /// Slightly stronger fill for Custom / primary actions.
  final bool emphasized;

  @override
  State<QuickAddChip> createState() => _QuickAddChipState();
}

class _QuickAddChipState extends State<QuickAddChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animFast,
      lowerBound: 0.94,
      upperBound: 1,
      value: 1,
    );
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
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ScaleTransition(
      scale: _controller,
      child: SizedBox(
        height: AppConstants.quickAddTileHeight,
        child: Material(
          color: widget.emphasized
              ? colorScheme.primary.withValues(alpha: 0.14)
              : colorScheme.surface,
          shape: StadiumBorder(
            side: BorderSide(
              color: colorScheme.primary.withValues(
                alpha: widget.emphasized ? 0.4 : 0.28,
              ),
            ),
          ),
          child: InkWell(
            onTap: _handleTap,
            customBorder: const StadiumBorder(),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Equal-height quick-add chips (presets + Custom).
class QuickAddChips extends StatelessWidget {
  /// Creates a quick-add chip row.
  const QuickAddChips({
    super.key,
    required this.onAmountSelected,
    required this.onCustomSelected,
    this.showTitle = true,
  });

  /// Called when the user taps a preset amount chip.
  final ValueChanged<int> onAmountSelected;

  /// Called when the user taps the Custom chip.
  final VoidCallback onCustomSelected;

  /// Whether to show the "Quick Add" section title.
  final bool showTitle;

  /// Label for a preset amount (e.g. `100 ml`, `1 L`).
  static String labelFor(int amountMl) {
    if (amountMl >= 1000 && amountMl % 1000 == 0) {
      final liters = amountMl ~/ 1000;
      return liters == 1 ? '1 L' : '$liters L';
    }
    return '$amountMl ml';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final amounts = AppConstants.quickAddAmountsMl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          Text(
            'Quick Add',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            for (var i = 0; i < amounts.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: QuickAddChip(
                  label: labelFor(amounts[i]),
                  onTap: () => onAmountSelected(amounts[i]),
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: QuickAddChip(
                label: AppConstants.customAmountLabel,
                emphasized: true,
                onTap: onCustomSelected,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Grid of quick-add amounts for bottom sheets.
class QuickAddAmountGrid extends StatelessWidget {
  /// Creates a wrap/grid of amount chips.
  const QuickAddAmountGrid({
    super.key,
    required this.onAmountSelected,
    required this.onCustomSelected,
  });

  final ValueChanged<int> onAmountSelected;
  final VoidCallback onCustomSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: [
        for (final amount in AppConstants.quickAddAmountsMl)
          QuickAddChip(
            label: QuickAddChips.labelFor(amount),
            onTap: () => onAmountSelected(amount),
          ),
        QuickAddChip(
          label: AppConstants.customAmountLabel,
          emphasized: true,
          onTap: onCustomSelected,
        ),
      ],
    );
  }
}
