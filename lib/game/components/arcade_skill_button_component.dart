import 'dart:math' as math;
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/input.dart';
import '../../models/battle_technique.dart';
import '../pickleball_game.dart';

/// An authentic 2D arcade skill button for in-game battle techniques.
/// Features a 3D bevel extrusion, technique badge icon, cooldown radial sweep,
/// active primed pulsing aura, and dynamic shockwave explosion on tap.
class ArcadeSkillButtonComponent extends HudMarginComponent with TapCallbacks {
  final BattleTechnique technique;
  late final TechniqueInfo info;
  double radius;
  double opacity;
  PickleballGame? game;
  VoidCallback? onTriggered;

  double cooldownRemaining = 0.0;
  bool isPrimed = false;
  double tapEffectProgress = 0.0;

  ArcadeSkillButtonComponent({
    required this.technique,
    this.radius = 28.0,
    this.opacity = 0.9,
    this.game,
    this.onTriggered,
    EdgeInsets? margin,
    super.position,
  }) : super(
          margin: margin ?? (position == null ? EdgeInsets.zero : null),
          size: Vector2(radius * 2 + 8, radius * 2 + 12),
        ) {
    info = TechniqueCatalog.get(technique);
  }

  void updateProperties({
    required double radius,
    required double opacity,
    EdgeInsets? margin,
  }) {
    this.radius = radius;
    this.opacity = opacity.clamp(0.1, 1.0);
    if (margin != null) {
      this.margin = margin;
    }
    size = Vector2(radius * 2 + 8, radius * 2 + 12);
  }

  void startCooldown() {
    cooldownRemaining = info.cooldownSeconds;
    isPrimed = false;
  }

  void resetCooldown() {
    cooldownRemaining = 0.0;
    isPrimed = false;
  }

  void triggerTapEffect() {
    tapEffectProgress = 1.0;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (cooldownRemaining <= 0.0) {
      triggerTapEffect();
      onTriggered?.call();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (cooldownRemaining > 0.0) {
      cooldownRemaining = math.max(0.0, cooldownRemaining - dt);
    }
    if (tapEffectProgress > 0.0) {
      tapEffectProgress = math.max(0.0, tapEffectProgress - dt * 4.0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final cx = size.x / 2;
    final cy = (size.y - 4) / 2;
    final bevelHeight = 4.0;
    final isReady = cooldownRemaining <= 0.0;
    final alphaVal = (opacity * 255).round().clamp(0, 255);

    // 1. Primed / Ready Pulsing Aura
    if (isReady && isPrimed) {
      final pulse = math.sin((game?.elapsedTime ?? 0.0) * 8.0) * 3.0;
      final auraPaint = Paint()
        ..color = info.glowColor.withAlpha((alphaVal * 0.55).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawCircle(Offset(cx, cy), radius + 5.0 + pulse, auraPaint);
    }

    // 2. Dynamic Tap Explosion & Shockwave
    if (tapEffectProgress > 0.0) {
      final expandDist = (1.0 - tapEffectProgress) * 26.0;
      final ripplePaint = Paint()
        ..color = info.glowColor.withAlpha((alphaVal * tapEffectProgress * 0.85).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * tapEffectProgress;
      canvas.drawCircle(Offset(cx, cy), radius + 4.0 + expandDist, ripplePaint);

      // Starburst sparks
      final sparkPaint = Paint()
        ..color = Colors.white.withAlpha((alphaVal * tapEffectProgress).round())
        ..strokeWidth = 2.0;
      for (int i = 0; i < 6; i++) {
        final angle = (i * math.pi / 3) + ((1.0 - tapEffectProgress) * 0.5);
        final sparkDist = radius + 6.0 + expandDist * 0.8;
        final sx = cx + math.cos(angle) * sparkDist;
        final sy = cy + math.sin(angle) * sparkDist;
        final ex = cx + math.cos(angle) * (sparkDist + 5.0);
        final ey = cy + math.sin(angle) * (sparkDist + 5.0);
        canvas.drawLine(Offset(sx, sy), Offset(ex, ey), sparkPaint);
      }
    }

    // 3. Dark Outer Bevel Casing Ring
    final casingPaint = Paint()
      ..color = const Color(0xFF090D16).withAlpha(alphaVal)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy + 2.0), radius + 3.0, casingPaint);

    // 4. 3D Bevel Extrusion
    final bevelPaint = Paint()
      ..color = isReady
          ? info.bevelColor.withAlpha(alphaVal)
          : const Color(0xFF334155).withAlpha(alphaVal)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + bevelHeight),
        width: radius * 2,
        height: radius * 2,
      ),
      bevelPaint,
    );

    // 5. Button Face Surface
    final facePaint = Paint()
      ..color = isReady
          ? info.buttonColor.withAlpha(alphaVal)
          : const Color(0xFF1E293B).withAlpha(alphaVal)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, facePaint);

    // 6. Top Gloss Highlight Arc
    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha(isReady ? (alphaVal * 0.25).round() : 25)
      ..style = PaintingStyle.fill;
    final highlightPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx, cy - 2.0), radius: radius * 0.85),
        math.pi * 1.1,
        math.pi * 0.8,
      );
    canvas.drawPath(highlightPath, highlightPaint);

    // 7. Icon Badge (⚡ or 🎯)
    final textPainter = TextPainter(
      text: TextSpan(
        text: info.icon,
        style: TextStyle(
          fontSize: radius * 0.85,
          color: isReady ? Colors.white : const Color(0xFF94A3B8),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );

    // 8. Cooldown Overlay & Countdown Text
    if (!isReady) {
      final sweepRatio = (cooldownRemaining / info.cooldownSeconds).clamp(0.0, 1.0);

      // Dark radial sweep overlay
      final cdOverlayPaint = Paint()
        ..color = Colors.black.withAlpha((alphaVal * 0.72).round())
        ..style = PaintingStyle.fill;
      final cdPath = Path()
        ..moveTo(cx, cy)
        ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          -math.pi / 2,
          -2 * math.pi * sweepRatio,
          false,
        )
        ..close();
      canvas.drawPath(cdPath, cdOverlayPaint);

      // Border progress ring
      final ringPaint = Paint()
        ..color = info.glowColor.withAlpha((alphaVal * 0.8).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius - 1.0),
        -math.pi / 2,
        -2 * math.pi * sweepRatio,
        false,
        ringPaint,
      );

      // Countdown seconds text (e.g. 4.2s)
      final timeStr = '${cooldownRemaining.toStringAsFixed(1)}s';
      final timePainter = TextPainter(
        text: TextSpan(
          text: timeStr,
          style: TextStyle(
            fontSize: radius * 0.42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 3),
              Shadow(color: Colors.black, offset: Offset(0, 1)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      timePainter.paint(
        canvas,
        Offset(cx - timePainter.width / 2, cy - timePainter.height / 2),
      );
    }

    // 9. Hotkey badge chip at bottom (K or L)
    final hotkeyPainter = TextPainter(
      text: TextSpan(
        text: info.hotkey,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: isReady ? info.glowColor : const Color(0xFF64748B),
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hotkeyPainter.paint(
      canvas,
      Offset(cx - hotkeyPainter.width / 2, cy + radius - 7),
    );
  }
}

