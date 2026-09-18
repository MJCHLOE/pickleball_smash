import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../pickleball_game.dart';

class Background extends SpriteComponent with HasGameReference<PickleballGame> {
  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('background/pickleball_court.png');
    size = Vector2(1280, 720);
    
    // Disable anti-aliasing for pixel art
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;

    updateTheme(game.settings?.courtTheme ?? 'Classic Green');
    
    // Position it at the center of the 1280x720 logical screen
    position = Vector2(1280 / 2, 720 / 2);
    anchor = Anchor.center;
  }

  void updateTheme(String theme) {
    if (theme == 'Electric Blue') {
      paint.colorFilter = const ColorFilter.mode(Color(0x3800E5FF), BlendMode.color);
    } else if (theme == 'Sunset Clay') {
      paint.colorFilter = const ColorFilter.mode(Color(0x38FF5722), BlendMode.color);
    } else if (theme == 'Neon Night') {
      paint.colorFilter = const ColorFilter.mode(Color(0x409C27B0), BlendMode.color);
    } else {
      paint.colorFilter = null;
    }
  }
}
