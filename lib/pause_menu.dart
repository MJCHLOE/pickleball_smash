import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/text.dart';
import 'pickleball_game.dart';

class PauseMenu extends Component with HasGameReference<PickleballGame> {
  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Background overlay (semi-transparent black)
    final overlay = RectangleComponent(
      size: game.size,
      paint: Paint()..color = Colors.black.withValues(alpha: 0.7),
    );
    add(overlay);

    final title = TextComponent(
      text: 'PAUSED',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold,
        ),
      ),
    )..anchor = Anchor.center
     ..position = Vector2(game.size.x / 2, game.size.y / 2 - 80);

    final continueBtn = MenuButton('Continue', () {
      game.router.pop();
    })
      ..anchor = Anchor.center
      ..position = Vector2(game.size.x / 2, game.size.y / 2 + 20);

    final exitBtn = MenuButton('Exit Match', () {
      // Pop the pause menu
      game.router.pop();
      // Replace gameplay with main menu
      game.router.pushReplacementNamed('menu');
    })
      ..anchor = Anchor.center
      ..position = Vector2(game.size.x / 2, game.size.y / 2 + 100);

    add(title);
    add(continueBtn);
    add(exitBtn);
  }
}

class MenuButton extends PositionComponent with TapCallbacks {
  final String text;
  final VoidCallback onPressed;
  
  late final TextComponent buttonText;

  MenuButton(this.text, this.onPressed) {
    size = Vector2(240, 60);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    buttonText = TextComponent(
      text: text,
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
    onPressed();
  }
}
