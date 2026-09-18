import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/player_avatar.dart';
import '../theme/app_theme.dart';

/// Pixel-crisp 2D arcade style Player Avatar widget
class PlayerAvatarWidget extends StatelessWidget {
  final String? avatarId;
  final PlayerAvatar? avatar;
  final double size;
  final bool showBadge;
  final bool showBorder;
  final bool isSelected;
  final VoidCallback? onTap;

  const PlayerAvatarWidget({
    super.key,
    this.avatarId,
    this.avatar,
    this.size = 40,
    this.showBadge = false,
    this.showBorder = true,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = avatar ?? PlayerAvatar.getById(avatarId);
    final borderRadius = BorderRadius.circular(size * 0.28);

    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: borderRadius,
        border: showBorder
            ? Border.all(
                color: isSelected
                    ? AppTheme.neonLime
                    : (showBorder ? const Color(0xFF090D16) : Colors.transparent),
                width: isSelected ? 2.5 : 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: (isSelected ? AppTheme.neonLime : resolvedAvatar.borderColor).withValues(alpha: 0.35),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: size > 30 ? 2.5 : 1.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: resolvedAvatar.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size * 0.25),
          border: Border.all(
            color: resolvedAvatar.borderColor.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildAvatarGraphic(resolvedAvatar),
      ),
    );

    if (showBadge && resolvedAvatar.badge.isNotEmpty) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: resolvedAvatar.borderColor, width: 1),
              ),
              child: Text(
                resolvedAvatar.badge,
                style: TextStyle(fontSize: size * 0.28),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: content,
      );
    }

    return content;
  }

  Widget _buildAvatarGraphic(PlayerAvatar av) {
    // 1. Custom photo URL or local file path
    if (av.customImageUrl != null && av.customImageUrl!.isNotEmpty) {
      final url = av.customImageUrl!;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) => _fallbackInitialsOrIcon(av),
        );
      } else if (!kIsWeb && (url.startsWith('file://') || url.contains(':\\') || url.contains(':/') || url.startsWith('/'))) {
        try {
          final filePath = url.replaceFirst('file://', '');
          final file = File(filePath);
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (context, error, stackTrace) => _fallbackInitialsOrIcon(av),
          );
        } catch (_) {
          return _fallbackInitialsOrIcon(av);
        }
      }
    }

    // 2. Custom initials
    if (av.initials != null && av.initials!.isNotEmpty) {
      return Center(
        child: Text(
          av.initials!.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.42,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    // 3. Sprite asset if provided
    if (av.assetPath != null && av.assetPath!.isNotEmpty) {
      return Image.asset(
        av.assetPath!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) => _fallbackInitialsOrIcon(av),
      );
    }

    // 4. Stylized icon
    return _fallbackInitialsOrIcon(av);
  }

  Widget _fallbackInitialsOrIcon(PlayerAvatar av) {
    return Center(
      child: Icon(
        av.icon,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}

