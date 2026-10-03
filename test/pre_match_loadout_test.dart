import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_smash/services/game_state_manager.dart';
import 'package:pickleball_smash/widgets/pre_match_loadout_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PreMatchLoadoutModal renders cleanly and cycles through Character -> Ball -> Court', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PreMatchLoadoutModal(isHost: true),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Step 1: Character selection
    expect(find.text('PRE-MATCH LOADOUT'), findsOneWidget);
    expect(find.text('STEP 1: CHOOSE YOUR FIGHTER'), findsOneWidget);
    expect(find.text('NEXT: BALL ➔'), findsOneWidget);
    expect(find.text('ALEX SMASH'), findsOneWidget);

    // Tap NEXT to advance to Step 2
    await tester.tap(find.text('NEXT: BALL ➔'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // 2. Step 2: Ball selection
    expect(find.text('STEP 2: CHOOSE YOUR BALL'), findsOneWidget);
    expect(find.text('NEXT: COURT ➔'), findsOneWidget);

    // Tap NEXT to advance to Step 3
    await tester.tap(find.text('NEXT: COURT ➔'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // 3. Step 3: Court selection
    expect(find.text('STEP 3: CHOOSE YOUR COURT'), findsOneWidget);
    expect(find.text('LOCK IN LOADOUT ⚡'), findsOneWidget);

    // Tap lock in loadout
    await tester.tap(find.text('LOCK IN LOADOUT ⚡'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Verify GameStateManager has valid active loadout
    final state = GameStateManager.instance;
    expect(state.playerAvatarId.isNotEmpty, isTrue);
    expect(state.equippedBallId.isNotEmpty, isTrue);
    expect(state.equippedCourtId.isNotEmpty, isTrue);
  });
}
