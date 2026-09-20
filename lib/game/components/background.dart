import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../pickleball_game.dart';

/// 2D Pixel-Art Pickleball Court Background Component
///
/// Features an authentic orthogonal 2D retro arcade court matching the
/// character sprites, un-aliased pixelated white lines, pixelated net,
/// and responsive apron extension that fills any screen aspect ratio with zero black bars.
class Background extends SpriteComponent with HasGameReference<PickleballGame> {
  Color _apronColor = const Color(0xFFB90225);
  Color _apronOuterColor = const Color(0xFF7A0114);
  Color _courtColor = const Color(0xFF1D4ED8);
  Color _kitchenColor = const Color(0xFF047857);

  Color get apronOuterColor => _apronOuterColor;

  // 2D Court geometry constants matching gameplay coordinates (Portrait 480x620)
  static const double courtLeftX = 400.0;
  static const double courtRightX = 880.0;
  static const double courtCenterX = 640.0;
  static const double courtTopY = 50.0;
  static const double courtBottomY = 670.0;
  static const double netY = 360.0;
  static const double kitchenTopY = 280.0;
  static const double kitchenBottomY = 440.0;

  Background() {
    size = Vector2(1280, 720);
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    position = Vector2(1280 / 2, 720 / 2);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    try {
      sprite = await game.loadSprite('background reworked/pickleball-court.png');
    } catch (_) {
      try {
        sprite = await game.loadSprite('background/pickleball_court.png');
      } catch (e) {
        debugPrint('Court sprite fallback load error: $e');
      }
    }
    size = Vector2(1280, 720);
    
    // Disable anti-aliasing for authentic retro arcade pixel art
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;

    updateTheme(game.settings?.courtTheme ?? 'Classic Red');
    
    // Position it at the center of the 1280x720 logical screen
    position = Vector2(1280 / 2, 720 / 2);
    anchor = Anchor.center;
  }

  void updateTheme(String theme) {
    if (theme == 'Electric Blue') {
      paint.colorFilter = const ColorFilter.mode(Color(0x3800E5FF), BlendMode.color);
      _apronColor = const Color(0xFF0E2A3A);
      _apronOuterColor = const Color(0xFF05121B);
      _courtColor = const Color(0xFF0369A1);
      _kitchenColor = const Color(0xFF0F172A);
    } else if (theme == 'Sunset Clay') {
      paint.colorFilter = const ColorFilter.mode(Color(0x38FF5722), BlendMode.color);
      _apronColor = const Color(0xFF381C16);
      _apronOuterColor = const Color(0xFF1C0A06);
      _courtColor = const Color(0xFF9A3412);
      _kitchenColor = const Color(0xFF78350F);
    } else if (theme == 'Neon Night') {
      paint.colorFilter = const ColorFilter.mode(Color(0x409C27B0), BlendMode.color);
      _apronColor = const Color(0xFF221133);
      _apronOuterColor = const Color(0xFF0D0516);
      _courtColor = const Color(0xFF581C87);
      _kitchenColor = const Color(0xFF701A75);
    } else {
      paint.colorFilter = null;
      _apronColor = const Color(0xFFB90225);
      _apronOuterColor = const Color(0xFF7A0114);
      _courtColor = const Color(0xFF1D4ED8);
      _kitchenColor = const Color(0xFF047857);
    }
  }

  @override
  void render(Canvas canvas) {
    // 1. Fill the entire visible area with the stadium floor gradient so there are no black bars
    final zoom = game.camera.viewfinder.zoom;
    final viewWidth = (zoom > 0 && game.size.x > 0)
        ? math.max(1280.0, game.size.x / zoom + 300.0)
        : 2000.0;
    final viewHeight = (zoom > 0 && game.size.y > 0)
        ? math.max(720.0, game.size.y / zoom + 300.0)
        : 1200.0;

    final floorRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: viewWidth,
      height: viewHeight,
    );

    final floorPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: [_apronColor, _apronOuterColor],
      ).createShader(floorRect);
    canvas.drawRect(floorRect, floorPaint);

    // 2. Render 2D pixel-art court sprite if loaded
    if (sprite != null) {
      super.render(canvas);
    } else {
      // Procedural 2D pixel-art court fallback
      _renderProceduralPixelCourt(canvas);
    }
  }

  void _renderProceduralPixelCourt(Canvas canvas) {
    // 1. Court drop shadow
    final shadowPaint = Paint()..color = Colors.black45;
    canvas.drawRect(
      const Rect.fromLTRB(courtLeftX - 6, courtTopY - 6, courtRightX + 6, courtBottomY + 6),
      shadowPaint,
    );

    // 2. Main 2D Court Surface (Service courts)
    final courtPaint = Paint()..color = _courtColor;
    canvas.drawRect(
      const Rect.fromLTRB(courtLeftX, courtTopY, courtRightX, courtBottomY),
      courtPaint,
    );

    // 3. Non-Volley Zone (The Kitchen)
    final kitchenPaint = Paint()..color = _kitchenColor;
    canvas.drawRect(
      const Rect.fromLTRB(courtLeftX, kitchenTopY, courtRightX, kitchenBottomY),
      kitchenPaint,
    );

    // 4. White Boundary Lines (4px pixel-styled un-aliased)
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..isAntiAlias = false;

    // Outer boundary (sidelines & baselines)
    canvas.drawRect(
      const Rect.fromLTRB(courtLeftX, courtTopY, courtRightX, courtBottomY),
      linePaint,
    );

    // Kitchen lines
    canvas.drawLine(
      const Offset(courtLeftX, kitchenTopY),
      const Offset(courtRightX, kitchenTopY),
      linePaint,
    );
    canvas.drawLine(
      const Offset(courtLeftX, kitchenBottomY),
      const Offset(courtRightX, kitchenBottomY),
      linePaint,
    );

    // Center service lines
    canvas.drawLine(
      const Offset(courtCenterX, courtTopY),
      const Offset(courtCenterX, kitchenTopY),
      linePaint,
    );
    canvas.drawLine(
      const Offset(courtCenterX, kitchenBottomY),
      const Offset(courtCenterX, courtBottomY),
      linePaint,
    );

    // 5. 2D Pixel Net at netY = 360
    final netShadowPaint = Paint()..color = Colors.black54;
    canvas.drawRect(
      const Rect.fromLTRB(courtLeftX - 30, netY + 3, courtRightX + 30, netY + 8),
      netShadowPaint,
    );

    final netMeshPaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(
      const Offset(courtLeftX - 25, netY),
      const Offset(courtRightX + 25, netY),
      netMeshPaint,
    );

    final netTapePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      const Offset(courtLeftX - 25, netY - 2),
      const Offset(courtRightX + 25, netY - 2),
      netTapePaint,
    );

    // Posts
    final postPaint = Paint()..color = const Color(0xFF64748B);
    canvas.drawRect(
      const Rect.fromLTWH(courtLeftX - 28, netY - 6, 6, 14),
      postPaint,
    );
    canvas.drawRect(
      const Rect.fromLTWH(courtRightX + 22, netY - 6, 6, 14),
      postPaint,
    );

    // 6. Side Arena Player Benches
    final benchWoodPaint = Paint()..color = const Color(0xFFD97706);
    final benchFramePaint = Paint()..color = const Color(0xFF334155);
    final benchShadowPaint = Paint()..color = Colors.black38;

    for (final bx in [230.0, 940.0]) {
      for (final by in [110.0, 530.0]) {
        // Shadow
        canvas.drawRect(Rect.fromLTWH(bx + 4, by + 28, 110, 6), benchShadowPaint);
        // Frame
        canvas.drawRect(Rect.fromLTWH(bx + 8, by + 4, 6, 28), benchFramePaint);
        canvas.drawRect(Rect.fromLTWH(bx + 96, by + 4, 6, 28), benchFramePaint);
        // Slats
        canvas.drawRect(Rect.fromLTWH(bx, by, 110, 8), benchWoodPaint);
        canvas.drawRect(Rect.fromLTWH(bx, by + 10, 110, 8), benchWoodPaint);
        canvas.drawRect(Rect.fromLTWH(bx, by + 20, 110, 8), benchWoodPaint);
      }
    }

    // 7. Referee Chair at Net (Left flank)
    const refX = 285.0;
    const refY = 315.0;
    canvas.drawRect(const Rect.fromLTWH(refX + 2, refY + 68, 40, 8), benchShadowPaint);
    final ladderPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(refX + 6, refY + 20), const Offset(refX + 2, refY + 70), ladderPaint);
    canvas.drawLine(const Offset(refX + 34, refY + 20), const Offset(refX + 38, refY + 70), ladderPaint);
    for (double ry = refY + 26; ry <= refY + 68; ry += 10) {
      canvas.drawLine(Offset(refX + 5, ry), Offset(refX + 35, ry), ladderPaint);
    }
    // Red Seat
    canvas.drawRect(const Rect.fromLTWH(refX + 8, refY + 8, 24, 12), Paint()..color = const Color(0xFFDC2626));
    // Canopy
    canvas.drawRect(const Rect.fromLTWH(refX - 6, refY - 26, 52, 8), Paint()..color = const Color(0xFFDC2626));
  }
}
