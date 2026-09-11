import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/text.dart';
import 'pickleball_game.dart';

class MainMenu extends Component with HasGameReference<PickleballGame> {
  @override
  Future<void> onLoad() async {
    super.onLoad();

    final title = TextComponent(
      text: 'Pickleball Smash',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontFamily: 'Courier', // Placeholder for pixel font
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final startButton = StartButton()
      ..anchor = Anchor.center;

    title.anchor = Anchor.center;

    // Use onGameResize to position them properly if size changes, 
    // but we can set initial positions here as well.
    title.position = Vector2(game.size.x / 2, game.size.y / 2 - 50);
    startButton.position = Vector2(game.size.x / 2, game.size.y / 2 + 50);

    add(title);
    add(startButton);
  }
}

class StartButton extends PositionComponent with TapCallbacks, HasGameReference<PickleballGame> {
  late final TextComponent buttonText;

  StartButton() {
    size = Vector2(200, 60);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    buttonText = TextComponent(
      text: 'Start Game',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold,
        ),
      ),
    )..anchor = Anchor.center
     ..position = size / 2;

    add(buttonText);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(size.toRect(), paint);
    
    final borderPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRect(size.toRect(), borderPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.router.pushReplacementNamed('gameplay');
  }
}
