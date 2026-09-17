import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'game/pickleball_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure for a landscape screen environment
  await Flame.device.fullScreen();
  await Flame.device.setLandscape(); // Game is 1280x720 landscape

  final game = PickleballGame();
  
  runApp(
    GameWidget(
      game: game,
    ),
  );
}
