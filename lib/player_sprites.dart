import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/collisions.dart';
import 'pickleball_game.dart';
import 'ball.dart';

import 'dart:math';

class PlayerSprite extends PositionComponent with HasGameReference<PickleballGame> {
  final Color bodyColor;
  final Color headColor;
  
  late RectangleComponent body;
  late RectangleComponent head;
  late RectangleComponent leftLeg;
  late RectangleComponent rightLeg;
  
  bool isMoving = false;
  double animationTimer = 0;
  final double speed = 250.0;
  
  // Joystick reference injected from CourtLevel
  JoystickComponent? joystick;

  PlayerSprite({required this.bodyColor, required this.headColor}) {
    size = Vector2(40, 70);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Body
    body = RectangleComponent(
      size: Vector2(40, 40),
      position: Vector2(0, 20),
      paint: Paint()..color = bodyColor,
    );

    // Head
    head = RectangleComponent(
      size: Vector2(24, 24),
      position: Vector2(8, 0),
      paint: Paint()..color = headColor,
    );
    
    // Face (Eyes and Mouth)
    final eyePaint = Paint()..color = Colors.black;
    head.add(RectangleComponent(size: Vector2(4, 4), position: Vector2(4, 6), paint: eyePaint));
    head.add(RectangleComponent(size: Vector2(4, 4), position: Vector2(16, 6), paint: eyePaint));
    head.add(RectangleComponent(size: Vector2(10, 2), position: Vector2(7, 16), paint: eyePaint));

    // Legs
    leftLeg = RectangleComponent(
      size: Vector2(10, 20),
      position: Vector2(5, 50),
      paint: Paint()..color = Colors.black,
    );
    
    rightLeg = RectangleComponent(
      size: Vector2(10, 20),
      position: Vector2(25, 50),
      paint: Paint()..color = Colors.black,
    );

    add(leftLeg);
    add(rightLeg);
    add(body);
    add(head);
    
    // Hitbox for the ball to bounce off
    add(RectangleHitbox(size: size));
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Procedural animation for moving
    if (isMoving) {
      animationTimer += dt * 10;
      head.position.y = (sin(animationTimer) * 2);
      
      // Swing legs
      leftLeg.position.y = 50 + (sin(animationTimer) * 5);
      rightLeg.position.y = 50 + (cos(animationTimer) * 5);
    } else {
      head.position.y = 0;
      leftLeg.position.y = 50;
      rightLeg.position.y = 50;
    }
    
    // Constrain to court Y boundaries
    if (position.y < size.y / 2) position.y = size.y / 2;
    if (position.y > game.size.y - size.y / 2) position.y = game.size.y - size.y / 2;
  }
}

class MalePlayer extends PlayerSprite with KeyboardHandler {
  Vector2 velocity = Vector2.zero();

  MalePlayer() : super(bodyColor: Colors.blue, headColor: Colors.orange);

  @override
  void update(double dt) {
    super.update(dt);
    
    velocity.setZero();
    
    // Joystick controls
    if (joystick != null && joystick!.direction != JoystickDirection.idle) {
      velocity.add(joystick!.relativeDelta * speed);
    }
    
    // Keyboard controls
    if (keysPressed.contains(LogicalKeyboardKey.keyW) || keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      velocity.y -= speed;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) || keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      velocity.y += speed;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      velocity.x -= speed;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      velocity.x += speed;
    }
    
    position += velocity * dt;
    isMoving = velocity.length2 > 0;
    
    // Optional: Constrain X to left half of court
    if (position.x < size.x / 2) position.x = size.x / 2;
    if (position.x > game.size.x / 2 - size.x / 2) position.x = game.size.x / 2 - size.x / 2;
  }
  
  final Set<LogicalKeyboardKey> keysPressed = {};
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    this.keysPressed.clear();
    this.keysPressed.addAll(keysPressed);
    return super.onKeyEvent(event, keysPressed);
  }
}

class FemalePlayer extends PlayerSprite {
  Ball? ball;
  
  FemalePlayer() : super(bodyColor: Colors.purple, headColor: Colors.yellow);

  @override
  void update(double dt) {
    super.update(dt);
    
    // Simple AI: Follow the ball's Y position
    if (ball != null) {
      final diff = ball!.position.y - position.y;
      
      // Move towards ball if it's on the right side of the court, or just always
      if (ball!.position.x > game.size.x / 2) {
        if (diff.abs() > 10) {
          position.y += diff.sign * speed * 0.8 * dt;
          isMoving = true;
        } else {
          isMoving = false;
        }
      } else {
        // Return to center slowly
        final centerDiff = (game.size.y / 2) - position.y;
        if (centerDiff.abs() > 10) {
           position.y += centerDiff.sign * speed * 0.4 * dt;
           isMoving = true;
        } else {
          isMoving = false;
        }
      }
    }
    
    // Constrain X to right half of court (AI shouldn't really change X, but just in case)
    position.x = game.size.x - 150; // Keep fixed X
  }
}
