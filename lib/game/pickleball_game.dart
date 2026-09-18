import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/painting.dart';
import 'components/background.dart';
import 'components/player.dart';
import 'components/ball.dart';

class PickleballGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  final void Function(int p1Score, int p2Score)? onScoreUpdated;
  final void Function(bool playerWon)? onMatchFinished;
  final VoidCallback? onSmash;
  final bool joystickOnLeft;
  final int targetScore;

  int p1Score = 0;
  int p2Score = 0;
  bool isGameOver = false;

  PickleballGame({
    this.onScoreUpdated,
    this.onMatchFinished,
    this.onSmash,
    this.joystickOnLeft = true,
    this.targetScore = 5,
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
  late BallComponent ball;

  void onPlayerSmash() {
    onSmash?.call();
  }

  void onPointScored({required bool isPlayerOne}) {
    if (isGameOver) return;
    if (isPlayerOne) {
      p1Score++;
    } else {
      p2Score++;
    }
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

    // Setup HUD Controls based on joystickOnLeft setting
    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final bgPaint = BasicPalette.blue.withAlpha(100).paint();
    
    final joystickMargin = joystickOnLeft
        ? const EdgeInsets.only(left: 40, bottom: 40)
        : const EdgeInsets.only(right: 40, bottom: 40);

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: knobPaint),
      background: CircleComponent(radius: 80, paint: bgPaint),
      margin: joystickMargin,
    );
    camera.viewport.add(joystick);

    final buttonPaint = BasicPalette.red.withAlpha(200).paint();
    final buttonDownPaint = BasicPalette.red.withAlpha(255).paint();
    
    final buttonMargin = joystickOnLeft
        ? const EdgeInsets.only(right: 40, bottom: 40)
        : const EdgeInsets.only(left: 40, bottom: 40);

    final strikeButton = HudButtonComponent(
      button: CircleComponent(radius: 40, paint: buttonPaint),
      buttonDown: CircleComponent(radius: 40, paint: buttonDownPaint),
      margin: buttonMargin,
      onPressed: () {
        player1.strike();
      },
    );
    camera.viewport.add(strikeButton);

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
  }
}


