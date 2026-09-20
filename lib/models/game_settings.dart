class GameSettings {
  // Audio Settings
  final double masterVolume;
  final double soundVolume; // SFX volume
  final double musicVolume;
  final double crowdVolume;
  final bool sfxEnabled;
  final bool musicEnabled;
  final bool crowdEnabled;
  final bool hapticsEnabled;
  final String soundProfile; // 'Arcade Retro', 'Stadium Live', 'Muted Night'

  // Controller Settings
  final String controlScheme; // 'joystick', 'dpad', 'drag'
  final bool joystickOnLeft;
  final double joystickExpand; // 0.7 to 1.6 (scale size of joystick)
  final double joystickDeadzone; // 0.05 to 0.30
  final String buttonSize; // 'Normal', 'Large', 'Extra Large'
  final double transparentCapacity; // 0.1 to 1.0 (opacity / transparent capacity)
  final String joystickColor; // 'Neon Lime', 'Electric Cyan', 'Hot Pink', 'Trophy Gold', 'Pure White'
  final bool hapticOnHit;
  final bool autoServe; // Auto-serves after countdown if player doesn't tap

  // Deprecated/compatibility aliases
  double get controllerOpacity => transparentCapacity;
  double get joystickSensitivity => 1.0;
  bool get continuousPlay => false;

  // Graphics Settings
  final String graphicsQuality; // 'Ultra', 'High', 'Medium', 'Low'
  final int targetFps; // 30, 60, 120
  final bool particlesEnabled;
  final bool shadowsEnabled;
  final bool screenShakeEnabled;
  final bool showFps;
  final String courtTheme; // 'Classic Green', 'Electric Blue', 'Sunset Clay', 'Neon Night'
  final double courtBrightness; // 0.5 to 1.5

  const GameSettings({
    // Audio
    this.masterVolume = 1.0,
    this.soundVolume = 0.8,
    this.musicVolume = 0.6,
    this.crowdVolume = 0.7,
    this.sfxEnabled = true,
    this.musicEnabled = true,
    this.crowdEnabled = true,
    this.hapticsEnabled = true,
    this.soundProfile = 'Arcade Retro',
    // Controller
    this.controlScheme = 'joystick',
    this.joystickOnLeft = true,
    this.joystickExpand = 1.0,
    this.joystickDeadzone = 0.10,
    this.buttonSize = 'Normal',
    this.transparentCapacity = 0.85,
    this.joystickColor = 'Neon Lime',
    this.hapticOnHit = true,
    this.autoServe = false,
    // Graphics
    this.graphicsQuality = 'High',
    this.targetFps = 60,
    this.particlesEnabled = true,
    this.shadowsEnabled = true,
    this.screenShakeEnabled = true,
    this.showFps = false,
    this.courtTheme = 'Classic Green',
    this.courtBrightness = 1.0,
  });

  GameSettings copyWith({
    // Audio
    double? masterVolume,
    double? soundVolume,
    double? musicVolume,
    double? crowdVolume,
    bool? sfxEnabled,
    bool? musicEnabled,
    bool? crowdEnabled,
    bool? hapticsEnabled,
    String? soundProfile,
    // Controller
    String? controlScheme,
    bool? joystickOnLeft,
    double? joystickExpand,
    double? joystickDeadzone,
    String? buttonSize,
    double? transparentCapacity,
    String? joystickColor,
    bool? hapticOnHit,
    bool? autoServe,
    // Deprecated compatibility parameters (ignored or redirected)
    double? joystickSensitivity,
    double? controllerOpacity,
    bool? continuousPlay,
    // Graphics
    String? graphicsQuality,
    int? targetFps,
    bool? particlesEnabled,
    bool? shadowsEnabled,
    bool? screenShakeEnabled,
    bool? showFps,
    String? courtTheme,
    double? courtBrightness,
  }) {
    return GameSettings(
      // Audio
      masterVolume: masterVolume ?? this.masterVolume,
      soundVolume: soundVolume ?? this.soundVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      crowdVolume: crowdVolume ?? this.crowdVolume,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      crowdEnabled: crowdEnabled ?? this.crowdEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundProfile: soundProfile ?? this.soundProfile,
      // Controller
      controlScheme: controlScheme ?? this.controlScheme,
      joystickOnLeft: joystickOnLeft ?? this.joystickOnLeft,
      joystickExpand: joystickExpand ?? this.joystickExpand,
      joystickDeadzone: joystickDeadzone ?? this.joystickDeadzone,
      buttonSize: buttonSize ?? this.buttonSize,
      transparentCapacity: transparentCapacity ?? controllerOpacity ?? this.transparentCapacity,
      joystickColor: joystickColor ?? this.joystickColor,
      hapticOnHit: hapticOnHit ?? this.hapticOnHit,
      autoServe: autoServe ?? this.autoServe,
      // Graphics
      graphicsQuality: graphicsQuality ?? this.graphicsQuality,
      targetFps: targetFps ?? this.targetFps,
      particlesEnabled: particlesEnabled ?? this.particlesEnabled,
      shadowsEnabled: shadowsEnabled ?? this.shadowsEnabled,
      screenShakeEnabled: screenShakeEnabled ?? this.screenShakeEnabled,
      showFps: showFps ?? this.showFps,
      courtTheme: courtTheme ?? this.courtTheme,
      courtBrightness: courtBrightness ?? this.courtBrightness,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Audio
      'masterVolume': masterVolume,
      'soundVolume': soundVolume,
      'musicVolume': musicVolume,
      'crowdVolume': crowdVolume,
      'sfxEnabled': sfxEnabled ? 1 : 0,
      'musicEnabled': musicEnabled ? 1 : 0,
      'crowdEnabled': crowdEnabled ? 1 : 0,
      'hapticsEnabled': hapticsEnabled ? 1 : 0,
      'soundProfile': soundProfile,
      // Controller
      'controlScheme': controlScheme,
      'joystickOnLeft': joystickOnLeft ? 1 : 0,
      'joystickExpand': joystickExpand,
      'joystickDeadzone': joystickDeadzone,
      'buttonSize': buttonSize,
      'transparentCapacity': transparentCapacity,
      'joystickColor': joystickColor,
      'hapticOnHit': hapticOnHit ? 1 : 0,
      'autoServe': autoServe ? 1 : 0,
      // Legacy backward compatibility keys
      'joystickSensitivity': 1.0,
      'controllerOpacity': transparentCapacity,
      'continuousPlay': 0,
      // Graphics
      'graphicsQuality': graphicsQuality,
      'targetFps': targetFps,
      'particlesEnabled': particlesEnabled ? 1 : 0,
      'shadowsEnabled': shadowsEnabled ? 1 : 0,
      'screenShakeEnabled': screenShakeEnabled ? 1 : 0,
      'showFps': showFps ? 1 : 0,
      'courtTheme': courtTheme,
      'courtBrightness': courtBrightness,
    };
  }

  factory GameSettings.fromMap(Map<String, dynamic> map) {
    return GameSettings(
      // Audio
      masterVolume: (map['masterVolume'] as num?)?.toDouble() ?? 1.0,
      soundVolume: (map['soundVolume'] as num?)?.toDouble() ?? 0.8,
      musicVolume: (map['musicVolume'] as num?)?.toDouble() ?? 0.6,
      crowdVolume: (map['crowdVolume'] as num?)?.toDouble() ?? 0.7,
      sfxEnabled: (map['sfxEnabled'] as int? ?? 1) == 1,
      musicEnabled: (map['musicEnabled'] as int? ?? 1) == 1,
      crowdEnabled: (map['crowdEnabled'] as int? ?? 1) == 1,
      hapticsEnabled: (map['hapticsEnabled'] as int? ?? 1) == 1,
      soundProfile: map['soundProfile'] as String? ?? 'Arcade Retro',
      // Controller
      controlScheme: map['controlScheme'] as String? ?? 'joystick',
      joystickOnLeft: (map['joystickOnLeft'] as int? ?? 1) == 1,
      joystickExpand: (map['joystickExpand'] as num?)?.toDouble() ?? 1.0,
      joystickDeadzone: (map['joystickDeadzone'] as num?)?.toDouble() ?? 0.10,
      buttonSize: map['buttonSize'] as String? ?? 'Normal',
      transparentCapacity: (map['transparentCapacity'] as num?)?.toDouble() ??
          (map['controllerOpacity'] as num?)?.toDouble() ??
          0.85,
      joystickColor: map['joystickColor'] as String? ?? 'Neon Lime',
      hapticOnHit: (map['hapticOnHit'] as int? ?? 1) == 1,
      autoServe: (map['autoServe'] as int? ?? 0) == 1,
      // Graphics
      graphicsQuality: map['graphicsQuality'] as String? ?? 'High',
      targetFps: (map['targetFps'] as num?)?.toInt() ?? 60,
      particlesEnabled: (map['particlesEnabled'] as int? ?? 1) == 1,
      shadowsEnabled: (map['shadowsEnabled'] as int? ?? 1) == 1,
      screenShakeEnabled: (map['screenShakeEnabled'] as int? ?? 1) == 1,
      showFps: (map['showFps'] as int? ?? 0) == 1,
      courtTheme: map['courtTheme'] as String? ?? 'Classic Green',
      courtBrightness: (map['courtBrightness'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
