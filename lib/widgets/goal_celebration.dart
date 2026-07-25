import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Lightweight goal-complete celebration overlay (confetti + glow + message).
class GoalCelebration extends StatefulWidget {
  /// Creates a celebration overlay.
  const GoalCelebration({
    super.key,
    required this.visible,
    this.message = 'Daily Goal Completed',
    this.onDismissed,
  });

  /// Whether the overlay is shown.
  final bool visible;

  /// Celebration message.
  final String message;

  /// Called after the celebration auto-hides.
  final VoidCallback? onDismissed;

  @override
  State<GoalCelebration> createState() => _GoalCelebrationState();
}

class _GoalCelebrationState extends State<GoalCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.visible) {
      _play();
    }
  }

  @override
  void didUpdateWidget(covariant GoalCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _play();
    } else if (!widget.visible && oldWidget.visible) {
      _controller.reset();
    }
  }

  Future<void> _play() async {
    HapticFeedback.mediumImpact();
    await _controller.forward(from: 0);
    if (!mounted) return;
    widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && !_controller.isAnimating) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final fade = _controller.value < 0.15
              ? Curves.easeOut.transform(_controller.value / 0.15)
              : _controller.value > 0.75
                  ? (1 - ((_controller.value - 0.75) / 0.25)).clamp(0.0, 1.0)
                  : 1.0;
          final scale = 0.92 +
              0.08 * Curves.easeOutBack.transform(
                (_controller.value / 0.35).clamp(0.0, 1.0),
              );

          return Opacity(
            opacity: fade,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _ConfettiPainter(progress: _controller.value),
                ),
                Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.16),
                        borderRadius: AppRadius.largeAll,
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.28),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.success,
                            size: 36,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.message,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
    ];

    for (var i = 0; i < 28; i++) {
      final seedX = ((i * 37) % 100) / 100.0;
      final seedY = ((i * 53) % 100) / 100.0;
      final drift = math.sin(progress * math.pi * 2 + i) * 18;
      final x = size.width * seedX + drift;
      final y = size.height * 0.15 +
          (size.height * 0.55) * Curves.easeIn.transform(progress) * seedY;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(
          alpha: (1 - progress * 0.85).clamp(0.0, 1.0),
        );
      final w = 4.0 + (i % 3) * 2;
      final h = 8.0 + (i % 2) * 3;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * 2 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
