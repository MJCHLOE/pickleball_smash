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

  void resetBall({bool? p1Scored}) {
    speed = initialSpeed;
    
    // Determine who serves. If null (start of game), pick randomly.
    bool p1Serve = p1Scored ?? Random().nextBool();
    
    // In onLoad, players might not be fully added to the game yet, so we delay the position
    // or set it based on the expected player position.
    // Player 1 position is expected at (1280 / 2, 720 * 0.75)
    // Player 2 position is expected at (1280 / 2, 720 * 0.25)
    Vector2 serverPos = p1Serve 
        ? Vector2(1280 / 2, 720 * 0.75) 
        : Vector2(1280 / 2, 720 * 0.25);
        
    try {
      if (p1Serve) {
        serverPos = game.player1.position;
      } else {
        serverPos = game.player2.position;
      }
    } catch (e) {
      // Game references might not be ready yet
    }
    
    // Place ball on the left hand (viewer's left side) of the serving player.
    if (p1Serve) {
      position = serverPos + Vector2(-25, 10); 
      velocity = Vector2(0, -1).normalized() * speed; // Serve towards Player 2
    } else {
      position = serverPos + Vector2(-25, 10);
      velocity = Vector2(0, 1).normalized() * speed; // Serve towards Player 1
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    position += velocity * dt;

    // Determine if the ball is out of bounds
    bool outLeft = position.x < -radius * 2;
    bool outRight = position.x > 1280 + radius * 2;
    bool outTop = position.y < -radius * 2;
    bool outBottom = position.y > 720 + radius * 2;

    if (outLeft || outRight || outTop || outBottom) {
      // If it went out top, it was traveling up (velocity.y < 0), so Player 1 hit it past Player 2 -> Player 1 scored.
      // If it went out bottom, it was traveling down (velocity.y > 0), so Player 2 hit it past Player 1 -> Player 2 scored.
      // If it went out left/right while traveling up, Player 1 hit it out -> Player 2 scored.
      // If it went out left/right while traveling down, Player 2 hit it out -> Player 1 scored.
      bool p1Scored;
      
      if (outTop) {
        p1Scored = true;
      } else if (outBottom) {
        p1Scored = false;
      } else {
        // Out left or right
        if (velocity.y < 0) {
          // Player 1 hit it out of bounds
          p1Scored = false;
        } else {
          // Player 2 hit it out of bounds
          p1Scored = true;
        }
      }
      
      resetBall(p1Scored: p1Scored);
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
        
        // Influence horizontal bounce based on player's current movement input
        // If holding left (horizontalMovement < 0), bounce more to the left
        // If holding right (horizontalMovement > 0), bounce more to the right
        velocity.x += other.horizontalMovement * 300.0;
        
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

