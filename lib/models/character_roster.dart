import 'package:flutter/material.dart';

enum CharacterType {
  male1,
  female1,
  male2,
  male3,
  female2,
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

  bool get isMale => type != CharacterType.female1 && type != CharacterType.female2;
  bool get isPurchasable => price > 0;

  String get readyToServePath {
    switch (type) {
      case CharacterType.female1:
        return 'assets/images/female1_sprite/female_p1sideidle.png';
      case CharacterType.female2:
        return 'assets/images/female2_sprite/female2_p1sideidle.png';
      case CharacterType.male2:
        return 'assets/images/male2_sprite/male2_p1sideidle.png';
      case CharacterType.male3:
        return 'assets/images/male3_sprite/male3_p1sideidle.png';
      case CharacterType.male1:
        return 'assets/images/male1_sprite/male_p1sideidle.png';
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
    name: 'Chloe Frost',
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

  static const List<CharacterInfo> allCharacters = [
    alex,
    maya,
    marcus,
    jax,
    chloe,
  ];

  static CharacterInfo getById(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('female2') || lower.contains('chloe') || lower.contains('frost')) return chloe;
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
      case CharacterType.male2:
        return marcus;
      case CharacterType.male3:
        return jax;
      case CharacterType.male1:
        return alex;
    }
  }
}
