import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// An ambient, performant background featuring smooth glowing lights and
/// gently floating alphabet letters in a 2D gaming style.
class SmoothLightsAlphabetBackground extends StatefulWidget {
  final Widget? child;
  final bool animate;
  final bool forceAnimateInTests;
  final double speedMultiplier;
  final Color baseColor;

  const SmoothLightsAlphabetBackground({
    super.key,
    this.child,
    this.animate = true,
    this.forceAnimateInTests = false,
    this.speedMultiplier = 1.0,
    this.baseColor = const Color(0xFF0A0F1D),
  });

  @override
  State<SmoothLightsAlphabetBackground> createState() =>
      _SmoothLightsAlphabetBackgroundState();
}

typedef SmoothLightsBallBackground = SmoothLightsAlphabetBackground;

class _SmoothLightsAlphabetBackgroundState
    extends State<SmoothLightsAlphabetBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FloatingBall> _balls;
  late List<_GlowingOrb> _orbs;

  bool get _shouldAnimate {
    if (!widget.animate) return false;
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    return !isTesting || widget.forceAnimateInTests;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _initFloatingElements();

    if (_shouldAnimate) {
      _controller.repeat();
    }
  }

  void _initFloatingElements() {
    final rand = math.Random(42); // deterministic seed for test consistency

    // 1. Initialize floating pickleballs that smoothly shift RGB colors
    _balls = List.generate(24, (i) {
      return _FloatingBall(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        radius: 10.0 + rand.nextDouble() * 16.0,
        baseHue: (i * (360.0 / 24.0)) % 360.0,
        hueCycleSpeed: 18.0 + rand.nextDouble() * 26.0,
        saturation: 0.88 + rand.nextDouble() * 0.12,
        speed: 0.015 + rand.nextDouble() * 0.035,
        swayFreq: 0.8 + rand.nextDouble() * 1.8,
        swayAmp: 0.02 + rand.nextDouble() * 0.04,
        rotationSpeed: (rand.nextDouble() - 0.5) * 1.4,
        opacity: 0.22 + rand.nextDouble() * 0.28,
        phase: rand.nextDouble() * math.pi * 2,
      );
    });

    // 2. Initialize 5 smooth glowing ambient orbs
    _orbs = [
      _GlowingOrb(
        baseX: 0.2,
        baseY: 0.25,
        radius: 180,
        color: AppTheme.electricCyan.withValues(alpha: 0.14),
        speedX: 0.7,
        speedY: 0.5,
        phase: 0.0,
      ),
      _GlowingOrb(
        baseX: 0.8,
        baseY: 0.35,
        radius: 220,
        color: AppTheme.neonLime.withValues(alpha: 0.12),
        speedX: 0.5,
        speedY: 0.8,
        phase: 1.5,
      ),
      _GlowingOrb(
        baseX: 0.3,
        baseY: 0.75,
        radius: 200,
        color: AppTheme.trophyAmber.withValues(alpha: 0.11),
        speedX: 0.6,
        speedY: 0.6,
        phase: 3.0,
      ),
      _GlowingOrb(
        baseX: 0.7,
        baseY: 0.8,
        radius: 190,
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
        speedX: 0.8,
        speedY: 0.4,
        phase: 4.5,
      ),
      _GlowingOrb(
        baseX: 0.5,
        baseY: 0.5,
        radius: 250,
        color: AppTheme.electricCyan.withValues(alpha: 0.08),
        speedX: 0.4,
        speedY: 0.7,
        phase: 2.2,
      ),
    ];
  }

  @override
  void didUpdateWidget(covariant SmoothLightsAlphabetBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundCanvas = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SmoothLightsAlphabetPainter(
              time: _controller.value * 20.0 * widget.speedMultiplier,
              balls: _balls,
              orbs: _orbs,
              baseColor: widget.baseColor,
            ),
            isComplex: true,
            willChange: widget.animate,
            size: Size.infinite,
          );
        },
      ),
    );

    if (widget.child == null) {
      return backgroundCanvas;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        backgroundCanvas,
        widget.child!,
      ],
    );
  }
}

class _FloatingBall {
  final double x;
  final double y;
  final double radius;
  final double baseHue;
  final double hueCycleSpeed;
  final double saturation;
  final double speed;
  final double swayFreq;
  final double swayAmp;
  final double rotationSpeed;
  final double opacity;
  final double phase;

  const _FloatingBall({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseHue,
    required this.hueCycleSpeed,
    required this.saturation,
    required this.speed,
    required this.swayFreq,
    required this.swayAmp,
    required this.rotationSpeed,
    required this.opacity,
    required this.phase,
  });
}

class _GlowingOrb {
  final double baseX;
  final double baseY;
  final double radius;
  final Color color;
  final double speedX;
  final double speedY;
  final double phase;

  const _GlowingOrb({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.color,
    required this.speedX,
    required this.speedY,
    required this.phase,
  });
}

class _SmoothLightsAlphabetPainter extends CustomPainter {
  final double time;
  final List<_FloatingBall> balls;
  final List<_GlowingOrb> orbs;
  final Color baseColor;

  static final Paint _bgPaint = Paint();
  static final Paint _orbPaint = Paint();
  static final Paint _gridPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.02)
    ..strokeWidth = 1.0;
  static final Paint _glowPaint = Paint();
  static final Paint _ballPaint = Paint();
  static final Paint _holePaint = Paint();
  static final Paint _seamPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8;

  _SmoothLightsAlphabetPainter({
    required this.time,
    required this.balls,
    required this.orbs,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Draw Deep Base Background
    _bgPaint.color = baseColor;
    canvas.drawRect(Offset.zero & size, _bgPaint);

    // 2. Draw Smooth Glowing Orbs (Radial Gradients)
    for (final orb in orbs) {
      final t = time + orb.phase;
      final dx = (orb.baseX + math.sin(t * orb.speedX * 0.4) * 0.12) * size.width;
      final dy = (orb.baseY + math.cos(t * orb.speedY * 0.4) * 0.12) * size.height;
      final currentRadius = orb.radius * (0.85 + math.sin(t * 0.8) * 0.15);

      _orbPaint.shader = RadialGradient(
        colors: [
          orb.color,
          orb.color.withValues(alpha: orb.color.a * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: currentRadius));

      canvas.drawCircle(Offset(dx, dy), currentRadius, _orbPaint);
    }

    // 3. Draw Subtle Grid Lines for 2D Gaming Aesthetic
    _drawRetroGrid(canvas, size);

    // 4. Draw Floating Pickleballs with Smooth RGB Color Cycling
    for (final fb in balls) {
      final localTime = time * fb.speed;
      final currentY = (fb.y - localTime) % 1.0;
      final yPos = (currentY < 0 ? 1.0 + currentY : currentY) * size.height;

      // Horizontal sinusoidal sway
      final xOffset = math.sin(fb.phase + time * fb.swayFreq * 0.3) * fb.swayAmp * size.width;
      final xPos = (fb.x * size.width + xOffset) % size.width;

      // Smooth RGB Hue Cycle over time
      final currentHue = (fb.baseHue + time * fb.hueCycleSpeed) % 360.0;
      final ballColor = HSVColor.fromAHSV(1.0, currentHue, fb.saturation, 1.0).toColor();
      final highlightColor = HSVColor.fromAHSV(1.0, currentHue, (fb.saturation * 0.35).clamp(0.0, 1.0), 1.0).toColor();
      final shadeColor = HSVColor.fromAHSV(1.0, currentHue, fb.saturation, 0.55).toColor();

      final rad = fb.radius;

      canvas.save();
      canvas.translate(xPos, yPos);

      // Soft ambient outer halo
      _glowPaint.color = ballColor.withValues(alpha: fb.opacity * 0.35);
      canvas.drawCircle(Offset.zero, rad * 1.4, _glowPaint);

      // Spherical 3D shaded ball body
      _ballPaint.shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: [
          highlightColor.withValues(alpha: fb.opacity),
          ballColor.withValues(alpha: fb.opacity),
          shadeColor.withValues(alpha: fb.opacity * 0.9),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: rad));
      canvas.drawCircle(Offset.zero, rad, _ballPaint);

      // Ball rotation & pickleball holes
      final rotAngle = fb.phase + time * fb.rotationSpeed;
      canvas.rotate(rotAngle);

      // Perforated pickleball holes: 6 outer holes in a circle + 1 center hole
      _holePaint.color = Colors.black.withValues(alpha: fb.opacity * 0.45);
      final holeRad = rad * 0.16;
      final ringDist = rad * 0.52;

      for (int h = 0; h < 6; h++) {
        final hAngle = h * (math.pi / 3.0);
        final hx = math.cos(hAngle) * ringDist;
        final hy = math.sin(hAngle) * ringDist;
        canvas.drawCircle(Offset(hx, hy), holeRad, _holePaint);
      }
      canvas.drawCircle(Offset.zero, holeRad, _holePaint);

      // Subtle equatorial seam arc
      _seamPaint.color = Colors.white.withValues(alpha: fb.opacity * 0.28);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: rad * 0.82),
        -math.pi / 4,
        math.pi / 2,
        false,
        _seamPaint,
      );

      canvas.restore();
    }
  }

  void _drawRetroGrid(Canvas canvas, Size size) {
    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothLightsAlphabetPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
