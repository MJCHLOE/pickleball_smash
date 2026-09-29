import 'package:flutter/material.dart';

enum CourtEnvironment {
  stadium,
  beach,
  cyber,
  forest,
  magma,
}

class CourtInfo {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final int price; // in coins (0 for default unlocked)
  final bool isDefaultUnlocked;
  final String badge;
  final CourtEnvironment environment;
  final Color courtColor;
  final Color kitchenColor;
  final Color apronColor;
  final Color apronOuterColor;
  final Color lineColor;
  final Color netTapeColor;
  final Color netMeshColor;
  final Color benchColor;
  final Color accentColor;
  final List<Color> previewGradient;

  const CourtInfo({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.price,
    this.isDefaultUnlocked = false,
    required this.badge,
    required this.environment,
    required this.courtColor,
    required this.kitchenColor,
    required this.apronColor,
    required this.apronOuterColor,
    this.lineColor = Colors.white,
    this.netTapeColor = Colors.white,
    this.netMeshColor = const Color(0xFF1F2937),
    this.benchColor = const Color(0xFFD97706),
    required this.accentColor,
    required this.previewGradient,
  });

  bool get isPurchasable => price > 0;
}

class CourtCatalog {
  // 1. Classic Pro Arena - Official championship tournament indoor arena (Free)
  static const CourtInfo proStadium = CourtInfo(
    id: 'court_pro_stadium',
    name: 'Classic Pro Arena',
    subtitle: 'Championship Indoor Stadium',
    description: 'Official Smash League tournament arena with sapphire acrylic courts and ruby red aprons.',
    price: 0,
    isDefaultUnlocked: true,
    badge: '🏟️',
    environment: CourtEnvironment.stadium,
    courtColor: Color(0xFF1D4ED8),       // Deep sapphire blue
    kitchenColor: Color(0xFF047857),     // Tournament emerald NVZ
    apronColor: Color(0xFFB90225),       // Ruby red apron
    apronOuterColor: Color(0xFF7A0114),  // Deep red stadium floor
    lineColor: Colors.white,
    netTapeColor: Colors.white,
    netMeshColor: Color(0xFF1F2937),
    benchColor: Color(0xFFD97706),       // Oak wood player benches
    accentColor: Color(0xFF38BDF8),
    previewGradient: [Color(0xFF1D4ED8), Color(0xFF047857), Color(0xFFB90225)],
  );

  // 2. Sunset Beach Resort - Tropical coastal sand court with palm trees and ocean vibes
  static const CourtInfo beachResort = CourtInfo(
    id: 'court_beach_resort',
    name: 'Sunset Beach Resort',
    subtitle: 'Tropical Oceanfront Boardwalk',
    description: 'Breezy tropical sand court with coral-teal surface, wooden boardwalk borders, and coastal palm scenery.',
    price: 1500,
    isDefaultUnlocked: false,
    badge: '🏖️',
    environment: CourtEnvironment.beach,
    courtColor: Color(0xFF0D9488),       // Caribbean ocean teal
    kitchenColor: Color(0xFFEA580C),     // Warm coral sunset orange
    apronColor: Color(0xFFD4A373),       // Golden beach sand
    apronOuterColor: Color(0xFFBC8A5F),  // Wet coastal shore sand
    lineColor: Color(0xFFFFFBEB),        // Warm sand-white boundary lines
    netTapeColor: Color(0xFFFEF08A),     // Sunlit white-yellow tape
    netMeshColor: Color(0xFF78350F),     // Nautical rope mesh
    benchColor: Color(0xFFA16207),       // Weathered teak boardwalk benches
    accentColor: Color(0xFFFBBF24),
    previewGradient: [Color(0xFF0D9488), Color(0xFFEA580C), Color(0xFFD4A373)],
  );

  // 3. Neon Cyber Arcade - Synthwave cyberpunk grid with glowing laser lines
  static const CourtInfo cyberArcade = CourtInfo(
    id: 'court_cyber_arcade',
    name: 'Neon Cyber Arcade',
    subtitle: 'Synthwave Digital Arena',
    description: 'High-octane retro 80s arcade court with pulsing laser grid lines, electric violet surface, and neon cyan accents.',
    price: 1800,
    isDefaultUnlocked: false,
    badge: '🕹️',
    environment: CourtEnvironment.cyber,
    courtColor: Color(0xFF581C87),       // Deep cyber purple
    kitchenColor: Color(0xFFBE185D),     // Electric magenta NVZ
    apronColor: Color(0xFF180B2E),       // Obsidian dark synthwave floor
    apronOuterColor: Color(0xFF0B0416),  // Deep abyss floor
    lineColor: Color(0xFF00E5FF),        // Laser electric cyan lines
    netTapeColor: Color(0xFFFF007F),     // Hot laser pink tape
    netMeshColor: Color(0xFF00E5FF),     // Glowing cyan mesh
    benchColor: Color(0xFF7C3AED),       // Cyber metallic benches
    accentColor: Color(0xFF00E5FF),
    previewGradient: [Color(0xFF581C87), Color(0xFFBE185D), Color(0xFF00E5FF)],
  );

  // 4. Emerald Forest Park - Lush outdoor woodland court surrounded by nature
  static const CourtInfo forestPark = CourtInfo(
    id: 'court_forest_park',
    name: 'Emerald Forest Park',
    subtitle: 'Lush Woodland Sanctuary',
    description: 'Scenic outdoor park court nestled among giant pine trees with mossy stone pavers and natural timber wood rails.',
    price: 2200,
    isDefaultUnlocked: false,
    badge: '🌲',
    environment: CourtEnvironment.forest,
    courtColor: Color(0xFF166534),       // Evergreen pine court
    kitchenColor: Color(0xFF854D0E),     // Rustic amber-brown earth NVZ
    apronColor: Color(0xFF14532D),       // Deep woodland grass apron
    apronOuterColor: Color(0xFF052E16),  // Dark forest soil perimeter
    lineColor: Color(0xFFF0FDF4),        // Crisp alpine chalk white
    netTapeColor: Color(0xFFFEF3C7),     // Natural linen tape
    netMeshColor: Color(0xFF1C1917),     // Dark stone mesh
    benchColor: Color(0xFF78350F),       // Cedar log benches
    accentColor: Color(0xFF4ADE80),
    previewGradient: [Color(0xFF166534), Color(0xFF854D0E), Color(0xFF14532D)],
  );

  // 5. Volcanic Magma Stadium - Fiery subterranean court with glowing lava borders
  static const CourtInfo magmaStadium = CourtInfo(
    id: 'court_magma_stadium',
    name: 'Volcanic Magma Stadium',
    subtitle: 'Inferno Caldera Arena',
    description: 'Intense subterranean volcano court with cooling basalt obsidian floors, molten lava veins, and fiery orange lines.',
    price: 2800,
    isDefaultUnlocked: false,
    badge: '🌋',
    environment: CourtEnvironment.magma,
    courtColor: Color(0xFF7F1D1D),       // Scorched volcanic crimson
    kitchenColor: Color(0xFFC2410C),     // Fiery molten magma orange
    apronColor: Color(0xFF261010),       // Obsidian basalt rock apron
    apronOuterColor: Color(0xFF140707),  // Dark volcanic abyss
    lineColor: Color(0xFFFFEDD5),        // Blazing heat-white lines
    netTapeColor: Color(0xFFFB923C),     // Flame-glowing net tape
    netMeshColor: Color(0xFF450A0A),     // Charcoal steel mesh
    benchColor: Color(0xFF991B1B),       // Forged iron benches
    accentColor: Color(0xFFF97316),
    previewGradient: [Color(0xFF7F1D1D), Color(0xFFC2410C), Color(0xFFF97316)],
  );

  static const List<CourtInfo> allCourts = [
    proStadium,
    beachResort,
    cyberArcade,
    forestPark,
    magmaStadium,
  ];

  static CourtInfo getById(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('beach')) return beachResort;
    if (lower.contains('cyber') || lower.contains('neon')) return cyberArcade;
    if (lower.contains('forest') || lower.contains('park') || lower.contains('green')) return forestPark;
    if (lower.contains('magma') || lower.contains('lava') || lower.contains('volcano') || lower.contains('clay')) return magmaStadium;
    return proStadium;
  }
}

