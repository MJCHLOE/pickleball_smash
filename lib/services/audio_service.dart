import 'package:flutter/services.dart';
import '../models/game_settings.dart';
import 'game_state_manager.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  GameSettings get _settings => GameStateManager.instance.settings;

  /// Effective SFX volume combining master and sound volume
  double get effectiveSfxVolume => _settings.sfxEnabled ? (_settings.masterVolume * _settings.soundVolume) : 0.0;

  /// Effective Music volume
  double get effectiveMusicVolume => _settings.musicEnabled ? (_settings.masterVolume * _settings.musicVolume) : 0.0;

  /// Effective Crowd volume
  double get effectiveCrowdVolume => _settings.crowdEnabled ? (_settings.masterVolume * _settings.crowdVolume) : 0.0;

  /// Play standard button tap sound & subtle feedback
  Future<void> playButtonTap() async {
    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      if (_settings.hapticsEnabled) {
        await HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  /// Play paddle hit sound & haptics
  Future<void> playPaddleHit() async {
    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      if (_settings.hapticsEnabled && _settings.hapticOnHit) {
        await HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  /// Play power smash impact sound & heavy haptics
  Future<void> playSmash() async {
    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      if (_settings.hapticsEnabled && _settings.hapticOnHit) {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  /// Play point scored fanfare/cheer effect
  Future<void> playPointScored() async {
    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      if (_settings.hapticsEnabled) {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  /// Test audio triggered by the user from the Audio Adjuster settings
  Future<void> playTestAudio() async {
    if (effectiveSfxVolume <= 0.01) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      if (_settings.hapticsEnabled) {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }
}

