import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Primary action button used to log a drink of water.
class DrinkButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: AppConstants.drinkButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.drinkButtonRadius,
            ),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text(AppConstants.drinkButtonLabel),
      ),
    );
  }
}
