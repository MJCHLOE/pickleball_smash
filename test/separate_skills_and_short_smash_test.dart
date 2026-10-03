import 'package:flutter_test/flutter_test.dart';
import 'package:flame/input.dart';
import 'package:pickleball_smash/game/components/background.dart';
import 'package:pickleball_smash/game/components/ball.dart';
import 'package:pickleball_smash/game/components/player.dart';
import 'package:pickleball_smash/game/pickleball_game.dart';
import 'package:pickleball_smash/models/battle_technique.dart';
import 'package:pickleball_smash/models/game_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PickleballGame createTestGame({GameSettings settings = const GameSettings(showSkillButtons: true)}) {
    final game = PickleballGame(joystickOnLeft: true, targetScore: 11, isDoubles: false, settings: settings);
    game.player1 = PlayerComponent(isPlayerOne: true)..customGame = game;
    game.player2 = PlayerComponent(isPlayerOne: false, isAI: true)..customGame = game;
    game.ball = BallComponent()..customGame = game;
    game.background = Background();
    game.applySettings(settings);
    return game;
  }

  group('Smash Button & Short Range Tests', () {
    test('Smash button is guaranteed to be strictly single on viewport', () {
      final game = createTestGame();
      final existingButtons = game.camera.viewport.children.whereType<HudButtonComponent>().toList();
      expect(existingButtons.length, 1);
      expect(game.strikeButton, isNotNull);
    });

    test('Triggering skills primes the technique for smash without auto-striking', () {
      final game = createTestGame();
      game.isWaitingForServe = false;
      game.ball.isWaitingForServe = false;
      game.ball.position.setValues(640, 520);
      game.player1.position.setValues(640, 550);

      // Trigger Skill 2 (Vortex Hook / Right Spin - Key L)
      game.triggerRightSpin();

      // Skill is primed on player 1, but did NOT auto-strike
      expect(game.player1.activeTechnique, BattleTechnique.rightSpin);
      expect(game.rightSpinButton?.isPrimed, true);
      expect(game.leftSpinButton?.isPrimed, false);
      expect(game.rightSpinButton?.cooldownRemaining, 0.0);
    });

    test('Short range smash: ball is NOT hit if outside short range', () {
      final game = createTestGame();
      game.isWaitingForServe = false;
      game.ball.isWaitingForServe = false;
      game.ball.bounceCountCurrentSide = 1; // already bounced once legally
      game.ball.velocity.setValues(0, 200); // incoming towards player 1

      // Position ball 75px vertically away from player (outside short range <= 52.0)
      game.player1.position.setValues(640, 600);
      game.ball.position.setValues(640, 525);

      final initialRallyHits = game.rallyHitCount;

      // Player swings / smashes
      game.player1.strike();

      // Ball was NOT hit because distance 75 > 52.0
      expect(game.rallyHitCount, initialRallyHits);
    });

    test('Short range smash: ball is hit when within short range', () {
      final game = createTestGame();
      game.isWaitingForServe = false;
      game.ball.isWaitingForServe = false;
      game.ball.bounceCountCurrentSide = 1; // legal groundstroke bounce
      game.ball.velocity.setValues(0, 200); // moving towards player 1

      // Position ball 40px vertically and 20px horizontally from player (inside short range <= 52 Y, <= 44 X)
      game.player1.position.setValues(640, 580);
      game.ball.position.setValues(620, 545);

      final initialRallyHits = game.rallyHitCount;

      // Player strikes / smashes
      game.player1.strike();

      // Ball was successfully hit!
      expect(game.rallyHitCount, initialRallyHits + 1);
    });
  });

  group('Separate Skills & Enemy Skill Isolation Tests', () {
    test('When enemy / opponent executes Skill L, local player skill is NOT consumed or put on cooldown', () {
      final game = createTestGame();
      // Local player has skills available and ready
      expect(game.leftSpinButton?.cooldownRemaining, 0.0);
      expect(game.rightSpinButton?.cooldownRemaining, 0.0);
      expect(game.dashButton?.cooldownRemaining, 0.0);

      // Enemy player (isLocalPlayer: false) executes Skill L (BattleTechnique.rightSpin)
      game.onTechniqueExecuted(BattleTechnique.rightSpin, isLocalPlayer: false);

      // Local player skill L is completely untouched and NOT on cooldown!
      expect(game.rightSpinButton?.cooldownRemaining, 0.0);
      expect(game.rightSpinButton?.isPrimed, false);
      expect(game.leftSpinButton?.cooldownRemaining, 0.0);
      expect(game.dashButton?.cooldownRemaining, 0.0);
    });

    test('When local player executes Skill L, local skill starts cooldown', () {
      final game = createTestGame();
      // Local player primes and executes Skill L
      game.triggerRightSpin();
      expect(game.rightSpinButton?.isPrimed, true);

      // Local player executes technique
      game.onTechniqueExecuted(BattleTechnique.rightSpin, isLocalPlayer: true);

      // Local player skill L is now on cooldown
      expect(game.rightSpinButton?.cooldownRemaining, 6.0);
      expect(game.rightSpinButton?.isPrimed, false);
    });

    test('Enemy clearing technique does not clear local player primed skill', () {
      final game = createTestGame();
      // Local player primes Skill 1 (left spin)
      game.triggerLeftSpin();
      expect(game.leftSpinButton?.isPrimed, true);

      // Enemy player2 clears technique
      game.player2.clearTechnique();

      // Local player leftSpinButton remains primed!
      expect(game.leftSpinButton?.isPrimed, true);
    });
  });
}

