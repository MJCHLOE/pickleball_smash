import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_smash/game/components/ball.dart';
import 'package:pickleball_smash/game/components/player.dart';
import 'package:pickleball_smash/game/pickleball_game.dart';
import 'package:pickleball_smash/models/game_settings.dart';
import 'package:pickleball_smash/widgets/hud_controls_adjuster_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Scoring System & Double Bounce Rule Tests', () {
    test('Double Bounce Fault: Ball bouncing twice on player court awards score to opponent', () {
      final game = PickleballGame(courtId: 'court_classic');
      game.player1 = PlayerComponent(isPlayerOne: true);
      game.player2 = PlayerComponent(isPlayerOne: false);
      game.ball = BallComponent()..customGame = game;
      game.prepareServicePositions();

      // Enemy serves to Player 1
      game.serverPlayer = 2;
      game.isWaitingForServe = false;
      expect(game.p2Score, 0);

      // Ball arrives on Player 1's side (y >= netY ~360)
      game.ball.position = Vector2(640, 520);
      game.ball.z = 0;
      game.ball.bounceCountCurrentSide = 1; // First bounce completed

      // Second bounce on Player 1's side without strike -> DOUBLE BOUNCE FAULT!
      // Calls _triggerFloorBounce with bounceCountCurrentSide becoming 2
      game.ball.z = 0;
      game.ball.zVelocity = -50; // falling to floor
      game.ball.update(0.016);

      // Score must be awarded to enemy (Player 2)
      expect(game.p2Score, 1, reason: 'Enemy must score when ball bounces twice on player court without strike');
    });

    test('Rally Scoring Mode: Winning side of every rally scores +1 immediately', () {
      final rallySettings = const GameSettings().copyWith(scoringMode: 'rally');
      final game = PickleballGame(courtId: 'court_classic', settings: rallySettings);
      game.player1 = PlayerComponent(isPlayerOne: true);
      game.player2 = PlayerComponent(isPlayerOne: false);
      game.ball = BallComponent()..customGame = game;
      game.prepareServicePositions();

      expect(game.p1Score, 0);
      expect(game.p2Score, 0);

      // Player 1 commits fault -> Enemy scores +1
      game.handleRallyWon(winnerIsPlayerOne: false, faultReason: 'FAULT: Double Bounce');
      expect(game.p2Score, 1);
      expect(game.p1Score, 0);

      // Enemy commits fault -> Player 1 scores +1
      game.handleRallyWon(winnerIsPlayerOne: true, faultReason: 'FAULT: Double Bounce');
      expect(game.p1Score, 1);
      expect(game.p2Score, 1);
    });
  });

  group('HUD Controls & Skills Adjuster Tests', () {
    test('GameSettings supports all HUD adjuster fields and serialization', () {
      const settings = GameSettings(
        scoringMode: 'rally',
        showJoystick: false,
        showSkillButtons: true,
        joystickMarginX: 48.0,
        joystickMarginY: 52.0,
        skillButtonScale: 1.2,
        skillMarginX: 40.0,
        skillMarginY: 42.0,
        skillSpacing: 105.0,
        controlsPreset: 'Pro Wide',
      );

      final map = settings.toMap();
      expect(map['scoringMode'], 'rally');
      expect(map['showJoystick'], 0);
      expect(map['showSkillButtons'], 1);
      expect(map['joystickMarginX'], 48.0);
      expect(map['skillButtonScale'], 1.2);
      expect(map['controlsPreset'], 'Pro Wide');

      final restored = GameSettings.fromMap(map);
      expect(restored.scoringMode, 'rally');
      expect(restored.showJoystick, isFalse);
      expect(restored.showSkillButtons, isTrue);
      expect(restored.joystickMarginX, 48.0);
      expect(restored.skillButtonScale, 1.2);
      expect(restored.controlsPreset, 'Pro Wide');
    });

    testWidgets('HudControlsAdjusterModal renders tabs, preview, and handles preset selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => HudControlsAdjusterModal.show(context),
                child: const Text('OPEN ADJUSTER'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN ADJUSTER'));
      await tester.pumpAndSettle();

      expect(find.text('HUD & CONTROLS ADJUSTER'), findsOneWidget);
      expect(find.text('LIVE HUD PREVIEW • ⚡ RALLY SCORING'), findsOneWidget);

      // Presets
      expect(find.text('Mobile Legends (Default)'), findsOneWidget);
      expect(find.text('Default Arcade Layout'), findsOneWidget);
      expect(find.text('Compact Mode', skipOffstage: false), findsOneWidget);
      expect(find.text('Pro Gamer / Wide', skipOffstage: false), findsOneWidget);
      expect(find.text('Left-Handed Flipped', skipOffstage: false), findsOneWidget);

      // Tap on Default Arcade Layout preset
      await tester.tap(find.text('Default Arcade Layout'));
      await tester.pumpAndSettle();

      // Check Positioning Tab
      await tester.tap(find.text('Positioning'));
      await tester.pumpAndSettle();
      expect(find.text('Fullscreen 1:1 Drag Editor'), findsOneWidget);
      expect(find.text('Select Control to Position'), findsOneWidget);

      // Check Joystick Tab
      await tester.tap(find.text('Joystick'));
      await tester.pumpAndSettle();
      expect(find.text('Show On-Screen Joystick'), findsOneWidget);
      expect(find.text('Joystick Size / Scale'), findsOneWidget);

      // Check Skills Tab
      await tester.tap(find.text('Skills'));
      await tester.pumpAndSettle();
      expect(find.text('Show On-Screen Skills & Smash'), findsOneWidget);
      expect(find.text('Skill & Action Button Scale'), findsOneWidget);

      // Check Scoring Rules Tab
      await tester.tap(find.text('Scoring Rules'));
      await tester.pumpAndSettle();
      expect(find.text('⚡ Rally Scoring (Major League Rules)'), findsOneWidget);
      expect(find.text('🏓 Traditional Side-Out (Official USA Pickleball)', skipOffstage: false), findsOneWidget);

      // Tap SAVE & APPLY
      await tester.tap(find.text('SAVE & APPLY'));
      await tester.pumpAndSettle();

      // Modal dismissed
      expect(find.text('HUD & CONTROLS ADJUSTER'), findsNothing);
    });

    test('Mobile Legends: Bang Bang (MLBB) Default Controller Layout Constants', () {
      const defaultSettings = GameSettings();
      expect(defaultSettings.controlsPreset, 'Mobile Legends (Default)');
      expect(defaultSettings.freePositioning, isTrue);

      // Movement Wheel (Joystick) at bottom-left
      expect(defaultSettings.joystickPosX, GameSettings.mlbbJoystickX);
      expect(defaultSettings.joystickPosY, GameSettings.mlbbJoystickY);
      expect(defaultSettings.joystickPosX, 0.16);
      expect(defaultSettings.joystickPosY, 0.78);

      // Smash (Basic Attack) at bottom-right
      expect(defaultSettings.smashPosX, GameSettings.mlbbSmashX);
      expect(defaultSettings.smashPosY, GameSettings.mlbbSmashY);
      expect(defaultSettings.smashPosX, 0.86);
      expect(defaultSettings.smashPosY, 0.80);

      // Skill 1 (Cyclone Curve / Left Spin K) to the left of Attack
      expect(defaultSettings.leftSpinPosX, GameSettings.mlbbLeftSpinX);
      expect(defaultSettings.leftSpinPosY, GameSettings.mlbbLeftSpinY);
      expect(defaultSettings.leftSpinPosX, 0.72);
      expect(defaultSettings.leftSpinPosY, 0.82);

      // Skill 2 (Vortex Hook / Right Spin L) diagonally upper-left of Attack
      expect(defaultSettings.rightSpinPosX, GameSettings.mlbbRightSpinX);
      expect(defaultSettings.rightSpinPosY, GameSettings.mlbbRightSpinY);
      expect(defaultSettings.rightSpinPosX, 0.76);
      expect(defaultSettings.rightSpinPosY, 0.67);

      // Skill 3 / Spell (Flash Dash) directly above Attack
      expect(defaultSettings.dashPosX, GameSettings.mlbbDashX);
      expect(defaultSettings.dashPosY, GameSettings.mlbbDashY);
      expect(defaultSettings.dashPosX, 0.86);
      expect(defaultSettings.dashPosY, 0.63);
    });

    test('Player can freely position controller anywhere on screen', () {
      const initial = GameSettings();

      // Custom free placement: player drags Joystick to top-left, Smash to center, Dash to right
      final custom = initial.copyWith(
        controlsPreset: 'Custom',
        freePositioning: true,
        joystickPosX: 0.22,
        joystickPosY: 0.45,
        smashPosX: 0.50,
        smashPosY: 0.75,
        leftSpinPosX: 0.40,
        leftSpinPosY: 0.70,
        rightSpinPosX: 0.60,
        rightSpinPosY: 0.70,
        dashPosX: 0.50,
        dashPosY: 0.60,
      );

      expect(custom.controlsPreset, 'Custom');
      expect(custom.joystickPosX, 0.22);
      expect(custom.joystickPosY, 0.45);
      expect(custom.smashPosX, 0.50);
      expect(custom.dashPosX, 0.50);

      // Serialization round-trip
      final map = custom.toMap();
      expect(map['controlsPreset'], 'Custom');
      expect(map['freePositioning'], 1);
      expect(map['joystickPosX'], 0.22);
      expect(map['smashPosX'], 0.50);

      final restored = GameSettings.fromMap(map);
      expect(restored.controlsPreset, 'Custom');
      expect(restored.freePositioning, isTrue);
      expect(restored.joystickPosX, 0.22);
      expect(restored.joystickPosY, 0.45);
      expect(restored.smashPosX, 0.50);
      expect(restored.smashPosY, 0.75);
      expect(restored.dashPosX, 0.50);
      expect(restored.dashPosY, 0.60);
    });

    testWidgets('FullscreenHudEditorModal opens, displays draggable controls, and handles reset MLBB', (tester) async {
      GameSettings? savedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  FullscreenHudEditorModal.show(
                    context,
                    initialSettings: const GameSettings(),
                    onSave: (s) => savedSettings = s,
                  );
                },
                child: const Text('OPEN FULLSCREEN EDITOR'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN FULLSCREEN EDITOR'));
      await tester.pumpAndSettle();

      expect(find.text('FREE DRAG HUD EDITOR'), findsOneWidget);
      expect(find.text('MLBB DEFAULT'), findsOneWidget);
      expect(find.text('SAVE & APPLY'), findsOneWidget);

      // Tap MLBB DEFAULT
      await tester.tap(find.text('MLBB DEFAULT'));
      await tester.pumpAndSettle();

      // Tap SAVE & APPLY
      await tester.tap(find.text('SAVE & APPLY'));
      await tester.pumpAndSettle();

      expect(find.text('FREE DRAG HUD EDITOR'), findsNothing);
      expect(savedSettings, isNotNull);
      expect(savedSettings!.controlsPreset, 'Mobile Legends (Default)');
    });
  });
}
