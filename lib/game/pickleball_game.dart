import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../models/game_settings.dart';
import '../services/audio_service.dart';
import 'components/background.dart';
import 'components/player.dart';
import 'components/ball.dart';
import 'components/arcade_button_component.dart';

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
  }) : super(
          camera: CameraComponent(),
        );

  Background? _background;
  Background get background => _background ??= Background();
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

    final bool serverWon = isDoubles
        ? (winnerIsPlayerOne == (serverTeam == 1))
        : (winnerIsPlayerOne == (serverPlayer == 1));

    if (serverWon) {
      // 1. Points can ONLY be scored by the serving team
      if (isDoubles) {
        if (serverTeam == 1) {
          p1Score++;
        } else {
          p2Score++;
        }
      } else {
        if (serverPlayer == 1) {
          p1Score++;
        } else {
          p2Score++;
        }
      }

      AudioService.instance.playPointScored();
      onScoreUpdated?.call(p1Score, p2Score);

      // 2. Win by 2 margin check
      final int servingScore = isDoubles
          ? (serverTeam == 1 ? p1Score : p2Score)
          : (serverPlayer == 1 ? p1Score : p2Score);
      final int receiverScore = isDoubles
          ? (serverTeam == 1 ? p2Score : p1Score)
          : (serverPlayer == 1 ? p2Score : p1Score);

      if (servingScore >= targetScore && (servingScore - receiverScore) >= 2) {
        isGameOver = true;
        pauseEngine();
        onAnnouncement?.call(
          winnerIsPlayerOne ? 'VICTORY!' : 'MATCH DEFEAT',
          'Final Score: $p1Score - $p2Score',
        );
        onMatchFinished?.call(winnerIsPlayerOne);
        return;
      }

      // 3. Rule 5: In Doubles, the serving team switches sides when they win a rally!
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

      onAnnouncement?.call(
        'POINT! ($callout)',
        faultReason.isNotEmpty ? faultReason : 'Rally won by serving team',
      );

      // Same server serves again from the switched side
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
    onScoreUpdated?.call(0, 0);
    onRallyStreakUpdated?.call(0, longestRally);
    prepareServicePositions();
  }

  /// Legacy helper for point scoring
  void onPointScored({required bool isPlayerOne}) {
    handleRallyWon(winnerIsPlayerOne: isPlayerOne, faultReason: '');
  }

  void _dispatchViolation(String faultReason) {
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

    background = Background();
    world.add(background);

    _setupControls();

    final effectiveP1IsFemale = player1IsFemale ?? false;

    // Player 1 (Team 1, Bottom, Human User)
    player1 = PlayerComponent(
      isPlayerOne: true,
      isFemale: effectiveP1IsFemale,
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
        isFemale: !effectiveP1IsFemale,
        isAI: true,
        playerSlot: 2,
        joystick: null,
      );
      player1Partner!.customGame = this;
      world.add(player1Partner!);
    }

    // Player 2 (Team 2, Top, CPU 1)
    player2 = PlayerComponent(
      isPlayerOne: false,
      isFemale: !effectiveP1IsFemale,
      isAI: true,
      playerSlot: 1,
      joystick: null,
    );
    player2.customGame = this;
    world.add(player2);

    // Player 2 Partner (Team 2, Top, CPU 2) in Doubles
    if (isDoubles) {
      player2Partner = PlayerComponent(
        isPlayerOne: false,
        isFemale: effectiveP1IsFemale,
        isAI: true,
        playerSlot: 2,
        joystick: null,
      );
      player2Partner!.customGame = this;
      world.add(player2Partner!);
    }

    // The Ball!
    ball = BallComponent();
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
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsedTime += dt;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateCameraViewport();
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

    double buttonRadius = 40.0;
    if (settings?.buttonSize == 'Large') {
      buttonRadius = 48.0;
    } else if (settings?.buttonSize == 'Extra Large') {
      buttonRadius = 56.0;
    }

    final knobRadius = 26.0 * expand;
    final bgRadius = 68.0 * expand;

    // Setup HUD Controls based on joystickOnLeft setting
    final knobPaint = Paint()..color = baseColor.withAlpha(knobAlpha);
    final bgPaint = Paint()..color = baseColor.withAlpha(bgAlpha);
    
    final joystickMargin = effectiveJoystickOnLeft
        ? const EdgeInsets.only(left: 36, bottom: 36)
        : const EdgeInsets.only(right: 36, bottom: 36);

    // 1. IN-PLACE UPDATE FOR JOYSTICK (prevents doubling / duplicate components)
    final existingJoysticks = camera.viewport.children.whereType<JoystickComponent>().toList();
    if (existingJoysticks.isNotEmpty) {
      joystick = existingJoysticks.first;
      final knobComp = joystick.knob as CircleComponent;
      knobComp.radius = knobRadius;
      knobComp.paint = knobPaint;

      final bgComp = joystick.background as CircleComponent;
      bgComp.radius = bgRadius;
      bgComp.paint = bgPaint;

      joystick.margin = joystickMargin;

      // Clean up any extraneous duplicate joysticks if present
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

    final buttonMargin = effectiveJoystickOnLeft
        ? const EdgeInsets.only(right: 36, bottom: 36)
        : const EdgeInsets.only(left: 36, bottom: 36);

    // 2. IN-PLACE UPDATE FOR 2D ARCADE SMASH BUTTON (prevents doubling / duplicate components)
    final existingButtons = camera.viewport.children.whereType<HudButtonComponent>().toList();
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

      // Clean up any extraneous duplicate buttons if present
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
