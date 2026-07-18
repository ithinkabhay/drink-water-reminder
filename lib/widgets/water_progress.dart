import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Animated circular progress with a water-wave fill.
class WaterProgress extends StatefulWidget {
  /// Creates a progress ring for the given [progress] (0.0 – 1.0).
  const WaterProgress({
    super.key,
    required this.progress,
  });

  /// Fraction of the daily goal completed, clamped between 0.0 and 1.0.
  final double progress;

  @override
  State<WaterProgress> createState() => _WaterProgressState();
}

class _WaterProgressState extends State<WaterProgress>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward();
  }

  @override
  void didUpdateWidget(covariant WaterProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
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
    final size = AppConstants.progressSize;

    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _progressController]),
      builder: (context, _) {
        final progress = _progressAnimation.value.clamp(0.0, 1.0);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _WaterRingPainter(
                  progress: progress,
                  wavePhase: _waveController.value * 2 * math.pi,
                  primary: colorScheme.primary,
                  track: colorScheme.primary.withValues(alpha: 0.18),
                  fillTop: colorScheme.primary.withValues(alpha: 0.55),
                  fillBottom: colorScheme.primary.withValues(alpha: 0.85),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(progress * 100).round()}%',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'hydrated',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Draws the ring track, progress arc, and animated water fill.
class _WaterRingPainter extends CustomPainter {
  _WaterRingPainter({
    required this.progress,
    required this.wavePhase,
    required this.primary,
    required this.track,
    required this.fillTop,
    required this.fillBottom,
  });

  final double progress;
  final double wavePhase;
  final Color primary;
  final Color track;
  final Color fillTop;
  final Color fillBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = AppConstants.progressStrokeWidth;
    final radius = (size.shortestSide - stroke) / 2;
    final fillRadius = radius - stroke * 0.55;

    // Soft outer glow.
    final glowPaint = Paint()
      ..color = primary.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, radius + 6, glowPaint);

    // Track ring.
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Water fill clipped to inner circle.
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: fillRadius));
    canvas.save();
    canvas.clipPath(clipPath);

    final waterLevel = size.height * (1 - progress);
    final wavePath = _buildWavePath(size, waterLevel, wavePhase, amplitude: 7);
    final wavePath2 = _buildWavePath(
      size,
      waterLevel + 4,
      wavePhase + math.pi * 0.7,
      amplitude: 5,
    );

    final fillRect = Rect.fromLTWH(0, waterLevel - 20, size.width, size.height);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillTop, fillBottom],
      ).createShader(fillRect);

    canvas.drawPath(wavePath2, Paint()..color = fillTop.withValues(alpha: 0.45));
    canvas.drawPath(wavePath, fillPaint);
    canvas.restore();

    // Progress arc.
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
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
  bool shouldRepaint(covariant _WaterRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.primary != primary;
  }
}
