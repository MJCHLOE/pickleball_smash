import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/painting.dart';
import 'components/background.dart';
import 'components/player.dart';
import 'components/ball.dart';

class PickleballGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  PickleballGame()
      : super(
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

  @override
  Future<void> onLoad() async {
    // Set the anchor to topLeft so (0,0) is the top-left corner of the screen
    camera.viewfinder.anchor = Anchor.topLeft;

    background = Background();
    world.add(background);

    // Setup HUD Controls
    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final bgPaint = BasicPalette.blue.withAlpha(100).paint();
    
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: knobPaint),
      background: CircleComponent(radius: 80, paint: bgPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    camera.viewport.add(joystick);

    final buttonPaint = BasicPalette.red.withAlpha(200).paint();
    final buttonDownPaint = BasicPalette.red.withAlpha(255).paint();
    
    final strikeButton = HudButtonComponent(
      button: CircleComponent(radius: 40, paint: buttonPaint),
      buttonDown: CircleComponent(radius: 40, paint: buttonDownPaint),
      margin: const EdgeInsets.only(right: 40, bottom: 40),
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


