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
import 'background.dart';
import 'player.dart';

class BallComponent extends CircleComponent with HasGameReference<PickleballGame>, CollisionCallbacks {
  PickleballGame? customGame;
  PickleballGame get currentGame {
    if (customGame != null) return customGame!;
    return game;
  }
  PickleballGame? get currentGameOrNull {
    if (customGame != null) return customGame;
    try {
      if (isMounted) return game;
    } catch (_) {}
    return null;
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

  // Court geometry constants matching the court view and white lines
  static const double courtTopY = Background.courtTopY;
  static const double courtBottomY = Background.courtBottomY;
  static const double topBaselineY = Background.courtTopY;
  static const double bottomBaselineY = Background.courtBottomY;
  static const double netY = Background.netY;
  static const double kitchenTopY = Background.kitchenTopY;    // Top Kitchen line (for P2)
  static const double kitchenBottomY = Background.kitchenBottomY; // Bottom Kitchen line (for P1)
  static const double courtCenterX = Background.courtCenterX;
  static const double courtLeftX = Background.courtLeftX;
  static const double courtRightX = Background.courtRightX;

  BallInfo _ballInfo;
  BallInfo get ballInfo => _ballInfo;

  final List<Offset> _trailPositions = [];
  double _trailTimer = 0.0;
  BattleTechnique activeTechniqueType = BattleTechnique.none;
  double spin = 0.0; // -1.0 = Left Spin (curves left, kicks left), +1.0 = Right Spin (curves right, kicks right)
  double curveStrength = 0.0; // Lateral acceleration px/s^2 (Magnus effect)
  double ballRotationAngle = 0.0; // Perforation visual rotation angle in radians

  // Reusable cached paints for zero-allocation 60 FPS rendering on low-end devices
  Paint? _cachedBallPaint;
  final Paint _shadowPaint = Paint();
  final Paint _ripplePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5;
  final Paint _trailFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _trailStrokePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5;
  final Paint _wispPaint = Paint()..style = PaintingStyle.fill;
  final Paint _auraFillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _holePaint = Paint()..style = PaintingStyle.fill;

  BallComponent({String? ballId})
      : _ballInfo = BallCatalog.getById(ballId ?? 'ball_elite') {
    radius = 11.0;
    anchor = Anchor.center;
    paint = Paint()..color = _ballInfo.gradientColors[1];
    _updateCachedBallPaint();
  }

  void _updateCachedBallPaint() {
    _cachedBallPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: _ballInfo.gradientColors,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    _holePaint.color = _ballInfo.holeColor;
  }

  void applyBall(String id) {
    _ballInfo = BallCatalog.getById(id);
    paint = Paint()..color = _ballInfo.gradientColors[1];
    _updateCachedBallPaint();
  }

  void applyBallInfo(BallInfo info) {
    _ballInfo = info;
    paint = Paint()..color = _ballInfo.gradientColors[1];
    _updateCachedBallPaint();
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

    // Rule 5: Service Foot Fault Check
    // Server must stand completely behind the baseline when making the serve.
    // Stepping on or inside the baseline before contacting the ball is an immediate fault.
    try {
      final serverComp = currentGame.activeServerComponentOrNull;
      if (serverComp != null && serverComp.position != Vector2.zero()) {
        if (serverComp.isPlayerOne && serverComp.position.y <= bottomBaselineY && serverComp.position.y >= netY) {
          isWaitingForServe = false;
          currentGame.isWaitingForServe = false;
          currentGame.handleRallyWon(
            winnerIsPlayerOne: false,
            faultReason: 'FAULT: Service Foot Fault (Server stepped on or inside baseline)',
          );
          return;
        } else if (!serverComp.isPlayerOne && serverComp.position.y >= topBaselineY && serverComp.position.y <= netY) {
          isWaitingForServe = false;
          currentGame.isWaitingForServe = false;
          currentGame.handleRallyWon(
            winnerIsPlayerOne: true,
            faultReason: 'FAULT: Service Foot Fault (Server stepped on or inside baseline)',
          );
          return;
        }
      }
    } catch (_) {}

    AudioService.instance.playServe();

    // Exact parabolic flight time to court floor bounce (z = 0)
    final double tBounce = (zVelocity + sqrt(zVelocity * zVelocity + 4 * 170.0 * z)) / 340.0;

    Vector2 target;
    if (isPlayerOne) {
      // Bottom server serves diagonally upwards into diagonal receiving box
      // Top court receiving boxes: between kitchenTopY (324) and topBaselineY (174)
      const targetY = 245.0;
      final leftBoxX = (Background.courtLeftAt(targetY) + courtCenterX) / 2.0;
      final rightBoxX = (courtCenterX + Background.courtRightAt(targetY)) / 2.0;
      final baseTargetX = (currentGame.servingSide == 'right') ? leftBoxX : rightBoxX;
      final clampedAngle = horizontalAngle.clamp(-0.20, 0.20);
      final minX = Background.courtLeftAt(targetY) + 15.0;
      final maxX = Background.courtRightAt(targetY) - 15.0;
      final targetX = (baseTargetX + clampedAngle * 55.0).clamp(minX, maxX);
      target = Vector2(targetX, targetY);
    } else {
      // Top server serves diagonally downwards into diagonal receiving box
      // Bottom court receiving boxes: between kitchenBottomY (474) and bottomBaselineY (661)
      const targetY = 570.0;
      final leftBoxX = (Background.courtLeftAt(targetY) + courtCenterX) / 2.0;
      final rightBoxX = (courtCenterX + Background.courtRightAt(targetY)) / 2.0;
      final baseTargetX = (currentGame.servingSide == 'right') ? rightBoxX : leftBoxX;
      final minX = Background.courtLeftAt(targetY) + 15.0;
      final maxX = Background.courtRightAt(targetY) - 15.0;
      target = Vector2(baseTargetX.clamp(minX, maxX), targetY);
    }

    velocity = Vector2(
      (target.x - position.x) / tBounce,
      (target.y - position.y) / tBounce,
    );
    speed = velocity.length;

    // Step forward into court on serve impact
    try {
      final serverComp = currentGame.activeServerComponent;
      if (serverComp.isPlayerOne && serverComp.position.y > 665.0) {
        serverComp.position.y = 640.0;
      } else if (!serverComp.isPlayerOne && serverComp.position.y < 165.0) {
        serverComp.position.y = 195.0;
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

    // Pseudo 2.5D perspective scaling based on court depth
    radius = (11.0 * Background.perspectiveScaleAt(position.y)).clamp(8.0, 12.0);

    // Track motion particle trail
    final settings = currentGameOrNull?.settings;
    final bool enableParticles = settings?.particlesEnabled ?? true;
    if (enableParticles && !isWaitingForServe && speed > 50) {
      _trailTimer += dt;
      if (_trailTimer >= 0.02) {
        _trailTimer = 0.0;
        final maxTrail = (settings?.graphicsQuality == 'Low') ? 4 : 8;
        _trailPositions.insert(0, Offset(position.x, position.y - z));
        if (_trailPositions.length > maxTrail) {
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
        // Must clear kitchenBottomY (474)
        if (position.y <= kitchenBottomY + 2.0) {
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
        // Must clear kitchenTopY (324)
        if (position.y >= kitchenTopY - 2.0) {
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

    // 6. Out of Bounds detection on first floor bounce according to white lines
    final double courtLeft = Background.courtLeftAt(position.y);
    final double courtRight = Background.courtRightAt(position.y);
    final bool outLeft = position.x < courtLeft - 6.0;
    final bool outRight = position.x > courtRight + 6.0;
    final bool outTop = position.y < topBaselineY - 8.0;
    final bool outBottom = position.y > bottomBaselineY + 8.0;

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
    final settings = currentGameOrNull?.settings;

    // 1. Draw realistic floor shadow at ground level beneath the ball
    final bool enableShadows = settings?.shadowsEnabled ?? true;
    if (enableShadows) {
      final shadowScale = (1.0 - (z / 220.0).clamp(0.0, 0.45));
      final shadowAlpha = ((1.0 - (z / 250.0).clamp(0.0, 0.6)) * 0.45);
      _shadowPaint.color = Colors.black.withValues(alpha: shadowAlpha);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(0, 4),
          width: radius * 2.2 * shadowScale,
          height: radius * 1.1 * shadowScale,
        ),
        _shadowPaint,
      );
    }

    // 2. Draw expanding ripple ring on the floor when the ball bounces
    if (_bounceEffectRadius > 0) {
      _ripplePaint.color = _ballInfo.rippleColor.withValues(alpha: (1.0 - (_bounceEffectRadius / 30)).clamp(0.0, 1.0));
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(0, 4),
          width: _bounceEffectRadius * 2.2,
          height: _bounceEffectRadius * 1.1,
        ),
        _ripplePaint,
      );
    }

    // 3. Draw particle motion trail
    final bool enableParticles = settings?.particlesEnabled ?? true;
    if (enableParticles && _trailPositions.isNotEmpty) {
      for (int i = 0; i < _trailPositions.length; i++) {
        final p = _trailPositions[i];
        final rel = Offset(p.dx - position.x, p.dy - position.y);
        final progress = 1.0 - (i / _trailPositions.length);
        final trailAlpha = (progress * 0.55).clamp(0.0, 1.0);
        final trailRad = radius * (0.35 + 0.45 * progress);

        // Special particle visual styles for active techniques!
        if (activeTechniqueType == BattleTechnique.leftSpin) {
          // 🌪️ Cyclone Left Spin: Emerald & mint wind vortex trail
          _trailFillPaint.color = (i % 2 == 0 ? const Color(0xFF10B981) : const Color(0xFF34D399))
              .withValues(alpha: (trailAlpha * 1.6).clamp(0.0, 1.0));
          canvas.drawCircle(rel, trailRad * 1.35, _trailFillPaint);

          // Counter-clockwise orbiting wind wisps
          final angle = -ballRotationAngle + (i * 0.4);
          final wispOffset = rel + Offset(cos(angle) * trailRad * 0.6, sin(angle) * trailRad * 0.6);
          _wispPaint.color = Colors.white.withValues(alpha: trailAlpha * 0.85);
          canvas.drawCircle(wispOffset, trailRad * 0.45, _wispPaint);
        } else if (activeTechniqueType == BattleTechnique.rightSpin) {
          // ⚡ Vortex Right Spin: Electric violet & purple plasma trail
          _trailFillPaint.color = (i % 2 == 0 ? const Color(0xFF8B5CF6) : const Color(0xFFA855F7))
              .withValues(alpha: (trailAlpha * 1.6).clamp(0.0, 1.0));
          canvas.drawCircle(rel, trailRad * 1.35, _trailFillPaint);

          // Clockwise orbiting plasma spark
          final angle = ballRotationAngle + (i * 0.4);
          final sparkOffset = rel + Offset(cos(angle) * trailRad * 0.6, sin(angle) * trailRad * 0.6);
          _wispPaint.color = const Color(0xFFE9D5FF).withValues(alpha: trailAlpha * 0.85);
          canvas.drawCircle(sparkOffset, trailRad * 0.45, _wispPaint);
        } else {
          _trailFillPaint.color = _ballInfo.sparkColor.withValues(alpha: trailAlpha);
          canvas.drawCircle(rel, trailRad, _trailFillPaint);

          if (_ballInfo.tier == BallTier.legendary ||
              _ballInfo.tier == BallTier.mythic ||
              _ballInfo.tier == BallTier.special) {
            _trailStrokePaint.color = _ballInfo.glowColor.withValues(alpha: trailAlpha * 0.45);
            canvas.drawCircle(rel, trailRad * 1.35, _trailStrokePaint);
          }
        }
      }
    }

    // 4. Draw 3D Pickleball elevated by altitude z with Squash & Stretch
    canvas.save();
    canvas.translate(0, -z);
    canvas.scale(2.0 - squashFactor, squashFactor);

    // Glowing aura for higher tier balls or active battle technique (Optimized: avoid MaskFilter.blur on budget GPUs)
    final bool useBlur = settings?.graphicsQuality == 'Ultra';
    if (activeTechniqueType == BattleTechnique.leftSpin) {
      if (useBlur) {
        _auraFillPaint.color = const Color(0xFF10B981).withValues(alpha: 0.65);
        _auraFillPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
        canvas.drawCircle(Offset.zero, radius + 4.5, _auraFillPaint);
      } else {
        // High-performance crisp arcade halo
        _auraFillPaint.maskFilter = null;
        _auraFillPaint.color = const Color(0xFF10B981).withValues(alpha: 0.25);
        canvas.drawCircle(Offset.zero, radius + 5.5, _auraFillPaint);
        _auraFillPaint.color = const Color(0xFF34D399).withValues(alpha: 0.55);
        canvas.drawCircle(Offset.zero, radius + 2.5, _auraFillPaint);
      }
    } else if (activeTechniqueType == BattleTechnique.rightSpin) {
      if (useBlur) {
        _auraFillPaint.color = const Color(0xFF8B5CF6).withValues(alpha: 0.65);
        _auraFillPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
        canvas.drawCircle(Offset.zero, radius + 4.5, _auraFillPaint);
      } else {
        // High-performance crisp arcade halo
        _auraFillPaint.maskFilter = null;
        _auraFillPaint.color = const Color(0xFF8B5CF6).withValues(alpha: 0.25);
        canvas.drawCircle(Offset.zero, radius + 5.5, _auraFillPaint);
        _auraFillPaint.color = const Color(0xFFA855F7).withValues(alpha: 0.55);
        canvas.drawCircle(Offset.zero, radius + 2.5, _auraFillPaint);
      }
    } else if (_ballInfo.tier != BallTier.elite) {
      if (useBlur) {
        _auraFillPaint.color = _ballInfo.glowColor.withValues(alpha: 0.35);
        _auraFillPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawCircle(Offset.zero, radius + 2.5, _auraFillPaint);
      } else {
        _auraFillPaint.maskFilter = null;
        _auraFillPaint.color = _ballInfo.glowColor.withValues(alpha: 0.30);
        canvas.drawCircle(Offset.zero, radius + 3.0, _auraFillPaint);
      }
    }

    _cachedBallPaint ??= Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.85,
        colors: _ballInfo.gradientColors,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, _cachedBallPaint!);

    // 5. Draw pickleball holes / perforations with dynamic sidespin rotation
    canvas.save();
    canvas.rotate(ballRotationAngle);
    const double holeRad = 1.7;
    canvas.drawCircle(const Offset(-4, -4), holeRad, _holePaint);
    canvas.drawCircle(const Offset(4, -4), holeRad, _holePaint);
    canvas.drawCircle(const Offset(-4, 4), holeRad, _holePaint);
    canvas.drawCircle(const Offset(4, 4), holeRad, _holePaint);
    canvas.drawCircle(const Offset(0, 0), holeRad, _holePaint);
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

    // 3. LEGAL HIT: Groundstroke, Dink, or Open-Play Volley outside Kitchen
    // Rule 6: Two-bounce rule applies to serve and return (evaluated as faults above).
    // Rule 7: Kitchen volleys are faults (evaluated as faults above).
    // Outside the kitchen after the first two bounces, open-play volleys are 100% legal!
    if ((currentGame.settings?.requireFloorBounceAllShots ?? false) && bounceCountCurrentSide == 0) {
      return; // Optional training mode: requires floor bounce before every hit
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
        targetY = 215.0;
        targetX = Background.courtLeftAt(targetY) + 18.0;
        currentGame.onAnnouncement?.call('🌪️ CYCLONE CURVE!', 'Wicked left sidespin curve!');
        currentGame.onTechniqueExecuted(BattleTechnique.leftSpin);
      } else {
        targetY = 620.0;
        targetX = Background.courtLeftAt(targetY) + 20.0;
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
        targetY = 215.0;
        targetX = Background.courtRightAt(targetY) - 18.0;
        currentGame.onAnnouncement?.call('⚡ VORTEX HOOK!', 'Fierce right sidespin hook!');
        currentGame.onTechniqueExecuted(BattleTechnique.rightSpin);
      } else {
        targetY = 620.0;
        targetX = Background.courtRightAt(targetY) - 20.0;
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
        double vInput = 0.0;
        if (player.joystick != null && !player.joystick!.delta.isZero()) {
          vInput = player.joystick!.relativeDelta.y;
        } else {
          vInput = player.vAxis.toDouble();
        }
        targetY = (245.0 + vInput * 45.0).clamp(195.0, 310.0);

        final aimOffset = (player.horizontalMovement * 120.0) + (diff.x * 0.7);
        final minX = Background.courtLeftAt(targetY) + 15.0;
        final maxX = Background.courtRightAt(targetY) - 15.0;
        targetX = (courtCenterX + aimOffset).clamp(minX, maxX);
      } else if (isPlayerOne && player.isAI) {
        final oppPos = currentGame.player2.position;
        final targetLeft = oppPos.x > courtCenterX;
        final isDeep = (currentGame.rallyHitCount % 3 != 0);
        targetY = isDeep ? 210.0 : 285.0;
        final leftBoxX = (Background.courtLeftAt(targetY) + courtCenterX) / 2.0;
        final rightBoxX = (courtCenterX + Background.courtRightAt(targetY)) / 2.0;
        final baseAim = targetLeft ? leftBoxX : rightBoxX;
        final minX = Background.courtLeftAt(targetY) + 15.0;
        final maxX = Background.courtRightAt(targetY) - 15.0;
        final aimOffset = (diff.x * 0.3) + ((Random().nextDouble() - 0.5) * 40.0);
        targetX = (baseAim + aimOffset).clamp(minX, maxX);
      } else {
        final oppPos = currentGame.player1.position;
        final targetLeft = oppPos.x > courtCenterX;
        final isDeep = (currentGame.rallyHitCount % 3 != 0);
        targetY = isDeep ? 625.0 : 520.0;
        final leftBoxX = (Background.courtLeftAt(targetY) + courtCenterX) / 2.0;
        final rightBoxX = (courtCenterX + Background.courtRightAt(targetY)) / 2.0;
        final baseAim = targetLeft ? leftBoxX : rightBoxX;
        final minX = Background.courtLeftAt(targetY) + 15.0;
        final maxX = Background.courtRightAt(targetY) - 15.0;
        final aimOffset = (diff.x * 0.3) + ((Random().nextDouble() - 0.5) * 40.0);
        targetX = (baseAim + aimOffset).clamp(minX, maxX);
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

