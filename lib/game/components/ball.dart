import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/ball_catalog.dart';
import '../../models/battle_technique.dart';
import '../../models/multiplayer_models.dart';
import '../../services/audio_service.dart';
import '../../services/multiplayer_service.dart';
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
  bool _cpuServeBounced = false;

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

  BallInfo _ballInfo;
  BallInfo get ballInfo => _ballInfo;

  final List<Offset> _trailPositions = [];
  double _trailTimer = 0.0;
  BattleTechnique activeTechniqueType = BattleTechnique.none;
  double spin = 0.0; // -1.0 = Left Spin (curves left, kicks left), +1.0 = Right Spin (curves right, kicks right)
  double curveStrength = 0.0; // Lateral acceleration px/s^2 (Magnus effect)
  double ballRotationAngle = 0.0; // Perforation visual rotation angle in radians

  BallComponent({String? ballId})
      : _ballInfo = BallCatalog.getById(ballId ?? 'ball_elite') {
    radius = 11.0;
    anchor = Anchor.center;
    paint = Paint()..color = _ballInfo.gradientColors[1];
  }

  void applyBall(String id) {
    _ballInfo = BallCatalog.getById(id);
    paint = Paint()..color = _ballInfo.gradientColors[1];
  }

  void applyBallInfo(BallInfo info) {
    _ballInfo = info;
    paint = Paint()..color = _ballInfo.gradientColors[1];
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
    _cpuServeBounced = false;
    z = 16.0;
    zVelocity = 0.0;
    squashFactor = 1.0;
    _trailPositions.clear();
    activeTechniqueType = BattleTechnique.none;
    spin = 0.0;
    curveStrength = 0.0;
    ballRotationAngle = 0.0;

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

    AudioService.instance.playServe();

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

    if (currentGame.isMultiplayer) {
      MultiplayerService.instance.broadcastPacket(
        MultiplayerPacket(
          type: PacketType.ballStrike,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          senderId: MultiplayerService.instance.myProfile.playerId,
          data: {
            'x': position.x,
            'y': position.y,
            'vx': velocity.x,
            'vy': velocity.y,
            'z': z,
            'zVelocity': zVelocity,
            'spin': spin,
          },
        ),
      );
    }
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

        if (isCpu) {
          // Drop Serve for AI / Bot: Ball drops to the court floor, bounces once, and CPU strikes on the bounce!
          if (_serveTimer < 0.45) {
            z = 16.0;
          } else if (_serveTimer < 0.8) {
            final dropProgress = ((_serveTimer - 0.45) / 0.35).clamp(0.0, 1.0);
            z = 16.0 * (1.0 - dropProgress);
            if (dropProgress >= 1.0 && !_cpuServeBounced) {
              _cpuServeBounced = true;
              AudioService.instance.playFloorBounce();
              _bounceEffectRadius = 6.0;
            }
          } else {
            final riseProgress = ((_serveTimer - 0.8) / 0.4).clamp(0.0, 1.0);
            z = sin(riseProgress * pi * 0.5) * 14.0;
          }

          if (_serveTimer >= threshold) {
            _cpuServeBounced = false;
            executeServe(isPlayerOne: serverComp.isPlayerOne);
            serverComp.strike();
          }
        } else {
          _serveBobTime += dt;
          final bob = sin(_serveBobTime * 6) * 3;
          z = 16.0 + bob;

          if (_serveTimer >= threshold) {
            executeServe(isPlayerOne: serverComp.isPlayerOne);
            serverComp.strike();
          }
        }
      } catch (_) {}
      return;
    }

    // Apply aerodynamic curving force (Magnus effect)
    if (spin != 0.0 && curveStrength > 0.0) {
      velocity.x += curveStrength * spin * dt;
      ballRotationAngle += spin * 24.0 * dt;
    }

    // Move ball along 2D court floor trajectory
    position += velocity * dt;
    _timeSinceLastBounce += dt;

    // Track motion particle trail
    if (!isWaitingForServe && speed > 50) {
      _trailTimer += dt;
      if (_trailTimer >= 0.02) {
        _trailTimer = 0.0;
        _trailPositions.insert(0, Offset(position.x, position.y - z));
        if (_trailPositions.length > 8) {
          _trailPositions.removeLast();
        }
      }
    } else {
      _trailPositions.clear();
    }

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
      if (bounceCountCurrentSide >= 1) {
        // Ball had already legally bounced on current side; receiver failed to return it!
        final bool isP1Side = position.y >= netY;
        currentGame.handleRallyWon(
          winnerIsPlayerOne: !isP1Side,
          faultReason: isP1Side
              ? 'FAULT: Double Bounce (Ball rolled dead on your court!)'
              : 'FAULT: Double Bounce (Opponent failed to return!)',
        );
      } else {
        // Ball flew past court on the fly without bouncing
        final bool hitterWasP1 = (velocity.y < 0);
        currentGame.handleRallyWon(
          winnerIsPlayerOne: !hitterWasP1,
          faultReason: 'FAULT: Out of Bounds (${hitterWasP1 ? 'Player 1' : 'Player 2'})',
        );
      }
    }
  }

  void _triggerFloorBounce() {
    if (_timeSinceLastBounce < 0.22) return;
    _timeSinceLastBounce = 0.0;

    // 1. Audio feedback for ball bouncing on floor
    AudioService.instance.playFloorBounce();
    _bounceEffectRadius = 6.0;
    squashFactor = 0.72; // Squashes on impact with court floor

    // 1.5. Heavy sidespin kicks the ball sharply sideways on the floor bounce
    if (spin != 0.0) {
      velocity.x += 160.0 * spin;
      spin = 0.0;
      curveStrength = 0.0;
    }
    activeTechniqueType = BattleTechnique.none;

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

    // Double Bounce Fault Rule (Pickleball Rule 4.A):
    // Ball can bounce AT MOST once on a side. If it bounces a second time without being struck,
    // the receiver on this side committed a double bounce fault!
    if (bounceCountCurrentSide >= 2) {
      currentGame.handleRallyWon(
        winnerIsPlayerOne: !isP1Side,
        faultReason: isP1Side
            ? 'FAULT: Double Bounce (Ball bounced twice on your court!)'
            : 'FAULT: Double Bounce (Opponent failed to return!)',
      );
      return;
    }

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

    // 6. Out of Bounds detection on first floor bounce
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
      return;
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
        ..color = _ballInfo.rippleColor.withValues(alpha: (1.0 - (_bounceEffectRadius / 30)).clamp(0.0, 1.0))
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

    // 3. Draw particle motion trail
    for (int i = 0; i < _trailPositions.length; i++) {
      final p = _trailPositions[i];
      final rel = Offset(p.dx - position.x, p.dy - position.y);
      final progress = 1.0 - (i / _trailPositions.length);
      final trailAlpha = (progress * 0.55).clamp(0.0, 1.0);
      final trailRad = radius * (0.35 + 0.45 * progress);

      // Special particle visual styles for active techniques!
      if (activeTechniqueType == BattleTechnique.leftSpin) {
        // 🌪️ Cyclone Left Spin: Emerald & mint wind vortex trail
        final cyclonePaint = Paint()
          ..color = (i % 2 == 0 ? const Color(0xFF10B981) : const Color(0xFF34D399))
              .withValues(alpha: (trailAlpha * 1.6).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(rel, trailRad * 1.35, cyclonePaint);

        // Counter-clockwise orbiting wind wisps
        final angle = -ballRotationAngle + (i * 0.4);
        final wispOffset = rel + Offset(cos(angle) * trailRad * 0.6, sin(angle) * trailRad * 0.6);
        canvas.drawCircle(
          wispOffset,
          trailRad * 0.45,
          Paint()..color = Colors.white.withValues(alpha: trailAlpha * 0.85),
        );
      } else if (activeTechniqueType == BattleTechnique.rightSpin) {
        // ⚡ Vortex Right Spin: Electric violet & purple plasma trail
        final vortexPaint = Paint()
          ..color = (i % 2 == 0 ? const Color(0xFF8B5CF6) : const Color(0xFFA855F7))
              .withValues(alpha: (trailAlpha * 1.6).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(rel, trailRad * 1.35, vortexPaint);

        // Clockwise orbiting plasma spark
        final angle = ballRotationAngle + (i * 0.4);
        final sparkOffset = rel + Offset(cos(angle) * trailRad * 0.6, sin(angle) * trailRad * 0.6);
        canvas.drawCircle(
          sparkOffset,
          trailRad * 0.45,
          Paint()..color = const Color(0xFFE9D5FF).withValues(alpha: trailAlpha * 0.85),
        );
      } else {
        final trailPaint = Paint()
          ..color = _ballInfo.sparkColor.withValues(alpha: trailAlpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(rel, trailRad, trailPaint);

        if (_ballInfo.tier == BallTier.legendary ||
            _ballInfo.tier == BallTier.mythic ||
            _ballInfo.tier == BallTier.special) {
          canvas.drawCircle(
            rel,
            trailRad * 1.35,
            Paint()
              ..color = _ballInfo.glowColor.withValues(alpha: trailAlpha * 0.45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }

    // 4. Draw 3D Pickleball elevated by altitude z with Squash & Stretch
    canvas.save();
    canvas.translate(0, -z);
    canvas.scale(2.0 - squashFactor, squashFactor);

    // Glowing aura for higher tier balls or active battle technique
    if (activeTechniqueType == BattleTechnique.leftSpin) {
      final leftAura = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawCircle(Offset.zero, radius + 4.5, leftAura);
    } else if (activeTechniqueType == BattleTechnique.rightSpin) {
      final rightAura = Paint()
        ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawCircle(Offset.zero, radius + 4.5, rightAura);
    } else if (_ballInfo.tier != BallTier.elite) {
      final glowPaint = Paint()
        ..color = _ballInfo.glowColor.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset.zero, radius + 2.5, glowPaint);
    }

    final ballPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: _ballInfo.gradientColors,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, ballPaint);

    // 5. Draw pickleball holes / perforations with dynamic sidespin rotation
    canvas.save();
    canvas.rotate(ballRotationAngle);
    final holePaint = Paint()..color = _ballInfo.holeColor;
    const double holeRad = 1.7;
    canvas.drawCircle(const Offset(-4, -4), holeRad, holePaint);
    canvas.drawCircle(const Offset(4, -4), holeRad, holePaint);
    canvas.drawCircle(const Offset(-4, 4), holeRad, holePaint);
    canvas.drawCircle(const Offset(4, 4), holeRad, holePaint);
    canvas.drawCircle(const Offset(0, 0), holeRad, holePaint);
    canvas.restore();

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
    // 3. Mandatory Floor Bounce: Ball MUST bounce on the court floor before any hit!
    if (bounceCountCurrentSide == 0) {
      return; // Ball has not bounced yet! Cannot hit out of the air.
    }

    // 4. LEGAL HIT (Groundstroke or Dink after floor bounce)
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

    // Check battle technique for Player 1 (or AI counter during rally)
    BattleTechnique executedTechnique = BattleTechnique.none;
    if (isPlayerOne && !player.isAI) {
      executedTechnique = player.activeTechnique;
      player.clearTechnique();
    } else if (!isPlayerOne && player.isAI && currentGame.rallyHitCount > 1) {
      final roll = Random().nextDouble();
      if (roll < 0.12) {
        executedTechnique = BattleTechnique.leftSpin;
      } else if (roll < 0.22) {
        executedTechnique = BattleTechnique.rightSpin;
      }
    }
    activeTechniqueType = executedTechnique;

    z = max(z, 8.0);
    double targetX;
    double targetY;
    double tBounce;

    if (executedTechnique == BattleTechnique.leftSpin) {
      // 🌪️ CYCLONE CURVE (Spin on the Left):
      // Ball arcs wide across the court, curving dramatically to the LEFT!
      // When it bounces, it kicks sharply to the left, pulling the opponent off-court!
      spin = -1.0;
      curveStrength = 360.0; // Lateral Magnus acceleration to the left
      zVelocity = 205.0;
      squashFactor = 1.25;

      tBounce = (zVelocity + sqrt(zVelocity * zVelocity + 4 * 170.0 * z)) / 340.0;

      if (isPlayerOne) {
        targetX = 470.0; // Deep left sideline
        targetY = 135.0;
        currentGame.onAnnouncement?.call('🌪️ CYCLONE CURVE!', 'Wicked left sidespin curve!');
        currentGame.onTechniqueExecuted(BattleTechnique.leftSpin);
      } else {
        targetX = 470.0;
        targetY = 595.0;
        currentGame.onAnnouncement?.call('🌪️ CPU CYCLONE CURVE!', 'Watch out! Violent left spin curve!');
        currentGame.onTechniqueExecuted(BattleTechnique.leftSpin);
      }

      final double lateralAcc = spin * curveStrength;
      final double v0X = (targetX - position.x - 0.5 * lateralAcc * tBounce * tBounce) / tBounce;
      final double v0Y = (targetY - position.y) / tBounce;
      velocity = Vector2(v0X, v0Y);
      speed = velocity.length;
      position += velocity.normalized() * 10;
      return;
    } else if (executedTechnique == BattleTechnique.rightSpin) {
      // ⚡ VORTEX HOOK (Spin to the Right):
      // Ball arcs wide across the court, curving dramatically to the RIGHT!
      // When it bounces, it kicks sharply to the right, pulling the opponent off-court!
      spin = 1.0;
      curveStrength = 360.0; // Lateral Magnus acceleration to the right
      zVelocity = 205.0;
      squashFactor = 1.25;

      tBounce = (zVelocity + sqrt(zVelocity * zVelocity + 4 * 170.0 * z)) / 340.0;

      if (isPlayerOne) {
        targetX = 810.0; // Deep right sideline
        targetY = 135.0;
        currentGame.onAnnouncement?.call('⚡ VORTEX HOOK!', 'Fierce right sidespin hook!');
        currentGame.onTechniqueExecuted(BattleTechnique.rightSpin);
      } else {
        targetX = 810.0;
        targetY = 595.0;
        currentGame.onAnnouncement?.call('⚡ CPU VORTEX HOOK!', 'Watch out! Violent right spin hook!');
        currentGame.onTechniqueExecuted(BattleTechnique.rightSpin);
      }

      final double lateralAcc = spin * curveStrength;
      final double v0X = (targetX - position.x - 0.5 * lateralAcc * tBounce * tBounce) / tBounce;
      final double v0Y = (targetY - position.y) / tBounce;
      velocity = Vector2(v0X, v0Y);
      speed = velocity.length;
      position += velocity.normalized() * 10;
      return;
    } else {
      // Standard return trajectory - reset any spin
      spin = 0.0;
      curveStrength = 0.0;
      zVelocity = 210.0;
      squashFactor = 1.12;
      tBounce = (zVelocity + sqrt(zVelocity * zVelocity + 4 * 170.0 * z)) / 340.0;

      final diff = position - player.position;
      if (isPlayerOne && !player.isAI) {
        final aimOffset = (player.horizontalMovement * 160.0) + (diff.x * 0.8);
        targetX = (640.0 + aimOffset).clamp(450.0, 830.0);

        double vInput = 0.0;
        if (player.joystick != null && !player.joystick!.delta.isZero()) {
          vInput = player.joystick!.relativeDelta.y;
        } else {
          vInput = player.vAxis.toDouble();
        }
        targetY = (195.0 + vInput * 65.0).clamp(115.0, 275.0);
      } else if (isPlayerOne && player.isAI) {
        final oppPos = currentGame.player2.position;
        final targetLeft = oppPos.x > 640.0;
        final baseAim = targetLeft ? 520.0 : 760.0;
        final aimOffset = (diff.x * 0.4) + ((Random().nextDouble() - 0.5) * 50.0);
        targetX = (baseAim + aimOffset).clamp(440.0, 840.0);
        final isDeep = (currentGame.rallyHitCount % 3 != 0);
        targetY = isDeep ? 145.0 : 255.0;
      } else {
        final oppPos = currentGame.player1.position;
        final targetLeft = oppPos.x > 640.0;
        final baseAim = targetLeft ? 520.0 : 760.0;
        final aimOffset = (diff.x * 0.4) + ((Random().nextDouble() - 0.5) * 50.0);
        targetX = (baseAim + aimOffset).clamp(440.0, 840.0);
        final isDeep = (currentGame.rallyHitCount % 3 != 0);
        targetY = isDeep ? 585.0 : 465.0;
      }
    }

    // Derive precise velocity so the ball lands and bounces at (targetX, targetY) inside the court
    velocity = Vector2(
      (targetX - position.x) / tBounce,
      (targetY - position.y) / tBounce,
    );
    speed = velocity.length;

    // Displace slightly forward along velocity to prevent immediate re-collision
    position += velocity.normalized() * 10;

    if (currentGame.isMultiplayer) {
      MultiplayerService.instance.broadcastPacket(
        MultiplayerPacket(
          type: PacketType.ballStrike,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          senderId: MultiplayerService.instance.myProfile.playerId,
          data: {
            'x': position.x,
            'y': position.y,
            'vx': velocity.x,
            'vy': velocity.y,
            'z': z,
            'zVelocity': zVelocity,
            'spin': spin,
          },
        ),
      );
    }
  }
}

