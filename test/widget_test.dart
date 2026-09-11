import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:pickleball_smash/pickleball_game.dart';

void main() {
  testWidgets('GameWidget loads PickleballGame', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      GameWidget(
        game: PickleballGame(),
      ),
    );

    // Basic test to see if GameWidget renders
    expect(find.byType(GameWidget<PickleballGame>), findsOneWidget);
  });
}
