import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pickleball_game.dart';

enum PlayerDirection { front, behind, left, right }
enum PlayerState { idle, run, slash }

class PlayerComponent extends SpriteAnimationComponent with HasGameReference<PickleballGame>, KeyboardHandler {
  PickleballGame? customGame;
  PickleballGame get currentGame {
    if (customGame != null) return customGame!;
    return game;
  }

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
  final bool isAI;
  final int playerSlot; // 1 = Primary, 2 = Partner
  JoystickComponent? joystick;
  
  final double speed = 280.0;
  final double aiSpeed = 315.0; // Expert agile speed with smooth acceleration
  Vector2 currentVelocity = Vector2.zero();
  Vector2 aiVelocity = Vector2.zero();

  int hAxis = 0;
  int vAxis = 0;
  bool _animationsLoaded = false;
  double timeSinceLastVolley = 999.0;

  void updateJoystick(JoystickComponent newJoystick) {
    joystick = newJoystick;
  }

  PlayerComponent({
    this.isPlayerOne = true, 
    bool? isFemale,
    this.joystick,
    bool? isAI,
    this.playerSlot = 1,
  })  : isAI = isAI ?? (!isPlayerOne),
        isFemale = isFemale ?? (!isPlayerOne),
        currentDirection = isPlayerOne ? PlayerDirection.front : PlayerDirection.behind {
    size = Vector2(64, 64);
    scale = Vector2.all(1.5);
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    anchor = Anchor.center;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!isPlayerOne || isAI) return super.onKeyEvent(event, keysPressed);

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
    
    try {
      if (isFemale) {
        // Female reworked sprites
        frontRun = await _loadAnimation([
          'female1_sprite/female_runfront.png',
          'female1 sprite (reworked)/female_runfront.png',
        ], amount: 8);
        behindRun = await _loadAnimation([
          'female1_sprite/female_runbehind.png',
          'female1 sprite (reworked)/female_runbehind.png',
        ], amount: 8);
        leftRun = await _loadAnimation([
          'female1_sprite/female_runleft.png',
          'female1 sprite (reworked)/female_runleft.png',
        ], amount: 8);
        rightRun = await _loadAnimation([
          'female1_sprite/female_runright.png',
          'female1 sprite (reworked)/female_runright.png',
        ], amount: 8);

        p1Idle = await _loadAnimation([
          'female1_sprite/female_p1sideidle.png',
          'female1 sprite (reworked)/female_p1sideidle.png',
          'female1_sprite/female_runfront.png',
        ], amount: 2, stepTime: 0.35);

        p2Idle = await _loadAnimation([
          'female1_sprite/female_p2sideidle.png',
          'female1 sprite (reworked)/female_p2sideidle.png',
          'female1_sprite/female_runbehind.png',
        ], amount: 2, stepTime: 0.35);

        // 384x64 has 6 frames of 64x64
        frontSlash = await _loadAnimation([
          'female1_sprite/female_frontslash.png',
          'female1 sprite (reworked)/female_frontslash.png',
        ], amount: 6, loop: false, stepTime: 0.06);

        behindSlash = await _loadAnimation([
          'female1_sprite/female_behindslash.png',
          'female1 sprite (reworked)/female _behindslash.png',
        ], amount: 6, loop: false, stepTime: 0.06);
      } else {
        // Male reworked sprites
        frontRun = await _loadAnimation([
          'male1_sprite/male_frontrun.png',
          'male1 sprite (reworked)/male_frontrun.png',
        ], amount: 8);
        behindRun = await _loadAnimation([
          'male1_sprite/male_behindrun.png',
          'male1 sprite (reworked)/male_behindrun.png',
        ], amount: 8);
        leftRun = await _loadAnimation([
          'male1_sprite/male_leftrun.png',
          'male1 sprite (reworked)/male_leftrun.png',
        ], amount: 8);
        rightRun = await _loadAnimation([
          'male1_sprite/male_rightrun.png',
          'male1 sprite (reworked)/male_rightrun.png',
        ], amount: 8);

        p1Idle = await _loadAnimation([
          'male1_sprite/male_p1sideidle.png',
          'male1 sprite (reworked)/male_p1sideidle.png',
        ], amount: 2, stepTime: 0.35);

        p2Idle = await _loadAnimation([
          'male1_sprite/male_p2sideidle.png',
          'male1 sprite (reworked)/male_p2sideidle.png',
        ], amount: 2, stepTime: 0.35);

        // 384x64 has 6 frames of 64x64
        frontSlash = await _loadAnimation([
          'male1_sprite/male_frontslash.png',
          'male1 sprite (reworked)/male_frontslash.png',
        ], amount: 6, loop: false, stepTime: 0.06);

        behindSlash = await _loadAnimation([
          'male1_sprite/male_behindslash.png',
          'male1 sprite (reworked)/male_behindslash.png',
        ], amount: 6, loop: false, stepTime: 0.06);
      }

      animation = isPlayerOne ? p1Idle : p2Idle;
      _animationsLoaded = true;
    } catch (e) {
      debugPrint('Warning: PlayerComponent failed to load sprite animations: $e');
      _animationsLoaded = false;
    }
    
    // Set the component size to match a single 64x64 frame exactly
    size = Vector2(64, 64);
    
    // Scale shrunk down a little bit as requested
    scale = Vector2.all(1.5);
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    
    anchor = Anchor.center;
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

    if (isPlayerOne && !isAI) {
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
          newDirection = PlayerDirection.front;
        } else if (joystick!.direction == JoystickDirection.down || 
                   joystick!.direction == JoystickDirection.downLeft || 
                   joystick!.direction == JoystickDirection.downRight) {
          newDirection = PlayerDirection.behind;
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
        final targetVel = moveDelta * speed;
        currentVelocity.lerp(targetVel, (dt * 14.0).clamp(0.0, 1.0));
        changeDirection(newDirection);
        position.add(currentVelocity * dt);
      } else {
        currentVelocity.lerp(Vector2.zero(), (dt * 16.0).clamp(0.0, 1.0));
        if (currentVelocity.length > 5.0) {
          position.add(currentVelocity * dt);
        } else {
          currentVelocity = Vector2.zero();
          if (currentState == PlayerState.run) {
            stopRunning();
          }
        }
      }
    } else {
      // AI Controlled Players (Team 1 AI Partner or Team 2 CPU)
      if (isPlayerOne) {
        _updateTeam1PartnerAI(dt);
      } else {
        _updateTeam2AI(dt);
      }
    }

    _clampToCourt();

    // Rule 3: Kitchen Momentum Fault Check
    // If a player hit a volley, forward momentum cannot carry them into the Kitchen!
    timeSinceLastVolley += dt;
    if (timeSinceLastVolley <= 0.5 && !currentGame.isGameOver && !currentGame.isWaitingForServe) {
      if (isPlayerOne && position.y <= 440.0) {
        timeSinceLastVolley = 999.0;
        currentGame.handleRallyWon(
          winnerIsPlayerOne: false,
          faultReason: 'FAULT: Kitchen Momentum (Momentum carried player into Non-Volley Zone)',
        );
      } else if (!isPlayerOne && position.y >= 280.0) {
        timeSinceLastVolley = 999.0;
        currentGame.handleRallyWon(
          winnerIsPlayerOne: true,
          faultReason: 'FAULT: Kitchen Momentum (Momentum carried player into Non-Volley Zone)',
        );
      }
    }
  }

  void _updateTeam1PartnerAI(double dt) {
    if (currentGame.isWaitingForServe) {
      final activeServer = currentGame.activeServerComponent;
      final bool isServer = (this == activeServer);
      final side = currentGame.p1PartnerCourtSide;
      final targetX = (side == 'right') ? 760.0 : 520.0;
      final targetY = isServer ? 695.0 : 580.0;
      final dx = targetX - position.x;
      final dy = targetY - position.y;
      if (dx.abs() > 6 || dy.abs() > 6) {
        final moveStep = Vector2(dx, dy).normalized() * (aiSpeed * 0.7 * dt);
        position += moveStep;
        if (dx.abs() > dy.abs()) {
          changeDirection(dx > 0 ? PlayerDirection.right : PlayerDirection.left);
        } else {
          changeDirection(dy > 0 ? PlayerDirection.behind : PlayerDirection.front);
        }
      } else {
        stopRunning();
      }
      _clampToCourt();
      return;
    }

    final ball = currentGame.ball;
    double targetX = position.x;
    double targetY = position.y;
    final side = currentGame.p1PartnerCourtSide;
    final double homeX = (side == 'right') ? 760.0 : 520.0;
    const double homeY = 570.0;

    if (ball.velocity.y > 0) {
      // Expert Predictive Interception: project future landing coordinate
      final estY = (ball.bounceCountCurrentSide >= 1) ? ball.position.y : 570.0;
      final tReach = ((estY - ball.position.y) / math.max(40.0, ball.velocity.y)).clamp(0.0, 1.2);
      final predictedX = ball.position.x + ball.velocity.x * tReach;

      final bool inMyZone = (side == 'right') ? (predictedX >= 630.0) : (predictedX <= 650.0);
      final distToMe = (Vector2(predictedX, estY) - position).length;
      final distToP1 = (Vector2(predictedX, estY) - currentGame.player1.position).length;

      if (inMyZone || distToMe < distToP1) {
        final minX = (side == 'right') ? 635.0 : 340.0;
        final maxX = (side == 'right') ? 940.0 : 645.0;
        targetX = predictedX.clamp(minX, maxX);

        if (ball.bounceCountCurrentSide >= 1) {
          // Ball bounced! Rush directly to hit point
          targetY = (ball.position.y + 20.0).clamp(445.0, 640.0);
        } else if (currentGame.rallyHitCount == 1) {
          targetY = 590.0;
        } else if (ball.position.y < 490.0) {
          targetY = 480.0; // Ready near kitchen
        } else {
          targetY = 585.0; // Baseline depth
        }
      } else {
        targetX = homeX;
        targetY = homeY;
      }
    } else {
      targetX = homeX;
      targetY = homeY;
    }

    final diffX = targetX - position.x;
    final diffY = targetY - position.y;
    final isMovingX = diffX.abs() > 5;
    final isMovingY = diffY.abs() > 5;

    if (isMovingX || isMovingY) {
      final moveVec = Vector2(diffX, diffY).normalized();
      final targetVel = moveVec * aiSpeed;
      aiVelocity.lerp(targetVel, (dt * 12.0).clamp(0.0, 1.0));
      position += aiVelocity * dt;

      if (diffY.abs() > diffX.abs() * 1.1) {
        changeDirection(diffY > 0 ? PlayerDirection.behind : PlayerDirection.front);
      } else {
        changeDirection(diffX < 0 ? PlayerDirection.left : PlayerDirection.right);
      }
    } else {
      aiVelocity.lerp(Vector2.zero(), (dt * 14.0).clamp(0.0, 1.0));
      if (aiVelocity.length > 5.0) {
        position += aiVelocity * dt;
      } else {
        aiVelocity = Vector2.zero();
        stopRunning();
      }
    }

    _clampToCourt();

    final distY = (ball.position.y - position.y).abs();
    final distX = (ball.position.x - position.x).abs();
    if (ball.velocity.y > 0 && distY < 115 && distX < 95) {
      // Ball must bounce first on the court floor before striking
      if (ball.bounceCountCurrentSide >= 1) {
        strike();
      }
    }
  }

  void _updateTeam2AI(double dt) {
    final bool isDoubles = currentGame.isDoubles;
    final String mySide = isDoubles
        ? (playerSlot == 1 ? currentGame.p2CourtSide : currentGame.p2PartnerCourtSide)
        : currentGame.servingSide;

    if (currentGame.isWaitingForServe) {
      final activeServer = currentGame.activeServerComponent;
      final bool isServer = (this == activeServer);
      final targetX = (mySide == 'right') ? 520.0 : 760.0;
      final targetY = isServer ? 25.0 : 140.0;
      final dx = targetX - position.x;
      final dy = targetY - position.y;
      if (dx.abs() > 6 || dy.abs() > 6) {
        final moveStep = Vector2(dx, dy).normalized() * (aiSpeed * 0.7 * dt);
        position += moveStep;
        if (dx.abs() > dy.abs()) {
          changeDirection(dx > 0 ? PlayerDirection.right : PlayerDirection.left);
        } else {
          changeDirection(dy > 0 ? PlayerDirection.front : PlayerDirection.behind);
        }
      } else {
        stopRunning();
      }
      _clampToCourt();
      return;
    }

    final ball = currentGame.ball;
    double targetX = position.x;
    double targetY = position.y;

    final double homeX = isDoubles ? ((mySide == 'right') ? 520.0 : 760.0) : 640.0;
    const double homeY = 150.0;

    if (ball.velocity.y < 0) {
      // Expert Predictive Interception: project future landing coordinate
      final estY = (ball.bounceCountCurrentSide >= 1) ? ball.position.y : 150.0;
      final tReach = ((ball.position.y - estY) / math.max(40.0, -ball.velocity.y)).clamp(0.0, 1.2);
      final predictedX = ball.position.x + ball.velocity.x * tReach;

      bool shouldTrack = true;
      if (isDoubles) {
        final bool inMyHalf = (mySide == 'right') ? (predictedX <= 645.0) : (predictedX >= 635.0);
        shouldTrack = inMyHalf;
      }

      if (shouldTrack) {
        if (isDoubles) {
          final minX = (mySide == 'right') ? 340.0 : 635.0;
          final maxX = (mySide == 'right') ? 645.0 : 940.0;
          targetX = predictedX.clamp(minX, maxX);
        } else {
          targetX = predictedX.clamp(340.0, 940.0);
        }

        if (ball.bounceCountCurrentSide >= 1) {
          // Ball bounced! Rush directly to hit point
          targetY = (ball.position.y - 20.0).clamp(90.0, 320.0);
        } else if (currentGame.rallyHitCount == 0) {
          targetY = 140.0;
        } else if (ball.position.y > 230) {
          targetY = 240.0; // Ready near kitchen
        } else {
          targetY = 120.0; // Baseline depth
        }
      } else {
        targetX = homeX;
        targetY = homeY;
      }
    } else {
      targetX = homeX;
      targetY = homeY;
    }

    final diffX = targetX - position.x;
    final diffY = targetY - position.y;
    final isMovingX = diffX.abs() > 5;
    final isMovingY = diffY.abs() > 5;

    if (isMovingX || isMovingY) {
      final moveVec = Vector2(diffX, diffY).normalized();
      final targetVel = moveVec * aiSpeed;
      aiVelocity.lerp(targetVel, (dt * 12.0).clamp(0.0, 1.0));
      position += aiVelocity * dt;

      if (diffY.abs() > diffX.abs() * 1.1) {
        changeDirection(diffY > 0 ? PlayerDirection.front : PlayerDirection.behind);
      } else {
        changeDirection(diffX < 0 ? PlayerDirection.left : PlayerDirection.right);
      }
    } else {
      aiVelocity.lerp(Vector2.zero(), (dt * 14.0).clamp(0.0, 1.0));
      if (aiVelocity.length > 5.0) {
        position += aiVelocity * dt;
      } else {
        aiVelocity = Vector2.zero();
        stopRunning();
      }
    }

    _clampToCourt();

    final distY = (ball.position.y - position.y).abs();
    final distX = (ball.position.x - position.x).abs();

    if (ball.velocity.y < 0 && distY < 115 && distX < 95) {
      // Ball must bounce first on the court floor before striking
      if (ball.bounceCountCurrentSide >= 1) {
        strike();
      }
    }
  }

  /// Clamps player to the playable court area, allowing them to step outside
  /// the white boundary lines into the apron to retrieve wide and deep balls,
  /// while preventing players from crossing the net into the opponent's court.
  void _clampToCourt() {
    const minPlayableX = 320.0;
    const maxPlayableX = 960.0;
    const topApronLimitY = 15.0;
    const bottomApronLimitY = 715.0;
    const p1NetLimitY = 385.0;
    const p2NetLimitY = 330.0;

    position.x = position.x.clamp(minPlayableX, maxPlayableX);

    if (isPlayerOne) {
      position.y = position.y.clamp(p1NetLimitY, bottomApronLimitY);
    } else {
      position.y = position.y.clamp(topApronLimitY, p2NetLimitY);
    }
  }

  /// Returns true if the player is currently standing outside the white boundary lines.
  bool get isOutsideCourt {
    const courtLeftX = 400.0;
    const courtRightX = 880.0;
    const topBaselineY = 50.0;
    const bottomBaselineY = 670.0;
    return position.x < courtLeftX ||
        position.x > courtRightX ||
        (isPlayerOne ? position.y > bottomBaselineY : position.y < topBaselineY);
  }

  Future<SpriteAnimation> _loadAnimation(
    List<String> candidatePaths, {
    required int amount,
    double stepTime = 0.1,
    bool loop = true,
    Vector2? textureSize,
  }) async {
    for (final path in candidatePaths) {
      try {
        final image = await currentGame.images.load(path);
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
      } catch (_) {
        // Try next candidate path
      }
    }
    throw StateError('Failed to load animation from candidate paths: $candidatePaths');
  }

  void strike() {
    // AI / bot players MUST let the ball bounce on the court floor once before they hit!
    if (isAI && !currentGame.isWaitingForServe && currentGame.ball.bounceCountCurrentSide == 0) {
      return; // Do NOT swing, animate slash, or hit before the floor bounce
    }

    if (isPlayerOne && !isAI) {
      currentGame.triggerSmashButtonEffect();
    }

    // Check if player is serving
    if (currentGame.isWaitingForServe) {
      final activeServer = currentGame.activeServerComponent;
      if (this == activeServer) {
        currentGame.ball.executeServe(
          isPlayerOne: isPlayerOne,
          horizontalAngle: horizontalMovement,
        );
      }
    } else {
      // Process ball hit if ball is within striking range
      final ball = currentGame.ball;
      final distY = (ball.position.y - position.y).abs();
      final distX = (ball.position.x - position.x).abs();
      if (distY < 95 && distX < 75) {
        // AI must always wait for floor bounce.
        // If player is outside the white line, the ball MUST have bounced first on the floor.
        // On serve return (rallyHitCount == 0) and 3rd shot (rallyHitCount == 1), ball MUST have bounced first.
        final bool requiresFloorBounce = isAI || isOutsideCourt || currentGame.rallyHitCount < 2;
        if (requiresFloorBounce && ball.bounceCountCurrentSide == 0) {
          return; // Ball has not bounced on the floor yet!
        }
        ball.processPlayerHit(this);
      }
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
      currentGame.onPlayerSmash();
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

  /// Whether player is currently standing inside the Non-Volley Zone (The Kitchen)
  bool get isInKitchen => isPlayerOne ? (position.y <= 440.0) : (position.y >= 280.0);

  @override
  void render(Canvas canvas) {
    // 1. Draw dynamic ground shadow beneath character feet
    final bool enableShadows = currentGame.settings?.shadowsEnabled ?? true;
    if (enableShadows) {
      final shadowCenter = Offset(size.x / 2, size.y * 0.90);
      // Soft ambient outer shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: shadowCenter,
          width: size.x * 0.62,
          height: size.y * 0.20,
        ),
        Paint()..color = const Color(0x45000000),
      );
      // Denser contact inner shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: shadowCenter,
          width: size.x * 0.40,
          height: size.y * 0.12,
        ),
        Paint()..color = const Color(0x60000000),
      );
    }

    // 2. Render character sprite animation or fallback
    if (animation != null) {
      super.render(canvas);
    } else {
      // Stylized fallback character rendering so player is NEVER invisible
      final bodyColor = isPlayerOne ? const Color(0xFF00E5FF) : const Color(0xFFFF5252);
      final headColor = const Color(0xFFFFE0B2);
      canvas.drawCircle(Offset(size.x / 2, size.y * 0.25), size.x * 0.2, Paint()..color = headColor);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(size.x / 2, size.y * 0.6), width: size.x * 0.5, height: size.y * 0.5),
          const Radius.circular(6),
        ),
        Paint()..color = bodyColor,
      );
    }
  }
}
