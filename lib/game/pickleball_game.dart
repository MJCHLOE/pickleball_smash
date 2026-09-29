import 'dart:async';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../models/character_roster.dart';
import '../models/game_settings.dart';
import '../models/multiplayer_models.dart';
import '../services/audio_service.dart';
import '../services/game_state_manager.dart';
import '../services/multiplayer_service.dart';
import 'components/background.dart';
import 'components/player.dart';
import 'components/ball.dart';
import 'components/arcade_button_component.dart';
import 'components/arcade_skill_button_component.dart';
import '../models/battle_technique.dart';

class PickleballGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  final void Function(int p1Score, int p2Score)? onScoreUpdated;
  final void Function(bool playerWon)? onMatchFinished;
  final VoidCallback? onSmash;
  final void Function(String title, String subtitle)? onAnnouncement;
  final void Function(bool isWaiting, int serverPlayer, String servingSide)? onServeStateChanged;
  final void Function(String violationType, String description, String ruleDetail)? onViolation;
  void Function(int streak, int longest)? onRallyStreakUpdated;
  final bool joystickOnLeft;
  final int targetScore;
  final bool isDoubles;
  GameSettings? settings;

  int p1Score = 0;
  int p2Score = 0;
  bool isGameOver = false;
  double elapsedTime = 0.0;
  int continuousRallyStreak = 0;
  int longestRally = 0;

  // Official Pickleball rules state
  int _serverPlayer = 1; // 1 = Player 1, 2 = Player 2 (CPU)
  int get serverPlayer => isDoubles ? serverTeam : _serverPlayer;
  set serverPlayer(int val) {
    _serverPlayer = val;
    if (isDoubles) serverTeam = val;
  }
  int rallyHitCount = 0; // 0 = serve, 1 = return, 2+ = open play
  bool isWaitingForServe = true;
  final bool? player1IsFemale;
  final CharacterType? player1CharacterType;
  final CharacterType? player2CharacterType;
  final CharacterType? partner1CharacterType;
  final CharacterType? partner2CharacterType;

  // Doubles (2v2) rotation & serve tracking
  int serverTeam = 1; // 1 = Team 1 (User + Partner), 2 = Team 2 (CPU 1 + CPU 2)
  int serverNumber = 2; // Rule 4: Match begins at 0-0-2 with server 2!
  String p1CourtSide = 'right';
  String p1PartnerCourtSide = 'left';
  String p2CourtSide = 'left';
  String p2PartnerCourtSide = 'right';

  PickleballGame({
    this.onScoreUpdated,
    this.onMatchFinished,
    this.onSmash,
    this.onAnnouncement,
    this.onServeStateChanged,
    this.onViolation,
    this.onRallyStreakUpdated,
    this.joystickOnLeft = true,
    this.targetScore = 11,
    this.isDoubles = false,
    this.settings,
    this.player1IsFemale,
    this.player1CharacterType,
    this.player2CharacterType,
    this.partner1CharacterType,
    this.partner2CharacterType,
    this.courtId,
    this.ballId,
    this.isMultiplayer = false,
    this.isHost = false,
  }) : super(
          camera: CameraComponent(),
        );

  final String? courtId;
  final String? ballId;
  final bool isMultiplayer;
  final bool isHost;
  RemotePlayerInterpolator? _remoteInterpolator;
  StreamSubscription<MultiplayerPacket>? _networkPacketSub;
  double _networkTickTimer = 0.0;

  Background? _background;
  Background get background =>
      _background ??= Background(courtId: courtId ?? GameStateManager.instance.equippedCourtId);
  set background(Background val) => _background = val;
  PlayerComponent? _player1;
  PlayerComponent get player1 => _player1!;
  set player1(PlayerComponent val) => _player1 = val;
  PlayerComponent? player1Partner;

  PlayerComponent? _player2;
  PlayerComponent get player2 => _player2!;
  set player2(PlayerComponent val) => _player2 = val;
  PlayerComponent? player2Partner;

  late JoystickComponent joystick;
  late HudButtonComponent strikeButton;
  ArcadeSkillButtonComponent? leftSpinButton;
  ArcadeSkillButtonComponent? rightSpinButton;
  ArcadeSkillButtonComponent? dashButton;

  // Backward-compatible aliases
  ArcadeSkillButtonComponent? get thunderButton => leftSpinButton;
  set thunderButton(ArcadeSkillButtonComponent? val) => leftSpinButton = val;
  ArcadeSkillButtonComponent? get phantomButton => rightSpinButton;
  set phantomButton(ArcadeSkillButtonComponent? val) => rightSpinButton = val;
  late BallComponent ball;
  FpsTextComponent? fpsText;
  Sprite? paddleSprite;

  String get servingSide {
    if (isDoubles) {
      final teamScore = (serverTeam == 1) ? p1Score : p2Score;
      return (teamScore % 2 == 0) ? 'right' : 'left';
    } else {
      final serverScore = (serverPlayer == 1) ? p1Score : p2Score;
      return (serverScore % 2 == 0) ? 'right' : 'left';
    }
  }

  PlayerComponent? get activeServerComponentOrNull {
    try {
      if (isDoubles) {
        if (serverTeam == 1) {
          return (p1CourtSide == servingSide) ? _player1 : (player1Partner ?? _player1);
        } else {
          return (p2CourtSide == servingSide) ? _player2 : (player2Partner ?? _player2);
        }
      } else {
        return (serverPlayer == 1) ? _player1 : _player2;
      }
    } catch (_) {
      return null;
    }
  }

  PlayerComponent get activeServerComponent => activeServerComponentOrNull ?? player1;

  bool get isHumanServer {
    final server = activeServerComponentOrNull;
    if (server == null) {
      return serverPlayer == 1;
    }
    return !server.isAI;
  }

  String get doublesScoreCallout {
    final servingScore = (serverTeam == 1) ? p1Score : p2Score;
    final receivingScore = (serverTeam == 1) ? p2Score : p1Score;
    return '$servingScore - $receivingScore - $serverNumber';
  }

  void onPlayerSmash() {
    AudioService.instance.playSmash();

    // Camera shake effect on smash if enabled
    if (settings?.screenShakeEnabled ?? true) {
      camera.viewfinder.position = Vector2(640, 364);
      Future.delayed(const Duration(milliseconds: 50), () {
        camera.viewfinder.position = Vector2(640, 356);
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        camera.viewfinder.position = Vector2(640, 360);
      });
    }

    onSmash?.call();
  }

  /// Official Pickleball Side-Out Scoring & Fault Resolution
  void handleRallyWon({required bool winnerIsPlayerOne, required String faultReason}) {
    if (isGameOver) return;

    if (faultReason.isNotEmpty) {
      _dispatchViolation(faultReason);
    }

    continuousRallyStreak = 0;
    onRallyStreakUpdated?.call(0, longestRally);

    final bool isRallyScoring = (settings?.scoringMode == 'rally');
    final bool serverWon = isDoubles
        ? (winnerIsPlayerOne == (serverTeam == 1))
        : (winnerIsPlayerOne == (serverPlayer == 1));

    if (isRallyScoring || serverWon) {
      // 1. Points awarded to winner of rally (in Rally Scoring, every rally awards point; in Side-Out, only server)
      if (winnerIsPlayerOne) {
        p1Score++;
      } else {
        p2Score++;
      }

      AudioService.instance.playPointScored();
      onScoreUpdated?.call(p1Score, p2Score);

      // 2. Win by 2 margin check
      final int maxScore = math.max(p1Score, p2Score);
      final int minScore = math.min(p1Score, p2Score);

      if (maxScore >= targetScore && (maxScore - minScore) >= 2) {
        isGameOver = true;
        pauseEngine();
        if (winnerIsPlayerOne) {
          AudioService.instance.playVictory();
        } else {
          AudioService.instance.playDefeat();
        }
        onAnnouncement?.call(
          winnerIsPlayerOne ? 'VICTORY!' : 'MATCH DEFEAT',
          'Final Score: $p1Score - $p2Score',
        );
        if (isMultiplayer && isHost) {
          MultiplayerService.instance.broadcastPacket(
            MultiplayerPacket(
              type: PacketType.scoreSync,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              senderId: MultiplayerService.instance.myProfile.playerId,
              data: {
                'p1Score': p1Score,
                'p2Score': p2Score,
              },
            ),
          );
        }
        onMatchFinished?.call(winnerIsPlayerOne);
        return;
      }

      // If Rally Scoring: the team that won the rally gets to serve next!
      if (isRallyScoring) {
        if (isDoubles) {
          serverTeam = winnerIsPlayerOne ? 1 : 2;
        } else {
          serverPlayer = winnerIsPlayerOne ? 1 : 2;
        }
      }

      // 3. In Doubles, the serving team switches sides when they win a rally!
      if (isDoubles) {
        if (serverTeam == 1) {
          final temp = p1CourtSide;
          p1CourtSide = p1PartnerCourtSide;
          p1PartnerCourtSide = temp;
        } else {
          final temp = p2CourtSide;
          p2CourtSide = p2PartnerCourtSide;
          p2PartnerCourtSide = temp;
        }
      }

      final callout = isDoubles ? doublesScoreCallout : '$p1Score - $p2Score';

      if (isMultiplayer && isHost) {
        MultiplayerService.instance.broadcastPacket(
          MultiplayerPacket(
            type: PacketType.scoreSync,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            senderId: MultiplayerService.instance.myProfile.playerId,
            data: {
              'p1Score': p1Score,
              'p2Score': p2Score,
            },
          ),
        );
      }

      onAnnouncement?.call(
        'POINT! ($callout)',
        faultReason.isNotEmpty ? faultReason : 'Rally won by ${winnerIsPlayerOne ? 'Player 1' : 'Player 2'}',
      );

      // Prepare next service positions
      prepareServicePositions();
    } else {
      // 4. Receiving team won rally -> No point awarded
      AudioService.instance.playPaddleHit();

      if (isDoubles) {
        if (serverNumber == 1) {
          // Serve passes to second server on the SAME team!
          // Partners do NOT switch sides!
          serverNumber = 2;
          onAnnouncement?.call(
            'SECOND SERVER! ($doublesScoreCallout)',
            faultReason.isNotEmpty ? '$faultReason • Second server up!' : 'Second server takes over',
          );
          prepareServicePositions();
        } else {
          // Server 2 lost rally -> SIDE OUT!
          // Serve passes to opposing team, starting with server 1!
          serverTeam = (serverTeam == 1) ? 2 : 1;
          serverNumber = 1;
          onAnnouncement?.call(
            'SIDE OUT! ($doublesScoreCallout)',
            faultReason.isNotEmpty
                ? '$faultReason • Serve changes!'
                : 'Serve changes to ${serverTeam == 1 ? 'Team 1' : 'Team 2'}',
          );
          prepareServicePositions();
        }
      } else {
        // Singles: Serve transfers to opponent
        serverPlayer = (serverPlayer == 1) ? 2 : 1;
        onAnnouncement?.call(
          'SIDE OUT!',
          faultReason.isNotEmpty
              ? '$faultReason • Serve changes!'
              : 'Serve changes to ${serverPlayer == 1 ? 'Player 1' : 'CPU'}',
        );
        prepareServicePositions();
      }
    }
  }

  /// Resets match state for continuous, instant rematch without reloading widgets
  void resetForNewMatch() {
    p1Score = 0;
    p2Score = 0;
    isGameOver = false;
    rallyHitCount = 0;
    continuousRallyStreak = 0;
    _serverPlayer = 1;
    serverTeam = 1;
    serverNumber = isDoubles ? 2 : 1;
    p1CourtSide = 'right';
    p1PartnerCourtSide = 'left';
    p2CourtSide = 'left';
    p2PartnerCourtSide = 'right';

    resumeEngine();
    leftSpinButton?.resetCooldown();
    rightSpinButton?.resetCooldown();
    dashButton?.resetCooldown();
    onScoreUpdated?.call(0, 0);
    onRallyStreakUpdated?.call(0, longestRally);
    prepareServicePositions();
  }

  /// Legacy helper for point scoring
  void onPointScored({required bool isPlayerOne}) {
    handleRallyWon(winnerIsPlayerOne: isPlayerOne, faultReason: '');
  }

  void _dispatchViolation(String faultReason) {
    AudioService.instance.playFault();
    String violationType = 'RULE VIOLATION';
    String description = faultReason;
    String ruleDetail = 'A fault ends the rally according to official pickleball rules.';

    final cleanReason = faultReason.replaceFirst('FAULT: ', '');

    if (cleanReason.contains('Kitchen Momentum')) {
      violationType = 'KITCHEN MOMENTUM';
      description = 'Momentum carried player into Non-Volley Zone';
      ruleDetail = 'Rule 3: Player momentum cannot carry them into the Kitchen after a volley!';
    } else if (cleanReason.contains('Kitchen Volley')) {
      violationType = 'KITCHEN VOLLEY';
      description = 'Volleyed ball inside Non-Volley Zone';
      ruleDetail = 'Rule 3: Cannot volley out of the air while inside the Kitchen or touching its line!';
    } else if (cleanReason.contains('Two-Bounce Rule')) {
      violationType = 'TWO-BOUNCE RULE';
      description = cleanReason;
      ruleDetail = 'Rule 2: Both the serve and return of serve must bounce before being hit!';
    } else if (cleanReason.contains('Service In Kitchen')) {
      violationType = 'SERVICE IN KITCHEN';
      description = 'Serve landed in Non-Volley Zone';
      ruleDetail = 'Rule 1: Serve must completely clear the Kitchen and kitchen line!';
    } else if (cleanReason.contains('Service Wrong Court')) {
      violationType = 'SERVICE WRONG COURT';
      description = 'Serve landed in wrong service box';
      ruleDetail = 'Rule 1: Serve must land diagonally in the opponent\'s receiving court!';
    } else if (cleanReason.contains('Net Fault')) {
      violationType = 'NET FAULT';
      description = 'Ball hit net and failed to clear';
      ruleDetail = 'Rule 4: Ball must clear the net onto the opponent\'s court!';
    } else if (cleanReason.contains('Out of Bounds')) {
      violationType = 'OUT OF BOUNDS';
      description = cleanReason;
      ruleDetail = 'Rule 4: Ball landed outside boundary lines!';
    }

    onViolation?.call(violationType, description, ruleDetail);
  }

  /// Sets up court positions for server and receiver per official singles/doubles rotation
  void prepareServicePositions() {
    isWaitingForServe = true;
    rallyHitCount = 0;

    if (isDoubles) {
      final activeServer = activeServerComponent;

      // Position Team 1 (Bottom)
      final p1IsServer = (activeServer == player1);
      final p1TargetX = (p1CourtSide == 'right') ? 760.0 : 520.0;
      player1.position = Vector2(p1TargetX, p1IsServer ? 695.0 : 580.0);

      if (player1Partner != null) {
        final p1pIsServer = (activeServer == player1Partner);
        final p1pTargetX = (p1PartnerCourtSide == 'right') ? 760.0 : 520.0;
        player1Partner!.position = Vector2(p1pTargetX, p1pIsServer ? 695.0 : 580.0);
      }

      // Position Team 2 (Top)
      // From P2 perspective: right court is viewer left (520), left court is viewer right (760)
      final p2IsServer = (activeServer == player2);
      final p2TargetX = (p2CourtSide == 'right') ? 520.0 : 760.0;
      player2.position = Vector2(p2TargetX, p2IsServer ? 25.0 : 140.0);

      if (player2Partner != null) {
        final p2pIsServer = (activeServer == player2Partner);
        final p2pTargetX = (p2PartnerCourtSide == 'right') ? 520.0 : 760.0;
        player2Partner!.position = Vector2(p2pTargetX, p2pIsServer ? 25.0 : 140.0);
      }

      player1.stopRunning();
      player1Partner?.stopRunning();
      player2.stopRunning();
      player2Partner?.stopRunning();

      ball.setupForServe();

      final callout = doublesScoreCallout;
      final sideName = servingSide.toUpperCase();

      String serverTitle;
      String serverSubtitle;
      if (activeServer == player1) {
        serverTitle = 'YOUR SERVE ($sideName)';
        serverSubtitle = 'Score: $callout • Tap Smash to Serve';
      } else if (activeServer == player1Partner) {
        serverTitle = 'PARTNER SERVE ($sideName)';
        serverSubtitle = 'Score: $callout • Partner is serving!';
      } else {
        serverTitle = 'CPU SERVE ($sideName)';
        serverSubtitle = 'Score: $callout • Get Ready!';
      }

      onAnnouncement?.call(serverTitle, serverSubtitle);
      final activeServerId = (activeServer == player1) ? 1 : 2;
      onServeStateChanged?.call(true, activeServerId, servingSide);
    } else {
      // Singles (1v1)
      if (serverPlayer == 1) {
        if (servingSide == 'right') {
          player1.position = Vector2(760, 695); // Behind baseline outside court
          player2.position = Vector2(520, 140); // Receiver inside diagonal court
        } else {
          player1.position = Vector2(520, 695);
          player2.position = Vector2(760, 140);
        }
      } else {
        if (servingSide == 'right') {
          player2.position = Vector2(520, 25);  // Behind baseline outside court
          player1.position = Vector2(760, 580); // Receiver inside diagonal court
        } else {
          player2.position = Vector2(760, 25);
          player1.position = Vector2(520, 580);
        }
      }

      player1.stopRunning();
      player2.stopRunning();

      ball.setupForServe();

      final serverName = serverPlayer == 1 ? 'YOUR' : 'CPU';
      final sideName = servingSide.toUpperCase();
      final callout = '$p1Score - $p2Score';
      onAnnouncement?.call(
        '$serverName SERVE ($sideName)',
        serverPlayer == 1 ? 'Score: $callout • Tap Smash to Serve' : 'Score: $callout • Get Ready!',
      );
      onServeStateChanged?.call(true, serverPlayer, servingSide);
    }
  }

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(1280 / 2, 720 / 2);
    _updateCameraViewport();

    final effectiveCourt = courtId ?? GameStateManager.instance.equippedCourtId;
    background = Background(courtId: effectiveCourt);
    world.add(background);

    _setupControls();

    final effectiveP1Char = player1CharacterType ??
        (player1IsFemale == true ? CharacterType.female1 : CharacterType.male1);
    final effectiveP2Char = player2CharacterType ??
        (effectiveP1Char == CharacterType.female1
            ? CharacterType.female2
            : (effectiveP1Char == CharacterType.female2 ? CharacterType.male2 : CharacterType.female1));
    final effectiveP1PartnerChar = partner1CharacterType ??
        (effectiveP1Char == CharacterType.male1 ? CharacterType.female2 : CharacterType.male1);
    final effectiveP2PartnerChar = partner2CharacterType ??
        (effectiveP2Char == CharacterType.male2 ? CharacterType.female2 : CharacterType.male2);

    // Player 1 (Team 1, Bottom, Human User)
    player1 = PlayerComponent(
      isPlayerOne: true,
      characterType: effectiveP1Char,
      isFemale: effectiveP1Char == CharacterType.female1 || effectiveP1Char == CharacterType.female2,
      isAI: false,
      playerSlot: 1,
      joystick: joystick,
    );
    player1.customGame = this;
    world.add(player1);

    // Player 1 Partner (Team 1, Bottom, AI Teammate) in Doubles
    if (isDoubles) {
      player1Partner = PlayerComponent(
        isPlayerOne: true,
        characterType: effectiveP1PartnerChar,
        isFemale: effectiveP1PartnerChar == CharacterType.female1 || effectiveP1PartnerChar == CharacterType.female2,
        isAI: true,
        playerSlot: 2,
        joystick: null,
      );
      player1Partner!.customGame = this;
      world.add(player1Partner!);
    }

    // Player 2 (Team 2, Top, Remote Player or CPU 1)
    player2 = PlayerComponent(
      isPlayerOne: false,
      characterType: effectiveP2Char,
      isFemale: effectiveP2Char == CharacterType.female1 || effectiveP2Char == CharacterType.female2,
      isAI: !isMultiplayer,
      playerSlot: 1,
      joystick: null,
    );
    player2.customGame = this;
    world.add(player2);

    // Player 2 Partner (Team 2, Top, CPU 2) in Doubles
    if (isDoubles) {
      player2Partner = PlayerComponent(
        isPlayerOne: false,
        characterType: effectiveP2PartnerChar,
        isFemale: effectiveP2PartnerChar == CharacterType.female1 || effectiveP2PartnerChar == CharacterType.female2,
        isAI: true,
        playerSlot: 2,
        joystick: null,
      );
      player2Partner!.customGame = this;
      world.add(player2Partner!);
    }

    // The Ball!
    final effectiveBall = ballId ?? GameStateManager.instance.equippedBallId;
    ball = BallComponent(ballId: effectiveBall);
    ball.customGame = this;
    world.add(ball);

    prepareServicePositions();

    // Load 2D Arcade Pixel Paddle Sprite for Smash Button
    try {
      final paddleImage = await images.load('logo/pixel_paddle.png');
      paddleSprite = Sprite(paddleImage);
      final existingButtons = camera.viewport.children.whereType<HudButtonComponent>().toList();
      if (existingButtons.isNotEmpty) {
        final btn = existingButtons.first;
        if (btn.button is ArcadeButtonFaceComponent) {
          (btn.button as ArcadeButtonFaceComponent).paddleSprite = paddleSprite;
        }
        if (btn.buttonDown is ArcadeButtonFaceComponent) {
          (btn.buttonDown as ArcadeButtonFaceComponent).paddleSprite = paddleSprite;
        }
      }
    } catch (_) {}

    _updateFpsOverlay();

    if (isMultiplayer) {
      _remoteInterpolator = RemotePlayerInterpolator(
        startX: player2.position.x,
        startY: player2.position.y,
      );
      player2.remoteInterpolator = _remoteInterpolator;
      _networkPacketSub = MultiplayerService.instance.packetStream.listen(_handleNetworkPacket);
    }
  }

  @override
  void update(double dt) {
    // Clamp delta time to prevent spiral-of-death and physical hitching on low-end devices
    final clampedDt = dt.clamp(0.001, 0.05);
    super.update(clampedDt);
    elapsedTime += clampedDt;

    if (isMultiplayer) {
      _networkTickTimer += dt;
      if (_networkTickTimer >= 0.033) {
        _networkTickTimer = 0.0;
        final myId = MultiplayerService.instance.myProfile.playerId;
        MultiplayerService.instance.broadcastPacket(
          MultiplayerPacket(
            type: PacketType.playerState,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            senderId: myId,
            data: {
              'x': player1.position.x,
              'y': player1.position.y,
              'vx': player1.currentVelocity.x,
              'vy': player1.currentVelocity.y,
              'isStriking': player1.currentState == PlayerState.slash,
              'technique': player1.activeTechnique.name,
              'isDashing': player1.isDashing,
            },
          ),
        );

        // Host continuously streams authoritative ball physics to Guest
        if (isHost && !ball.isWaitingForServe) {
          MultiplayerService.instance.broadcastPacket(
            MultiplayerPacket(
              type: PacketType.ballStrike,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              senderId: myId,
              data: {
                'x': ball.position.x,
                'y': ball.position.y,
                'vx': ball.velocity.x,
                'vy': ball.velocity.y,
                'z': ball.z,
                'zVelocity': ball.zVelocity,
                'spin': ball.spin,
              },
            ),
          );
        }
      }
    }
  }

  @override
  void onRemove() {
    _networkPacketSub?.cancel();
    super.onRemove();
  }

  void _handleNetworkPacket(MultiplayerPacket packet) {
    if (packet.senderId == MultiplayerService.instance.myProfile.playerId) {
      return;
    }
    if (packet.type == PacketType.playerState) {
      // Invert coordinates across the symmetrical court (center: 640, 360)
      final rawX = (packet.data['x'] as num?)?.toDouble() ?? 640.0;
      final rawY = (packet.data['y'] as num?)?.toDouble() ?? 550.0;
      final rawVx = (packet.data['vx'] as num?)?.toDouble() ?? 0.0;
      final rawVy = (packet.data['vy'] as num?)?.toDouble() ?? 0.0;

      final x = 1280.0 - rawX;
      final y = 720.0 - rawY;
      final vx = -rawVx;
      final vy = -rawVy;

      _remoteInterpolator?.onPacketReceived(x: x, y: y, vx: vx, vy: vy);

      if (packet.data['isStriking'] == true) {
        player2.strike();
      }
      if (packet.data['isDashing'] == true) {
        player2.dash();
      }
      if (packet.data['technique'] != null && packet.data['technique'] != 'none') {
        final tech = BattleTechnique.values.firstWhere(
          (t) => t.name == packet.data['technique'],
          orElse: () => BattleTechnique.none,
        );
        if (tech != BattleTechnique.none) {
          player2.queueTechnique(tech);
        }
      }
    } else if (packet.type == PacketType.ballStrike) {
      final rawX = (packet.data['x'] as num?)?.toDouble();
      final rawY = (packet.data['y'] as num?)?.toDouble();
      final rawVx = (packet.data['vx'] as num?)?.toDouble();
      final rawVy = (packet.data['vy'] as num?)?.toDouble();
      final rawSpin = (packet.data['spin'] as num?)?.toDouble();
      final z = (packet.data['z'] as num?)?.toDouble();
      final zVelocity = (packet.data['zVelocity'] as num?)?.toDouble();

      final bx = rawX != null ? 1280.0 - rawX : null;
      final by = rawY != null ? 720.0 - rawY : null;
      final bvx = rawVx != null ? -rawVx : null;
      final bvy = rawVy != null ? -rawVy : null;
      final bspin = rawSpin != null ? -rawSpin : null;

      if (bx != null && by != null) {
        if (!isHost) {
          // Guest receiving authoritative ball from Host
          ball.position.setValues(bx, by);
          if (bvx != null && bvy != null) ball.velocity.setValues(bvx, bvy);
          if (bspin != null) ball.spin = bspin;
          if (z != null) ball.z = z;
          if (zVelocity != null) ball.zVelocity = zVelocity;
          if (ball.isWaitingForServe) {
            ball.isWaitingForServe = false;
            isWaitingForServe = false;
          }
        } else {
          // Host receiving ball hit from Guest: Guest struck the ball
          ball.position.setValues(bx, by);
          if (bvx != null && bvy != null) ball.velocity.setValues(bvx, bvy);
          if (bspin != null) ball.spin = bspin;
        }
      }
    } else if (packet.type == PacketType.scoreSync) {
      final p1 = packet.data['p1Score'] as int?;
      final p2 = packet.data['p2Score'] as int?;
      if (p1 != null && p2 != null) {
        if (isHost) {
          p1Score = p1;
          p2Score = p2;
        } else {
          p1Score = p2;
          p2Score = p1;
        }
        onScoreUpdated?.call(p1Score, p2Score);
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateCameraViewport();
    if (isLoaded) {
      _setupControls();
    }
  }

  void _updateCameraViewport() {
    if (size.x > 0 && size.y > 0) {
      final zoom = math.min(size.x / 1280.0, size.y / 720.0);
      camera.viewfinder.zoom = zoom;
    } else {
      camera.viewfinder.zoom = 1.0;
    }
    camera.viewfinder.position = Vector2(1280 / 2, 720 / 2);
    camera.viewfinder.anchor = Anchor.center;
  }

  @override
  Color backgroundColor() {
    if (_background != null && _background!.isLoaded) {
      return _background!.apronOuterColor;
    }
    return const Color(0xFF7A0114);
  }

  Color _resolveJoystickColor(String? colorChoice) {
    switch (colorChoice) {
      case 'Electric Cyan':
        return const Color(0xFF00E5FF);
      case 'Hot Pink':
        return const Color(0xFFFF1744);
      case 'Trophy Gold':
        return const Color(0xFFFFD700);
      case 'Pure White':
        return const Color(0xFFFFFFFF);
      case 'Neon Lime':
      default:
        return const Color(0xFFCCFF00);
    }
  }

  void _setupControls() {
    final effectiveJoystickOnLeft = settings?.joystickOnLeft ?? joystickOnLeft;
    final expand = (settings?.joystickExpand ?? 1.0).clamp(0.7, 1.6);
    final opacity = (settings?.transparentCapacity ?? settings?.controllerOpacity ?? 0.85).clamp(0.1, 1.0);
    final knobAlpha = (240 * opacity).round();
    final bgAlpha = (115 * opacity).round();

    final baseColor = _resolveJoystickColor(settings?.joystickColor);

    final bool showJoystick = settings?.showJoystick ?? true;
    final bool showSkillButtons = settings?.showSkillButtons ?? true;

    final double joyMarginX = settings?.joystickMarginX ?? 36.0;
    final double joyMarginY = settings?.joystickMarginY ?? 36.0;

    final double skillMarginX = settings?.skillMarginX ?? 36.0;
    final double skillMarginY = settings?.skillMarginY ?? 36.0;
    final double skillSpacing = settings?.skillSpacing ?? 90.0;
    final double skillScale = settings?.skillButtonScale ?? 1.0;

    double baseButtonRadius = 40.0;
    if (settings?.buttonSize == 'Large') {
      baseButtonRadius = 48.0;
    } else if (settings?.buttonSize == 'Extra Large') {
      baseButtonRadius = 56.0;
    }
    final buttonRadius = baseButtonRadius * skillScale;
    final skillRadius = (buttonRadius * 0.65).clamp(20.0, 48.0);

    final knobRadius = 26.0 * expand;
    final bgRadius = 68.0 * expand;

    // Setup HUD Controls based on joystickOnLeft setting
    final knobPaint = Paint()..color = baseColor.withAlpha(knobAlpha);
    final bgPaint = Paint()..color = baseColor.withAlpha(bgAlpha);

    final bool isArcadePreset = settings?.controlsPreset == 'Default Arcade';
    final double vpWidth = hasLayout ? (camera.viewport.size.x > 0 ? camera.viewport.size.x : 1280.0) : 1280.0;
    final double vpHeight = hasLayout ? (camera.viewport.size.y > 0 ? camera.viewport.size.y : 720.0) : 720.0;
    final bool isLeftHanded = !effectiveJoystickOnLeft;

    EdgeInsets calculateNormalizedMargin(double normalizedX, double normalizedY, double width, double height) {
      final effX = isLeftHanded ? (1.0 - normalizedX) : normalizedX;
      final effY = normalizedY;
      final double targetLeft = (effX * vpWidth - width / 2).clamp(4.0, math.max(4.0, vpWidth - width - 4.0)).toDouble();
      final double targetTop = (effY * vpHeight - height / 2).clamp(4.0, math.max(4.0, vpHeight - height - 4.0)).toDouble();
      return EdgeInsets.only(left: targetLeft, top: targetTop);
    }

    final EdgeInsets joystickMargin;
    final EdgeInsets buttonMargin;
    final EdgeInsets leftSpinMargin;
    final EdgeInsets rightSpinMargin;
    final EdgeInsets dashMargin;

    if (isArcadePreset) {
      joystickMargin = effectiveJoystickOnLeft
          ? EdgeInsets.only(left: joyMarginX, bottom: joyMarginY)
          : EdgeInsets.only(right: joyMarginX, bottom: joyMarginY);

      buttonMargin = effectiveJoystickOnLeft
          ? EdgeInsets.only(right: skillMarginX, bottom: skillMarginY)
          : EdgeInsets.only(left: skillMarginX, bottom: skillMarginY);

      leftSpinMargin = effectiveJoystickOnLeft
          ? EdgeInsets.only(right: skillMarginX + skillSpacing, bottom: skillMarginY)
          : EdgeInsets.only(left: skillMarginX + skillSpacing, bottom: skillMarginY);
      rightSpinMargin = effectiveJoystickOnLeft
          ? EdgeInsets.only(right: skillMarginX, bottom: skillMarginY + skillSpacing)
          : EdgeInsets.only(left: skillMarginX, bottom: skillMarginY + skillSpacing);
      dashMargin = effectiveJoystickOnLeft
          ? EdgeInsets.only(right: skillMarginX + skillSpacing, bottom: skillMarginY + skillSpacing)
          : EdgeInsets.only(left: skillMarginX + skillSpacing, bottom: skillMarginY + skillSpacing);
    } else {
      // Mobile Legends: Bang Bang (MLBB) & Free Position Controller Layout
      final double joyX = settings?.joystickPosX ?? GameSettings.mlbbJoystickX;
      final double joyY = settings?.joystickPosY ?? GameSettings.mlbbJoystickY;
      final double smashX = settings?.smashPosX ?? GameSettings.mlbbSmashX;
      final double smashY = settings?.smashPosY ?? GameSettings.mlbbSmashY;
      final double leftSpinX = settings?.leftSpinPosX ?? GameSettings.mlbbLeftSpinX;
      final double leftSpinY = settings?.leftSpinPosY ?? GameSettings.mlbbLeftSpinY;
      final double rightSpinX = settings?.rightSpinPosX ?? GameSettings.mlbbRightSpinX;
      final double rightSpinY = settings?.rightSpinPosY ?? GameSettings.mlbbRightSpinY;
      final double dashX = settings?.dashPosX ?? GameSettings.mlbbDashX;
      final double dashY = settings?.dashPosY ?? GameSettings.mlbbDashY;

      joystickMargin = calculateNormalizedMargin(joyX, joyY, bgRadius * 2, bgRadius * 2);
      buttonMargin = calculateNormalizedMargin(smashX, smashY, buttonRadius * 2, buttonRadius * 2);
      leftSpinMargin = calculateNormalizedMargin(leftSpinX, leftSpinY, skillRadius * 2 + 8, skillRadius * 2 + 12);
      rightSpinMargin = calculateNormalizedMargin(rightSpinX, rightSpinY, skillRadius * 2 + 8, skillRadius * 2 + 12);
      dashMargin = calculateNormalizedMargin(dashX, dashY, skillRadius * 2 + 8, skillRadius * 2 + 12);
    }

    // 1. JOYSTICK COMPONENT MANAGEMENT
    final existingJoysticks = camera.viewport.children.whereType<JoystickComponent>().toList();
    if (!showJoystick) {
      for (final joy in existingJoysticks) {
        joy.removeFromParent();
      }
    } else {
      if (existingJoysticks.isNotEmpty) {
        joystick = existingJoysticks.first;
        final knobComp = joystick.knob as CircleComponent;
        knobComp.radius = knobRadius;
        knobComp.paint = knobPaint;

        final bgComp = joystick.background as CircleComponent;
        bgComp.radius = bgRadius;
        bgComp.paint = bgPaint;

        joystick.margin = joystickMargin;

        for (int i = 1; i < existingJoysticks.length; i++) {
          existingJoysticks[i].removeFromParent();
        }
      } else {
        joystick = JoystickComponent(
          knob: CircleComponent(radius: knobRadius, paint: knobPaint),
          background: CircleComponent(radius: bgRadius, paint: bgPaint),
          margin: joystickMargin,
        );
        camera.viewport.add(joystick);
      }
    }

    // 2. SMASH / STRIKE BUTTON MANAGEMENT
    final existingButtons = camera.viewport.children.whereType<HudButtonComponent>().toList();
    if (!showSkillButtons) {
      for (final btn in existingButtons) {
        btn.removeFromParent();
      }
    } else {
      if (existingButtons.isNotEmpty) {
        strikeButton = existingButtons.first;
        if (strikeButton.button is ArcadeButtonFaceComponent) {
          final btnFace = strikeButton.button as ArcadeButtonFaceComponent;
          btnFace.updateProperties(
            radius: buttonRadius,
            opacity: opacity,
            paddleSprite: paddleSprite,
          );
        }
        if (strikeButton.buttonDown is ArcadeButtonFaceComponent) {
          final btnDownFace = strikeButton.buttonDown as ArcadeButtonFaceComponent;
          btnDownFace.updateProperties(
            radius: buttonRadius,
            opacity: opacity,
            paddleSprite: paddleSprite,
          );
        }

        strikeButton.margin = buttonMargin;

        for (int i = 1; i < existingButtons.length; i++) {
          existingButtons[i].removeFromParent();
        }
      } else {
        strikeButton = HudButtonComponent(
          button: ArcadeButtonFaceComponent(
            radius: buttonRadius,
            opacity: opacity,
            isPressed: false,
            paddleSprite: paddleSprite,
            game: this,
          ),
          buttonDown: ArcadeButtonFaceComponent(
            radius: buttonRadius,
            opacity: opacity,
            isPressed: true,
            paddleSprite: paddleSprite,
            game: this,
          ),
          margin: buttonMargin,
          onPressed: () {
            triggerSmashButtonEffect();
            player1.strike();
          },
        );
        camera.viewport.add(strikeButton);
      }
    }

    // 3. SKILL BUTTONS (Left Spin, Right Spin, Dash)

    final existingLeftSpin = camera.viewport.children
        .whereType<ArcadeSkillButtonComponent>()
        .where((b) => b.technique == BattleTechnique.leftSpin)
        .toList();
    final existingRightSpin = camera.viewport.children
        .whereType<ArcadeSkillButtonComponent>()
        .where((b) => b.technique == BattleTechnique.rightSpin)
        .toList();
    final existingDash = camera.viewport.children
        .whereType<ArcadeSkillButtonComponent>()
        .where((b) => b.technique == BattleTechnique.dash)
        .toList();

    if (!showSkillButtons) {
      for (final btn in existingLeftSpin) {
        btn.removeFromParent();
      }
      for (final btn in existingRightSpin) {
        btn.removeFromParent();
      }
      for (final btn in existingDash) {
        btn.removeFromParent();
      }
      leftSpinButton = null;
      rightSpinButton = null;
      dashButton = null;
    } else {
      if (existingLeftSpin.isNotEmpty) {
        leftSpinButton = existingLeftSpin.first;
        leftSpinButton!.updateProperties(
          radius: skillRadius,
          opacity: opacity,
          margin: leftSpinMargin,
        );
        for (int i = 1; i < existingLeftSpin.length; i++) {
          existingLeftSpin[i].removeFromParent();
        }
      } else {
        leftSpinButton = ArcadeSkillButtonComponent(
          technique: BattleTechnique.leftSpin,
          radius: skillRadius,
          opacity: opacity,
          game: this,
          margin: leftSpinMargin,
          onTriggered: triggerLeftSpin,
        );
        camera.viewport.add(leftSpinButton!);
      }

      if (existingRightSpin.isNotEmpty) {
        rightSpinButton = existingRightSpin.first;
        rightSpinButton!.updateProperties(
          radius: skillRadius,
          opacity: opacity,
          margin: rightSpinMargin,
        );
        for (int i = 1; i < existingRightSpin.length; i++) {
          existingRightSpin[i].removeFromParent();
        }
      } else {
        rightSpinButton = ArcadeSkillButtonComponent(
          technique: BattleTechnique.rightSpin,
          radius: skillRadius,
          opacity: opacity,
          game: this,
          margin: rightSpinMargin,
          onTriggered: triggerRightSpin,
        );
        camera.viewport.add(rightSpinButton!);
      }

      if (existingDash.isNotEmpty) {
        dashButton = existingDash.first;
        dashButton!.updateProperties(
          radius: skillRadius,
          opacity: opacity,
          margin: dashMargin,
        );
        for (int i = 1; i < existingDash.length; i++) {
          existingDash[i].removeFromParent();
        }
      } else {
        dashButton = ArcadeSkillButtonComponent(
          technique: BattleTechnique.dash,
          radius: skillRadius,
          opacity: opacity,
          game: this,
          margin: dashMargin,
          onTriggered: triggerDash,
        );
        camera.viewport.add(dashButton!);
      }
    }
  }

  /// Triggers the dynamic tap shockwave & sparks effect on the HUD smash button
  void triggerSmashButtonEffect() {
    final existingButtons = camera.viewport.children.whereType<HudButtonComponent>().toList();
    if (existingButtons.isNotEmpty) {
      final btn = existingButtons.first;
      if (btn.button is ArcadeButtonFaceComponent) {
        (btn.button as ArcadeButtonFaceComponent).triggerTapEffect();
      }
      if (btn.buttonDown is ArcadeButtonFaceComponent) {
        (btn.buttonDown as ArcadeButtonFaceComponent).triggerTapEffect();
      }
    }
  }

  /// Triggers the Left Spin (Cyclone Curve) battle technique (Hotkey K)
  void triggerLeftSpin() {
    if (leftSpinButton != null && leftSpinButton!.cooldownRemaining > 0) return;
    leftSpinButton?.triggerTapEffect();
    player1.queueTechnique(BattleTechnique.leftSpin);
    leftSpinButton?.isPrimed = true;
    rightSpinButton?.isPrimed = false;
    AudioService.instance.playPaddleHit();
    if ((ball.position.y - player1.position.y).abs() < 120 && ball.velocity.y > 0) {
      player1.strike();
    }
  }

  /// Triggers the Right Spin (Vortex Hook) battle technique (Hotkey L)
  void triggerRightSpin() {
    if (rightSpinButton != null && rightSpinButton!.cooldownRemaining > 0) return;
    rightSpinButton?.triggerTapEffect();
    player1.queueTechnique(BattleTechnique.rightSpin);
    rightSpinButton?.isPrimed = true;
    leftSpinButton?.isPrimed = false;
    AudioService.instance.playPaddleHit();
    if ((ball.position.y - player1.position.y).abs() < 120 && ball.velocity.y > 0) {
      player1.strike();
    }
  }

  /// Triggers the Flash Dash skill technique (Hotkey Shift / I / Dash Button)
  void triggerDash() {
    if (dashButton != null && dashButton!.cooldownRemaining > 0) return;
    final didDash = player1.dash();
    if (didDash) {
      dashButton?.triggerTapEffect();
      dashButton?.startCooldown();
    }
  }

  // Backward compatibility trigger methods
  void triggerThunderDrive() => triggerLeftSpin();
  void triggerPhantomDink() => triggerRightSpin();

  /// Called when a battle technique is successfully struck and launched into the rally
  void onTechniqueExecuted(BattleTechnique technique) {
    if (technique == BattleTechnique.leftSpin) {
      leftSpinButton?.startCooldown();
      leftSpinButton?.isPrimed = false;
      AudioService.instance.playLeftSpin();
      if (settings?.screenShakeEnabled ?? true) {
        camera.viewfinder.position = Vector2(640, 364);
        Future.delayed(const Duration(milliseconds: 60), () {
          camera.viewfinder.position = Vector2(640, 356);
        });
        Future.delayed(const Duration(milliseconds: 120), () {
          camera.viewfinder.position = Vector2(640, 360);
        });
      }
    } else if (technique == BattleTechnique.rightSpin) {
      rightSpinButton?.startCooldown();
      rightSpinButton?.isPrimed = false;
      AudioService.instance.playRightSpin();
      if (settings?.screenShakeEnabled ?? true) {
        camera.viewfinder.position = Vector2(640, 364);
        Future.delayed(const Duration(milliseconds: 60), () {
          camera.viewfinder.position = Vector2(640, 356);
        });
        Future.delayed(const Duration(milliseconds: 120), () {
          camera.viewfinder.position = Vector2(640, 360);
        });
      }
    } else if (technique == BattleTechnique.dash) {
      dashButton?.startCooldown();
      dashButton?.isPrimed = false;
      AudioService.instance.playDash();
    }
  }

  void _updateFpsOverlay() {
    if (settings?.showFps ?? false) {
      if (fpsText == null) {
        fpsText = FpsTextComponent(
          position: Vector2(20, 20),
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFF76FF03),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        camera.viewport.add(fpsText!);
      }
    } else {
      if (fpsText != null) {
        fpsText!.removeFromParent();
        fpsText = null;
      }
    }
  }

  /// Live updates settings during active gameplay
  void applySettings(GameSettings newSettings) {
    settings = newSettings;

    // 1. Update background court theme
    background.updateTheme(newSettings.courtTheme);

    // 2. Refresh HUD Controls in-place (never removes/duplicates or stacks)
    _setupControls();

    // 3. Connect joystick reference to player
    player1.updateJoystick(joystick);

    // 4. Update FPS overlay
    _updateFpsOverlay();
  }
}
