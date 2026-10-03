import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../pickleball_game.dart';

/// An authentic 2D arcade cabinet push-button component.
/// Features a dark casing ring, 3D bottom bevel extrusion, vibrant arcade face,
/// glossy highlight arc, and a centered pixelated 2D arcade paddle sprite.
/// When pressed, the face and paddle translate downward to compress the bevel.
/// Features dynamic shockwave ripples and starburst sparks upon being tapped.
class ArcadeButtonFaceComponent extends PositionComponent {
  double radius;
  double opacity;
  final bool isPressed;
  Color faceColor;
  Color bevelColor;
  Color casingColor;
  Sprite? paddleSprite;
  PickleballGame? game;

  /// Progress of tap burst effect: 1.0 (just tapped) -> 0.0 (idle)
  double tapEffectProgress = 0.0;

  // Reusable cached paints for zero-allocation rendering
  final Paint _pulsePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3.0;
  final Paint _ripplePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _sparkPaint = Paint()..style = PaintingStyle.fill;
  final Paint _casingPaint = Paint()..style = PaintingStyle.fill;
  final Paint _bevelPaint = Paint()..style = PaintingStyle.fill;
  final Paint _facePaint = Paint()..style = PaintingStyle.fill;
  final Paint _rimPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5;
  final Paint _flashPaint = Paint()..style = PaintingStyle.fill;
  final Paint _glossPaint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
  final Paint _spritePaint = Paint();

  ArcadeButtonFaceComponent({
    required this.radius,
    required this.opacity,
    required this.isPressed,
    this.faceColor = const Color(0xFFFF2D55),
    this.bevelColor = const Color(0xFFB71C1C),
    this.casingColor = const Color(0xFF0B0F19),
    this.paddleSprite,
    this.game,
  }) : super(
          size: Vector2(radius * 2 + 8, radius * 2 + 16),
          anchor: Anchor.center,
        );

  /// Mutates properties in-place without component recreation
  void updateProperties({
    required double radius,
    required double opacity,
    Color? faceColor,
    Color? bevelColor,
    Color? casingColor,
    Sprite? paddleSprite,
  }) {
    this.radius = radius;
    this.opacity = opacity.clamp(0.1, 1.0);
    if (faceColor != null) this.faceColor = faceColor;
    if (bevelColor != null) this.bevelColor = bevelColor;
    if (casingColor != null) this.casingColor = casingColor;
    if (paddleSprite != null) this.paddleSprite = paddleSprite;
    size = Vector2(radius * 2 + 8, radius * 2 + 16);
  }

  /// Triggers the dynamic arcade shockwave & spark explosion
  void triggerTapEffect() {
    tapEffectProgress = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (tapEffectProgress > 0.0) {
      tapEffectProgress = math.max(0.0, tapEffectProgress - dt * 4.0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final cx = size.x / 2;
    final cy = (size.y - 6) / 2;
    final bevelHeight = 6.0 * (radius / 40.0);
    final pressY = isPressed ? (bevelHeight - 1.5) : 0.0;
    final currentBevel = isPressed ? 1.5 : bevelHeight;

    final alphaVal = (opacity * 255).round().clamp(0, 255);

    // Check if waiting for serve to render an active ready glow
    final isServingPrompt = (game?.isWaitingForServe ?? false) && (game?.isHumanServer ?? false);

    // 0. Optional Serve Pulse Glow
    if (isServingPrompt && !isPressed) {
      final pulseRadius = radius + 5.0 + math.sin((game?.elapsedTime ?? 0.0) * 8) * 3.0;
      _pulsePaint.color = const Color(0xFFCCFF00).withAlpha((alphaVal * 0.45).round());
      canvas.drawCircle(Offset(cx, cy), pulseRadius, _pulsePaint);
    }

    // Dynamic Tap Explosion & Ripple Effects
    if (tapEffectProgress > 0.0) {
      // 1. Expanding Shockwave Ring
      final expandDist = (1.0 - tapEffectProgress) * 34.0;
      final rippleRadius = radius + 4.0 + expandDist;
      _ripplePaint
        ..color = const Color(0xFF00E5FF).withAlpha((alphaVal * tapEffectProgress * 0.9).round())
        ..strokeWidth = 3.5 * tapEffectProgress;
      canvas.drawCircle(Offset(cx, cy), rippleRadius, _ripplePaint);

      // 2. Starburst Energy Sparks
      for (int i = 0; i < 8; i++) {
        final angle = (i * math.pi / 4) + (1.0 - tapEffectProgress) * 0.45;
        final dist = radius + 8.0 + (1.0 - tapEffectProgress) * 26.0;
        final sx = cx + math.cos(angle) * dist;
        final sy = cy + math.sin(angle) * dist;
        final sparkColor = (i % 2 == 0) ? const Color(0xFFCCFF00) : const Color(0xFFFF3D00);
        _sparkPaint.color = sparkColor.withAlpha((alphaVal * tapEffectProgress).round());
        canvas.drawCircle(Offset(sx, sy), 3.5 * tapEffectProgress, _sparkPaint);
      }
    }

    // 1. Dark Arcade Housing Casing
    _casingPaint.color = casingColor.withAlpha((alphaVal * 0.95).round());
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + (bevelHeight / 2)),
        width: (radius + 3.0) * 2,
        height: (radius + 2.5) * 2 + bevelHeight,
      ),
      _casingPaint,
    );

    // 2. 3D Bottom Bevel Extrusion (Optimized 3-pass cylinder)
    final effectiveBevelColor = isPressed
        ? const Color(0xFF880E0E)
        : bevelColor;
    _bevelPaint.color = effectiveBevelColor.withAlpha(alphaVal);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + currentBevel),
        width: radius * 2,
        height: radius * 2,
      ),
      _bevelPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(cx - radius, cy, cx + radius, cy + currentBevel),
      _bevelPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: radius * 2,
        height: radius * 2,
      ),
      _bevelPaint,
    );

    // 3. Top Button Face
    final faceY = cy - (bevelHeight / 2) + pressY;
    final effectiveFaceColor = isPressed
        ? Color.lerp(faceColor, Colors.black, 0.22)!
        : faceColor;
    _facePaint.color = effectiveFaceColor.withAlpha(alphaVal);
    canvas.drawCircle(Offset(cx, faceY), radius, _facePaint);

    // Subtle dark inner edge rim for 2D depth
    _rimPaint.color = Colors.black.withAlpha((alphaVal * 0.4).round());
    canvas.drawCircle(Offset(cx, faceY), radius - 0.75, _rimPaint);

    // Tap Flash Highlight on Face
    if (tapEffectProgress > 0.0) {
      _flashPaint.color = Colors.white.withAlpha((alphaVal * tapEffectProgress * 0.55).round());
      canvas.drawCircle(Offset(cx, faceY), radius - 1, _flashPaint);
    }

    // 4. Glossy Top Highlight Arc
    if (!isPressed) {
      _glossPaint
        ..color = Colors.white.withAlpha((alphaVal * 0.45).round())
        ..strokeWidth = 2.5 * (radius / 40.0);

      final glossRect = Rect.fromCircle(
        center: Offset(cx, faceY),
        radius: radius - 3.5,
      );
      canvas.drawArc(glossRect, -math.pi * 0.85, math.pi * 0.7, false, _glossPaint);
    }

    // 5. Centered Pixelated 2D Arcade Paddle Sprite
    final paddleSize = radius * 1.28;
    final paddlePos = Vector2(cx - (paddleSize / 2), faceY - (paddleSize / 2));

    if (paddleSprite != null) {
      _spritePaint.color = Colors.white.withAlpha(alphaVal);
      paddleSprite!.render(
        canvas,
        position: paddlePos,
        size: Vector2(paddleSize, paddleSize),
        overridePaint: _spritePaint,
      );
    } else {
      // Fallback 2D arcade pixelated paddle rendering (for unit tests / initial load)
      _renderFallbackPaddle(canvas, Offset(cx, faceY), radius * 0.62, alphaVal);
    }

    // 6. Action Tag: Always the authentic single SMASH button
    const actionText = 'SMASH';
    final textPainter = TextPainter(
      text: TextSpan(
        text: actionText,
        style: TextStyle(
          color: isServingPrompt
              ? const Color(0xFFCCFF00).withAlpha(alphaVal)
              : Colors.white.withAlpha((alphaVal * 0.9).round()),
          fontSize: (radius * 0.22).clamp(8.0, 13.0),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha((alphaVal * 0.8).round()),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(cx - (textPainter.width / 2), faceY + (radius * 0.45)),
    );
  }

  void _renderFallbackPaddle(Canvas canvas, Offset center, double size, int alpha) {
    final paddlePaint = Paint()
      ..color = const Color(0xFF10141E).withAlpha(alpha)
      ..style = PaintingStyle.fill;
    final highlightPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final gripPaint = Paint()
      ..color = Colors.white.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 4);

    // Paddle face
    final rect = Rect.fromCenter(center: Offset(0, -size * 0.25), width: size * 0.85, height: size * 1.1);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size * 0.25));
    canvas.drawRRect(rrect, paddlePaint);
    canvas.drawRRect(rrect, highlightPaint);

    // Handle
    final handleRect = Rect.fromCenter(center: Offset(0, size * 0.55), width: size * 0.25, height: size * 0.6);
    canvas.drawRect(handleRect, paddlePaint);
    canvas.drawLine(Offset(-size * 0.1, size * 0.4), Offset(size * 0.1, size * 0.4), gripPaint);
    canvas.drawLine(Offset(-size * 0.1, size * 0.6), Offset(size * 0.1, size * 0.6), gripPaint);

    canvas.restore();
  }
}
