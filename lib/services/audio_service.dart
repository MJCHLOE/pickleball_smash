import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/game_settings.dart';
import 'game_state_manager.dart';

class AudioService with WidgetsBindingObserver {
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

  bool _initialized = false;
  bool _isAppInBackground = false;
  bool get isAppInBackground => _isAppInBackground;

  bool _wasBgmPlayingBeforeBackground = false;
  int _bgmRequestId = 0;

  /// Check whether running inside automated unit test environment
  bool get _isTestEnvironment {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Initialize AudioService, configure background mode audio context,
  /// and register application lifecycle observer.
  void initialize() {
    if (_initialized || _isTestEnvironment) return;
    _initialized = true;

    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (e) {
      debugPrint('AudioService WidgetsBinding observer notice: $e');
    }

    try {
      AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false, // Ensures music does not keep device awake or play when screen is off
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Global AudioContext setup skipped: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _handleAppBackgrounded();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.resumed:
        _handleAppForegrounded();
        break;
    }
  }

  /// Called when user goes to mobile home screen, turns off phone screen, or switches apps
  void _handleAppBackgrounded() {
    _isAppInBackground = true;
    if (_isBgmPlaying) {
      _wasBgmPlayingBeforeBackground = true;
      pauseBgm();
    }
    _stopAllSfx();
  }

  /// Called when user returns to app from home screen or unlocks the phone
  void _handleAppForegrounded() {
    _isAppInBackground = false;
    if (_wasBgmPlayingBeforeBackground && _settings.musicEnabled && effectiveMusicVolume > 0.01) {
      resumeBgm();
    }
    _wasBgmPlayingBeforeBackground = false;
  }

  /// Called when app is backed out of or terminated
  void _handleAppDetached() {
    _isAppInBackground = true;
    _wasBgmPlayingBeforeBackground = false;
    stopBgm();
    _stopAllSfx();
  }

  /// Stop all active sound effects immediately
  void _stopAllSfx() {
    try { _uiPlayer?.stop(); } catch (_) {}
    try { _hitPlayer?.stop(); } catch (_) {}
    try { _smashPlayer?.stop(); } catch (_) {}
    try { _skillPlayer?.stop(); } catch (_) {}
    try { _stepPlayer?.stop(); } catch (_) {}
    try { _fanfarePlayer?.stop(); } catch (_) {}
    try { _whistlePlayer?.stop(); } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // BACKGROUND MUSIC (BGM)
  // ---------------------------------------------------------------------------

  static const String defaultInGameBgm = 'audio/bgm_arcade_loop.wav';
  static const String menuBgm = 'audio/bgm_menu.mp3';

  String _currentBgmAsset = '';
  String get currentBgmAsset => _currentBgmAsset;

  Future<AudioPlayer> _ensureBgmPlayer() async {
    if (_bgmPlayer == null) {
      final player = AudioPlayer(playerId: 'pickleball_bgm_player');
      try {
        await player.setPlayerMode(PlayerMode.mediaPlayer);
        await player.setReleaseMode(ReleaseMode.loop);
        player.onPlayerComplete.listen((_) {
          // Seamless loop recovery fallback for devices where native loop drops
          if (_isBgmPlaying && !_isAppInBackground && _currentBgmAsset.isNotEmpty) {
            player.play(AssetSource(_currentBgmAsset));
          }
        });
      } catch (_) {}
      _bgmPlayer = player;
    }
    return _bgmPlayer!;
  }

  /// Play or loop background music stably with race-condition protection and lifecycle checks
  Future<void> playBgm([String assetPath = menuBgm]) async {
    if (_isTestEnvironment) {
      if (!_isAppInBackground && _settings.musicEnabled && effectiveMusicVolume > 0.01) {
        _currentBgmAsset = assetPath;
        _isBgmPlaying = true;
      }
      return;
    }

    final int currentId = ++_bgmRequestId;

    // If app is currently minimized or phone is off, do NOT start audio
    if (_isAppInBackground) {
      _currentBgmAsset = assetPath;
      _wasBgmPlayingBeforeBackground = true;
      return;
    }

    if (!_settings.musicEnabled || effectiveMusicVolume <= 0.01) {
      _currentBgmAsset = assetPath;
      await stopBgm();
      return;
    }

    try {
      final player = await _ensureBgmPlayer();

      // If already playing this exact track stably, smoothly adjust volume without restarting
      if (_currentBgmAsset == assetPath && _isBgmPlaying && player.state == PlayerState.playing) {
        await player.setVolume(effectiveMusicVolume.clamp(0.0, 1.0));
        return;
      }

      // If the exact same track is already paused, RESUME IT rather than restarting from intro!
      if (_currentBgmAsset == assetPath && player.state == PlayerState.paused) {
        await player.setVolume(effectiveMusicVolume.clamp(0.0, 1.0));
        await player.resume();
        _isBgmPlaying = true;
        return;
      }

      await player.stop();

      // Guard against newer requests or app being backgrounded while stopping
      if (currentId != _bgmRequestId || _isAppInBackground) return;

      _currentBgmAsset = assetPath;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(effectiveMusicVolume.clamp(0.0, 1.0));
      await player.play(AssetSource(assetPath));

      if (currentId == _bgmRequestId) {
        _isBgmPlaying = true;
      }
    } catch (e) {
      debugPrint('BGM play caught: $e');
    }
  }

  /// Play the menu/dashboard background music
  Future<void> playMenuBgm() => playBgm(menuBgm);

  /// Play the default in-game match background music
  Future<void> playInGameBgm() => playBgm(defaultInGameBgm);

  /// Pause retro arcade background music
  Future<void> pauseBgm() async {
    if (_isTestEnvironment) {
      _isBgmPlaying = false;
      return;
    }
    try {
      if (_bgmPlayer != null && _isBgmPlaying) {
        await _bgmPlayer!.pause();
        _isBgmPlaying = false;
      }
    } catch (_) {}
  }

  /// Resume retro arcade background music from where it was paused
  Future<void> resumeBgm() async {
    if (_isTestEnvironment) {
      if (!_isAppInBackground && _settings.musicEnabled && effectiveMusicVolume > 0.01) {
        _isBgmPlaying = true;
      }
      return;
    }
    if (_isAppInBackground) {
      _wasBgmPlayingBeforeBackground = true;
      return;
    }
    if (!_settings.musicEnabled || effectiveMusicVolume <= 0.01) return;

    try {
      if (_bgmPlayer != null) {
        await _bgmPlayer!.setVolume(effectiveMusicVolume.clamp(0.0, 1.0));
        if (_bgmPlayer!.state == PlayerState.paused) {
          await _bgmPlayer!.resume();
          _isBgmPlaying = true;
          return;
        }
      }
      await playBgm(_currentBgmAsset.isNotEmpty ? _currentBgmAsset : menuBgm);
    } catch (_) {
      try {
        await _bgmPlayer?.resume();
        _isBgmPlaying = true;
      } catch (_) {}
    }
  }

  /// Stop retro arcade background music
  Future<void> stopBgm() async {
    if (_isTestEnvironment) {
      _isBgmPlaying = false;
      return;
    }
    _bgmRequestId++;
    try {
      if (_bgmPlayer != null) {
        await _bgmPlayer!.stop();
        _isBgmPlaying = false;
      }
    } catch (_) {}
  }

  /// Handle live settings updates (music toggles, volume sliders)
  Future<void> onSettingsUpdated() async {
    if (_isTestEnvironment) {
      if (!_settings.musicEnabled || effectiveMusicVolume <= 0.01) {
        _isBgmPlaying = false;
      }
      return;
    }
    try {
      if (!_settings.musicEnabled || effectiveMusicVolume <= 0.01) {
        if (_isBgmPlaying && _bgmPlayer != null) {
          await _bgmPlayer!.pause();
          _isBgmPlaying = false;
        }
      } else {
        if (_bgmPlayer != null) {
          await _bgmPlayer!.setVolume(effectiveMusicVolume.clamp(0.0, 1.0));
          if (!_isBgmPlaying && !_isAppInBackground) {
            await _bgmPlayer!.resume();
            _isBgmPlaying = true;
          }
        } else if (!_isAppInBackground) {
          await playBgm();
        }
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // RETRO SFX PLAYBACK HELPERS
  // ---------------------------------------------------------------------------

  Future<void> _playSfxPlayer(AudioPlayer Function() playerGetter, String assetPath, double volume) async {
    if (_isTestEnvironment || _isAppInBackground) return;
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

  /// 4.1 Play power smash / speed boost strike sound (alias for playSmash)
  Future<void> playPowerSmash() async => playSmash();

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

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01 || _isAppInBackground) return;
    // Duck BGM during triumphant victory fanfare
    try {
      if (_isBgmPlaying && !_isAppInBackground && _bgmPlayer != null) {
        await _bgmPlayer!.setVolume((effectiveMusicVolume * 0.25).clamp(0.0, 1.0));
      }
    } catch (_) {}

    await _playSfxPlayer(() => _fanfarePlayer ??= AudioPlayer(), 'audio/sfx_victory.wav', (effectiveSfxVolume * 1.1).clamp(0.0, 1.0));

    // Restore BGM after fanfare finishes
    Future.delayed(const Duration(milliseconds: 1900), () {
      try {
        if (_isBgmPlaying && !_isAppInBackground && _bgmPlayer != null) {
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

    if (!_settings.sfxEnabled || effectiveSfxVolume <= 0.01 || _isAppInBackground) return;
    // Duck BGM during defeat jingle
    try {
      if (_isBgmPlaying && !_isAppInBackground && _bgmPlayer != null) {
        await _bgmPlayer!.setVolume((effectiveMusicVolume * 0.20).clamp(0.0, 1.0));
      }
    } catch (_) {}

    await _playSfxPlayer(() => _fanfarePlayer ??= AudioPlayer(), 'audio/sfx_defeat.wav', (effectiveSfxVolume * 1.0).clamp(0.0, 1.0));

    // Restore BGM after defeat motif
    Future.delayed(const Duration(milliseconds: 1700), () {
      try {
        if (_isBgmPlaying && !_isAppInBackground && _bgmPlayer != null) {
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
