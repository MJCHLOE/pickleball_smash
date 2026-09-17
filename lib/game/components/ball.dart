import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../pickleball_game.dart';
import 'dart:math';
import 'player.dart';

class BallComponent extends CircleComponent with HasGameReference<PickleballGame>, CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  final double initialSpeed = 400.0;
  double speed = 400.0;
  
  BallComponent() {
    radius = 12.0;
    anchor = Anchor.center;
    paint = Paint()..color = Colors.yellowAccent;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Add hitbox for collision detection
    add(CircleHitbox());
    resetBall();
  }

  void resetBall() {
    position = Vector2(1280 / 2, 720 / 2);
    speed = initialSpeed;
    
    // Serve ball in a random direction (either up or down towards the players)
    final random = Random();
    final directionX = (random.nextDouble() * 2) - 1.0; // Random slight horizontal angle
    final directionY = random.nextBool() ? 1.0 : -1.0; // Up or Down
    
    velocity = Vector2(directionX, directionY).normalized() * speed;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    position += velocity * dt;

    // Bounce off left and right walls
    if (position.x - radius < 0) {
      position.x = radius;
      velocity.x = -velocity.x;
    } else if (position.x + radius > 1280) {
      position.x = 1280 - radius;
      velocity.x = -velocity.x;
    }

    // Check bounds for scoring (Top and Bottom walls)
    if (position.y < -radius * 2 || position.y > 720 + radius * 2) {
      // Score! (Just reset for now)
      resetBall();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is PlayerComponent) {
      // If the player is currently slashing, they hit the ball!
      if (other.currentState == PlayerState.slash) {
        final diff = position - other.position;
        
        // Reflect the ball vertically
        velocity.y = -velocity.y;
        
        // Add some horizontal angle based on where it hit the player
        velocity.x += (diff.x * 2.5); 
        
        // Cap horizontal speed to prevent crazy angles
        velocity.x = velocity.x.clamp(-400.0, 400.0);
        
        speed *= 1.1; // Speed up slightly on hit
        velocity = velocity.normalized() * speed;
        
        // Prevent sticking
        position += velocity.normalized() * 5;
      }
    }
  }
}

