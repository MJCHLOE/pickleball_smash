import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../pickleball_game.dart';
import 'player.dart';

class BallComponent extends CircleComponent with HasGameReference<PickleballGame>, CollisionCallbacks {
  PickleballGame? customGame;
  PickleballGame get currentGame {
    if (customGame != null) return customGame!;
    return game;
  }

  Vector2 velocity = Vector2.zero();
  final double initialSpeed = 450.0;
  double speed = 450.0;

  // Serve & Bouncing state per official Pickleball rules
  bool isWaitingForServe = true;
  double _serveBobTime = 0.0;
  double _cpuServeTimer = 0.0;

  // Bounce tracking:
  // 0 = in air (volley if struck)
  // 1 = bounced once (groundstroke/dink if struck)
  // 2 = double bounce fault
  int bounceCountCurrentSide = 0;
  bool _hasBouncedOnCurrentSide = false;
  double _lastSideChangeY = 360.0;
  double _bounceEffectRadius = 0.0;

  // Court geometry constants
  static const double courtLeftX = 340.0;
  static const double courtRightX = 940.0;
  static const double courtCenterX = 640.0;
  static const double netY = 360.0;
  static const double kitchenTopY = 280.0;    // Top Kitchen line (for P2)
  static const double kitchenBottomY = 440.0; // Bottom Kitchen line (for P1)
  static const double topBaselineY = 60.0;
  static const double bottomBaselineY = 660.0;

  BallComponent() {
    radius = 11.0;
    anchor = Anchor.center;
    paint = Paint()..color = const Color(0xFFCCFF00); // Neon Pickleball Chartreuse
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox());
    setupForServe();
  }

  /// Sets up ball with the current server, ready for active serve
  void setupForServe() {
    isWaitingForServe = true;
    velocity = Vector2.zero();
    speed = initialSpeed;
    bounceCountCurrentSide = 0;
    _hasBouncedOnCurrentSide = false;
    _cpuServeTimer = 0.0;

    try {
      if (currentGame.serverPlayer == 1) {
        position = currentGame.player1.position + Vector2(20, -28);
        _lastSideChangeY = 720.0;
      } else {
        position = currentGame.player2.position + Vector2(-20, 28);
        _lastSideChangeY = 0.0;
      }
    } catch (_) {
      // Game references might still be initializing
      position = Vector2(760, 622);
    }
  }

  /// Executes underhand serve according to singles rotation diagonal target
  void executeServe({required bool isPlayerOne, double horizontalAngle = 0.0}) {
    if (!isWaitingForServe) return;
    isWaitingForServe = false;
    currentGame.isWaitingForServe = false;
    currentGame.rallyHitCount = 0;
    speed = initialSpeed;
    bounceCountCurrentSide = 0;
    _hasBouncedOnCurrentSide = false;

    AudioService.instance.playPaddleHit();

    Vector2 target;
    if (isPlayerOne) {
      // Player 1 serves diagonally upwards past the Kitchen (kitchenTopY = 280)
      if (currentGame.servingSide == 'right') {
        // From right court (X≈760) -> Opponent's right court (viewer's top-left: X≈490, Y≈170)
        target = Vector2(490, 170);
      } else {
        // From left court (X≈520) -> Opponent's left court (viewer's top-right: X≈790, Y≈170)
        target = Vector2(790, 170);
      }
      final dir = (target - position).normalized();
      final clampedAngle = horizontalAngle.clamp(-0.35, 0.35);
      velocity = Vector2(dir.x + clampedAngle * 0.25, dir.y).normalized() * speed;
    } else {
      // Player 2 (CPU) serves diagonally downwards past the Kitchen (kitchenBottomY = 440)
      if (currentGame.servingSide == 'right') {
        // From P2 right (viewer top-left X≈520) -> P1 right court (viewer bottom-right: X≈790, Y≈550)
        target = Vector2(790, 550);
      } else {
        // From P2 left (viewer top-right X≈760) -> P1 left court (viewer bottom-left: X≈490, Y≈550)
        target = Vector2(490, 550);
      }
      final dir = (target - position).normalized();
      velocity = dir * speed;
    }

    currentGame.onServeStateChanged?.call(false, currentGame.serverPlayer, currentGame.servingSide);
  }

  /// Legacy reset helper
  void resetBall({bool? p1Scored}) {
    setupForServe();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isWaitingForServe) {
      _serveBobTime += dt;
      final bob = sin(_serveBobTime * 6) * 3;

      if (currentGame.serverPlayer == 1) {
        position = currentGame.player1.position + Vector2(20, -28 + bob);
      } else {
        position = currentGame.player2.position + Vector2(-20, 28 + bob);
        _cpuServeTimer += dt;
        // CPU serves automatically after 1.2s preparation delay
        if (_cpuServeTimer >= 1.2) {
          executeServe(isPlayerOne: false);
          currentGame.player2.strike();
        }
      }
      return;
    }

    // Move ball along trajectory
    position += velocity * dt;

    if (_bounceEffectRadius > 0) {
      _bounceEffectRadius += dt * 35;
      if (_bounceEffectRadius > 25) {
        _bounceEffectRadius = 0;
      }
    }

    // 1. Detect crossing the Net (Y = 360)
    if (velocity.y < 0 && position.y < netY && _lastSideChangeY >= netY) {
      // Crossed net going to Player 2 side
      _lastSideChangeY = position.y;
      bounceCountCurrentSide = 0;
      _hasBouncedOnCurrentSide = false;
    } else if (velocity.y > 0 && position.y > netY && _lastSideChangeY <= netY) {
      // Crossed net going to Player 1 side
      _lastSideChangeY = position.y;
      bounceCountCurrentSide = 0;
      _hasBouncedOnCurrentSide = false;
    }

    // 2. Simulate Ball Bounce landing
    // When ball travels into the court baseline zone, trigger the bounce
    final bool travelingToP2 = velocity.y < 0;
    final bool travelingToP1 = velocity.y > 0;

    // First bounce trigger on Player 2 side (past the Kitchen line Y=280)
    if (travelingToP2 && position.y <= 240 && !_hasBouncedOnCurrentSide) {
      _triggerBounce(isPlayerOneSide: false);
    }
    // First bounce trigger on Player 1 side (past the Kitchen line Y=440)
    else if (travelingToP1 && position.y >= 480 && !_hasBouncedOnCurrentSide) {
      _triggerBounce(isPlayerOneSide: true);
    }

    // 3. Double Bounce check: If ball continues past baseline without return
    if (travelingToP2 && position.y < topBaselineY + 20 && bounceCountCurrentSide >= 1) {
      bounceCountCurrentSide++;
      // Second bounce! Double bounce fault
      currentGame.handleRallyWon(
        winnerIsPlayerOne: true,
        faultReason: 'FAULT: Double Bounce (Player 2)',
      );
      return;
    } else if (travelingToP1 && position.y > bottomBaselineY - 20 && bounceCountCurrentSide >= 1) {
      bounceCountCurrentSide++;
      // Second bounce! Double bounce fault
      currentGame.handleRallyWon(
        winnerIsPlayerOne: false,
        faultReason: 'FAULT: Double Bounce (Player 1)',
      );
      return;
    }

    // 4. Out of Bounds detection (exterior lines are in, beyond is out)
    final bool outLeft = position.x < courtLeftX - 10;
    final bool outRight = position.x > courtRightX + 10;
    final bool outTop = position.y < topBaselineY - 30;
    final bool outBottom = position.y > bottomBaselineY + 30;

    if (outLeft || outRight || outTop || outBottom) {
      // The player who hit the ball last hit it out of bounds
      final bool hitterWasP1 = (velocity.y < 0);
      currentGame.handleRallyWon(
        winnerIsPlayerOne: !hitterWasP1,
        faultReason: 'FAULT: Out of Bounds (${hitterWasP1 ? 'Player 1' : 'Player 2'})',
      );
    }
  }

  void _triggerBounce({required bool isPlayerOneSide}) {
    _hasBouncedOnCurrentSide = true;
    bounceCountCurrentSide = 1;
    _bounceEffectRadius = 6.0;

    // Check Service Rules on first bounce if it's the Serve (rallyHitCount == 0)
    if (currentGame.rallyHitCount == 0) {
      if (isPlayerOneSide) {
        // CPU served to P1:
        // Must clear kitchenBottomY (440)
        if (position.y <= kitchenBottomY) {
          currentGame.handleRallyWon(
            winnerIsPlayerOne: true,
            faultReason: 'FAULT: Service In Kitchen (CPU)',
          );
          return;
        }
        // Must land in diagonal box
        final bool shouldBeRightBox = (currentGame.servingSide == 'right');
        final bool isRightBox = position.x >= courtCenterX;
        if (shouldBeRightBox != isRightBox) {
          currentGame.handleRallyWon(
            winnerIsPlayerOne: true,
            faultReason: 'FAULT: Service Wrong Court (CPU)',
          );
          return;
        }
      } else {
        // P1 served to CPU:
        // Must clear kitchenTopY (280)
        if (position.y >= kitchenTopY) {
          currentGame.handleRallyWon(
            winnerIsPlayerOne: false,
            faultReason: 'FAULT: Service In Kitchen (Must clear Kitchen)',
          );
          return;
        }
        // Must land in diagonal box
        // If P1 served from right (even), diagonal box is viewer left (X < 640)
        final bool shouldBeLeftBox = (currentGame.servingSide == 'right');
        final bool isLeftBox = position.x <= courtCenterX;
        if (shouldBeLeftBox != isLeftBox) {
          currentGame.handleRallyWon(
            winnerIsPlayerOne: false,
            faultReason: 'FAULT: Service In Wrong Service Court',
          );
          return;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // 1. Draw subtle shadow underneath ball
    final shadowPaint = Paint()..color = Colors.black38;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 5), width: radius * 2.1, height: radius * 1.0),
      shadowPaint,
    );

    // 2. Draw expanding bounce ring if bounce occurred recently
    if (_bounceEffectRadius > 0) {
      final ringPaint = Paint()
        ..color = const Color(0xFF76FF03).withValues(alpha: (1.0 - (_bounceEffectRadius / 25)).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset.zero, _bounceEffectRadius, ringPaint);
    }

    // 3. Draw main Pickleball sphere
    super.render(canvas);

    // 4. Draw pickleball holes / perforations
    final holePaint = Paint()..color = const Color(0xFF88CC00);
    const double holeRad = 1.8;
    canvas.drawCircle(const Offset(-4, -4), holeRad, holePaint);
    canvas.drawCircle(const Offset(4, -4), holeRad, holePaint);
    canvas.drawCircle(const Offset(-4, 4), holeRad, holePaint);
    canvas.drawCircle(const Offset(4, 4), holeRad, holePaint);
    canvas.drawCircle(const Offset(0, 0), holeRad, holePaint);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerComponent && other.currentState == PlayerState.slash) {
      _processPlayerHit(other);
    }
  }

  /// Evaluates official Pickleball strike rules (Two-Bounce Rule, Kitchen Volley, Legal Hit)
  void _processPlayerHit(PlayerComponent player) {
    final bool isPlayerOne = player.isPlayerOne;

    // Ensure ball is moving towards the player who is hitting
    if (isPlayerOne && velocity.y <= 0) return;
    if (!isPlayerOne && velocity.y >= 0) return;

    // 1. Check Two-Bounce Rule (Rule 2)
    // Shot 1: Return of Serve (rallyHitCount == 0) -> Receiver MUST let serve bounce!
    if (currentGame.rallyHitCount == 0) {
      if (bounceCountCurrentSide == 0) {
        // Volleyed the serve!
        currentGame.handleRallyWon(
          winnerIsPlayerOne: !isPlayerOne,
          faultReason: 'FAULT: Two-Bounce Rule (Serve must bounce before return!)',
        );
        return;
      }
    }
    // Shot 2: 3rd Shot (rallyHitCount == 1) -> Server MUST let return bounce!
    else if (currentGame.rallyHitCount == 1) {
      if (bounceCountCurrentSide == 0) {
        // Volleyed the return!
        currentGame.handleRallyWon(
          winnerIsPlayerOne: !isPlayerOne,
          faultReason: 'FAULT: Two-Bounce Rule (Return must bounce before 3rd shot!)',
        );
        return;
      }
    }

    // 2. Check Kitchen (Non-Volley Zone) Rule (Rule 3)
    // Volleys out of the air inside the Kitchen or touching Kitchen line are FAULTS!
    if (bounceCountCurrentSide == 0) {
      if (isPlayerOne && player.position.y <= kitchenBottomY + 5) {
        currentGame.handleRallyWon(
          winnerIsPlayerOne: false,
          faultReason: 'FAULT: Kitchen Volley (Cannot volley inside Kitchen!)',
        );
        return;
      } else if (!isPlayerOne && player.position.y >= kitchenTopY - 5) {
        currentGame.handleRallyWon(
          winnerIsPlayerOne: true,
          faultReason: 'FAULT: Kitchen Volley (Cannot volley inside Kitchen!)',
        );
        return;
      }
    }

    // 3. LEGAL HIT (Groundstroke, Dink, or Open-Play Volley outside Kitchen)
    AudioService.instance.playPaddleHit();
    currentGame.rallyHitCount++;
    bounceCountCurrentSide = 0;
    _hasBouncedOnCurrentSide = false;

    // Calculate return trajectory
    final diff = position - player.position;
    velocity.y = -velocity.y;
    velocity.x += (diff.x * 2.4) + (player.horizontalMovement * 260.0);
    velocity.x = velocity.x.clamp(-380.0, 380.0);

    speed = (speed * 1.05).clamp(420.0, 620.0);
    velocity = velocity.normalized() * speed;

    // Displace slightly to prevent double collisions
    position += velocity.normalized() * 8;
  }
}

