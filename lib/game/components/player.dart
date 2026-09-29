import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/battle_technique.dart';
import '../../models/character_roster.dart';
import '../../services/audio_service.dart';
import '../../services/multiplayer_service.dart';
import '../pickleball_game.dart';

enum PlayerDirection { front, behind, left, right }
enum PlayerState { idle, run, slash }

class PlayerAfterimage {
  Vector2 position;
  Sprite? sprite;
  double opacity;
  final Color tint;

  PlayerAfterimage({
    required this.position,
    this.sprite,
    this.opacity = 0.65,
    this.tint = const Color(0xFF38BDF8),
  });
}

class DashDustParticle {
  Vector2 position;
  Vector2 velocity;
  double life;
  double maxLife;
  double radius;
  Color color;

  DashDustParticle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxLife,
    required this.radius,
    required this.color,
  });
}

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
  final CharacterType characterType;
  final bool isAI;
  final int playerSlot; // 1 = Primary, 2 = Partner
  JoystickComponent? joystick;
  
  final double speed = 280.0;
  final double aiSpeed = 315.0; // Expert agile speed with smooth acceleration
  Vector2 currentVelocity = Vector2.zero();
  Vector2 aiVelocity = Vector2.zero();

  RemotePlayerInterpolator? remoteInterpolator;
  bool get isRemote => remoteInterpolator != null;

  int hAxis = 0;
  int vAxis = 0;
  bool _animationsLoaded = false;
  double timeSinceLastVolley = 999.0;

  BattleTechnique activeTechnique = BattleTechnique.none;
  double techniquePrimeTimer = 0.0;

  void queueTechnique(BattleTechnique tech) {
    activeTechnique = tech;
    techniquePrimeTimer = 4.5;
    if (!currentGame.isWaitingForServe) {
      final ball = currentGame.ball;
      final distY = (ball.position.y - position.y).abs();
      final distX = (ball.position.x - position.x).abs();
      if (distY < 100 && distX < 80) {
        strike();
      }
    }
  }

  void clearTechnique() {
    activeTechnique = BattleTechnique.none;
    techniquePrimeTimer = 0.0;
    try {
      currentGame.leftSpinButton?.isPrimed = false;
      currentGame.rightSpinButton?.isPrimed = false;
      currentGame.dashButton?.isPrimed = false;
      currentGame.thunderButton?.isPrimed = false;
      currentGame.phantomButton?.isPrimed = false;
    } catch (_) {}
  }

  // Dash Movement Skill Properties
  bool isDashing = false;
  double dashTimer = 0.0;
  static const double dashDuration = 0.22;
  static const double dashSpeed = 750.0;
  Vector2 dashDirection = Vector2.zero();
  double dashCooldown = 0.0;
  static const double defaultDashCooldown = 3.5;
  final List<PlayerAfterimage> afterimages = [];
  double _afterimageSpawnTimer = 0.0;
  final List<DashDustParticle> dashParticles = [];
  double _footstepTimer = 0.22;

  // Reusable cached paints for zero-allocation 60 FPS rendering
  static final Paint _shadowOuterPaint = Paint()..color = const Color(0x45000000);
  static final Paint _shadowInnerPaint = Paint()..color = const Color(0x60000000);
  final Paint _afterimagePaint = Paint();
  final Paint _ghostPaint = Paint()..style = PaintingStyle.fill;
  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;
  final Paint _streakPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2;
  final Paint _auraPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3.0;
  final Paint _glowPaint = Paint()..style = PaintingStyle.fill;
  final Paint _fallbackHeadPaint = Paint()..color = const Color(0xFFFFE0B2);
  final Paint _fallbackBodyPaint = Paint();

  Vector2 getFacingDirectionVector() {
    switch (currentDirection) {
      case PlayerDirection.front:
        return Vector2(0, -1);
      case PlayerDirection.behind:
        return Vector2(0, 1);
      case PlayerDirection.left:
        return Vector2(-1, 0);
      case PlayerDirection.right:
        return Vector2(1, 0);
    }
  }

  bool dash({Vector2? customDirection}) {
    if (isDashing || dashCooldown > 0) return false;

    Vector2 dir;
    if (customDirection != null && !customDirection.isZero()) {
      dir = customDirection.normalized();
    } else if (joystick != null && !joystick!.delta.isZero()) {
      dir = joystick!.relativeDelta.normalized();
    } else if (hAxis != 0 || vAxis != 0) {
      dir = Vector2(hAxis.toDouble(), vAxis.toDouble()).normalized();
    } else if (currentVelocity.length > 20.0) {
      dir = currentVelocity.normalized();
    } else {
      if (!isAI && !currentGame.isWaitingForServe) {
        final ballPos = currentGame.ball.position;
        final toBall = ballPos - position;
        if (toBall.length > 20.0 && toBall.length < 350.0) {
          dir = toBall.normalized();
        } else {
          dir = getFacingDirectionVector();
        }
      } else {
        dir = getFacingDirectionVector();
      }
    }

    if (dir.isZero()) {
      dir = isPlayerOne ? Vector2(0, -1) : Vector2(0, 1);
    }

    dashDirection = dir;
    isDashing = true;
    dashTimer = dashDuration;
    dashCooldown = defaultDashCooldown;
    currentVelocity = dashDirection * dashSpeed;

    // Update facing direction based on dash vector
    if (dashDirection.y.abs() > dashDirection.x.abs() * 1.1) {
      changeDirection(dashDirection.y > 0 ? PlayerDirection.behind : PlayerDirection.front);
    } else {
      changeDirection(dashDirection.x < 0 ? PlayerDirection.left : PlayerDirection.right);
    }

    // Trigger audio
    AudioService.instance.playDash();

    // Trigger camera micro-shake if enabled
    if (isPlayerOne && !isAI && (currentGame.settings?.screenShakeEnabled ?? true)) {
      currentGame.camera.viewfinder.position = Vector2(640, 362);
      Future.delayed(const Duration(milliseconds: 35), () {
        currentGame.camera.viewfinder.position = Vector2(640, 358);
      });
      Future.delayed(const Duration(milliseconds: 70), () {
        currentGame.camera.viewfinder.position = Vector2(640, 360);
      });
    }

    // Spawn burst of dust particles behind dash direction (only if particles enabled)
    final bool enableParticles = currentGame.settings?.particlesEnabled ?? true;
    if (enableParticles) {
      final backAngle = math.atan2(-dashDirection.y, -dashDirection.x);
      final count = (currentGame.settings?.graphicsQuality == 'Low') ? 3 : 6;
      for (int i = 0; i < count; i++) {
        final angle = backAngle + (math.Random().nextDouble() - 0.5) * 1.0;
        final pSpeed = 40.0 + math.Random().nextDouble() * 80.0;
        dashParticles.add(
          DashDustParticle(
            position: position.clone(),
            velocity: Vector2(math.cos(angle), math.sin(angle)) * pSpeed,
            life: 0.30 + math.Random().nextDouble() * 0.15,
            maxLife: 0.45,
            radius: 2.5 + math.Random().nextDouble() * 3.0,
            color: const Color(0xFFBAE6FD).withAlpha(180),
          ),
        );
      }
    }

    // Capture initial afterimage
    _captureAfterimage();

    // Notify game for HUD cooldown if human player
    if (isPlayerOne && !isAI) {
      currentGame.onTechniqueExecuted(BattleTechnique.dash);
    }

    return true;
  }

  void _captureAfterimage() {
    final maxAfterimages = (currentGame.settings?.graphicsQuality == 'Low') ? 2 : 4;
    while (afterimages.length >= maxAfterimages) {
      afterimages.removeAt(0);
    }

    Sprite? currentSprite;
    try {
      if (animation != null && animation!.frames.isNotEmpty) {
        final idx = (animationTicker?.currentIndex ?? 0).clamp(0, animation!.frames.length - 1);
        currentSprite = animation!.frames[idx].sprite;
      }
    } catch (_) {}

    afterimages.add(
      PlayerAfterimage(
        position: position.clone(),
        sprite: currentSprite,
        opacity: 0.65,
        tint: isPlayerOne ? const Color(0xFF38BDF8) : const Color(0xFFF472B6),
      ),
    );
  }

  void updateJoystick(JoystickComponent newJoystick) {
    joystick = newJoystick;
  }

  PlayerComponent({
    this.isPlayerOne = true, 
    bool? isFemale,
    CharacterType? characterType,
    this.joystick,
    bool? isAI,
    this.playerSlot = 1,
  })  : isAI = isAI ?? (!isPlayerOne),
        characterType = characterType ??
            (isFemale == true
                ? CharacterType.female1
                : (isFemale == false
                    ? CharacterType.male1
                    : (!isPlayerOne ? CharacterType.female1 : CharacterType.male1))),
        isFemale = characterType != null
            ? (characterType == CharacterType.female1 || characterType == CharacterType.female2)
            : (isFemale ?? (!isPlayerOne)),
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

    if (keysPressed.contains(LogicalKeyboardKey.space) || keysPressed.contains(LogicalKeyboardKey.keyJ)) {
      strike();
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyK)) {
      currentGame.triggerLeftSpin();
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyL)) {
      currentGame.triggerRightSpin();
    }
    if (keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
        keysPressed.contains(LogicalKeyboardKey.shiftRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyI)) {
      currentGame.triggerDash();
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  Future<void> onLoad() async {
    // Add hitbox for ball collisions
    add(RectangleHitbox());
    
    try {
      if (characterType == CharacterType.female1) {
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
      } else if (characterType == CharacterType.male2) {
        // Male 2 (Marcus Blaze) sprites
        frontRun = await _loadAnimation([
          'male2_sprite/male2_frontrun.png',
        ], amount: 8);
        behindRun = await _loadAnimation([
          'male2_sprite/male2_behindrun.png',
        ], amount: 8);
        leftRun = await _loadAnimation([
          'male2_sprite/male2_leftrun.png',
        ], amount: 8);
        rightRun = await _loadAnimation([
          'male2_sprite/male2_rightrun.png',
        ], amount: 8);

        p1Idle = await _loadAnimation([
          'male2_sprite/male2_p1sideidle.png',
        ], amount: 2, stepTime: 0.35);

        p2Idle = await _loadAnimation([
          'male2_sprite/male2_p2sideidle.png',
        ], amount: 2, stepTime: 0.35);

        frontSlash = await _loadAnimation([
          'male2_sprite/male2_frontslash.png',
        ], amount: 6, loop: false, stepTime: 0.06);

        behindSlash = await _loadAnimation([
          'male2_sprite/male2_behindslash.png',
        ], amount: 6, loop: false, stepTime: 0.06);
      } else if (characterType == CharacterType.male3) {
        // Male 3 (Jax Thunder) sprites
        frontRun = await _loadAnimation([
          'male3_sprite/male3_frontrun.png',
        ], amount: 8);
        behindRun = await _loadAnimation([
          'male3_sprite/male3_behindrun.png',
        ], amount: 8);
        leftRun = await _loadAnimation([
          'male3_sprite/male3_leftrun.png',
        ], amount: 8);
        rightRun = await _loadAnimation([
          'male3_sprite/male3_rightrun.png',
        ], amount: 8);

        p1Idle = await _loadAnimation([
          'male3_sprite/male3_p1sideidle.png',
        ], amount: 2, stepTime: 0.35);

        p2Idle = await _loadAnimation([
          'male3_sprite/male3_p2sideidle.png',
        ], amount: 2, stepTime: 0.35);

        frontSlash = await _loadAnimation([
          'male3_sprite/male3_frontslash.png',
        ], amount: 6, loop: false, stepTime: 0.06);

        behindSlash = await _loadAnimation([
          'male3_sprite/male3_behindslash.png',
        ], amount: 6, loop: false, stepTime: 0.06);
      } else if (characterType == CharacterType.female2) {
        // Female 2 (Chloe Frost) sprites
        frontRun = await _loadAnimation([
          'female2_sprite/female2_frontrun.png',
        ], amount: 8);
        behindRun = await _loadAnimation([
          'female2_sprite/female2_behindrun.png',
        ], amount: 8);
        leftRun = await _loadAnimation([
          'female2_sprite/female2_leftrun.png',
        ], amount: 8);
        rightRun = await _loadAnimation([
          'female2_sprite/female2_rightrun.png',
        ], amount: 8);

        p1Idle = await _loadAnimation([
          'female2_sprite/female2_p1sideidle.png',
        ], amount: 2, stepTime: 0.35);

        p2Idle = await _loadAnimation([
          'female2_sprite/female2_p2sideidle.png',
        ], amount: 2, stepTime: 0.35);

        frontSlash = await _loadAnimation([
          'female2_sprite/female2_frontslash.png',
        ], amount: 6, loop: false, stepTime: 0.06);

        behindSlash = await _loadAnimation([
          'female2_sprite/female2_behindslash.png',
        ], amount: 6, loop: false, stepTime: 0.06);
      } else {
        // Male 1 (Alex Smash) reworked sprites
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

    if (techniquePrimeTimer > 0) {
      techniquePrimeTimer = math.max(0.0, techniquePrimeTimer - dt);
      if (techniquePrimeTimer <= 0) {
        clearTechnique();
      }
    }

    if (dashCooldown > 0) {
      dashCooldown = math.max(0.0, dashCooldown - dt);
    }

    // Update afterimages decay
    if (afterimages.isNotEmpty) {
      for (int i = afterimages.length - 1; i >= 0; i--) {
        final img = afterimages[i];
        img.opacity -= dt * 3.2;
        if (img.opacity <= 0.0) {
          afterimages.removeAt(i);
        }
      }
    }

    // Update dash dust particles
    if (dashParticles.isNotEmpty) {
      for (int i = dashParticles.length - 1; i >= 0; i--) {
        final p = dashParticles[i];
        p.life -= dt;
        p.position += p.velocity * dt;
        if (p.life <= 0) {
          dashParticles.removeAt(i);
        }
      }
    }
    
    if (currentState == PlayerState.slash) return; // Don't move while slashing

    if (remoteInterpolator != null) {
      remoteInterpolator!.update(dt);
      position.setValues(remoteInterpolator!.currentX, remoteInterpolator!.currentY);
      final vx = remoteInterpolator!.velocityX;
      final vy = remoteInterpolator!.velocityY;
      if (vx.abs() > 15 || vy.abs() > 15) {
        if (vx.abs() > vy.abs()) {
          changeDirection(vx > 0 ? PlayerDirection.right : PlayerDirection.left);
        } else {
          changeDirection(vy > 0 ? PlayerDirection.behind : PlayerDirection.front);
        }
      } else {
        stopRunning();
      }
      return;
    }

    if (isPlayerOne && !isAI) {
      if (isDashing) {
        dashTimer -= dt;
        _afterimageSpawnTimer += dt;
        if (_afterimageSpawnTimer >= 0.04) {
          _afterimageSpawnTimer = 0.0;
          _captureAfterimage();
        }
        position.add(dashDirection * (dashSpeed * dt));

        if (dashTimer <= 0) {
          isDashing = false;
          currentVelocity = dashDirection * speed;
        }
      } else {
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

          // Retro arcade walking footstep SFX & foot dust (only if particles enabled)
          if (!isDashing && currentState != PlayerState.slash) {
            _footstepTimer += dt;
            if (_footstepTimer >= 0.26) {
              _footstepTimer = 0.0;
              AudioService.instance.playFootstep();
              final bool enableParticles = currentGame.settings?.particlesEnabled ?? true;
              if (enableParticles && dashParticles.length < 8) {
                dashParticles.add(
                  DashDustParticle(
                    position: Vector2(
                      position.x + (math.Random().nextDouble() - 0.5) * 12.0,
                      position.y + size.y * 0.38,
                    ),
                    velocity: Vector2(
                      (math.Random().nextDouble() - 0.5) * 18.0,
                      (math.Random().nextDouble() - 0.5) * 10.0,
                    ),
                    life: 0.20,
                    maxLife: 0.20,
                    radius: 1.6 + math.Random().nextDouble() * 1.4,
                    color: const Color(0xFFE2E8F0).withAlpha(130),
                  ),
                );
              }
            }
          }
        } else {
          _footstepTimer = 0.22;
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
    if (isDashing) {
      dashTimer -= dt;
      _afterimageSpawnTimer += dt;
      if (_afterimageSpawnTimer >= 0.04) {
        _afterimageSpawnTimer = 0.0;
        _captureAfterimage();
      }
      position.add(dashDirection * (dashSpeed * dt));
      if (dashTimer <= 0) {
        isDashing = false;
        aiVelocity = dashDirection * aiSpeed;
      }
      _clampToCourt();
      return;
    }

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

      if (!isDashing && math.Random().nextDouble() < 0.18) {
        dashParticles.add(
          DashDustParticle(
            position: Vector2(position.x + (math.Random().nextDouble() - 0.5) * 10.0, position.y + size.y * 0.38),
            velocity: Vector2((math.Random().nextDouble() - 0.5) * 15.0, (math.Random().nextDouble() - 0.5) * 8.0),
            life: 0.18,
            maxLife: 0.18,
            radius: 1.5,
            color: const Color(0xFFE2E8F0).withAlpha(100),
          ),
        );
      }

      if (ball.velocity.y > 0 && !currentGame.isGameOver && !currentGame.isWaitingForServe) {
        final distToTarget = math.sqrt(diffX * diffX + diffY * diffY);
        if (distToTarget > 140.0 && ball.bounceCountCurrentSide >= 1 && dashCooldown <= 0 && !isDashing) {
          dash(customDirection: Vector2(diffX, diffY).normalized());
          currentGame.onAnnouncement?.call('💨 PARTNER DASH!', 'Clutch positioning save!');
        }
      }

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
    if (isDashing) {
      dashTimer -= dt;
      _afterimageSpawnTimer += dt;
      if (_afterimageSpawnTimer >= 0.04) {
        _afterimageSpawnTimer = 0.0;
        _captureAfterimage();
      }
      position.add(dashDirection * (dashSpeed * dt));
      if (dashTimer <= 0) {
        isDashing = false;
        aiVelocity = dashDirection * aiSpeed;
      }
      _clampToCourt();
      return;
    }

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

      final bool enableParticles = currentGame.settings?.particlesEnabled ?? true;
      if (enableParticles && !isDashing && dashParticles.length < 8 && math.Random().nextDouble() < 0.18) {
        dashParticles.add(
          DashDustParticle(
            position: Vector2(position.x + (math.Random().nextDouble() - 0.5) * 10.0, position.y + size.y * 0.38),
            velocity: Vector2((math.Random().nextDouble() - 0.5) * 15.0, (math.Random().nextDouble() - 0.5) * 8.0),
            life: 0.18,
            maxLife: 0.18,
            radius: 1.5,
            color: const Color(0xFFE2E8F0).withAlpha(100),
          ),
        );
      }

      if (ball.velocity.y < 0 && !currentGame.isGameOver && !currentGame.isWaitingForServe) {
        final distToTarget = math.sqrt(diffX * diffX + diffY * diffY);
        if (distToTarget > 140.0 && ball.bounceCountCurrentSide >= 1 && dashCooldown <= 0 && !isDashing) {
          dash(customDirection: Vector2(diffX, diffY).normalized());
          currentGame.onAnnouncement?.call('💨 CPU FLASH DASH!', 'Lightning court recovery!');
        }
      }

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
    if (isDashing) {
      isDashing = false;
    }

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
        _shadowOuterPaint,
      );
      // Denser contact inner shadow
      canvas.drawOval(
        Rect.fromCenter(
          center: shadowCenter,
          width: size.x * 0.40,
          height: size.y * 0.12,
        ),
        _shadowInnerPaint,
      );
    }

    // 2. Render motion trail afterimages
    for (final img in afterimages) {
      final relOffset = img.position - position;
      final drawX = relOffset.x;
      final drawY = relOffset.y;
      if (img.sprite != null) {
        _afterimagePaint
          ..colorFilter = ColorFilter.mode(
            img.tint.withAlpha((img.opacity * 190).round()),
            BlendMode.srcATop,
          )
          ..color = Colors.white.withAlpha((img.opacity * 255).round());
        img.sprite!.render(
          canvas,
          position: Vector2(drawX, drawY),
          size: size,
          overridePaint: _afterimagePaint,
        );
      } else {
        _ghostPaint.color = img.tint.withAlpha((img.opacity * 140).round());
        canvas.drawCircle(Offset(size.x / 2 + drawX, size.y * 0.55 + drawY), size.x * 0.35, _ghostPaint);
      }
    }

    // 3. Render dash dust particles
    final bool enableParticles = currentGame.settings?.particlesEnabled ?? true;
    if (enableParticles && dashParticles.isNotEmpty) {
      for (final p in dashParticles) {
        final relOffset = p.position - position;
        final pAlpha = (p.life / p.maxLife).clamp(0.0, 1.0);
        _particlePaint.color = p.color.withAlpha((pAlpha * 220).round());
        canvas.drawCircle(Offset(size.x / 2 + relOffset.x, size.y * 0.85 + relOffset.y), p.radius * pAlpha, _particlePaint);
      }
    }

    // 4. Render speed streak lines while dashing
    if (isDashing) {
      _streakPaint.color = (isPlayerOne ? const Color(0xFF38BDF8) : const Color(0xFFF472B6)).withAlpha(200);
      final backDir = -dashDirection;
      for (int i = -1; i <= 1; i++) {
        final startOffset = Offset(
          size.x / 2 + (i * 12.0) * (-dashDirection.y),
          size.y * 0.6 + (i * 12.0) * (dashDirection.x),
        );
        final endOffset = Offset(
          startOffset.dx + backDir.x * 28.0,
          startOffset.dy + backDir.y * 28.0,
        );
        canvas.drawLine(startOffset, endOffset, _streakPaint);
      }
    }

    // 5. Render character sprite animation or fallback
    if (animation != null) {
      super.render(canvas);
    } else {
      // Stylized fallback character rendering so player is NEVER invisible
      final bodyColor = isPlayerOne ? const Color(0xFF00E5FF) : const Color(0xFFFF5252);
      _fallbackBodyPaint.color = bodyColor;
      canvas.drawCircle(Offset(size.x / 2, size.y * 0.25), size.x * 0.2, _fallbackHeadPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(size.x / 2, size.y * 0.6), width: size.x * 0.5, height: size.y * 0.5),
          const Radius.circular(6),
        ),
        _fallbackBodyPaint,
      );
    }

    // 6. Render active battle technique primed aura
    if (activeTechnique != BattleTechnique.none) {
      final pulse = math.sin((currentGame.elapsedTime) * 10.0) * 3.0;
      final isLeft = activeTechnique == BattleTechnique.leftSpin;
      final auraColor = isLeft ? const Color(0xFF10B981) : const Color(0xFFA855F7);

      _auraPaint.color = auraColor.withAlpha(140);
      canvas.drawCircle(Offset(size.x / 2, size.y * 0.55), size.x * 0.45 + pulse, _auraPaint);

      _glowPaint.color = auraColor.withAlpha(50);
      canvas.drawCircle(Offset(size.x / 2, size.y * 0.55), size.x * 0.42 + pulse, _glowPaint);
    }
  }
}
