import 'package:flutter/material.dart';

enum CharacterType {
  male1,
  female1,
  male2,
  male3,
  male4,
  female2,
  female3,
  female4,
}

class CharacterInfo {
  final String id;
  final String name;
  final String title;
  final CharacterType type;
  final String spriteFolder;
  final int price; // In coins (0 for default unlocked)
  final int sellRefund; // In coins
  final bool isDefaultUnlocked;
  final String charSelectIdlePath;
  final String frontRunPath;
  final String frontSlashPath;
  final List<Color> gradientColors;
  final Color borderColor;
  final String badge;
  final String description;

  const CharacterInfo({
    required this.id,
    required this.name,
    required this.title,
    required this.type,
    required this.spriteFolder,
    required this.price,
    required this.sellRefund,
    this.isDefaultUnlocked = false,
    required this.charSelectIdlePath,
    required this.frontRunPath,
    required this.frontSlashPath,
    required this.gradientColors,
    required this.borderColor,
    required this.badge,
    required this.description,
  });

  bool get isMale =>
      type != CharacterType.female1 &&
      type != CharacterType.female2 &&
      type != CharacterType.female3 &&
      type != CharacterType.female4;
  bool get isPurchasable => price > 0;

  String get readyToServePath {
    switch (type) {
      case CharacterType.female1:
        return 'assets/images/female1_sprite/female_p1sideidle.png';
      case CharacterType.female2:
        return 'assets/images/female2_sprite/female2_p1sideidle.png';
      case CharacterType.female3:
        return 'assets/images/female3_sprite/female3_p1sideidle.png';
      case CharacterType.female4:
        return 'assets/images/female4_sprite/female4_p1sideidle.png';
      case CharacterType.male2:
        return 'assets/images/male2_sprite/male2_p1sideidle.png';
      case CharacterType.male3:
        return 'assets/images/male3_sprite/male3_p1sideidle.png';
      case CharacterType.male4:
        return 'assets/images/male4_sprite/male4_p1sideidle.png';
      case CharacterType.male1:
        return 'assets/images/male1_sprite/male_p1sideidle.png';
    }
  }

  String get iconPath {
    switch (type) {
      case CharacterType.female1:
        return 'assets/images/female1 sprite (reworked)/female1_icon.png';
      case CharacterType.female2:
        return 'assets/images/female2_sprite/female2_icon.png';
      case CharacterType.female3:
        return 'assets/images/female3_sprite/female3_icon.png';
      case CharacterType.female4:
        return 'assets/images/female4_sprite/female4_icon.png';
      case CharacterType.male1:
        return 'assets/images/male1_sprite/male1_icon.png';
      case CharacterType.male2:
        return 'assets/images/male2_sprite/male2_icon.png';
      case CharacterType.male3:
        return 'assets/images/male3_sprite/male3_icon.png';
      case CharacterType.male4:
        return 'assets/images/male4_sprite/male4_icon.png';
    }
  }
}

class CharacterRoster {
  static const CharacterInfo alex = CharacterInfo(
    id: 'alex_classic',
    name: 'Alex Smash',
    title: 'Power Smasher',
    type: CharacterType.male1,
    spriteFolder: 'male1_sprite',
    price: 0,
    sellRefund: 0,
    isDefaultUnlocked: true,
    charSelectIdlePath: 'assets/images/male1_sprite/male_charselectidle.png',
    frontRunPath: 'assets/images/male1_sprite/male_frontrun.png',
    frontSlashPath: 'assets/images/male1_sprite/male_frontslash.png',
    gradientColors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    borderColor: Color(0xFF38BDF8),
    badge: '⚡',
    description: 'Balanced power and agility. The classic court powerhouse.',
  );

  static const CharacterInfo maya = CharacterInfo(
    id: 'maya_speed',
    name: 'Maya Swift',
    title: 'Agile Volleyer',
    type: CharacterType.female1,
    spriteFolder: 'female1_sprite',
    price: 0,
    sellRefund: 0,
    isDefaultUnlocked: true,
    charSelectIdlePath: 'assets/images/female1_sprite/female_charselectidle.png',
    frontRunPath: 'assets/images/female1_sprite/female_runfront.png',
    frontSlashPath: 'assets/images/female1_sprite/female_frontslash.png',
    gradientColors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    borderColor: Color(0xFFC084FC),
    badge: '✨',
    description: 'Lightning-fast footwork with razor-sharp reflexes.',
  );

  static const CharacterInfo marcus = CharacterInfo(
    id: 'male2_blaze',
    name: 'Marcus Blaze',
    title: 'Fire Striker',
    type: CharacterType.male2,
    spriteFolder: 'male2_sprite',
    price: 0,
    sellRefund: 0,
    isDefaultUnlocked: true,
    charSelectIdlePath: 'assets/images/male2_sprite/male2_charselectidle.png',
    frontRunPath: 'assets/images/male2_sprite/male2_frontrun.png',
    frontSlashPath: 'assets/images/male2_sprite/male2_frontslash.png',
    gradientColors: [Color(0xFFEA580C), Color(0xFFC2410C)],
    borderColor: Color(0xFFF97316),
    badge: '🔥',
    description: 'Fiery aggressive shots and explosive topspin drives.',
  );

  static const CharacterInfo jax = CharacterInfo(
    id: 'male3_thunder',
    name: 'Jax Thunder',
    title: 'Thunder Smasher',
    type: CharacterType.male3,
    spriteFolder: 'male3_sprite',
    price: 0,
    sellRefund: 0,
    isDefaultUnlocked: true,
    charSelectIdlePath: 'assets/images/male3_sprite/male3_charselectidle.png',
    frontRunPath: 'assets/images/male3_sprite/male3_frontrun.png',
    frontSlashPath: 'assets/images/male3_sprite/male3_frontslash.png',
    gradientColors: [Color(0xFF0D9488), Color(0xFF0F766E)],
    borderColor: Color(0xFF2DD4BF),
    badge: '⚡',
    description: 'Devastating overhead smashes and lightning service aces.',
  );

  static const CharacterInfo chloe = CharacterInfo(
    id: 'female2_frost',
    name: 'Princess-Joy',
    title: 'Spin Specialist',
    type: CharacterType.female2,
    spriteFolder: 'female2_sprite',
    price: 0,
    sellRefund: 0,
    isDefaultUnlocked: true,
    charSelectIdlePath: 'assets/images/female2_sprite/female2_charselectidle.png',
    frontRunPath: 'assets/images/female2_sprite/female2_frontrun.png',
    frontSlashPath: 'assets/images/female2_sprite/female2_frontslash.png',
    gradientColors: [Color(0xFFEC4899), Color(0xFFBE185D)],
    borderColor: Color(0xFFF472B6),
    badge: '💎',
    description: 'Deceptive spin curves and razor-sharp sideline placement.',
  );

  static const CharacterInfo female3 = CharacterInfo(
    id: 'female3',
    name: 'Disneykirk',
    title: 'Surge Striker',
    type: CharacterType.female3,
    spriteFolder: 'female3_sprite',
    price: 0,
    sellRefund: 0,
    isDefaultUnlocked: true,
    charSelectIdlePath: 'assets/images/female3_sprite/female3_charselectidle.png',
    frontRunPath: 'assets/images/female3_sprite/female3_frontrun.png',
    frontSlashPath: 'assets/images/female3_sprite/female3_frontslash.png',
    gradientColors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
    borderColor: Color(0xFF60A5FA),
    badge: '🌊',
    description: 'Electric court agility with high-velocity drive shots and sharp angle smashes.',
  );

  static const CharacterInfo nard = CharacterInfo(
    id: 'male4_nard',
    name: 'Nard',
    title: 'Precision Ace',
    type: CharacterType.male4,
    spriteFolder: 'male4_sprite',
    price: 0,
    sellRefund: 0,
    isDefaultUnlocked: true,
    charSelectIdlePath: 'assets/images/male4_sprite/male4_charselectidle.png',
    frontRunPath: 'assets/images/male4_sprite/male4_frontrun.png',
    frontSlashPath: 'assets/images/male4_sprite/male4_frontslash.png',
    gradientColors: [Color(0xFF0284C7), Color(0xFF0369A1)],
    borderColor: Color(0xFF38BDF8),
    badge: '🎯',
    description: 'Pinpoint laser precision with lightning baseline drives and relentless stamina.',
  );

  static const CharacterInfo ashley = CharacterInfo(
    id: 'female4_ashley',
    name: 'Ashley',
    title: 'Shadow Striker',
    type: CharacterType.female4,
    spriteFolder: 'female4_sprite',
    price: 0,
    sellRefund: 0,
    isDefaultUnlocked: true,
    charSelectIdlePath: 'assets/images/female4_sprite/female4_charselectidle.png',
    frontRunPath: 'assets/images/female4_sprite/female4_frontrun.png',
    frontSlashPath: 'assets/images/female4_sprite/female4_frontslash.png',
    gradientColors: [Color(0xFF9333EA), Color(0xFF7E22CE)],
    borderColor: Color(0xFFA855F7),
    badge: '⚡',
    description: 'Dynamic kinetic burst speed with swift kitchen resets and devastating angled smashes.',
  );

  static const List<CharacterInfo> allCharacters = [
    alex,
    maya,
    marcus,
    jax,
    chloe,
    female3,
    nard,
    ashley,
  ];

  static CharacterInfo getById(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('female4') || lower.contains('ashley')) return ashley;
    if (lower.contains('male4') || lower.contains('nard')) return nard;
    if (lower.contains('female3') || lower.contains('disneykirk') || lower.contains('disney')) return female3;
    if (lower.contains('female2') || lower.contains('chloe') || lower.contains('frost') || lower.contains('princess') || lower.contains('joy')) return chloe;
    if (lower.contains('male3') || lower.contains('jax')) return jax;
    if (lower.contains('male2') || lower.contains('marcus')) return marcus;
    if (lower.contains('maya')) return maya;
    return alex;
  }

  static CharacterInfo getByType(CharacterType type) {
    switch (type) {
      case CharacterType.female1:
        return maya;
      case CharacterType.female2:
        return chloe;
      case CharacterType.female3:
        return female3;
      case CharacterType.female4:
        return ashley;
      case CharacterType.male2:
        return marcus;
      case CharacterType.male3:
        return jax;
      case CharacterType.male4:
        return nard;
      case CharacterType.male1:
        return alex;
    }
  }
}
