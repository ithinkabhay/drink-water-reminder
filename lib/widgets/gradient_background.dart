import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-bleed blue gradient backdrop for light and dark modes.
class GradientBackground extends StatelessWidget {
  /// Creates a gradient background wrapping [child].
  const GradientBackground({
    super.key,
    required this.child,
  });

  /// Content drawn above the gradient.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = AppTheme.gradientColors(brightness);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: const [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }
}
