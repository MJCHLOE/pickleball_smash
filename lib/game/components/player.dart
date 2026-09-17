import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'paddle.dart';

import '../pickleball_game.dart';

enum PlayerDirection { front, behind, left, right }
enum PlayerState { idle, run, slash }

class PlayerComponent extends SpriteAnimationComponent with HasGameReference<PickleballGame> {
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
  final JoystickComponent? joystick;
  late PaddleComponent paddle;
  
  final double speed = 250.0;

  PlayerComponent({this.isPlayerOne = true, this.joystick}) 
      : currentDirection = isPlayerOne ? PlayerDirection.front : PlayerDirection.behind;

  @override
  Future<void> onLoad() async {
    // Slash animations have 6 frames (384 / 64)
    frontSlash = await _loadAnimation('male1_sprite/male_frontslash.png', amount: 6, loop: false, stepTime: 0.08);
    behindSlash = await _loadAnimation('male1_sprite/male_behindslash.png', amount: 6, loop: false, stepTime: 0.08);

    // Idle animations have 2 frames (128 / 64)
    p1Idle = await _loadAnimation('male1_sprite/male_p1sideidle.png', amount: 2);
    p2Idle = await _loadAnimation('male1_sprite/male_p2sideidle.png', amount: 2);

    frontRun = await _loadAnimation('male1_sprite/male_frontrun.png', amount: 8);
    behindRun = await _loadAnimation('male1_sprite/male_behindrun.png', amount: 8);
    leftRun = await _loadAnimation('male1_sprite/male_leftrun.png', amount: 8);
    rightRun = await _loadAnimation('male1_sprite/male_rightrun.png', amount: 8);

    animation = isPlayerOne ? p1Idle : p2Idle;
    
    // Set the component size to match a single 64x64 frame exactly
    size = Vector2(64, 64);
    
    // Scale shrunk down a little bit as requested
    scale = Vector2.all(1.5);
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    
    anchor = Anchor.center;

    paddle = PaddleComponent(isPlayerOne: isPlayerOne);
    add(paddle);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (currentState == PlayerState.slash) return; // Don't move while slashing

    if (joystick != null && !joystick!.delta.isZero()) {
      // Move the player
      position.add(joystick!.relativeDelta * speed * dt);
      
      // Keep player inside the court vertically (example boundary, can be tweaked)
      position.y = position.y.clamp(0.0, 720.0);
      position.x = position.x.clamp(0.0, 1280.0);

      // Determine animation direction based on joystick angle
      PlayerDirection newDirection = currentDirection;
      
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
      
      changeDirection(newDirection);
    } else {
      if (currentState == PlayerState.run) {
        stopRunning();
      }
    }
  }

  Future<SpriteAnimation> _loadAnimation(String path, {required int amount, double stepTime = 0.1, bool loop = true}) async {
    final image = await game.images.load(path);
    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        // Calculate the size of a single frame (Image Width / number of frames)
        textureSize: Vector2(image.width / amount, image.height.toDouble()),
        loop: loop,
      ),
    );
  }

  void strike() {
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
    
    // Swing the paddle alongside the character
    paddle.swing();
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
