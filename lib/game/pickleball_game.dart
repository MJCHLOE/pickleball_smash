import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/painting.dart';
import '../models/game_settings.dart';
import '../services/audio_service.dart';
import 'components/background.dart';
import 'components/player.dart';
import 'components/ball.dart';

class PickleballGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  final void Function(int p1Score, int p2Score)? onScoreUpdated;
  final void Function(bool playerWon)? onMatchFinished;
  final VoidCallback? onSmash;
  final void Function(String title, String subtitle)? onAnnouncement;
  final void Function(bool isWaiting, int serverPlayer, String servingSide)? onServeStateChanged;
  final bool joystickOnLeft;
  final int targetScore;
  GameSettings? settings;

  int p1Score = 0;
  int p2Score = 0;
  bool isGameOver = false;

  // Official Pickleball rules state
  int serverPlayer = 1; // 1 = Player 1, 2 = Player 2 (CPU)
  int rallyHitCount = 0; // 0 = serve, 1 = return, 2+ = open play
  bool isWaitingForServe = true;

  PickleballGame({
    this.onScoreUpdated,
    this.onMatchFinished,
    this.onSmash,
    this.onAnnouncement,
    this.onServeStateChanged,
    this.joystickOnLeft = true,
    this.targetScore = 5,
    this.settings,
  }) : super(
          camera: CameraComponent.withFixedResolution(
            width: 1280,
            height: 720,
          ),
        );

  late Background background;
  late PlayerComponent player1;
  late PlayerComponent player2;
  late JoystickComponent joystick;
  late HudButtonComponent strikeButton;
  late BallComponent ball;
  FpsTextComponent? fpsText;

  String get servingSide {
    final serverScore = (serverPlayer == 1) ? p1Score : p2Score;
    return (serverScore % 2 == 0) ? 'right' : 'left';
  }

  void onPlayerSmash() {
    AudioService.instance.playSmash();

    // Camera shake effect on smash if enabled
    if (settings?.screenShakeEnabled ?? true) {
      camera.viewfinder.position = Vector2(0, 4);
      Future.delayed(const Duration(milliseconds: 50), () {
        camera.viewfinder.position = Vector2(0, -4);
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        camera.viewfinder.position = Vector2.zero();
      });
    }

    onSmash?.call();
  }

  /// Official Pickleball Side-Out Scoring & Fault Resolution
  void handleRallyWon({required bool winnerIsPlayerOne, required String faultReason}) {
    if (isGameOver) return;

    final bool serverWon = (winnerIsPlayerOne == (serverPlayer == 1));

    if (serverWon) {
      // 1. Points can ONLY be scored by the serving team
      if (serverPlayer == 1) {
        p1Score++;
      } else {
        p2Score++;
      }

      AudioService.instance.playPointScored();
      onScoreUpdated?.call(p1Score, p2Score);

      // 2. Win by 2 margin check
      final int serverScore = serverPlayer == 1 ? p1Score : p2Score;
      final int receiverScore = serverPlayer == 1 ? p2Score : p1Score;

      if (serverScore >= targetScore && (serverScore - receiverScore) >= 2) {
        isGameOver = true;
        pauseEngine();
        onAnnouncement?.call(
          winnerIsPlayerOne ? 'VICTORY!' : 'MATCH DEFEAT',
          'Final Score: $p1Score - $p2Score',
        );
        onMatchFinished?.call(winnerIsPlayerOne);
        return;
      }

      onAnnouncement?.call(
        'POINT! ($p1Score - $p2Score)',
        faultReason.isNotEmpty ? faultReason : 'Rally won by server',
      );

      // Server serves again (from opposite court because score changed)
      prepareServicePositions();
    } else {
      // 3. Side-Out! Receiving team wins rally; no point awarded. Serve transfers.
      serverPlayer = (serverPlayer == 1) ? 2 : 1;

      AudioService.instance.playPaddleHit();
      onAnnouncement?.call(
        'SIDE OUT!',
        faultReason.isNotEmpty
            ? '$faultReason • Serve changes!'
            : 'Serve changes to ${serverPlayer == 1 ? 'Player 1' : 'CPU'}',
      );

      prepareServicePositions();
    }
  }

  /// Legacy helper for point scoring
  void onPointScored({required bool isPlayerOne}) {
    handleRallyWon(winnerIsPlayerOne: isPlayerOne, faultReason: '');
  }

  /// Sets up court positions for server and receiver per official singles rotation
  void prepareServicePositions() {
    isWaitingForServe = true;
    rallyHitCount = 0;

    // Baseline service positioning according to singles rotation
    if (serverPlayer == 1) {
      // Player 1 serves:
      // Even score -> Right court (viewer right X≈760, behind baseline Y≈650)
      // Odd score  -> Left court  (viewer left  X≈520, behind baseline Y≈650)
      if (servingSide == 'right') {
        player1.position = Vector2(760, 650);
        player2.position = Vector2(520, 140); // Receiver diagonal (viewer top-left)
      } else {
        player1.position = Vector2(520, 650);
        player2.position = Vector2(760, 140); // Receiver diagonal (viewer top-right)
      }
    } else {
      // Player 2 (CPU) serves:
      // Even score -> Right court from P2 perspective (viewer top-left X≈520, Y≈70)
      // Odd score  -> Left court from P2 perspective  (viewer top-right X≈760, Y≈70)
      if (servingSide == 'right') {
        player2.position = Vector2(520, 70);
        player1.position = Vector2(760, 580); // Receiver diagonal (viewer bottom-right)
      } else {
        player2.position = Vector2(760, 70);
        player1.position = Vector2(520, 580); // Receiver diagonal (viewer bottom-left)
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
      serverPlayer == 1 ? 'Score: $callout • Tap Strike to Serve' : 'Score: $callout • Get Ready!',
    );
    onServeStateChanged?.call(true, serverPlayer, servingSide);
  }

  @override
  Future<void> onLoad() async {
    // Set the anchor to topLeft so (0,0) is the top-left corner of the screen
    camera.viewfinder.anchor = Anchor.topLeft;

    background = Background();
    world.add(background);

    _setupControls();

    // Player 1 (bottom) - uses front slash
    player1 = PlayerComponent(isPlayerOne: true, joystick: joystick);
    world.add(player1);

    // Player 2 (top) - uses behind slash
    player2 = PlayerComponent(isPlayerOne: false, joystick: null);
    world.add(player2);

    // The Ball!
    ball = BallComponent();
    ball.customGame = this;
    world.add(ball);

    prepareServicePositions();

    _updateFpsOverlay();
  }

  void _setupControls() {
    final effectiveJoystickOnLeft = settings?.joystickOnLeft ?? joystickOnLeft;
    final opacity = (settings?.controllerOpacity ?? 0.85).clamp(0.2, 1.0);
    final knobAlpha = (220 * opacity).round();
    final bgAlpha = (110 * opacity).round();
    final buttonAlpha = (220 * opacity).round();
    final buttonDownAlpha = (255 * opacity).round();

    double buttonRadius = 40.0;
    if (settings?.buttonSize == 'Large') {
      buttonRadius = 48.0;
    } else if (settings?.buttonSize == 'Extra Large') {
      buttonRadius = 56.0;
    }

    // Setup HUD Controls based on joystickOnLeft setting
    final knobPaint = BasicPalette.blue.withAlpha(knobAlpha).paint();
    final bgPaint = BasicPalette.blue.withAlpha(bgAlpha).paint();
    
    final joystickMargin = effectiveJoystickOnLeft
        ? const EdgeInsets.only(left: 40, bottom: 40)
        : const EdgeInsets.only(right: 40, bottom: 40);

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: knobPaint),
      background: CircleComponent(radius: 80, paint: bgPaint),
      margin: joystickMargin,
    );
    camera.viewport.add(joystick);

    final buttonPaint = BasicPalette.red.withAlpha(buttonAlpha).paint();
    final buttonDownPaint = BasicPalette.red.withAlpha(buttonDownAlpha).paint();
    
    final buttonMargin = effectiveJoystickOnLeft
        ? const EdgeInsets.only(right: 40, bottom: 40)
        : const EdgeInsets.only(left: 40, bottom: 40);

    strikeButton = HudButtonComponent(
      button: CircleComponent(radius: buttonRadius, paint: buttonPaint),
      buttonDown: CircleComponent(radius: buttonRadius, paint: buttonDownPaint),
      margin: buttonMargin,
      onPressed: () {
        player1.strike();
      },
    );
    camera.viewport.add(strikeButton);
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

    // 2. Refresh HUD Controls
    if (camera.viewport.contains(joystick)) {
      joystick.removeFromParent();
    }
    if (camera.viewport.contains(strikeButton)) {
      strikeButton.removeFromParent();
    }
    _setupControls();

    // 3. Connect new joystick reference to player
    player1.updateJoystick(joystick);

    // 4. Update FPS overlay
    _updateFpsOverlay();
  }
}
