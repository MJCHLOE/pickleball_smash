import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/court_catalog.dart';
import '../pickleball_game.dart';

/// 2D Pixel-Art Pickleball Court Background Component
///
/// Features an authentic orthogonal 2D retro arcade court matching the
/// character sprites, un-aliased pixelated white lines, pixelated net,
/// and responsive apron extension that fills any screen aspect ratio with zero black bars.
/// Supports 5 distinct pixel court environments:
/// 1. Classic Pro Arena (stadium)
/// 2. Sunset Beach Resort (beach)
/// 3. Neon Cyber Arcade (cyber)
/// 4. Emerald Forest Park (forest)
/// 5. Volcanic Magma Stadium (magma)
class Background extends SpriteComponent with HasGameReference<PickleballGame> {
  CourtInfo _courtInfo;
  CourtInfo get courtInfo => _courtInfo;

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

  Background({String? courtId})
      : _courtInfo = CourtCatalog.getById(courtId ?? 'court_pro_stadium') {
    size = Vector2(1280, 720);
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    position = Vector2(1280 / 2, 720 / 2);
    anchor = Anchor.center;
    _applyCourtColors();
  }

  void applyCourt(String id) {
    _courtInfo = CourtCatalog.getById(id);
    _applyCourtColors();
    if (_courtInfo.environment != CourtEnvironment.stadium) {
      sprite = null;
    }
  }

  void applyCourtInfo(CourtInfo info) {
    _courtInfo = info;
    _applyCourtColors();
    if (_courtInfo.environment != CourtEnvironment.stadium) {
      sprite = null;
    }
  }

  void _applyCourtColors() {
    _apronColor = _courtInfo.apronColor;
    _apronOuterColor = _courtInfo.apronOuterColor;
    _courtColor = _courtInfo.courtColor;
    _kitchenColor = _courtInfo.kitchenColor;
  }

  @override
  Future<void> onLoad() async {
    if (_courtInfo.environment == CourtEnvironment.stadium) {
      try {
        sprite = await game.loadSprite('background reworked/pickleball-court.png');
      } catch (_) {
        try {
          sprite = await game.loadSprite('background/pickleball_court.png');
        } catch (e) {
          debugPrint('Court sprite fallback load error: $e');
        }
      }
    } else {
      sprite = null;
    }

    size = Vector2(1280, 720);
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;

    if (_courtInfo.environment == CourtEnvironment.stadium) {
      updateTheme(game.settings?.courtTheme ?? 'Classic Red');
    } else {
      _applyCourtColors();
    }

    position = Vector2(1280 / 2, 720 / 2);
    anchor = Anchor.center;
  }

  void updateTheme(String theme) {
    if (_courtInfo.environment != CourtEnvironment.stadium) {
      _applyCourtColors();
      return;
    }

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
      _apronColor = _courtInfo.apronColor;
      _apronOuterColor = _courtInfo.apronOuterColor;
      _courtColor = _courtInfo.courtColor;
      _kitchenColor = _courtInfo.kitchenColor;
    }
  }

  @override
  void render(Canvas canvas) {
    // 1. Fill entire visible area with responsive floor gradient (zero black bars)
    double zoom = 1.0;
    double gameW = 1280.0;
    double gameH = 720.0;
    try {
      zoom = game.camera.viewfinder.zoom;
      gameW = game.size.x;
      gameH = game.size.y;
    } catch (_) {}

    final viewWidth = (zoom > 0 && gameW > 0)
        ? math.max(1280.0, gameW / zoom + 300.0)
        : 2000.0;
    final viewHeight = (zoom > 0 && gameH > 0)
        ? math.max(720.0, gameH / zoom + 300.0)
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

    // 2. Render pixel court
    if (sprite != null) {
      super.render(canvas);
    } else {
      _renderProceduralPixelCourt(canvas);
    }
  }

  void _renderProceduralPixelCourt(Canvas canvas) {
    // Environment Pre-court Decorations (Floor layers)
    _renderEnvironmentFloor(canvas);

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

    // 4. White / Custom Boundary Lines (4px pixel-styled un-aliased)
    final linePaint = Paint()
      ..color = _courtInfo.lineColor
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
      ..color = _courtInfo.netMeshColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(
      const Offset(courtLeftX - 25, netY),
      const Offset(courtRightX + 25, netY),
      netMeshPaint,
    );

    final netTapePaint = Paint()
      ..color = _courtInfo.netTapeColor
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

    // 6. Environment Props & Furniture (Benches, boardwalks, trees, fissures)
    _renderEnvironmentProps(canvas);
  }

  /// Draws environment-specific floor patterns under and around the court
  void _renderEnvironmentFloor(Canvas canvas) {
    switch (_courtInfo.environment) {
      case CourtEnvironment.beach:
        // Ocean waves on left and right outer borders
        final wavePaint = Paint()..color = const Color(0x330284C7);
        final foamPaint = Paint()..color = const Color(0x55E0F2FE);
        for (double y = 40; y <= 680; y += 48) {
          // Left water ripples
          canvas.drawOval(Rect.fromLTWH(60, y, 160, 24), wavePaint);
          canvas.drawLine(Offset(80, y + 12), Offset(180, y + 12), foamPaint);
          // Right water ripples
          canvas.drawOval(Rect.fromLTWH(1060, y + 20, 160, 24), wavePaint);
          canvas.drawLine(Offset(1080, y + 32), Offset(1180, y + 32), foamPaint);
        }
        // Wooden boardwalk slats along court sidelines
        final plankPaint = Paint()..color = const Color(0xFFB45309).withValues(alpha: 0.35);
        final plankLine = Paint()..color = const Color(0xFF78350F).withValues(alpha: 0.4)..strokeWidth = 2;
        for (double py = 50; py <= 670; py += 24) {
          canvas.drawRect(Rect.fromLTWH(courtLeftX - 56, py, 48, 20), plankPaint);
          canvas.drawLine(Offset(courtLeftX - 56, py + 20), Offset(courtLeftX - 8, py + 20), plankLine);
          canvas.drawRect(Rect.fromLTWH(courtRightX + 8, py, 48, 20), plankPaint);
          canvas.drawLine(Offset(courtRightX + 8, py + 20), Offset(courtRightX + 56, py + 20), plankLine);
        }
        break;

      case CourtEnvironment.cyber:
        // Synthwave perspective grid lines across apron
        final gridPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.16)
          ..strokeWidth = 1.5;
        // Horizontal scan lines
        for (double y = 40; y <= 680; y += 32) {
          canvas.drawLine(Offset(100, y), Offset(1180, y), gridPaint);
        }
        // Angled perspective rays on apron sides
        for (double x = 120; x <= 360; x += 40) {
          canvas.drawLine(Offset(x, 40), Offset(x - 30, 680), gridPaint);
        }
        for (double x = 920; x <= 1160; x += 40) {
          canvas.drawLine(Offset(x, 40), Offset(x + 30, 680), gridPaint);
        }
        // Glowing neon boundary halo
        final neonHalo = Paint()
          ..color = const Color(0x3300E5FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.0;
        canvas.drawRect(
          const Rect.fromLTRB(courtLeftX - 8, courtTopY - 8, courtRightX + 8, courtBottomY + 8),
          neonHalo,
        );
        break;

      case CourtEnvironment.forest:
        // Mossy cobblestone border around court
        final stonePaint = Paint()..color = const Color(0x4444403C);
        final mossPaint = Paint()..color = const Color(0x3322C55E);
        for (double py = 50; py <= 670; py += 30) {
          canvas.drawRect(Rect.fromLTWH(courtLeftX - 32, py, 26, 26), stonePaint);
          canvas.drawRect(Rect.fromLTWH(courtLeftX - 28, py + 4, 18, 18), mossPaint);
          canvas.drawRect(Rect.fromLTWH(courtRightX + 6, py, 26, 26), stonePaint);
          canvas.drawRect(Rect.fromLTWH(courtRightX + 10, py + 4, 18, 18), mossPaint);
        }
        break;

      case CourtEnvironment.magma:
        // Volcanic glowing magma fissures across the basalt floor
        final lavaCore = Paint()
          ..color = const Color(0xFFFBBF24)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;
        final lavaGlow = Paint()
          ..color = const Color(0x77EA580C)
          ..strokeWidth = 8.0
          ..style = PaintingStyle.stroke;

        void drawFissure(List<Offset> points) {
          final path = Path()..moveTo(points.first.dx, points.first.dy);
          for (int i = 1; i < points.length; i++) {
            path.lineTo(points[i].dx, points[i].dy);
          }
          canvas.drawPath(path, lavaGlow);
          canvas.drawPath(path, lavaCore);
        }

        // Left apron fissures
        drawFissure([
          const Offset(160, 100),
          const Offset(220, 160),
          const Offset(270, 140),
          const Offset(340, 210),
          const Offset(370, 260),
        ]);
        drawFissure([
          const Offset(180, 580),
          const Offset(250, 520),
          const Offset(310, 550),
          const Offset(360, 480),
        ]);
        // Right apron fissures
        drawFissure([
          const Offset(1100, 120),
          const Offset(1040, 180),
          const Offset(980, 160),
          const Offset(910, 230),
        ]);
        drawFissure([
          const Offset(1120, 560),
          const Offset(1050, 500),
          const Offset(990, 540),
          const Offset(920, 470),
        ]);
        break;

      case CourtEnvironment.stadium:
        break;
    }
  }

  /// Draws environment-specific props like player benches, referee chairs, or trees
  void _renderEnvironmentProps(Canvas canvas) {
    final benchWoodPaint = Paint()..color = _courtInfo.benchColor;
    final benchFramePaint = Paint()..color = const Color(0xFF334155);
    final benchShadowPaint = Paint()..color = Colors.black38;

    // Side player benches
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

    // Referee Chair or Environment Focal Prop (Left flank)
    const refX = 285.0;
    const refY = 315.0;

    switch (_courtInfo.environment) {
      case CourtEnvironment.beach:
        // Tropical Beach Umbrella and Tiki Stand
        canvas.drawOval(const Rect.fromLTWH(refX - 10, refY + 60, 60, 12), benchShadowPaint);
        // Umbrella pole
        final polePaint = Paint()..color = const Color(0xFFD97706)..strokeWidth = 5;
        canvas.drawLine(const Offset(refX + 20, refY + 65), const Offset(refX + 20, refY - 10), polePaint);
        // Canopy dome (Striped coral & white)
        final umbrellaPaint = Paint()..color = const Color(0xFFEA580C);
        final stripePaint = Paint()..color = Colors.white;
        canvas.drawArc(const Rect.fromLTWH(refX - 25, refY - 35, 90, 50), math.pi, math.pi, true, umbrellaPaint);
        canvas.drawArc(const Rect.fromLTWH(refX - 5, refY - 35, 50, 50), math.pi, math.pi, true, stripePaint);
        break;

      case CourtEnvironment.cyber:
        // Digital Holo-Terminal & Scoreboard
        canvas.drawRect(const Rect.fromLTWH(refX + 4, refY + 68, 36, 6), benchShadowPaint);
        final cyberPillar = Paint()..color = const Color(0xFF1E1B4B);
        canvas.drawRect(const Rect.fromLTWH(refX + 16, refY + 10, 12, 60), cyberPillar);
        // Hologram screen
        final holoPaint = Paint()..color = const Color(0xCC00E5FF);
        canvas.drawRect(const Rect.fromLTWH(refX, refY - 20, 44, 28), holoPaint);
        canvas.drawRect(
          const Rect.fromLTWH(refX, refY - 20, 44, 28),
          Paint()..color = const Color(0xFFFF007F)..style = PaintingStyle.stroke..strokeWidth = 2,
        );
        break;

      case CourtEnvironment.forest:
        // Pine Tree Silhouette Cluster
        canvas.drawOval(const Rect.fromLTWH(refX - 10, refY + 60, 60, 14), benchShadowPaint);
        // Trunk
        final trunkPaint = Paint()..color = const Color(0xFF78350F);
        canvas.drawRect(const Rect.fromLTWH(refX + 14, refY + 20, 12, 45), trunkPaint);
        // Pine foliage triangles
        final pinePaint = Paint()..color = const Color(0xFF14532D);
        final p1 = Path()..moveTo(refX + 20, refY - 35)..lineTo(refX - 15, refY + 25)..lineTo(refX + 55, refY + 25)..close();
        final p2 = Path()..moveTo(refX + 20, refY - 20)..lineTo(refX - 8, refY + 10)..lineTo(refX + 48, refY + 10)..close();
        canvas.drawPath(p1, pinePaint);
        canvas.drawPath(p2, Paint()..color = const Color(0xFF166534));
        break;

      case CourtEnvironment.magma:
        // Magma Vent with fiery glow
        canvas.drawOval(const Rect.fromLTWH(refX - 5, refY + 30, 50, 24), Paint()..color = const Color(0xFF991B1B));
        canvas.drawOval(const Rect.fromLTWH(refX, refY + 34, 40, 16), Paint()..color = const Color(0xFFF97316));
        canvas.drawOval(const Rect.fromLTWH(refX + 5, refY + 37, 30, 10), Paint()..color = const Color(0xFFFEF08A));
        break;

      case CourtEnvironment.stadium:
        // Classic Referee Chair at Net
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
        break;
    }
  }
}
