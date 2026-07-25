import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/constants.dart';
import 'capsule_nav_bar.dart';

/// Circular floating water-drop action button.
class FloatingAddButton extends StatefulWidget {
  /// Creates the floating add button.
  const FloatingAddButton({
    super.key,
    required this.onPressed,
  });

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  @override
  State<FloatingAddButton> createState() => _FloatingAddButtonState();
}

class _FloatingAddButtonState extends State<FloatingAddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animFast,
      lowerBound: 0.92,
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
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = CapsuleNavBar.contentClearance(context) + AppSpacing.xs;

    return Positioned(
      right: AppSpacing.xl,
      bottom: bottom,
      child: ScaleTransition(
        scale: _controller,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _handleTap,
              child: const SizedBox(
                width: 60,
                height: 60,
                child: Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
