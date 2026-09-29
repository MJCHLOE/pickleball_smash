import 'package:flutter/material.dart';

enum BallTier {
  elite,
  special,
  epic,
  mythic,
  legendary,
}

class BallInfo {
  final String id;
  final String name;
  final BallTier tier;
  final String tierName;
  final int price; // in coins (0 for default unlocked)
  final bool isDefaultUnlocked;
  final String badge;
  final String description;
  final String effectDescription;
  final List<Color> gradientColors;
  final Color holeColor;
  final Color glowColor;
  final Color rippleColor;
  final Color sparkColor;
  final Color badgeBgColor;

  const BallInfo({
    required this.id,
    required this.name,
    required this.tier,
    required this.tierName,
    required this.price,
    this.isDefaultUnlocked = false,
    required this.badge,
    required this.description,
    required this.effectDescription,
    required this.gradientColors,
    required this.holeColor,
    required this.glowColor,
    required this.rippleColor,
    required this.sparkColor,
    required this.badgeBgColor,
  });

  bool get isPurchasable => price > 0;
}

class BallCatalog {
  // 1. Elite Ball - Tournament Precision Neon Chartreuse (Free)
  static const BallInfo elite = BallInfo(
    id: 'ball_elite',
    name: 'Elite Ball',
    tier: BallTier.elite,
    tierName: 'ELITE',
    price: 0,
    isDefaultUnlocked: true,
    badge: '⚡',
    description: 'Tournament-grade precision chartreuse pickleball with crisp aerodynamic balance.',
    effectDescription: 'Neon Green Precision Trail & Impact Starburst',
    gradientColors: [Color(0xFFE8FF59), Color(0xFFCCFF00), Color(0xFF99CC00)],
    holeColor: Color(0xFF7CB305),
    glowColor: Color(0xFFCCFF00),
    rippleColor: Color(0xFF76FF03),
    sparkColor: Color(0xFFFFFF00),
    badgeBgColor: Color(0xFF65A30D),
  );

  // 2. Special Ball - Electric Azure & Cyan Plasma (1,200 Coins)
  static const BallInfo special = BallInfo(
    id: 'ball_special',
    name: 'Special Ball',
    tier: BallTier.special,
    tierName: 'SPECIAL',
    price: 1200,
    isDefaultUnlocked: false,
    badge: '💎',
    description: 'Ionized plasma pickleball that crackles with concentrated electric charge in flight.',
    effectDescription: 'Electric Cyan Pulse Trail & Lightning Shockwave',
    gradientColors: [Color(0xFFA5F3FC), Color(0xFF00E5FF), Color(0xFF0284C7)],
    holeColor: Color(0xFF0891B2),
    glowColor: Color(0xFF00E5FF),
    rippleColor: Color(0xFF38BDF8),
    sparkColor: Color(0xFF67E8F9),
    badgeBgColor: Color(0xFF0284C7),
  );

  // 3. Epic Ball - Blazing Molten Inferno (1,800 Coins)
  static const BallInfo epic = BallInfo(
    id: 'ball_epic',
    name: 'Epic Ball',
    tier: BallTier.epic,
    tierName: 'EPIC',
    price: 1800,
    isDefaultUnlocked: false,
    badge: '🔥',
    description: 'Forged in subterranean magma vents, leaving burning thermal trails on every smash.',
    effectDescription: 'Molten Flame Trail & Fiery Ember Bursts',
    gradientColors: [Color(0xFFFED7AA), Color(0xFFFF5722), Color(0xFFDC2626)],
    holeColor: Color(0xFF991B1B),
    glowColor: Color(0xFFFF5722),
    rippleColor: Color(0xFFF97316),
    sparkColor: Color(0xFFFFA000),
    badgeBgColor: Color(0xFFEA580C),
  );

  // 4. Mythic Ball - Celestial Cosmic Void (2,400 Coins)
  static const BallInfo mythic = BallInfo(
    id: 'ball_mythic',
    name: 'Mythic Ball',
    tier: BallTier.mythic,
    tierName: 'MYTHIC',
    price: 2400,
    isDefaultUnlocked: false,
    badge: '🌌',
    description: 'Enchanted cosmic orb infused with astral starlight and anti-gravity quantum particles.',
    effectDescription: 'Astral Galaxy Violet Trail & Starlight Sparks',
    gradientColors: [Color(0xFFF0ABFC), Color(0xFFA855F7), Color(0xFF581C87)],
    holeColor: Color(0xFF3B0764),
    glowColor: Color(0xFFA855F7),
    rippleColor: Color(0xFFC084FC),
    sparkColor: Color(0xFFF472B6),
    badgeBgColor: Color(0xFF9333EA),
  );

  // 5. Legendary Ball - 24K Radiant Solar Gold (3,000 Coins)
  static const BallInfo legendary = BallInfo(
    id: 'ball_legendary',
    name: 'Legendary Ball',
    tier: BallTier.legendary,
    tierName: 'LEGENDARY',
    price: 3000,
    isDefaultUnlocked: false,
    badge: '👑',
    description: 'Masterwork pure solid gold sphere that glints with blinding solar flares and royal majesty.',
    effectDescription: 'Radiant 24K Solar Flare Trail & Golden Shockwave',
    gradientColors: [Color(0xFFFEF08A), Color(0xFFFFD700), Color(0xFFB45309)],
    holeColor: Color(0xFF78350F),
    glowColor: Color(0xFFFFD700),
    rippleColor: Color(0xFFFBBF24),
    sparkColor: Color(0xFFFFFBEB),
    badgeBgColor: Color(0xFFD97706),
  );

  static const List<BallInfo> allBalls = [
    elite,
    special,
    epic,
    mythic,
    legendary,
  ];

  static BallInfo getById(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('legendary') || lower.contains('gold')) return legendary;
    if (lower.contains('mythic') || lower.contains('cosmic') || lower.contains('void')) return mythic;
    if (lower.contains('epic') || lower.contains('fire') || lower.contains('flame')) return epic;
    if (lower.contains('special') || lower.contains('cyan') || lower.contains('plasma') || lower.contains('blue')) return special;
    return elite;
  }
}

