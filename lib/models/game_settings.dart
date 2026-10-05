enum AIDifficulty {
  easy,
  normal,
  hard,
  extreme,
}

extension AIDifficultyExtension on AIDifficulty {
  String get displayName {
    switch (this) {
      case AIDifficulty.easy:
        return 'Easy';
      case AIDifficulty.normal:
        return 'Normal';
      case AIDifficulty.hard:
        return 'Hard';
      case AIDifficulty.extreme:
        return 'Extreme';
    }
  }

  double get speedMultiplier {
    switch (this) {
      case AIDifficulty.easy:
        return 0.75;
      case AIDifficulty.normal:
        return 1.0;
      case AIDifficulty.hard:
        return 1.20;
      case AIDifficulty.extreme:
        return 1.40;
    }
  }

  double get reactionSpread {
    switch (this) {
      case AIDifficulty.easy:
        return 75.0;
      case AIDifficulty.normal:
        return 40.0;
      case AIDifficulty.hard:
        return 18.0;
      case AIDifficulty.extreme:
        return 4.0;
    }
  }

  double get dashThreshold {
    switch (this) {
      case AIDifficulty.easy:
        return 210.0;
      case AIDifficulty.normal:
        return 140.0;
      case AIDifficulty.hard:
        return 95.0;
      case AIDifficulty.extreme:
        return 65.0;
    }
  }

  double get spinTechniqueChance {
    switch (this) {
      case AIDifficulty.easy:
        return 0.05;
      case AIDifficulty.normal:
        return 0.16;
      case AIDifficulty.hard:
        return 0.32;
      case AIDifficulty.extreme:
        return 0.55;
    }
  }
}

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

  // Controller & HUD Customization Settings
  final String controlScheme; // 'joystick', 'dpad', 'drag'
  final bool joystickOnLeft;
  final double joystickExpand; // 0.7 to 1.6 (scale size of joystick)
  final double joystickDeadzone; // 0.05 to 0.30
  final String buttonSize; // 'Normal', 'Large', 'Extra Large'
  final double transparentCapacity; // 0.1 to 1.0 (opacity / transparent capacity)
  final String joystickColor; // 'Neon Lime', 'Electric Cyan', 'Hot Pink', 'Trophy Gold', 'Pure White'
  final bool hapticOnHit;
  final bool autoServe; // Auto-serves after countdown if player doesn't tap
  final bool showJoystick; // Toggle on-screen joystick display
  final bool showSkillButtons; // Toggle on-screen skills display
  final double joystickMarginX; // Horizontal offset from screen edge (12 to 120)
  final double joystickMarginY; // Vertical offset from screen bottom (12 to 120)
  final double skillButtonScale; // Skill button scale multiplier (0.65 to 1.6)
  final double smashScale; // Smash button scale multiplier (0.65 to 1.6)
  final double leftSpinScale; // Spin Left (Skill 1) scale multiplier (0.65 to 1.6)
  final double rightSpinScale; // Spin Right (Skill 2) scale multiplier (0.65 to 1.6)
  final double dashScale; // Dash (Skill 3) scale multiplier (0.65 to 1.6)
  final double speedBoostScale; // Speed Boost Strike (Skill 4) scale multiplier (0.65 to 1.6)
  final double skillMarginX; // Horizontal offset for skill buttons (12 to 120)
  final double skillMarginY; // Vertical offset for skill buttons (12 to 120)
  final double skillSpacing; // Spacing between skill cluster buttons (60 to 140)
  final String controlsPreset; // 'Control Default', 'Default Arcade', 'Compact', 'Pro Wide', 'Left-Handed', 'Custom'

  // Control Default (Radial Fan) Controller Layout Constants
  static const double controlDefaultJoystickX = 0.16;
  static const double controlDefaultJoystickY = 0.79;
  static const double controlDefaultSmashX = 0.88;
  static const double controlDefaultSmashY = 0.81;
  static const double controlDefaultLeftSpinX = 0.76;
  static const double controlDefaultLeftSpinY = 0.84;
  static const double controlDefaultRightSpinX = 0.85;
  static const double controlDefaultRightSpinY = 0.62;
  static const double controlDefaultDashX = 0.93;
  static const double controlDefaultDashY = 0.62;
  static const double controlDefaultSpeedBoostX = 0.79;
  static const double controlDefaultSpeedBoostY = 0.72;

  // Backward compatibility MLBB aliases
  static const double mlbbJoystickX = controlDefaultJoystickX;
  static const double mlbbJoystickY = controlDefaultJoystickY;
  static const double mlbbSmashX = controlDefaultSmashX;
  static const double mlbbSmashY = controlDefaultSmashY;
  static const double mlbbLeftSpinX = controlDefaultLeftSpinX;
  static const double mlbbLeftSpinY = controlDefaultLeftSpinY;
  static const double mlbbRightSpinX = controlDefaultRightSpinX;
  static const double mlbbRightSpinY = controlDefaultRightSpinY;
  static const double mlbbDashX = controlDefaultDashX;
  static const double mlbbDashY = controlDefaultDashY;
  static const double mlbbSpeedBoostX = controlDefaultSpeedBoostX;
  static const double mlbbSpeedBoostY = controlDefaultSpeedBoostY;

  // Classic Arcade 2x2 Layout Constants
  static const double arcadeJoystickX = 0.14;
  static const double arcadeJoystickY = 0.80;
  static const double arcadeSmashX = 0.88;
  static const double arcadeSmashY = 0.82;
  static const double arcadeLeftSpinX = 0.76;
  static const double arcadeLeftSpinY = 0.82;
  static const double arcadeRightSpinX = 0.88;
  static const double arcadeRightSpinY = 0.68;
  static const double arcadeDashX = 0.76;
  static const double arcadeDashY = 0.68;
  static const double arcadeSpeedBoostX = 0.66;
  static const double arcadeSpeedBoostY = 0.72;

  // Free Drag & Drop Positioning (Normalized 0.0 to 1.0 screen coordinates)
  final bool freePositioning;
  final double joystickPosX;
  final double joystickPosY;
  final double smashPosX;
  final double smashPosY;
  final double leftSpinPosX;
  final double leftSpinPosY;
  final double rightSpinPosX;
  final double rightSpinPosY;
  final double dashPosX;
  final double dashPosY;
  final double speedBoostPosX;
  final double speedBoostPosY;

  // Gameplay & Scoring Rules
  final String scoringMode; // 'rally' (Major League / Arcade) or 'sideOut' (Traditional USA Pickleball)
  final bool requireFloorBounceAllShots; // false by default (Official Pickleball: volleys allowed after 2-bounce rule outside NVZ)
  final AIDifficulty aiDifficulty; // 'easy', 'normal', 'hard', 'extreme'

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
    this.showJoystick = true,
    this.showSkillButtons = true,
    this.joystickMarginX = 36.0,
    this.joystickMarginY = 36.0,
    this.skillButtonScale = 1.0,
    this.smashScale = 1.0,
    this.leftSpinScale = 1.0,
    this.rightSpinScale = 1.0,
    this.dashScale = 1.0,
    this.speedBoostScale = 1.0,
    this.skillMarginX = 36.0,
    this.skillMarginY = 36.0,
    this.skillSpacing = 90.0,
    this.controlsPreset = 'Control Default',
    this.freePositioning = true,
    this.joystickPosX = controlDefaultJoystickX,
    this.joystickPosY = controlDefaultJoystickY,
    this.smashPosX = controlDefaultSmashX,
    this.smashPosY = controlDefaultSmashY,
    this.leftSpinPosX = controlDefaultLeftSpinX,
    this.leftSpinPosY = controlDefaultLeftSpinY,
    this.rightSpinPosX = controlDefaultRightSpinX,
    this.rightSpinPosY = controlDefaultRightSpinY,
    this.dashPosX = controlDefaultDashX,
    this.dashPosY = controlDefaultDashY,
    this.speedBoostPosX = controlDefaultSpeedBoostX,
    this.speedBoostPosY = controlDefaultSpeedBoostY,
    this.scoringMode = 'rally',
    this.requireFloorBounceAllShots = false,
    this.aiDifficulty = AIDifficulty.normal,
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
    bool? showJoystick,
    bool? showSkillButtons,
    double? joystickMarginX,
    double? joystickMarginY,
    double? skillButtonScale,
    double? smashScale,
    double? leftSpinScale,
    double? rightSpinScale,
    double? dashScale,
    double? speedBoostScale,
    double? skillMarginX,
    double? skillMarginY,
    double? skillSpacing,
    String? controlsPreset,
    bool? freePositioning,
    double? joystickPosX,
    double? joystickPosY,
    double? smashPosX,
    double? smashPosY,
    double? leftSpinPosX,
    double? leftSpinPosY,
    double? rightSpinPosX,
    double? rightSpinPosY,
    double? dashPosX,
    double? dashPosY,
    double? speedBoostPosX,
    double? speedBoostPosY,
    String? scoringMode,
    bool? requireFloorBounceAllShots,
    AIDifficulty? aiDifficulty,
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
      showJoystick: showJoystick ?? this.showJoystick,
      showSkillButtons: showSkillButtons ?? this.showSkillButtons,
      joystickMarginX: joystickMarginX ?? this.joystickMarginX,
      joystickMarginY: joystickMarginY ?? this.joystickMarginY,
      skillButtonScale: skillButtonScale ?? this.skillButtonScale,
      smashScale: smashScale ?? this.smashScale,
      leftSpinScale: leftSpinScale ?? this.leftSpinScale,
      rightSpinScale: rightSpinScale ?? this.rightSpinScale,
      dashScale: dashScale ?? this.dashScale,
      speedBoostScale: speedBoostScale ?? this.speedBoostScale,
      skillMarginX: skillMarginX ?? this.skillMarginX,
      skillMarginY: skillMarginY ?? this.skillMarginY,
      skillSpacing: skillSpacing ?? this.skillSpacing,
      controlsPreset: controlsPreset ?? this.controlsPreset,
      freePositioning: freePositioning ?? this.freePositioning,
      joystickPosX: joystickPosX ?? this.joystickPosX,
      joystickPosY: joystickPosY ?? this.joystickPosY,
      smashPosX: smashPosX ?? this.smashPosX,
      smashPosY: smashPosY ?? this.smashPosY,
      leftSpinPosX: leftSpinPosX ?? this.leftSpinPosX,
      leftSpinPosY: leftSpinPosY ?? this.leftSpinPosY,
      rightSpinPosX: rightSpinPosX ?? this.rightSpinPosX,
      rightSpinPosY: rightSpinPosY ?? this.rightSpinPosY,
      dashPosX: dashPosX ?? this.dashPosX,
      dashPosY: dashPosY ?? this.dashPosY,
      speedBoostPosX: speedBoostPosX ?? this.speedBoostPosX,
      speedBoostPosY: speedBoostPosY ?? this.speedBoostPosY,
      scoringMode: scoringMode ?? this.scoringMode,
      requireFloorBounceAllShots: requireFloorBounceAllShots ?? this.requireFloorBounceAllShots,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
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
      'showJoystick': showJoystick ? 1 : 0,
      'showSkillButtons': showSkillButtons ? 1 : 0,
      'joystickMarginX': joystickMarginX,
      'joystickMarginY': joystickMarginY,
      'skillButtonScale': skillButtonScale,
      'smashScale': smashScale,
      'leftSpinScale': leftSpinScale,
      'rightSpinScale': rightSpinScale,
      'dashScale': dashScale,
      'speedBoostScale': speedBoostScale,
      'skillMarginX': skillMarginX,
      'skillMarginY': skillMarginY,
      'skillSpacing': skillSpacing,
      'controlsPreset': controlsPreset,
      'freePositioning': freePositioning ? 1 : 0,
      'joystickPosX': joystickPosX,
      'joystickPosY': joystickPosY,
      'smashPosX': smashPosX,
      'smashPosY': smashPosY,
      'leftSpinPosX': leftSpinPosX,
      'leftSpinPosY': leftSpinPosY,
      'rightSpinPosX': rightSpinPosX,
      'rightSpinPosY': rightSpinPosY,
      'dashPosX': dashPosX,
      'dashPosY': dashPosY,
      'speedBoostPosX': speedBoostPosX,
      'speedBoostPosY': speedBoostPosY,
      'scoringMode': scoringMode,
      'requireFloorBounceAllShots': requireFloorBounceAllShots ? 1 : 0,
      'aiDifficulty': aiDifficulty.name,
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
      showJoystick: (map['showJoystick'] as int? ?? 1) == 1,
      showSkillButtons: (map['showSkillButtons'] as int? ?? 1) == 1,
      joystickMarginX: (map['joystickMarginX'] as num?)?.toDouble() ?? 36.0,
      joystickMarginY: (map['joystickMarginY'] as num?)?.toDouble() ?? 36.0,
      skillButtonScale: (map['skillButtonScale'] as num?)?.toDouble() ?? 1.0,
      smashScale: (map['smashScale'] as num?)?.toDouble() ??
          (map['skillButtonScale'] as num?)?.toDouble() ??
          1.0,
      leftSpinScale: (map['leftSpinScale'] as num?)?.toDouble() ??
          (map['skillButtonScale'] as num?)?.toDouble() ??
          1.0,
      rightSpinScale: (map['rightSpinScale'] as num?)?.toDouble() ??
          (map['skillButtonScale'] as num?)?.toDouble() ??
          1.0,
      dashScale: (map['dashScale'] as num?)?.toDouble() ??
          (map['skillButtonScale'] as num?)?.toDouble() ??
          1.0,
      speedBoostScale: (map['speedBoostScale'] as num?)?.toDouble() ??
          (map['skillButtonScale'] as num?)?.toDouble() ??
          1.0,
      skillMarginX: (map['skillMarginX'] as num?)?.toDouble() ?? 36.0,
      skillMarginY: (map['skillMarginY'] as num?)?.toDouble() ?? 36.0,
      skillSpacing: (map['skillSpacing'] as num?)?.toDouble() ?? 90.0,
      controlsPreset: (map['controlsPreset'] == 'Mobile Legends (Default)' ||
              map['controlsPreset'] == 'MLBB Default' ||
              map['controlsPreset'] == null)
          ? 'Control Default'
          : (map['controlsPreset'] as String),
      freePositioning: (map['freePositioning'] as int? ?? 1) == 1,
      joystickPosX: (map['joystickPosX'] as num?)?.toDouble() ?? controlDefaultJoystickX,
      joystickPosY: (map['joystickPosY'] as num?)?.toDouble() ?? controlDefaultJoystickY,
      smashPosX: (map['smashPosX'] as num?)?.toDouble() ?? controlDefaultSmashX,
      smashPosY: (map['smashPosY'] as num?)?.toDouble() ?? controlDefaultSmashY,
      leftSpinPosX: (map['leftSpinPosX'] as num?)?.toDouble() ?? controlDefaultLeftSpinX,
      leftSpinPosY: (map['leftSpinPosY'] as num?)?.toDouble() ?? controlDefaultLeftSpinY,
      rightSpinPosX: (map['rightSpinPosX'] as num?)?.toDouble() ?? controlDefaultRightSpinX,
      rightSpinPosY: (map['rightSpinPosY'] as num?)?.toDouble() ?? controlDefaultRightSpinY,
      dashPosX: (map['dashPosX'] as num?)?.toDouble() ?? controlDefaultDashX,
      dashPosY: (map['dashPosY'] as num?)?.toDouble() ?? controlDefaultDashY,
      speedBoostPosX: (map['speedBoostPosX'] as num?)?.toDouble() ?? controlDefaultSpeedBoostX,
      speedBoostPosY: (map['speedBoostPosY'] as num?)?.toDouble() ?? controlDefaultSpeedBoostY,
      scoringMode: map['scoringMode'] as String? ?? 'rally',
      requireFloorBounceAllShots: (map['requireFloorBounceAllShots'] as int? ?? 0) == 1,
      aiDifficulty: () {
        final val = map['aiDifficulty'] as String?;
        return AIDifficulty.values.firstWhere(
          (e) => e.name == val,
          orElse: () => AIDifficulty.normal,
        );
      }(),
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
