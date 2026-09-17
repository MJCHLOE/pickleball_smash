import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../pickleball_game.dart';
import 'player.dart';
class PaddleComponent extends SpriteComponent with HasGameReference<PickleballGame> {
  final bool isPlayerOne;

  PaddleComponent({this.isPlayerOne = true});

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('male1_sprite/pickleballpaddle_for player1.png');
    
    // Shrink the paddle a little bit more as requested
    size = Vector2(20, 20); 
    
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    
    // Set the anchor to where the handle actually is on the sprite (bottom center)
    anchor = Anchor(0.5, 0.8);
  }

  bool _isSwinging = false;

  @override
  void update(double dt) {
    super.update(dt);
    
    if (parent is! PlayerComponent) return;
    final player = parent as PlayerComponent;
    
    if (!_isSwinging) {
      // Track hand placement based on player direction
      // The anchor is the handle, so position is exactly the player's hand!
      switch (player.currentDirection) {
        case PlayerDirection.front:
          // Facing camera: right hand is on viewer's left
          position = Vector2(18, 42);
          angle = -0.6; // Pointing up-left
          break;
        case PlayerDirection.behind:
          // Facing away: right hand is on viewer's right
          position = Vector2(46, 42);
          angle = 0.6; // Pointing up-right
          break;
        case PlayerDirection.left:
          // Facing left
          position = Vector2(24, 42);
          angle = -1.2; // Pointing mostly left
          break;
        case PlayerDirection.right:
          // Facing right
          position = Vector2(40, 42);
          angle = 1.2; // Pointing mostly right
          break;
      }
    }
  }

  void swing() {
    _isSwinging = true;
    
    final player = parent as PlayerComponent;
    
    // Adjust swing animation based on direction
    if (player.currentDirection == PlayerDirection.behind) {
      // Swing inwards/forwards
      angle = -0.2;
      position = Vector2(36, 40); 
    } else if (player.currentDirection == PlayerDirection.front) {
      angle = 0.2;
      position = Vector2(28, 40);
    } else if (player.currentDirection == PlayerDirection.left) {
      angle = -2.0; 
      position = Vector2(16, 44);
    } else {
      angle = 2.0;
      position = Vector2(48, 44);
    }
    
    // Reset back after the swing completes
    Future.delayed(const Duration(milliseconds: 200), () {
      _isSwinging = false;
    });
  }
}
