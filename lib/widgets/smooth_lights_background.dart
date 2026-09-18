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

class _SmoothLightsAlphabetBackgroundState
    extends State<SmoothLightsAlphabetBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FloatingLetter> _letters;
  late List<_GlowingOrb> _orbs;

  // The alphabet letters to float
  static const List<String> _alphabetPool = [
    'P', 'I', 'C', 'K', 'L', 'E', 'B', 'A', 'L', 'L',
    'S', 'M', 'A', 'S', 'H',
    'A', 'C', 'E', 'N', 'E', 'T', 'W', 'I', 'N',
  ];

  static const List<Color> _palette = [
    AppTheme.neonLime,
    AppTheme.electricCyan,
    AppTheme.trophyAmber,
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF38BDF8), // Sky Blue
  ];

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

    // 1. Initialize 22 floating letters
    _letters = List.generate(22, (i) {
      final letter = _alphabetPool[i % _alphabetPool.length];
      final color = _palette[i % _palette.length];
      return _FloatingLetter(
        letter: letter,
        color: color,
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        baseSize: 14.0 + rand.nextDouble() * 22.0,
        speed: (0.015 + rand.nextDouble() * 0.035),
        swayFreq: 1.0 + rand.nextDouble() * 2.0,
        swayAmp: 0.02 + rand.nextDouble() * 0.04,
        rotationSpeed: (rand.nextDouble() - 0.5) * 1.2,
        opacity: 0.07 + rand.nextDouble() * 0.12,
        phase: rand.nextDouble() * math.pi * 2,
      );
    });

    // 2. Initialize 5 smooth glowing orbs
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
              letters: _letters,
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

class _FloatingLetter {
  final String letter;
  final Color color;
  final double x;
  final double y;
  final double baseSize;
  final double speed;
  final double swayFreq;
  final double swayAmp;
  final double rotationSpeed;
  final double opacity;
  final double phase;

  const _FloatingLetter({
    required this.letter,
    required this.color,
    required this.x,
    required this.y,
    required this.baseSize,
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
  final List<_FloatingLetter> letters;
  final List<_GlowingOrb> orbs;
  final Color baseColor;

  static final Map<String, TextPainter> _textPainterCache = {};

  _SmoothLightsAlphabetPainter({
    required this.time,
    required this.letters,
    required this.orbs,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Draw Deep Base Background
    final bgPaint = Paint()..color = baseColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Draw Smooth Glowing Orbs (Radial Gradients)
    for (final orb in orbs) {
      final t = time + orb.phase;
      // Gentle lissajous motion
      final dx = (orb.baseX + math.sin(t * orb.speedX * 0.4) * 0.12) * size.width;
      final dy = (orb.baseY + math.cos(t * orb.speedY * 0.4) * 0.12) * size.height;
      // Pulsing radius
      final currentRadius = orb.radius * (0.85 + math.sin(t * 0.8) * 0.15);

      final orbPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color,
            orb.color.withValues(alpha: orb.color.a * 0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: currentRadius));

      canvas.drawCircle(Offset(dx, dy), currentRadius, orbPaint);
    }

    // 3. Draw Subtle Grid Lines for 2D Gaming Aesthetic
    _drawRetroGrid(canvas, size);

    // 4. Draw Floating Alphabet Letters
    for (final fl in letters) {
      final localTime = time * fl.speed;
      // Upward drift with wrap
      final currentY = (fl.y - localTime) % 1.0;
      final yPos = (currentY < 0 ? 1.0 + currentY : currentY) * size.height;

      // Horizontal sinusoidal sway
      final xOffset = math.sin(fl.phase + time * fl.swayFreq * 0.3) * fl.swayAmp * size.width;
      final xPos = (fl.x * size.width + xOffset) % size.width;

      // Rotation
      final angle = math.sin(fl.phase + time * fl.rotationSpeed * 0.4) * 0.25;

      // Draw Letter
      canvas.save();
      canvas.translate(xPos, yPos);
      canvas.rotate(angle);

      final key = '${fl.letter}_${fl.color.toARGB32()}_${fl.baseSize.toInt()}';
      TextPainter? tp = _textPainterCache[key];
      if (tp == null) {
        tp = TextPainter(
          text: TextSpan(
            text: fl.letter,
            style: TextStyle(
              color: fl.color.withValues(alpha: fl.opacity),
              fontSize: fl.baseSize,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              shadows: [
                Shadow(
                  color: fl.color.withValues(alpha: fl.opacity * 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        if (_textPainterCache.length < 60) {
          _textPainterCache[key] = tp;
        }
      }

      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  void _drawRetroGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1.0;

    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothLightsAlphabetPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
