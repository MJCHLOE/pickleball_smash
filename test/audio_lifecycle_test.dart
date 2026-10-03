import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_smash/services/audio_service.dart';
import 'package:pickleball_smash/services/game_state_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioService Background Music & Lifecycle Stability Tests', () {
    test('AudioService initializes and responds to lifecycle state transitions', () {
      final audio = AudioService.instance;
      audio.initialize();

      expect(audio.isAppInBackground, isFalse);

      // Simulate user minimizing app / going to home screen / turning phone screen off
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(audio.isAppInBackground, isTrue);

      // Simulate user opening phone / returning to app
      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(audio.isAppInBackground, isFalse);

      // Inactive (split screen / incoming call / notification shade)
      audio.didChangeAppLifecycleState(AppLifecycleState.inactive);
      expect(audio.isAppInBackground, isTrue);

      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(audio.isAppInBackground, isFalse);

      // App detached / backed out / closed
      audio.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(audio.isAppInBackground, isTrue);
    });

    test('BGM methods handle in-game and menu asset paths stably', () async {
      final audio = AudioService.instance;
      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);

      await audio.playMenuBgm();
      expect(audio.currentBgmAsset, equals(AudioService.menuBgm));

      await audio.playInGameBgm();
      expect(audio.currentBgmAsset, equals(AudioService.defaultInGameBgm));

      await audio.pauseBgm();
      expect(audio.isBgmPlaying, isFalse);

      await audio.stopBgm();
      expect(audio.isBgmPlaying, isFalse);
    });

    test('AudioService does not start BGM while in background', () async {
      final audio = AudioService.instance;
      // Simulate phone screen turned off or on home screen
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(audio.isAppInBackground, isTrue);

      // Attempting to play BGM while phone is off / in background should not mark BGM as playing
      await audio.playBgm(AudioService.menuBgm);
      expect(audio.isBgmPlaying, isFalse);

      // Returning to foreground resumes cleanly
      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(audio.isAppInBackground, isFalse);
    });

    test('Settings toggle updates BGM playback state', () async {
      final audio = AudioService.instance;
      final state = GameStateManager.instance;

      // Disable music in settings
      state.updateSettings(state.settings.copyWith(musicEnabled: false));
      await audio.onSettingsUpdated();
      expect(audio.effectiveMusicVolume, equals(0.0));

      // Re-enable music in settings
      state.updateSettings(
        state.settings.copyWith(
          musicEnabled: true,
          musicVolume: 0.8,
          masterVolume: 1.0,
        ),
      );
      await audio.onSettingsUpdated();
      expect(audio.effectiveMusicVolume, greaterThan(0.0));
    });
  });
}

