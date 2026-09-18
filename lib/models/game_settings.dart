class GameSettings {
  final double soundVolume;
  final double musicVolume;
  final bool sfxEnabled;
  final bool musicEnabled;
  final bool joystickOnLeft;
  final double joystickSensitivity;
  final String courtTheme;
  final bool showFps;

  const GameSettings({
    this.soundVolume = 0.8,
    this.musicVolume = 0.6,
    this.sfxEnabled = true,
    this.musicEnabled = true,
    this.joystickOnLeft = true,
    this.joystickSensitivity = 1.0,
    this.courtTheme = 'Classic Green',
    this.showFps = false,
  });

  GameSettings copyWith({
    double? soundVolume,
    double? musicVolume,
    bool? sfxEnabled,
    bool? musicEnabled,
    bool? joystickOnLeft,
    double? joystickSensitivity,
    String? courtTheme,
    bool? showFps,
  }) {
    return GameSettings(
      soundVolume: soundVolume ?? this.soundVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      joystickOnLeft: joystickOnLeft ?? this.joystickOnLeft,
      joystickSensitivity: joystickSensitivity ?? this.joystickSensitivity,
      courtTheme: courtTheme ?? this.courtTheme,
      showFps: showFps ?? this.showFps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'soundVolume': soundVolume,
      'musicVolume': musicVolume,
      'sfxEnabled': sfxEnabled ? 1 : 0,
      'musicEnabled': musicEnabled ? 1 : 0,
      'joystickOnLeft': joystickOnLeft ? 1 : 0,
      'joystickSensitivity': joystickSensitivity,
      'courtTheme': courtTheme,
      'showFps': showFps ? 1 : 0,
    };
  }

  factory GameSettings.fromMap(Map<String, dynamic> map) {
    return GameSettings(
      soundVolume: (map['soundVolume'] as num?)?.toDouble() ?? 0.8,
      musicVolume: (map['musicVolume'] as num?)?.toDouble() ?? 0.6,
      sfxEnabled: (map['sfxEnabled'] as int? ?? 1) == 1,
      musicEnabled: (map['musicEnabled'] as int? ?? 1) == 1,
      joystickOnLeft: (map['joystickOnLeft'] as int? ?? 1) == 1,
      joystickSensitivity: (map['joystickSensitivity'] as num?)?.toDouble() ?? 1.0,
      courtTheme: map['courtTheme'] as String? ?? 'Classic Green',
      showFps: (map['showFps'] as int? ?? 0) == 1,
    );
  }
}

