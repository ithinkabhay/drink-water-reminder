import 'package:flutter/material.dart';

/// Full-bleed calm backdrop for light and dark modes.
///
/// Uses a near-solid color with a barely-there vertical wash — not a heavy
/// decorative gradient.
class GradientBackground extends StatelessWidget {
  /// Creates a background wrapping [child].
  const GradientBackground({
    super.key,
    required this.child,
  });

  /// Content drawn above the backdrop.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scaffold = Theme.of(context).scaffoldBackgroundColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scaffold,
            Color.lerp(scaffold, colorScheme.surface, 0.35) ?? scaffold,
          ],
        ),
      ),
      child: child,
    );
  }
}