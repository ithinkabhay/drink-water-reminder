import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/constants.dart';

/// Premium animated hydration circle: gradient stroke, glow, counted numbers.
class HydrationCircle extends StatefulWidget {
  /// Creates the hydration hero circle.
  const HydrationCircle({
    super.key,
    required this.progress,
    required this.consumedMl,
    required this.goalMl,
    required this.remainingMl,
    this.size,
  });

  /// Fraction of the daily goal completed (0.0 – 1.0).
  final double progress;

  /// Milliliters logged today.
  final int consumedMl;

  /// Daily goal in milliliters.
  final int goalMl;

  /// Milliliters still needed to hit the goal.
  final int remainingMl;

  /// Optional diameter override for responsive layouts.
  final double? size;

  @override
  State<HydrationCircle> createState() => _HydrationCircleState();
}

class _HydrationCircleState extends State<HydrationCircle>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late Animation<int> _consumedAnimation;

  bool get _inTest {
    final binding = WidgetsBinding.instance.runtimeType.toString();
    return binding.contains('TestWidgetsFlutterBinding') ||
        Platform.environment.containsKey('FLUTTER_TEST');
  }

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (!_inTest) {
      _waveController.repeat();
    }

    _progressController = AnimationController(
      vsync: this,
      duration: AppConstants.animNormal,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _consumedAnimation = IntTween(
      begin: 0,
      end: widget.consumedMl,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    if (_inTest) {
      _progressController.value = 1;
    } else {
      _progressController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant HydrationCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress ||
        oldWidget.consumedMl != widget.consumedMl) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeOutCubic,
        ),
      );
      _consumedAnimation = IntTween(
        begin: _consumedAnimation.value,
        end: widget.consumedMl,
      ).animate(
        CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeOutCubic,
        ),
      );
      _progressController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = widget.size ?? AppConstants.progressSize;
    final complete = widget.progress >= 1.0;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _progressController]),
        builder: (context, _) {
          final progress = _progressAnimation.value.clamp(0.0, 1.0);
          final percent = (progress * 100).round();
          final displayConsumed = _consumedAnimation.value;

          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft glow behind the ring.
                Container(
                  width: size * 0.88,
                  height: size * 0.88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (complete
                                ? AppColors.success
                                : colorScheme.primary)
                            .withValues(alpha: 0.22),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                CustomPaint(
                  size: Size.square(size),
                  painter: _HydrationRingPainter(
                    progress: progress,
                    wavePhase: _waveController.value * 2 * math.pi,
                    primary: complete
                        ? AppColors.success
                        : colorScheme.primary,
                    accent: colorScheme.secondary,
                    track: colorScheme.primary.withValues(alpha: 0.14),
                    fillTop: colorScheme.primary.withValues(alpha: 0.32),
                    fillBottom: colorScheme.primary.withValues(alpha: 0.72),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size * 0.14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$displayConsumed ml',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'of ${widget.goalMl} ml',
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.remainingMl == 0
                            ? 'Goal reached'
                            : '${widget.remainingMl} ml left',
                        style: textTheme.bodySmall?.copyWith(
                          color: complete
                              ? AppColors.success
                              : colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

/// Compatibility alias for older imports.
typedef WaterProgress = HydrationCircle;

class _HydrationRingPainter extends CustomPainter {
  _HydrationRingPainter({
    required this.progress,
    required this.wavePhase,
    required this.primary,
    required this.accent,
    required this.track,
    required this.fillTop,
    required this.fillBottom,
  });

  final double progress;
  final double wavePhase;
  final Color primary;
  final Color accent;
  final Color track;
  final Color fillTop;
  final Color fillBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = AppConstants.progressStrokeWidth;
    final radius = (size.shortestSide - stroke) / 2;
    final fillRadius = radius - stroke * 0.55;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: fillRadius));
    canvas.save();
    canvas.clipPath(clipPath);

    final waterLevel = size.height * (1 - progress);
    final wavePath = _buildWavePath(size, waterLevel, wavePhase, amplitude: 6);
    final wavePath2 = _buildWavePath(
      size,
      waterLevel + 4,
      wavePhase + math.pi * 0.7,
      amplitude: 4,
    );

    final fillRect = Rect.fromLTWH(0, waterLevel - 20, size.width, size.height);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillTop, fillBottom],
      ).createShader(fillRect);

    canvas.drawPath(
      wavePath2,
      Paint()..color = fillTop.withValues(alpha: 0.4),
    );
    canvas.drawPath(wavePath, fillPaint);
    canvas.restore();

    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final sweep = 2 * math.pi * progress;
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
        colors: [accent, primary, primary],
        stops: const [0.0, 0.55, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      );

      final arcPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);

      // Soft tip glow.
      final tipAngle = -math.pi / 2 + sweep;
      final tip = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );
      canvas.drawCircle(
        tip,
        stroke * 0.35,
        Paint()
          ..color = primary.withValues(alpha: 0.9)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
      );
    }
  }

  Path _buildWavePath(
    Size size,
    double waterLevel,
    double phase, {
    required double amplitude,
  }) {
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, waterLevel);

    const waves = 2.0;
    for (double x = 0; x <= size.width; x += 1) {
      final normalized = x / size.width;
      final y = waterLevel +
          math.sin((normalized * waves * 2 * math.pi) + phase) * amplitude;
      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HydrationRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.primary != primary ||
        oldDelegate.accent != accent;
  }
}
