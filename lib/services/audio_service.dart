import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/game_settings.dart';
import 'game_state_manager.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  GameSettings get _settings => GameStateManager.instance.settings;

  /// Effective SFX volume combining master and sound volume
  double get effectiveSfxVolume =>
      _settings.sfxEnabled ? (_settings.masterVolume * _settings.soundVolume) : 0.0;

  /// Effective Music volume combining master and music volume
  double get effectiveMusicVolume =>
      _settings.musicEnabled ? (_settings.masterVolume * _settings.musicVolume) : 0.0;

  /// Effective Crowd volume
  double get effectiveCrowdVolume =>
      _settings.crowdEnabled ? (_settings.masterVolume * _settings.crowdVolume) : 0.0;

  // Dedicated Audio Players
  AudioPlayer? _bgmPlayer;
  AudioPlayer? _uiPlayer;
  AudioPlayer? _hitPlayer;
  AudioPlayer? _smashPlayer;
  AudioPlayer? _skillPlayer;
  AudioPlayer? _stepPlayer;
  AudioPlayer? _fanfarePlayer;
  AudioPlayer? _whistlePlayer;

  bool _isBgmPlaying = false;
  bool get isBgmPlaying => _isBgmPlaying;

  /// Check whether running inside automated unit test environment
  bool get _isTestEnvironment {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // BACKGROUND MUSIC (BGM)
  // ---------------------------------------------------------------------------

  /// Play or loop retro arcade background music
  Future<void> playBgm() async {
    if (_isTestEnvironment) return;
    if (!_settings.musicEnabled || effectiveMusicVolume <= 0.01) return;

    try {
      _bgmPlayer ??= AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(effectiveMusicVolume.clamp(0.0, 1.0));
      if (!_isBgmPlaying) {
        await _bgmPlayer!.play(AssetSource('audio/bgm_arcade_loop.wav'));
        _isBgmPlaying = true;
      }
    } catch (e) {
      debugPrint('BGM play caught: $e');
    }
  }

  /// Pause retro arcade background music
  Future<void> pauseBgm() async {
    if (_isTestEnvironment) return;
    try {
      if (_bgmPlayer != null && _isBgmPlaying) {
        await _bgmPlayer!.pause();
        _isBgmPlaying = false;
      }
    } catch (_) {}
  }

  /// Resume retro arcade background music
  Future<void> resumeBgm() async {
    if (_isTestEnvironment) return;
    if (!_settings.musicEnabled || effectiveMusicVolume <= 0.01) return;

    try {
      if (_bgmPlayer != null) {
        await _bgmPlayer!.setVolume(effectiveMusicVolume.clamp(0.0, 1.0));
        await _bgmPlayer!.resume();
        _isBgmPlaying = true;
      } else {
        await playBgm();
      }
    } catch (_) {
      await playBgm();
    }
  }

  /// Stop retro arcade background music
  Future<void> stopBgm() async {
    if (_isTestEnvironment) return;
    try {
      if (_bgmPlayer != null) {
        await _bgmPlayer!.stop();
        _isBgmPlaying = false;
      }
    } catch (_) {}
  }

  /// Handle live settings updates (music toggles, volume sliders)
  Future<void> onSettingsUpdated() async {
    if (_isTestEnvironment) return;
    try {
      if (!_settings.musicEnabled || effectiveMusicVolume <= 0.01) {
        if (_isBgmPlaying && _bgmPlayer != null) {
          await _bgmPlayer!.pause();
          _isBgmPlaying = false;
        }
      } else {
        if (_bgmPlayer != null) {
          await _bgmPlayer!.setVolume(effectiveMusicVolume.clamp(0.0, 1.0));
          if (!_isBgmPlaying) {
            await _bgmPlayer!.resume();
            _isBgmPlaying = true;
          }
        } else {
          await playBgm();
        }
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // RETRO SFX PLAYBACK HELPERS
  // ---------------------------------------------------------------------------

  Future<void> _playSfxPlayer(AudioPlayer Function() playerGetter, String assetPath, double volume) async {
    if (_isTestEnvironment) return;
    if (!_settings.sfxEnabled || volume <= 0.01) return;

    try {
      final player = playerGetter();
      await player.stop();
      await player.setVolume(volume.clamp(0.0, 1.0));
      await player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('SFX play error ($assetPath): $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PUBLIC SOUND EFFECT TRIGGERS
  // ---------------------------------------------------------------------------

  /// 1. Play standard button tap / click sound & subtle feedback
  Future<void> playButtonTap() async {
    if (_settings.hapticsEnabled) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;

    try {
      await _playSfxPlayer(() => _uiPlayer ??= AudioPlayer(), 'audio/sfx_click.wav', effectiveSfxVolume);
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// 2. Play walk footstep tap sound
  Future<void> playFootstep() async {
    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    // Footsteps are mixed slightly lower so they remain pleasant background rhythm
    final stepVol = (effectiveSfxVolume * 0.40).clamp(0.0, 1.0);
    await _playSfxPlayer(() => _stepPlayer ??= AudioPlayer(), 'audio/sfx_step.wav', stepVol);
  }

  /// 3. Play normal paddle hit sound & haptics
  Future<void> playPaddleHit() async {
    if (_settings.hapticsEnabled && _settings.hapticOnHit) {
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    await _playSfxPlayer(() => _hitPlayer ??= AudioPlayer(), 'audio/sfx_hit.wav', effectiveSfxVolume);
  }

  /// 4. Play power smash impact sound & heavy haptics
  Future<void> playSmash() async {
    if (_settings.hapticsEnabled && _settings.hapticOnHit) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    await _playSfxPlayer(() => _smashPlayer ??= AudioPlayer(), 'audio/sfx_smash.wav', effectiveSfxVolume);
  }

  /// 5. Play Flash Dash swoosh sound & light haptics
  Future<void> playDash() async {
    if (_settings.hapticsEnabled) {
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    await _playSfxPlayer(() => _skillPlayer ??= AudioPlayer(), 'audio/sfx_dash.wav', effectiveSfxVolume);
  }

  /// 6. Play Left Spin (Cyclone Curve) swirling retro audio & haptics
  Future<void> playLeftSpin() async {
    if (_settings.hapticsEnabled && _settings.hapticOnHit) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    await _playSfxPlayer(() => _skillPlayer ??= AudioPlayer(), 'audio/sfx_left_spin.wav', effectiveSfxVolume);
  }

  /// 7. Play Right Spin (Vortex Hook) electric plasma audio & haptics
  Future<void> playRightSpin() async {
    if (_settings.hapticsEnabled && _settings.hapticOnHit) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    await _playSfxPlayer(() => _skillPlayer ??= AudioPlayer(), 'audio/sfx_right_spin.wav', effectiveSfxVolume);
  }

  /// 8. Play point scored reward chime
  Future<void> playPointScored() async {
    if (_settings.hapticsEnabled) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    await _playSfxPlayer(() => _uiPlayer ??= AudioPlayer(), 'audio/sfx_point_scored.wav', effectiveSfxVolume);
  }

  /// 9. Play Match Victory / Winning Fanfare Jingle
  Future<void> playVictory() async {
    if (_settings.hapticsEnabled) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    // Duck BGM during triumphant victory fanfare
    try {
      if (_isBgmPlaying && _bgmPlayer != null) {
        await _bgmPlayer!.setVolume((effectiveMusicVolume * 0.25).clamp(0.0, 1.0));
      }
    } catch (_) {}

    await _playSfxPlayer(() => _fanfarePlayer ??= AudioPlayer(), 'audio/sfx_victory.wav', (effectiveSfxVolume * 1.1).clamp(0.0, 1.0));

    // Restore BGM after fanfare finishes
    Future.delayed(const Duration(milliseconds: 1900), () {
      try {
        if (_isBgmPlaying && _bgmPlayer != null) {
          _bgmPlayer!.setVolume(effectiveMusicVolume.clamp(0.0, 1.0));
        }
      } catch (_) {}
    });
  }

  /// 10. Play Match Defeat / Game Over Jingle
  Future<void> playDefeat() async {
    if (_settings.hapticsEnabled) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    // Duck BGM during defeat jingle
    try {
      if (_isBgmPlaying && _bgmPlayer != null) {
        await _bgmPlayer!.setVolume((effectiveMusicVolume * 0.20).clamp(0.0, 1.0));
      }
    } catch (_) {}

    await _playSfxPlayer(() => _fanfarePlayer ??= AudioPlayer(), 'audio/sfx_defeat.wav', (effectiveSfxVolume * 1.0).clamp(0.0, 1.0));

    // Restore BGM after defeat motif
    Future.delayed(const Duration(milliseconds: 1700), () {
      try {
        if (_isBgmPlaying && _bgmPlayer != null) {
          _bgmPlayer!.setVolume(effectiveMusicVolume.clamp(0.0, 1.0));
        }
      } catch (_) {}
    });
  }

  /// 11. Play Fault / Violation Warning Alert (Double bounce, kitchen violation, out of bounds)
  Future<void> playFault() async {
    if (_settings.hapticsEnabled) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    await _playSfxPlayer(() => _whistlePlayer ??= AudioPlayer(), 'audio/sfx_fault.wav', (effectiveSfxVolume * 0.85).clamp(0.0, 1.0));
  }

  /// 12. Play Coin Earned or Shop Purchase Chime
  Future<void> playCoin() async {
    if (_settings.hapticsEnabled) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    await _playSfxPlayer(() => _uiPlayer ??= AudioPlayer(), 'audio/sfx_coin.wav', effectiveSfxVolume);
  }

  /// 13. Play Serve Launch Whoosh
  Future<void> playServe() async {
    if (_settings.hapticsEnabled && _settings.hapticOnHit) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    await _playSfxPlayer(() => _hitPlayer ??= AudioPlayer(), 'audio/sfx_serve.wav', effectiveSfxVolume);
  }

  /// 14. Play Court Floor Bounce (hollow acrylic/wood court bounce, distinct from paddle hit)
  Future<void> playFloorBounce() async {
    if (_settings.hapticsEnabled && _settings.hapticOnHit) {
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    await _playSfxPlayer(() => _hitPlayer ??= AudioPlayer(), 'audio/sfx_bounce.wav', (effectiveSfxVolume * 0.85).clamp(0.0, 1.0));
  }

  /// 15. Play Level Up Celebration Fanfare
  Future<void> playLevelUp() async {
    if (_settings.hapticsEnabled) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    await _playSfxPlayer(() => _fanfarePlayer ??= AudioPlayer(), 'audio/sfx_levelup.wav', effectiveSfxVolume);
  }

  /// 16. Play Countdown / Ready Beep
  Future<void> playCountdown() async {
    if (_settings.hapticsEnabled) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    await _playSfxPlayer(() => _uiPlayer ??= AudioPlayer(), 'audio/sfx_countdown.wav', (effectiveSfxVolume * 0.75).clamp(0.0, 1.0));
  }

  /// Test audio triggered by user from settings
  Future<void> playTestAudio() async {
    if (effectiveSfxVolume <= 0.01) return;
    try {
      await playVictory();
    } catch (_) {}
  }
}
