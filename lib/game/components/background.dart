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
    
    // Position it at the center of the 1280x720 logical screen
    position = Vector2(1280 / 2, 720 / 2);
    anchor = Anchor.center;
  }
}

