import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'main_menu.dart';
import 'court_level.dart';
import 'pause_menu.dart';

class PickleballGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  late final RouterComponent router;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    router = RouterComponent(
      initialRoute: 'menu',
      routes: {
        'menu': Route(() => MainMenu()),
        'gameplay': Route(() => CourtLevel()),
        'pause': Route(() => PauseMenu()),
      },
    );
    add(router);
  }
}
