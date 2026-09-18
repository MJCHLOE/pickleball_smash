import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../pickleball_game.dart';

class PaddleComponent extends SpriteComponent with HasGameReference<PickleballGame> {
  final bool isPlayerOne;

  PaddleComponent({this.isPlayerOne = true});

  @override
  Future<void> onLoad() async {
    // Loading the specific paddle image from assets based on player
    final paddleAsset = isPlayerOne
        ? 'male1_sprite/pickleballpaddle_for player1.png'
        : 'female1_sprite/pickleballpaddle_for player2.png';
    sprite = await game.loadSprite(paddleAsset);
    
    // We assume the paddle size based on standard asset sizes.
    // If it's a different size, we can adjust this.
    size = Vector2(32, 32); 
    
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    
    // Place paddle on the player's right hand. 
    // Player 1 (front) right hand is on the left side of the sprite.
    // Player 2 (behind) right hand is on the right side of the sprite.
    if (isPlayerOne) {
      position = Vector2(12, 36); 
      // Flip the paddle so it looks correct in the other hand
      flipHorizontally(); 
    } else {
      position = Vector2(52, 36);
    }
    
    anchor = Anchor.center;
  }

  // A simple swing animation for the paddle when striking
  void swing() {
    // Basic rotation to simulate a swing
    angle = 1.5; // Rotate forwards
    
    // Reset back after a delay
    Future.delayed(const Duration(milliseconds: 200), () {
      angle = 0;
    });
  }
}
