import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

/// Primary action button used to log a drink of water.
class DrinkButton extends StatefulWidget {
  /// Creates a full-width drink button.
  ///
  /// When [onPressed] is `null`, the button is disabled (e.g. goal reached).
  const DrinkButton({
    super.key,
    required this.onPressed,
  });

  /// Called when the user taps the button; `null` disables the button.
  final VoidCallback? onPressed;

  @override
  State<DrinkButton> createState() => _DrinkButtonState();
}

class _DrinkButtonState extends State<DrinkButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  bool get _enabled => widget.onPressed != null;

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
    if (!_enabled) return;
    HapticFeedback.lightImpact();
    await _controller.reverse();
    await _controller.forward();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: double.infinity,
        height: AppConstants.drinkButtonHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              AppConstants.drinkButtonRadius,
            ),
            gradient: _enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      Color.lerp(
                            colorScheme.primary,
                            const Color(0xFF0288D1),
                            0.45,
                          ) ??
                          colorScheme.primary,
                    ],
                  )
                : null,
            color: _enabled ? null : colorScheme.surfaceContainerHighest,
            boxShadow: _enabled
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _enabled ? _handleTap : null,
              borderRadius: BorderRadius.circular(
                AppConstants.drinkButtonRadius,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      color: _enabled
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _enabled
                          ? AppConstants.drinkButtonLabel
                          : 'Goal reached',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _enabled
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withValues(alpha: 0.38),
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
