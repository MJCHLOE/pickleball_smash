import 'package:flutter/material.dart';

class AppTheme {
  // Breakpoints
  static const double compactBreakpoint = 700.0;
  static const double largeBreakpoint = 1050.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= compactBreakpoint && w < largeBreakpoint;
  }

  static bool isLarge(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= largeBreakpoint;

  // Colors
  static const Color background = Color(0xFF0D1527);
  static const Color surface = Color(0xFF17233D);
  static const Color surfaceLight = Color(0xFF223254);
  static const Color surfaceBorder = Color(0xFF2D4370);

  // Energy & Pickleball Sports Palette
  static const Color neonLime = Color(0xFF76FF03);
  static const Color pickleGreen = Color(0xFF00E676);
  static const Color electricCyan = Color(0xFF00E5FF);
  static const Color goldCoin = Color(0xFFFFD54F);
  static const Color trophyAmber = Color(0xFFFF9100);
  static const Color fireOrange = Color(0xFFFF5722);
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: neonLime,
      colorScheme: const ColorScheme.dark(
        primary: neonLime,
        secondary: electricCyan,
        surface: surface,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorder, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  // Common card gradient
  static LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      surface,
      surfaceLight.withValues(alpha: 0.8),
    ],
  );

  // Hero play button gradient
  static const LinearGradient playButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF76FF03),
      Color(0xFF00C853),
    ],
  );

  // Tournament gradient
  static const LinearGradient tournamentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF9100),
      Color(0xFFFF3D00),
    ],
  );

  // Challenge gradient
  static const LinearGradient challengeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2979FF),
      Color(0xFF00E5FF),
    ],
  );

  /// 2D arcade video-game TextStyle with multi-direction outline and 2D extrusion shadow.
  /// Suitable for widgets where only a TextStyle can be passed.
  static TextStyle game2DTextStyle({
    double fontSize = 18.0,
    FontWeight fontWeight = FontWeight.w900,
    Color color = Colors.white,
    Color outlineColor = const Color(0xFF070B16),
    Color shadowColor = Colors.black87,
    double outlineWidth = 2.0,
    double shadowDistance = 2.5,
    String? fontFamily,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
      letterSpacing: letterSpacing,
      color: color,
      shadows: [
        // 4-directional outline
        Shadow(offset: Offset(-outlineWidth, -outlineWidth), color: outlineColor),
        Shadow(offset: Offset(outlineWidth, -outlineWidth), color: outlineColor),
        Shadow(offset: Offset(-outlineWidth, outlineWidth), color: outlineColor),
        Shadow(offset: Offset(outlineWidth, outlineWidth), color: outlineColor),
        // 2D bottom extrusion drop shadow
        Shadow(offset: Offset(0, shadowDistance), color: shadowColor, blurRadius: 0),
        Shadow(
          offset: Offset(0, shadowDistance + 1.0),
          color: shadowColor.withValues(alpha: 0.65),
          blurRadius: 2.0,
        ),
      ],
    );
  }
}


