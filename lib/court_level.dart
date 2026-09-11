import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'player_sprites.dart';
import 'pickleball_game.dart';
import 'ball.dart';

class CourtLevel extends Component with HasGameReference<PickleballGame> {
  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Draw the green court background
    add(CourtBackground());
    
    // Add Joystick for mobile
    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.blue.withAlpha(100).paint();
    
    final joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    
    // Add ball
    final ball = Ball();
    
    // Add players
    final malePlayer = MalePlayer()
      ..position = Vector2(150, game.size.y / 2)
      ..joystick = joystick;
      
    final femalePlayer = FemalePlayer()
      ..position = Vector2(game.size.x - 150, game.size.y / 2)
      ..ball = ball;
    
    // Add Pause button
    final pauseBtn = PauseButton()
      ..position = Vector2(20, 20);

    add(ball);
    add(malePlayer);
    add(femalePlayer);
    add(joystick);
    add(pauseBtn);
  }
}

class PauseButton extends PositionComponent with TapCallbacks, HasGameReference<PickleballGame> {
  PauseButton() {
    size = Vector2(50, 50);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.white;
    // Draw pause icon (two vertical bars)
    canvas.drawRect(Rect.fromLTWH(10, 10, 10, 30), paint);
    canvas.drawRect(Rect.fromLTWH(30, 10, 10, 30), paint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.router.pushNamed('pause');
  }
}

class CourtBackground extends PositionComponent with HasGameReference<PickleballGame> {
  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = game.size;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Outer court background (darker green)
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFF2E7D32));

    // Inner court (standard green)
    final paintGreen = Paint()..color = const Color(0xFF4CAF50);
    final courtRect = Rect.fromCenter(
      center: size.toOffset() / 2, 
      width: size.x * 0.8, 
      height: size.y * 0.8
    );
    canvas.drawRect(courtRect, paintGreen);

    // Draw white boundary lines
    final paintWhite = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(courtRect, paintWhite);
    
    // Draw the center line
    canvas.drawLine(
      Offset(size.x / 2, courtRect.top), 
      Offset(size.x / 2, courtRect.bottom), 
      paintWhite
    );
    
    // Kitchens
    final kitchenWidth = (courtRect.width / 2) * 0.3;
    final leftKitchenLine = size.x / 2 - kitchenWidth;
    final rightKitchenLine = size.x / 2 + kitchenWidth;
    
    canvas.drawLine(Offset(leftKitchenLine, courtRect.top), Offset(leftKitchenLine, courtRect.bottom), paintWhite);
    canvas.drawLine(Offset(rightKitchenLine, courtRect.top), Offset(rightKitchenLine, courtRect.bottom), paintWhite);
    
    // Centerline for service courts
    canvas.drawLine(Offset(courtRect.left, size.y / 2), Offset(leftKitchenLine, size.y / 2), paintWhite);
    canvas.drawLine(Offset(rightKitchenLine, size.y / 2), Offset(courtRect.right, size.y / 2), paintWhite);

    // Net
    final paintNet = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 10.0;
    canvas.drawLine(Offset(size.x / 2, courtRect.top - 20), Offset(size.x / 2, courtRect.bottom + 20), paintNet);
  }
}
