import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/court_catalog.dart';
import '../pickleball_game.dart';
import 'background.dart';

/// 2D Retro Arcade Net Component
///
/// Provides authentic visual depth and regulation pickleball net rendering:
/// - 36" height at posts, 34" at center with regulation sag
/// - Top regulation vinyl tape with 3D highlight
/// - Diamond mesh lattice matching the court environment theme
/// - Official center net strap with buckle
/// - Left & right tension posts with crank handles
/// - Zero-allocation cached rendering using [ui.Picture] for rock-solid 60/120 FPS
/// - Priority 10 so far court players/balls render behind, near court players render in front
class NetComponent extends PositionComponent with HasGameReference<PickleballGame> {
  CourtInfo _courtInfo;
  ui.Picture? _cachedPicture;
  double _wobbleOffset = 0.0;
  double _wobbleVelocity = 0.0;

  static const double courtLeftX = Background.courtLeftX; // 400.0
  static const double courtRightX = Background.courtRightX; // 880.0
  static const double netY = Background.netY; // 360.0
  static const double netHeight = 20.0; // Visual 20px upright height
  static const double postMargin = 24.0;

  NetComponent({String? courtId})
      : _courtInfo = CourtCatalog.getById(courtId ?? 'court_pro_stadium') {
    priority = 10;
    // Bounds encompass the posts and net
    position = Vector2(courtLeftX - postMargin - 8, netY - netHeight - 8);
    size = Vector2((courtRightX - courtLeftX) + (postMargin * 2) + 16, netHeight + 16);
  }

  void updateCourtTheme(String courtId) {
    _courtInfo = CourtCatalog.getById(courtId);
    _invalidateCache();
  }

  void wobble([double impulse = 3.5]) {
    _wobbleVelocity = impulse;
  }

  void _invalidateCache() {
    _cachedPicture?.dispose();
    _cachedPicture = null;
  }

  @override
  void onRemove() {
    _invalidateCache();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_wobbleVelocity.abs() > 0.05 || _wobbleOffset.abs() > 0.05) {
      // Spring dampening physics for net cord ripple
      final force = -28.0 * _wobbleOffset - 8.0 * _wobbleVelocity;
      _wobbleVelocity += force * dt;
      _wobbleOffset += _wobbleVelocity * dt;
      if (_wobbleVelocity.abs() <= 0.05 && _wobbleOffset.abs() <= 0.05) {
        _wobbleOffset = 0.0;
        _wobbleVelocity = 0.0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_cachedPicture == null) {
      _recordNetPicture();
    }

    if (_wobbleOffset != 0.0) {
      canvas.save();
      canvas.translate(0, _wobbleOffset);
      canvas.drawPicture(_cachedPicture!);
      canvas.restore();
    } else {
      canvas.drawPicture(_cachedPicture!);
    }
  }

  void _recordNetPicture() {
    _cachedPicture?.dispose();
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder, Rect.fromLTWH(0, 0, size.x, size.y));

    // Coordinates relative to this component's top-left
    const double originX = postMargin + 8;
    const double originY = netHeight + 8; // Baseline Y of the net (Y = 360 in game space)
    const double netWidth = courtRightX - courtLeftX; // 480.0
    const double netTopY = originY - netHeight;
    const double postLeftX = originX - postMargin;
    const double postRightX = originX + netWidth + postMargin;
    const double centerX = originX + (netWidth / 2.0);

    // 1. Soft ground shadow along the baseline
    final shadowPaint = Paint()..color = const Color(0x77000000);
    c.drawRect(
      Rect.fromLTRB(postLeftX - 6, originY + 1, postRightX + 6, originY + 6),
      shadowPaint,
    );

    // 2. Net Mesh lattice (Criss-cross diamond pattern with theme mesh color)
    final meshBgPaint = Paint()..color = _courtInfo.netMeshColor.withValues(alpha: 0.75);
    c.drawRect(
      Rect.fromLTRB(postLeftX + 4, netTopY + 3, postRightX - 4, originY + 1),
      meshBgPaint,
    );

    final meshGridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;

    for (double my = netTopY + 4; my <= originY; my += 3.0) {
      c.drawLine(Offset(postLeftX + 4, my), Offset(postRightX - 4, my), meshGridPaint);
    }

    for (double mx = postLeftX + 6; mx <= postRightX - 6; mx += 4.0) {
      final distFromCenter = (mx - centerX).abs() / (netWidth / 2.0);
      final sag = (1.0 - distFromCenter.clamp(0.0, 1.0)) * 2.5;
      c.drawLine(Offset(mx, netTopY + 3 + sag), Offset(mx, originY + 1), meshGridPaint);
    }

    // 3. Bottom Net Cord
    final bottomCordPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 2.0;
    c.drawLine(Offset(postLeftX + 2, originY + 1), Offset(postRightX - 2, originY + 1), bottomCordPaint);

    // 4. Top Regulation Vinyl Tape
    final tapeColor = _courtInfo.netTapeColor;
    final topTapePaint = Paint()
      ..color = tapeColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final tapePath = Path();
    tapePath.moveTo(postLeftX + 2, netTopY);
    tapePath.quadraticBezierTo(centerX, netTopY + 3.0, postRightX - 2, netTopY);
    c.drawPath(tapePath, topTapePaint);

    // Highlight line on top tape
    final tapeHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final highlightPath = Path();
    highlightPath.moveTo(postLeftX + 2, netTopY - 1.0);
    highlightPath.quadraticBezierTo(centerX, netTopY + 2.0, postRightX - 2, netTopY - 1.0);
    c.drawPath(highlightPath, tapeHighlightPaint);

    // 5. Official Center Net Strap (Vertical white strap at centerX)
    final strapPaint = Paint()..color = Colors.white;
    c.drawRect(Rect.fromLTWH(centerX - 3, netTopY + 2, 6, netHeight), strapPaint);
    final bucklePaint = Paint()..color = const Color(0xFF334155);
    c.drawRect(Rect.fromLTWH(centerX - 4, netTopY + 6, 8, 4), bucklePaint);

    // 6. Heavy-Duty Side Net Posts (Left & Right)
    final postColor = const Color(0xFF475569);
    final postHighlightColor = const Color(0xFFE2E8F0);
    final postPaint = Paint()..color = postColor;
    final postHighlightPaint = Paint()..color = postHighlightColor..strokeWidth = 1.5;

    for (final px in [postLeftX, postRightX]) {
      // Post shadow
      c.drawOval(Rect.fromLTWH(px - 4, originY - 1, 14, 6), shadowPaint);
      // Post cylinder
      c.drawRect(Rect.fromLTWH(px - 1, netTopY - 4, 8, netHeight + 6), postPaint);
      c.drawLine(Offset(px + 1, netTopY - 4), Offset(px + 1, originY + 2), postHighlightPaint);
      // Post cap
      c.drawRect(Rect.fromLTWH(px - 2, netTopY - 6, 10, 3), Paint()..color = const Color(0xFF94A3B8));
      // Base plate
      c.drawRect(Rect.fromLTWH(px - 3, originY, 12, 3), Paint()..color = const Color(0xFF1E293B));
    }

    _cachedPicture = recorder.endRecording();
  }
}
