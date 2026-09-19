import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pickleball_game.dart';

enum PlayerDirection { front, behind, left, right }
enum PlayerState { idle, run, slash }

class PlayerComponent extends SpriteAnimationComponent with HasGameReference<PickleballGame>, KeyboardHandler {
  late SpriteAnimation frontRun;
  late SpriteAnimation behindRun;
  late SpriteAnimation leftRun;
  late SpriteAnimation rightRun;
  
  late SpriteAnimation frontSlash;
  late SpriteAnimation behindSlash;
  
  late SpriteAnimation p1Idle;
  late SpriteAnimation p2Idle;

  PlayerDirection currentDirection;
  PlayerState currentState = PlayerState.idle;
  
  final bool isPlayerOne;
  final bool isFemale;
  JoystickComponent? joystick;
  
  final double speed = 350.0;
  final double aiSpeed = 400.0; // AI needs to be fast enough to hit the ball

  int hAxis = 0;
  int vAxis = 0;
  bool _animationsLoaded = false;

  void updateJoystick(JoystickComponent newJoystick) {
    joystick = newJoystick;
  }

  PlayerComponent({
    this.isPlayerOne = true, 
    bool? isFemale,
    this.joystick,
  })  : isFemale = isFemale ?? (!isPlayerOne),
        currentDirection = isPlayerOne ? PlayerDirection.front : PlayerDirection.behind;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!isPlayerOne) return super.onKeyEvent(event, keysPressed);

    hAxis = 0;
    vAxis = 0;

    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) || keysPressed.contains(LogicalKeyboardKey.keyA)) {
      hAxis -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight) || keysPressed.contains(LogicalKeyboardKey.keyD)) {
      hAxis += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) || keysPressed.contains(LogicalKeyboardKey.keyW)) {
      vAxis -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown) || keysPressed.contains(LogicalKeyboardKey.keyS)) {
      vAxis += 1;
    }

    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      strike();
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  Future<void> onLoad() async {
    // Add hitbox for ball collisions
    add(RectangleHitbox());
    
    if (isFemale) {
      // Female sprites (8 frames of 64x64)
      frontRun = await _loadAnimation('female1 sprite (reworked)/female_runfront.png', amount: 8);
      behindRun = await _loadAnimation('female1 sprite (reworked)/female_runbehind.png', amount: 8);
      leftRun = await _loadAnimation('female1 sprite (reworked)/female_runleft.png', amount: 8);
      rightRun = await _loadAnimation('female1 sprite (reworked)/female_runright.png', amount: 8);

      p1Idle = await _loadAnimation(
        'female1 sprite (reworked)/female_runfront.png',
        amount: 2,
        textureSize: Vector2(64, 64),
        stepTime: 0.35,
      );
      p2Idle = await _loadAnimation(
        'female1 sprite (reworked)/female_runbehind.png',
        amount: 2,
        textureSize: Vector2(64, 64),
        stepTime: 0.35,
      );

      frontSlash = await _loadAnimation(
        'female1 sprite (reworked)/female_frontslash.png', // Changed from female_runfront.png to use the actual slash sprite! Wait, previous code used female_runfront for slash? Let me check.
        amount: 8,
        loop: false,
        stepTime: 0.04,
      );
      behindSlash = await _loadAnimation(
        'female1 sprite (reworked)/female _behindslash.png', // Notice the space!
        amount: 8,
        loop: false,
        stepTime: 0.04,
      );
    } else {
      // Male sprites
      // Slash animations have 6 frames (384 / 64)
      frontSlash = await _loadAnimation('male1 sprite (reworked)/male_frontslash.png', amount: 6, loop: false, stepTime: 0.08);
      behindSlash = await _loadAnimation('male1 sprite (reworked)/male_behindslash.png', amount: 6, loop: false, stepTime: 0.08);

      // Idle animations have 2 frames (128 / 64)
      p1Idle = await _loadAnimation('male1 sprite (reworked)/male_p1sideidle.png', amount: 2);
      p2Idle = await _loadAnimation('male1 sprite (reworked)/male_p2sideidle.png', amount: 2);

      frontRun = await _loadAnimation('male1 sprite (reworked)/male_frontrun.png', amount: 8);
      behindRun = await _loadAnimation('male1 sprite (reworked)/male_behindrun.png', amount: 8);
      leftRun = await _loadAnimation('male1 sprite (reworked)/male_leftrun.png', amount: 8);
      rightRun = await _loadAnimation('male1 sprite (reworked)/male_rightrun.png', amount: 8);
    }

    animation = isPlayerOne ? p1Idle : p2Idle;
    
    // Set the component size to match a single 64x64 frame exactly
    size = Vector2(64, 64);
    
    // Scale shrunk down a little bit as requested
    scale = Vector2.all(1.5);
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    
    anchor = Anchor.center;
    _animationsLoaded = true;
  }

  double get horizontalMovement {
    if (joystick != null && !joystick!.delta.isZero()) {
      return joystick!.relativeDelta.x;
    }
    return hAxis.toDouble();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (currentState == PlayerState.slash) return; // Don't move while slashing

    if (isPlayerOne) {
      bool isMoving = false;
      Vector2 moveDelta = Vector2.zero();
      PlayerDirection newDirection = currentDirection;

      // 1. Check Joystick
      if (joystick != null && !joystick!.delta.isZero()) {
        isMoving = true;
        moveDelta = joystick!.relativeDelta;

        if (joystick!.direction == JoystickDirection.up || 
            joystick!.direction == JoystickDirection.upLeft || 
            joystick!.direction == JoystickDirection.upRight) {
          newDirection = PlayerDirection.front; // Swapped as requested
        } else if (joystick!.direction == JoystickDirection.down || 
                   joystick!.direction == JoystickDirection.downLeft || 
                   joystick!.direction == JoystickDirection.downRight) {
          newDirection = PlayerDirection.behind; // Swapped as requested
        } else if (joystick!.direction == JoystickDirection.left) {
          newDirection = PlayerDirection.left;
        } else if (joystick!.direction == JoystickDirection.right) {
          newDirection = PlayerDirection.right;
        }
      } 
      // 2. Check Keyboard
      else if (hAxis != 0 || vAxis != 0) {
        isMoving = true;
        moveDelta = Vector2(hAxis.toDouble(), vAxis.toDouble()).normalized();

        if (vAxis < 0) {
          newDirection = PlayerDirection.front;
        } else if (vAxis > 0) {
          newDirection = PlayerDirection.behind;
        } else if (hAxis < 0) {
          newDirection = PlayerDirection.left;
        } else if (hAxis > 0) {
          newDirection = PlayerDirection.right;
        }
      }

      if (isMoving) {
        final sensitivity = game.settings?.joystickSensitivity ?? 1.0;
        position.add(moveDelta * speed * sensitivity * dt);
        changeDirection(newDirection);
      } else {
        if (currentState == PlayerState.run) {
          stopRunning();
        }
      }

      // Screen bounds and sprite size
      final halfW = (size.x * scale.x) / 2;
      final halfH = (size.y * scale.y) / 2;
      
      // Strict court bounds
      final courtLeftX = 340.0;
      final courtRightX = 940.0;
      
      // Allow entering the Kitchen (net is at 360), stopping just before touching the net
      final p1NetLimitY = 380.0;
      final bottomEdgeY = 700.0;
      
      position.y = position.y.clamp(p1NetLimitY + halfH, bottomEdgeY - halfH);
      position.x = position.x.clamp(courtLeftX + halfW, courtRightX - halfW);
      
    } else {
      // AI Logic for Player 2 (CPU)
      if (game.isWaitingForServe) {
        if (game.serverPlayer == 1) {
          // Waiting for Player 1 to serve: remain in ready position in diagonal receiving court
          stopRunning();
          return;
        }
      }

      final ball = game.ball;
      
      // Move towards the ball's X position
      if (ball.position.x < position.x - 12) {
        position.x -= aiSpeed * dt;
        changeDirection(PlayerDirection.left);
      } else if (ball.position.x > position.x + 12) {
        position.x += aiSpeed * dt;
        changeDirection(PlayerDirection.right);
      } else {
        stopRunning();
      }
      
      final halfW = (size.x * scale.x) / 2;
      final courtLeftX = 340.0;
      final courtRightX = 940.0;
      position.x = position.x.clamp(courtLeftX + halfW, courtRightX - halfW);
      
      // Strike if ball is close and coming towards Player 2 (moving UP)
      // Obey Two-Bounce Rule: on serve return (rallyHitCount == 0), wait until ball has bounced!
      if (ball.velocity.y < 0 && (ball.position.y - position.y).abs() < 120) {
        if (game.rallyHitCount == 0 && ball.bounceCountCurrentSide == 0) {
          // Waiting for serve to bounce! (Rule 2)
        } else {
          strike();
        }
      }
    }
  }

  Future<SpriteAnimation> _loadAnimation(
    String path, {
    required int amount,
    double stepTime = 0.1,
    bool loop = true,
    Vector2? textureSize,
  }) async {
    final image = await game.images.load(path);
    final frameSize = textureSize ?? Vector2(image.width / amount, image.height.toDouble());
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: frameSize,
        loop: loop,
      ),
    );
  }

  void strike() {
    // Check if player is serving
    if (isPlayerOne && game.isWaitingForServe && game.serverPlayer == 1) {
      game.ball.executeServe(
        isPlayerOne: true,
        horizontalAngle: horizontalMovement,
      );
    }

    if (!_animationsLoaded) return;
    if (currentState == PlayerState.slash) return; // Already striking

    currentState = PlayerState.slash;
    
    // Switch to the slash animation
    animation = isPlayerOne ? frontSlash : behindSlash;
    
    // Reset the ticker so the animation plays from the beginning
    animationTicker?.reset();
    
    // Wait for the animation to complete, then return to idle
    animationTicker?.onComplete = () {
      currentState = PlayerState.idle;
      _updateAnimation();
    };
    
    if (isPlayerOne) {
      game.onPlayerSmash();
    }
  }

  void changeDirection(PlayerDirection newDirection) {
    if (currentDirection == newDirection) return;
    currentDirection = newDirection;
    currentState = PlayerState.run;
    _updateAnimation();
  }

  void stopRunning() {
    currentState = PlayerState.idle;
    _updateAnimation();
  }

  void _updateAnimation() {
    if (!_animationsLoaded) return;
    if (currentState == PlayerState.slash) return; // Don't interrupt a slash
    
    if (currentState == PlayerState.idle) {
       animation = isPlayerOne ? p1Idle : p2Idle;
    } else if (currentState == PlayerState.run) {
      switch (currentDirection) {
        case PlayerDirection.front:
          animation = frontRun;
          break;
        case PlayerDirection.behind:
          animation = behindRun;
          break;
        case PlayerDirection.left:
          animation = leftRun;
          break;
        case PlayerDirection.right:
          animation = rightRun;
          break;
      }
    }
  }
}
