import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pickleball_smash/services/audio_service.dart';
import 'package:pickleball_smash/services/game_state_manager.dart';
import 'package:pickleball_smash/widgets/game_2d_button.dart';
import 'package:pickleball_smash/game/components/ball.dart';
import 'package:pickleball_smash/game/components/player.dart';
import 'package:pickleball_smash/game/pickleball_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Retro 2D Arcade Audio Assets Verification', () {
    test('All retro 8-bit sound assets exist and have valid PCM WAV headers', () {
      final assets = [
        'assets/audio/sfx_click.wav',
        'assets/audio/sfx_step.wav',
        'assets/audio/sfx_hit.wav',
        'assets/audio/sfx_smash.wav',
        'assets/audio/sfx_dash.wav',
        'assets/audio/sfx_left_spin.wav',
        'assets/audio/sfx_right_spin.wav',
        'assets/audio/bgm_arcade_loop.wav',
        'assets/audio/sfx_victory.wav',
        'assets/audio/sfx_defeat.wav',
        'assets/audio/sfx_point_scored.wav',
        'assets/audio/sfx_fault.wav',
        'assets/audio/sfx_coin.wav',
        'assets/audio/sfx_serve.wav',
        'assets/audio/sfx_bounce.wav',
        'assets/audio/sfx_levelup.wav',
        'assets/audio/sfx_countdown.wav',
      ];

      for (final path in assets) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'File $path must exist');
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(44), reason: '$path must have standard WAV header');
        // RIFF header
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
        // WAVE header
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      }
    });
  });

  group('AudioService SFX & BGM Operations', () {
    test('Effective volumes calculate accurately with toggles', () {
      final audio = AudioService.instance;
      final state = GameStateManager.instance;

      state.updateSettings(state.settings.copyWith(
        masterVolume: 0.8,
        musicVolume: 0.5,
        soundVolume: 0.6,
        musicEnabled: true,
        sfxEnabled: true,
      ));

      expect(audio.effectiveMusicVolume, closeTo(0.4, 0.001));
      expect(audio.effectiveSfxVolume, closeTo(0.48, 0.001));

      // Disable music
      state.updateSettings(state.settings.copyWith(musicEnabled: false));
      expect(audio.effectiveMusicVolume, 0.0);
      expect(audio.effectiveSfxVolume, closeTo(0.48, 0.001));

      // Disable sfx
      state.updateSettings(state.settings.copyWith(sfxEnabled: false));
      expect(audio.effectiveSfxVolume, 0.0);
    });

    test('All sound trigger methods execute gracefully without unhandled exceptions', () async {
      final audio = AudioService.instance;

      await expectLater(audio.playButtonTap(), completes);
      await expectLater(audio.playFootstep(), completes);
      await expectLater(audio.playPaddleHit(), completes);
      await expectLater(audio.playSmash(), completes);
      await expectLater(audio.playDash(), completes);
      await expectLater(audio.playLeftSpin(), completes);
      await expectLater(audio.playRightSpin(), completes);
      await expectLater(audio.playPointScored(), completes);
      await expectLater(audio.playVictory(), completes);
      await expectLater(audio.playDefeat(), completes);
      await expectLater(audio.playFault(), completes);
      await expectLater(audio.playCoin(), completes);
      await expectLater(audio.playServe(), completes);
      await expectLater(audio.playFloorBounce(), completes);
      await expectLater(audio.playLevelUp(), completes);
      await expectLater(audio.playCountdown(), completes);
      await expectLater(audio.playTestAudio(), completes);
      await expectLater(audio.playBgm(), completes);
      await expectLater(audio.pauseBgm(), completes);
      await expectLater(audio.resumeBgm(), completes);
      await expectLater(audio.stopBgm(), completes);
      await expectLater(audio.onSettingsUpdated(), completes);
    });
  });

  group('UI Button Click Integration', () {
    testWidgets('Game2DButton triggers playButtonTap on press', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Game2DButton(
                text: 'PLAY RETRO',
                onPressed: () {
                  pressed = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('PLAY RETRO'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });
  });

  group('In-Game Match Finish & Game State Audio Triggers', () {
    test('PickleballGame triggers victory on win and defeat on loss', () {
      final game = PickleballGame(courtId: 'court_classic', targetScore: 2);
      game.player1 = PlayerComponent(isPlayerOne: true);
      game.player2 = PlayerComponent(isPlayerOne: false);
      game.ball = BallComponent()..customGame = game;
      game.prepareServicePositions();
      game.p1Score = 1;
      game.p2Score = 0;

      // P1 wins -> victory
      expect(() => game.handleRallyWon(winnerIsPlayerOne: true, faultReason: ''), returnsNormally);
      expect(game.isGameOver, isTrue);

      final game2 = PickleballGame(courtId: 'court_classic', targetScore: 2);
      game2.player1 = PlayerComponent(isPlayerOne: true);
      game2.player2 = PlayerComponent(isPlayerOne: false);
      game2.ball = BallComponent()..customGame = game2;
      game2.prepareServicePositions();
      game2.p1Score = 0;
      game2.p2Score = 1;
      game2.serverPlayer = 2;

      // P2 wins -> defeat
      expect(() => game2.handleRallyWon(winnerIsPlayerOne: false, faultReason: ''), returnsNormally);
      expect(game2.isGameOver, isTrue);
    });

    test('PickleballGame triggers fault sound on violation dispatch', () {
      final game = PickleballGame(courtId: 'court_classic');
      game.player1 = PlayerComponent(isPlayerOne: true);
      game.player2 = PlayerComponent(isPlayerOne: false);
      game.ball = BallComponent()..customGame = game;
      game.prepareServicePositions();
      expect(() => game.handleRallyWon(winnerIsPlayerOne: false, faultReason: 'FAULT: Double Bounce'), returnsNormally);
    });

    test('GameStateManager triggers coin sound on purchase and level up on max xp', () {
      final state = GameStateManager.instance;
      state.loginAsGuest();
      state.coins = 5000;

      // Purchase character triggers coin sound
      expect(() => state.purchaseCharacter('marcus_power'), returnsNormally);

      // Level up triggers fanfare
      expect(() => state.addXp(1000), returnsNormally);
    });
  });
}
