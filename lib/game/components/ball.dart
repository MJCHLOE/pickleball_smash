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
  final double initialSpeed = 280.0;
  double speed = 280.0;

  // 3D Altitude and Floor Bounce Physics per official Pickleball rules
  double z = 0.0; // Altitude in pixels above court floor (0 = on the floor)
  double zVelocity = 0.0;
  final double gravity = 340.0;
  final double bounceRestitution = 0.55;
  double squashFactor = 1.0;

  // Serve & Bouncing state per official Pickleball rules
  bool _isWaitingForServe = true;
  bool get isWaitingForServe {
    if (customGame != null) return customGame!.isWaitingForServe;
    return _isWaitingForServe;
  }
  set isWaitingForServe(bool value) {
    _isWaitingForServe = value;
    if (customGame != null) {
      customGame!.isWaitingForServe = value;
    }
  }
  double _serveBobTime = 0.0;
  double _serveTimer = 0.0;

  // Bounce tracking:
  // 0 = in air (volley if struck)
  // 1 = bounced once on floor (groundstroke/dink if struck)
  // 2 = double bounce fault
  int bounceCountCurrentSide = 0;
  bool _netClippedThisCross = false;
  double _bounceEffectRadius = 0.0;
  double _timeSinceLastBounce = 1.0;

  // Court geometry constants (Portrait-proportioned 2D arcade court)
  static const double courtLeftX = 400.0;
  static const double courtRightX = 880.0;
  static const double courtCenterX = 640.0;
  static const double netY = 360.0;
  static const double kitchenTopY = 280.0;    // Top Kitchen line (for P2)
  static const double kitchenBottomY = 440.0; // Bottom Kitchen line (for P1)
  static const double topBaselineY = 50.0;
  static const double bottomBaselineY = 670.0;

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
    _serveTimer = 0.0;
    z = 16.0;
    zVelocity = 0.0;
    squashFactor = 1.0;

    try {
      final serverComp = currentGame.activeServerComponent;
      if (serverComp.isPlayerOne) {
        position = serverComp.position + Vector2(20, -28);
      } else {
        position = serverComp.position + Vector2(-20, 28);
      }
    } catch (_) {
      // Game references might still be initializing
      position = Vector2(760, 667);
    }
  }

  /// Executes underhand serve according to singles/doubles diagonal target
  void executeServe({required bool isPlayerOne, double horizontalAngle = 0.0}) {
    if (!isWaitingForServe) return;
    isWaitingForServe = false;
    currentGame.isWaitingForServe = false;
    currentGame.rallyHitCount = 0;
    speed = 310.0;
    bounceCountCurrentSide = 0;
    z = 14.0;
    zVelocity = 210.0; // Launch smooth parabolic serve arc over net
    squashFactor = 1.0;

    AudioService.instance.playPaddleHit();

    // Exact parabolic flight time to court floor bounce (z = 0)
    final double tBounce = (zVelocity + sqrt(zVelocity * zVelocity + 4 * 170.0 * z)) / 340.0;

    Vector2 target;
    if (isPlayerOne) {
      // Bottom server serves diagonally upwards into diagonal receiving box
      // Right service box: [640, 880], Left service box: [400, 640]
      // Safe depth past kitchen (280) and before baseline (50): Y = 165
      final baseTargetX = (currentGame.servingSide == 'right') ? 520.0 : 760.0;
      final clampedAngle = horizontalAngle.clamp(-0.25, 0.25);
      final targetX = (baseTargetX + clampedAngle * 70.0).clamp(440.0, 840.0);
      target = Vector2(targetX, 165.0);
    } else {
      // Top server serves diagonally downwards into diagonal receiving box
      // Safe depth past kitchen (440) and before baseline (670): Y = 555
      final baseTargetX = (currentGame.servingSide == 'right') ? 760.0 : 520.0;
      target = Vector2(baseTargetX, 555.0);
    }

    velocity = Vector2(
      (target.x - position.x) / tBounce,
      (target.y - position.y) / tBounce,
    );
    speed = velocity.length;

    // Step forward into court on serve impact
    try {
      final serverComp = currentGame.activeServerComponent;
      if (serverComp.isPlayerOne && serverComp.position.y > 650) {
        serverComp.position.y = 625.0;
      } else if (!serverComp.isPlayerOne && serverComp.position.y < 70) {
        serverComp.position.y = 95.0;
      }
    } catch (_) {}

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
      z = 16.0 + bob;

      try {
        final serverComp = currentGame.activeServerComponent;
        if (serverComp.isPlayerOne) {
          position = serverComp.position + Vector2(20, -28);
        } else {
          position = serverComp.position + Vector2(-20, 28);
        }

        // Serving flow: Player must manually serve before game starts.
        // CPU waits 1.2s before executing serve so player can get ready.
        _serveTimer += dt;
        final bool isCpu = !currentGame.isHumanServer;
        final bool autoServeEnabled = currentGame.settings?.autoServe ?? false;
        final double threshold = isCpu ? 1.2 : (autoServeEnabled ? 1.8 : double.infinity);

        if (_serveTimer >= threshold) {
          executeServe(isPlayerOne: serverComp.isPlayerOne);
          serverComp.strike();
        }
      } catch (_) {}
      return;
    }

    // Move ball along 2D court floor trajectory
    position += velocity * dt;
    _timeSinceLastBounce += dt;

    // 3D Altitude & Gravity
    zVelocity -= gravity * dt;
    z += zVelocity * dt;

    // Squash recovery
    if (squashFactor < 1.0) {
      squashFactor = min(1.0, squashFactor + dt * 5.0);
    } else if (squashFactor > 1.0) {
      squashFactor = max(1.0, squashFactor - dt * 4.0);
    }

    // Expand floor ripple ring on bounce
    if (_bounceEffectRadius > 0) {
      _bounceEffectRadius += dt * 40;
      if (_bounceEffectRadius > 30) {
        _bounceEffectRadius = 0;
      }
    }

    // 1. Detect crossing or clipping the Net (Y = 360)
    final double prevY = position.y - velocity.y * dt;
    final bool crossingToP2 = velocity.y < 0 && prevY > netY && position.y <= netY;
    final bool crossingToP1 = velocity.y > 0 && prevY < netY && position.y >= netY;

    if (crossingToP2 || crossingToP1) {
      // Net cord height is ~18.0 px
      if (z <= 6.0) {
        // Hit directly into net mesh - fails to clear!
        AudioService.instance.playPaddleHit();
        velocity.y = -velocity.y * 0.15;
        zVelocity = -40.0;
        final bool hitterWasP1 = crossingToP2;
        currentGame.handleRallyWon(
          winnerIsPlayerOne: !hitterWasP1,
          faultReason: 'FAULT: Net Fault (Ball hit net and failed to clear)',
        );
        return;
      } else if (z <= 18.0 && !_netClippedThisCross) {
        // Net clip: clips top tape of net cord, dampens slightly but continues LIVE!
        _netClippedThisCross = true;
        AudioService.instance.playPaddleHit();
        velocity.x *= 0.94;
        velocity.y *= 0.90;
        zVelocity -= 15.0;
      }

      bounceCountCurrentSide = 0;
      _netClippedThisCross = false;
      _timeSinceLastBounce = 1.0;
    }

    // 2. FLOOR BOUNCE EVENT (Ball contacts court floor z <= 0)
    if (z <= 0) {
      z = 0.0;
      final bool wasFalling = zVelocity < 0;
      if (wasFalling) {
        _triggerFloorBounce();
      }
    }

    // 3. Out of Bounds safety check if ball flies far past baseline/sideline without return
    if (position.y < topBaselineY - 90 || position.y > bottomBaselineY + 90 ||
        position.x < courtLeftX - 90 || position.x > courtRightX + 90) {
      final bool hitterWasP1 = (velocity.y < 0);
      currentGame.handleRallyWon(
        winnerIsPlayerOne: !hitterWasP1,
        faultReason: 'FAULT: Out of Bounds (${hitterWasP1 ? 'Player 1' : 'Player 2'})',
      );
    }
  }

  void _triggerFloorBounce() {
    if (_timeSinceLastBounce < 0.22) return;
    _timeSinceLastBounce = 0.0;

    // 1. Audio feedback for ball bouncing on floor
    AudioService.instance.playPaddleHit();
    _bounceEffectRadius = 6.0;
    squashFactor = 0.72; // Squashes on impact with court floor

    // 2. Parabolic bounce restitution (generous pop-up arc for continuous play)
    if (zVelocity.abs() > 35.0) {
      final popSpeed = max(175.0, zVelocity.abs() * 0.85);
      zVelocity = popSpeed;
    } else {
      zVelocity = 0.0;
    }

    // 3. Increment floor bounce count for current player side
    bounceCountCurrentSide++;

    final bool isP1Side = position.y >= netY;

    // Double Bounce violation removed per user request:
    // Ball can bounce multiple times on the court without fault, keeping rallies live!

    // 4. Check Service Rules on first bounce if it's the Serve (rallyHitCount == 0 && bounceCountCurrentSide == 1)
    if (currentGame.rallyHitCount == 0 && bounceCountCurrentSide == 1) {
      if (isP1Side) {
        // CPU served to P1:
        // Must clear kitchenBottomY (440)
        if (position.y <= kitchenBottomY) {
          currentGame.handleRallyWon(
            winnerIsPlayerOne: true,
            faultReason: 'FAULT: Service In Kitchen (CPU)',
          );
          return;
        }
        // Must land in diagonal service box
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
        // Must land in diagonal service box
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

    // 6. Out of Bounds detection on floor bounce
    final bool outLeft = position.x < courtLeftX - 5;
    final bool outRight = position.x > courtRightX + 5;
    final bool outTop = position.y < topBaselineY - 10;
    final bool outBottom = position.y > bottomBaselineY + 10;

    if (outLeft || outRight || outTop || outBottom) {
      final bool hitterWasP1 = !isP1Side;
      currentGame.handleRallyWon(
        winnerIsPlayerOne: !hitterWasP1,
        faultReason: 'FAULT: Out of Bounds (${hitterWasP1 ? 'Player 1' : 'Player 2'})',
      );
    }
  }

  @override
  void render(Canvas canvas) {
    // 1. Draw realistic floor shadow at ground level beneath the ball
    final shadowScale = (1.0 - (z / 220.0).clamp(0.0, 0.45));
    final shadowAlpha = ((1.0 - (z / 250.0).clamp(0.0, 0.6)) * 0.45);
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: shadowAlpha);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, 4),
        width: radius * 2.2 * shadowScale,
        height: radius * 1.1 * shadowScale,
      ),
      shadowPaint,
    );

    // 2. Draw expanding ripple ring on the floor when the ball bounces
    if (_bounceEffectRadius > 0) {
      final ringPaint = Paint()
        ..color = const Color(0xFF76FF03).withValues(alpha: (1.0 - (_bounceEffectRadius / 30)).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(0, 4),
          width: _bounceEffectRadius * 2.2,
          height: _bounceEffectRadius * 1.1,
        ),
        ringPaint,
      );
    }

    // 3. Draw 3D Pickleball elevated by altitude z with Squash & Stretch
    canvas.save();
    canvas.translate(0, -z);
    canvas.scale(2.0 - squashFactor, squashFactor);

    final ballPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: const [Color(0xFFE8FF59), Color(0xFFCCFF00), Color(0xFF99CC00)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, ballPaint);

    // 4. Draw pickleball holes / perforations
    final holePaint = Paint()..color = const Color(0xFF7CB305);
    const double holeRad = 1.7;
    canvas.drawCircle(const Offset(-4, -4), holeRad, holePaint);
    canvas.drawCircle(const Offset(4, -4), holeRad, holePaint);
    canvas.drawCircle(const Offset(-4, 4), holeRad, holePaint);
    canvas.drawCircle(const Offset(4, 4), holeRad, holePaint);
    canvas.drawCircle(const Offset(0, 0), holeRad, holePaint);

    canvas.restore();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerComponent) {
      if (other.currentState == PlayerState.slash) {
        processPlayerHit(other);
      }
      // Body Fault removed per user request:
      // Live ball in flight touching a player does not cause a fault!
    }
  }

  /// Evaluates official Pickleball strike rules (Two-Bounce Rule, Kitchen Volley, Legal Hit)
  void processPlayerHit(PlayerComponent player) {
    final bool isPlayerOne = player.isPlayerOne;

    // Ensure ball is moving towards the player who is hitting
    if (isPlayerOne && velocity.y <= 0) return;
    if (!isPlayerOne && velocity.y >= 0) return;

    // Record volley timing for Kitchen Momentum Rule check
    final bool isVolley = (bounceCountCurrentSide == 0);
    player.timeSinceLastVolley = isVolley ? 0.0 : 999.0;

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
      if (isPlayerOne && player.position.y <= kitchenBottomY) {
        currentGame.handleRallyWon(
          winnerIsPlayerOne: false,
          faultReason: 'FAULT: Kitchen Volley (Cannot volley inside Kitchen!)',
        );
        return;
      } else if (!isPlayerOne && player.position.y >= kitchenTopY) {
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
    currentGame.continuousRallyStreak++;
    if (currentGame.continuousRallyStreak > currentGame.longestRally) {
      currentGame.longestRally = currentGame.continuousRallyStreak;
    }
    currentGame.onRallyStreakUpdated?.call(
      currentGame.continuousRallyStreak,
      currentGame.longestRally,
    );
    bounceCountCurrentSide = 0;

    // Launch parabolic return trajectory
    z = max(z, 8.0);
    zVelocity = 210.0;
    squashFactor = 1.12;

    // Calculate exact flight time until the ball contacts the floor (z = 0)
    // 170 * t^2 - zVelocity * t - z = 0
    final double tBounce = (zVelocity + sqrt(zVelocity * zVelocity + 4 * 170.0 * z)) / 340.0;

    // Calculate landing target (targetX, targetY) guaranteed to be inside opponent's court
    final diff = position - player.position;
    double targetX;
    double targetY;

    if (isPlayerOne && !player.isAI) {
      // Player 1 (Human) hitting to Player 2 (opponent side: Y in [50, 360])
      // Steering: player horizontal movement + paddle offset
      final aimOffset = (player.horizontalMovement * 160.0) + (diff.x * 0.8);
      targetX = (640.0 + aimOffset).clamp(450.0, 830.0);

      // Depth steering: UP key / forward joystick = deep; DOWN / back = short / dink
      double vInput = 0.0;
      if (player.joystick != null && !player.joystick!.delta.isZero()) {
        vInput = player.joystick!.relativeDelta.y;
      } else {
        vInput = player.vAxis.toDouble();
      }
      // Target Y base is 195.0 (mid service court, deep past kitchen 280)
      // vInput < 0 is UP/forward -> deeper shot towards baseline (130.0)
      // vInput > 0 is DOWN/backward -> shorter dink near kitchen (270.0)
      targetY = (195.0 + vInput * 65.0).clamp(115.0, 275.0);
    } else if (isPlayerOne && player.isAI) {
      // Expert AI Teammate (Team 1 Partner) hitting to Team 2
      // Tactically targets the open court opposite to opponent position
      final oppPos = currentGame.player2.position;
      final targetLeft = oppPos.x > 640.0;
      final baseAim = targetLeft ? 520.0 : 760.0;
      final aimOffset = (diff.x * 0.4) + ((Random().nextDouble() - 0.5) * 50.0);
      targetX = (baseAim + aimOffset).clamp(440.0, 840.0);
      // Alternate between deep baseline drives and soft drops
      final isDeep = (currentGame.rallyHitCount % 3 != 0);
      targetY = isDeep ? 145.0 : 255.0;
    } else {
      // Expert AI Opponent (Team 2 CPU) hitting to Team 1
      // Tactically targets the open court opposite to human player position
      final oppPos = currentGame.player1.position;
      final targetLeft = oppPos.x > 640.0;
      final baseAim = targetLeft ? 520.0 : 760.0;
      final aimOffset = (diff.x * 0.4) + ((Random().nextDouble() - 0.5) * 50.0);
      targetX = (baseAim + aimOffset).clamp(440.0, 840.0);
      // Alternate between deep baseline drives and soft kitchen drops
      final isDeep = (currentGame.rallyHitCount % 3 != 0);
      targetY = isDeep ? 585.0 : 465.0;
    }

    // Derive precise velocity so the ball lands and bounces at (targetX, targetY) inside the court
    velocity = Vector2(
      (targetX - position.x) / tBounce,
      (targetY - position.y) / tBounce,
    );
    speed = velocity.length;

    // Displace slightly forward along velocity to prevent immediate re-collision
    position += velocity.normalized() * 10;
  }
}

