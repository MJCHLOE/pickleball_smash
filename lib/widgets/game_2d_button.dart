import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum GameButtonVariant {
  primary, // Neon Lime face + Deep Emerald bevel (black text)
  cyan,    // Electric Cyan face + Deep Navy Cobalt bevel (black text)
  amber,   // Trophy Gold/Amber face + Deep Bronze bevel (black text)
  fire,    // Arcade Flame Orange face + Dark Maroon bevel (white text)
  dark,    // Arcade Steel face + Deep Midnight bevel (white text, cyan accent)
}

enum GameButtonSize {
  small,  // 36px height, compact font, used for chips, claim buttons, dialogs
  medium, // 48px height, standard buttons
  large,  // 56px height, hero action buttons (Quick Match, Sign In)
}

class Game2DButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final GameButtonVariant variant;
  final GameButtonSize size;
  final bool isFullWidth;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const Game2DButton({
    super.key,
    this.text,
    this.child,
    this.icon,
    this.trailingIcon,
    required this.onPressed,
    this.variant = GameButtonVariant.primary,
    this.size = GameButtonSize.medium,
    this.isFullWidth = false,
    this.isLoading = false,
    this.width,
    this.padding,
  });

  @override
  State<Game2DButton> createState() => _Game2DButtonState();
}

class _Game2DButtonState extends State<Game2DButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    HapticFeedback.selectionClick();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    // Bevel depths & dimensions based on size
    final double bevelHeight = widget.size == GameButtonSize.small
        ? 3.5
        : widget.size == GameButtonSize.medium
            ? 5.0
            : 6.0;

    final double borderRadius = widget.size == GameButtonSize.small ? 10.0 : 14.0;
    final double fontSize = widget.size == GameButtonSize.small
        ? 12.0
        : widget.size == GameButtonSize.medium
            ? 14.0
            : 16.0;

    final double iconSize = widget.size == GameButtonSize.small
        ? 16.0
        : widget.size == GameButtonSize.medium
            ? 20.0
            : 24.0;

    final EdgeInsets defaultPadding = widget.size == GameButtonSize.small
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : widget.size == GameButtonSize.medium
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 11)
            : const EdgeInsets.symmetric(horizontal: 26, vertical: 14);

    // Color Palette Setup
    late final Color topFaceColor;
    late final Color bottomBevelColor;
    late final Color textColor;
    late final Color specularHighlightColor;
    late final Color borderColor;

    if (!isEnabled) {
      topFaceColor = const Color(0xFF334155);
      bottomBevelColor = const Color(0xFF1E293B);
      textColor = const Color(0xFF64748B);
      specularHighlightColor = Colors.white.withValues(alpha: 0.05);
      borderColor = const Color(0xFF0F172A);
    } else {
      borderColor = const Color(0xFF090D16);
      switch (widget.variant) {
        case GameButtonVariant.primary:
          topFaceColor = const Color(0xFF76FF03);
          bottomBevelColor = const Color(0xFF1B5E20);
          textColor = Colors.black;
          specularHighlightColor = Colors.white.withValues(alpha: 0.45);
          break;
        case GameButtonVariant.cyan:
          topFaceColor = const Color(0xFF00E5FF);
          bottomBevelColor = const Color(0xFF006064);
          textColor = Colors.black;
          specularHighlightColor = Colors.white.withValues(alpha: 0.45);
          break;
        case GameButtonVariant.amber:
          topFaceColor = const Color(0xFFFFD54F);
          bottomBevelColor = const Color(0xFFE65100);
          textColor = Colors.black;
          specularHighlightColor = Colors.white.withValues(alpha: 0.45);
          break;
        case GameButtonVariant.fire:
          topFaceColor = const Color(0xFFFF5722);
          bottomBevelColor = const Color(0xFFB71C1C);
          textColor = Colors.white;
          specularHighlightColor = Colors.white.withValues(alpha: 0.35);
          break;
        case GameButtonVariant.dark:
          topFaceColor = const Color(0xFF1E293B);
          bottomBevelColor = const Color(0xFF0B0F19);
          textColor = Colors.white;
          specularHighlightColor = const Color(0xFF00E5FF).withValues(alpha: 0.4);
          break;
      }
    }

    final double pressTranslation = _isPressed ? bevelHeight - 1.0 : 0.0;
    final double currentBevel = _isPressed ? 1.0 : bevelHeight;

    Widget content;
    if (widget.isLoading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: fontSize,
            height: fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          if (widget.text != null) ...[
            const SizedBox(width: 8),
            Text(
              'LOADING...',
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      );
    } else if (widget.child != null) {
      content = widget.child!;
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: iconSize, color: textColor),
            const SizedBox(width: 8),
          ],
          if (widget.text != null)
            Text(
              widget.text!,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          if (widget.trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(widget.trailingIcon, size: iconSize, color: textColor),
          ],
        ],
      );
    }

    final buttonCore = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOutQuad,
        padding: EdgeInsets.only(top: pressTranslation),
        child: Container(
          decoration: BoxDecoration(
            color: bottomBevelColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 2.0),
            boxShadow: [
              if (!_isPressed && isEnabled)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: currentBevel),
            decoration: BoxDecoration(
              color: topFaceColor,
              borderRadius: BorderRadius.circular(borderRadius - 2.0),
              // Top specular glossy highlight edge
              border: Border(
                top: BorderSide(color: specularHighlightColor, width: 2.0),
                bottom: BorderSide(color: Colors.black.withValues(alpha: 0.15), width: 1.0),
              ),
            ),
            padding: widget.padding ?? defaultPadding,
            child: Center(
              widthFactor: widget.isFullWidth ? null : 1.0,
              child: content,
            ),
          ),
        ),
      ),
    );

    if (widget.isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: buttonCore,
      );
    }

    if (widget.width != null) {
      return SizedBox(
        width: widget.width,
        child: buttonCore,
      );
    }

    return buttonCore;
  }
}

