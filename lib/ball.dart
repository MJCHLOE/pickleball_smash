import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'pickleball_game.dart';
import 'dart:math';
import 'player_sprites.dart';

class Ball extends CircleComponent with HasGameReference<PickleballGame>, CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  final double speed = 300.0;
  
  Ball() {
    radius = 10.0;
    anchor = Anchor.center;
    paint = Paint()..color = Colors.yellow;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox());
    resetBall();
  }

  void resetBall() {
    position = game.size / 2;
    // Serve ball in random direction, mostly horizontal
    final random = Random();
    final directionX = random.nextBool() ? 1.0 : -1.0;
    final directionY = (random.nextDouble() * 2) - 1.0;
    
    velocity = Vector2(directionX, directionY).normalized() * speed;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    position += velocity * dt;

    // Bounce off top and bottom walls
    if (position.y - radius < 0) {
      position.y = radius;
      velocity.y = -velocity.y;
    } else if (position.y + radius > game.size.y) {
      position.y = game.size.y - radius;
      velocity.y = -velocity.y;
    }

    // Check bounds for scoring
    if (position.x < -radius * 2 || position.x > game.size.x + radius * 2) {
      // Score!
      resetBall();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is PlayerSprite) {
      // Simple AABB collision reflection based on center positions
      final diff = position - other.position;
      
      // Determine if it was mostly horizontal or vertical hit
      if (diff.x.abs() > diff.y.abs()) {
        velocity.x = -velocity.x;
        // Add some spin/english based on where it hit the paddle/player Y
        velocity.y += (diff.y * 5); 
      } else {
        velocity.y = -velocity.y;
      }
      
      velocity *= 1.05; // Speed up slightly on hit
      
      // Prevent sticking by moving it out of collision
      position += velocity.normalized() * 5;
    }
  }
}
