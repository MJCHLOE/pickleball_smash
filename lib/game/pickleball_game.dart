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
  final bool joystickOnLeft;
  final int targetScore;
  GameSettings? settings;

  int p1Score = 0;
  int p2Score = 0;
  bool isGameOver = false;

  PickleballGame({
    this.onScoreUpdated,
    this.onMatchFinished,
    this.onSmash,
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

  void onPointScored({required bool isPlayerOne}) {
    if (isGameOver) return;
    if (isPlayerOne) {
      p1Score++;
    } else {
      p2Score++;
    }
    AudioService.instance.playPointScored();
    onScoreUpdated?.call(p1Score, p2Score);

    if (p1Score >= targetScore || p2Score >= targetScore) {
      isGameOver = true;
      pauseEngine();
      onMatchFinished?.call(p1Score >= targetScore);
    }
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
    player1.position = Vector2(1280 / 2, 720 * 0.75); // Bottom half
    world.add(player1);

    // Player 2 (top) - uses behind slash
    player2 = PlayerComponent(isPlayerOne: false, joystick: null);
    player2.position = Vector2(1280 / 2, 720 * 0.25); // Top half
    world.add(player2);

    // The Ball!
    ball = BallComponent();
    world.add(ball);

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
