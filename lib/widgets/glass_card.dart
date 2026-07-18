import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Frosted-glass container used for premium card surfaces.
class GlassCard extends StatelessWidget {
  /// Creates a glassmorphism card around [child].
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
  });

  /// Content displayed inside the glass surface.
  final Widget child;

  /// Inner padding around [child].
  final EdgeInsetsGeometry padding;

  /// Optional override for the card corner radius.
  final BorderRadius? borderRadius;

  static bool get _skipBlur {
    // BackdropFilter is expensive and can stall widget tests on Windows.
    try {
      final name = WidgetsBinding.instance.runtimeType.toString();
      return name.contains('TestWidgetsFlutterBinding') ||
          name.contains('AutomatedTestWidgetsFlutterBinding');
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ??
        BorderRadius.circular(AppConstants.glassCardRadius);

    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.05),
                ]
              : [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.28),
                ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    return ClipRRect(
      borderRadius: radius,
      child: _skipBlur
          ? content
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: content,
            ),
    );
  }
}
