import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// An authentic 2D arcade video-game styled text widget.
///
/// Features a dark contrasting stroke outline, an extruded 2D drop shadow,
/// vibrant gaming color palettes, and optional gradient shader fills.
/// Renders the stroke via CustomPainter to maintain single-Text semantics
/// for accessibility and test match reliability.
class Game2DText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? textColor;
  final Color strokeColor;
  final double strokeWidth;
  final Color shadowColor;
  final Offset shadowOffset;
  final Gradient? gradient;
  final String? fontFamily;
  final double? letterSpacing;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const Game2DText(
    this.text, {
    super.key,
    this.fontSize = 22.0,
    this.fontWeight = FontWeight.w900,
    this.textColor = Colors.white,
    this.strokeColor = const Color(0xFF070B16),
    this.strokeWidth = 3.5,
    this.shadowColor = Colors.black87,
    this.shadowOffset = const Offset(0, 3.0),
    this.gradient,
    this.fontFamily,
    this.letterSpacing = 0.5,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// Large hero title styling (e.g. "PICKLEBALL SMASH", game over banners)
  factory Game2DText.hero(
    String text, {
    Key? key,
    double fontSize = 34.0,
    Color? textColor,
    Gradient? gradient = AppTheme.playButtonGradient,
    Color strokeColor = const Color(0xFF050811),
    double strokeWidth = 5.0,
    Offset shadowOffset = const Offset(0, 5.0),
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Game2DText(
      text,
      key: key,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      textColor: textColor,
      gradient: gradient,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      shadowOffset: shadowOffset,
      letterSpacing: 1.5,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Section or card title (e.g. "TOURNAMENTS", "PLAYER STATS")
  factory Game2DText.title(
    String text, {
    Key? key,
    double fontSize = 22.0,
    Color textColor = Colors.white,
    Color strokeColor = const Color(0xFF0A0F1E),
    double strokeWidth = 3.5,
    Offset shadowOffset = const Offset(0, 3.0),
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Game2DText(
      text,
      key: key,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      textColor: textColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      shadowOffset: shadowOffset,
      letterSpacing: 0.8,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Scoreboards, coins, gems, timer numbers
  factory Game2DText.score(
    String text, {
    Key? key,
    double fontSize = 28.0,
    Color textColor = AppTheme.electricCyan,
    Color strokeColor = const Color(0xFF030712),
    double strokeWidth = 4.0,
    Offset shadowOffset = const Offset(0, 3.5),
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Game2DText(
      text,
      key: key,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      textColor: textColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      shadowOffset: shadowOffset,
      letterSpacing: 1.0,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Small chip, tag, or badge text (e.g. "LVL 5", "RANK 1", "READY")
  factory Game2DText.badge(
    String text, {
    Key? key,
    double fontSize = 13.0,
    Color textColor = AppTheme.trophyAmber,
    Color strokeColor = const Color(0xFF070B16),
    double strokeWidth = 2.5,
    Offset shadowOffset = const Offset(0, 1.5),
    TextAlign? textAlign,
  }) {
    return Game2DText(
      text,
      key: key,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      textColor: textColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      shadowOffset: shadowOffset,
      letterSpacing: 0.5,
      textAlign: textAlign,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Foreground Fill Layer (The single Text widget in the tree for a11y & tests)
    Widget fillWidget;
    if (gradient != null) {
      fillWidget = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => gradient!.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        ),
        child: Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
            letterSpacing: letterSpacing,
            color: Colors.white,
          ),
        ),
      );
    } else {
      fillWidget = Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          letterSpacing: letterSpacing,
          color: textColor ?? Colors.white,
        ),
      );
    }

    // 2. Base Stroke & 2D Extrusion Shadow Layer drawn on Canvas directly behind the text
    final strokeWidget = Positioned.fill(
      child: CustomPaint(
        painter: _Game2DTextStrokePainter(
          text: text,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          letterSpacing: letterSpacing,
          strokeWidth: strokeWidth,
          strokeColor: strokeColor,
          shadowOffset: shadowOffset,
          shadowColor: shadowColor,
          textAlign: textAlign ?? TextAlign.start,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ),
    );

    return Stack(
      alignment: _getStackAlignment(textAlign),
      children: [
        strokeWidget,
        fillWidget,
      ],
    );
  }

  AlignmentGeometry _getStackAlignment(TextAlign? align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.left:
      case TextAlign.start:
      default:
        return Alignment.centerLeft;
    }
  }
}

class _Game2DTextStrokePainter extends CustomPainter {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final String? fontFamily;
  final double? letterSpacing;
  final double strokeWidth;
  final Color strokeColor;
  final Offset shadowOffset;
  final Color shadowColor;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  _Game2DTextStrokePainter({
    required this.text,
    required this.fontSize,
    required this.fontWeight,
    this.fontFamily,
    this.letterSpacing,
    required this.strokeWidth,
    required this.strokeColor,
    required this.shadowOffset,
    required this.shadowColor,
    required this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          letterSpacing: letterSpacing,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = strokeColor,
          shadows: [
            Shadow(
              offset: shadowOffset,
              color: shadowColor,
              blurRadius: 0,
            ),
            Shadow(
              offset: Offset(shadowOffset.dx, shadowOffset.dy + 1.5),
              color: shadowColor.withValues(alpha: 0.65),
              blurRadius: 2.0,
            ),
          ],
        ),
      ),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: overflow == TextOverflow.ellipsis ? '…' : null,
    )..layout(maxWidth: size.width > 0 ? size.width : double.infinity);

    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _Game2DTextStrokePainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.fontWeight != fontWeight ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.shadowOffset != shadowOffset ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.textAlign != textAlign;
  }
}

