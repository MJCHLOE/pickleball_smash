import 'package:flutter/material.dart';

/// Represents a player profile picture / avatar.
/// Supports built-in character presets, custom user photo URLs / file paths,
/// and customizable avatar studio payloads.
class PlayerAvatar {
  final String id;
  final String name;
  final String title;
  final String badge;
  final List<Color> gradientColors;
  final Color borderColor;
  final IconData icon;
  final String? assetPath;
  final String? customImageUrl;
  final String? initials;
  final bool isCustom;

  const PlayerAvatar({
    required this.id,
    required this.name,
    required this.title,
    required this.badge,
    required this.gradientColors,
    required this.borderColor,
    required this.icon,
    this.assetPath,
    this.customImageUrl,
    this.initials,
    this.isCustom = false,
  });

  /// Catalog of player preset avatars
  static const List<PlayerAvatar> presetAvatars = [
    PlayerAvatar(
      id: 'alex_classic',
      name: 'Alex Smash',
      title: 'Power Smasher',
      badge: '⚡',
      gradientColors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      borderColor: Color(0xFF38BDF8),
      icon: Icons.sports_tennis_rounded,
      assetPath: 'assets/images/male1_sprite/male_charselectidle.png',
    ),
    PlayerAvatar(
      id: 'maya_speed',
      name: 'Maya Swift',
      title: 'Agile Volleyer',
      badge: '✨',
      gradientColors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      borderColor: Color(0xFFC084FC),
      icon: Icons.flash_on_rounded,
      assetPath: 'assets/images/female1_sprite/female_runfront.png',
    ),
    PlayerAvatar(
      id: 'leo_spin',
      name: 'Leo Spin',
      title: 'Topspin Master',
      badge: '🌀',
      gradientColors: [Color(0xFF0D9488), Color(0xFF0F766E)],
      borderColor: Color(0xFF2DD4BF),
      icon: Icons.rotate_right_rounded,
    ),
    PlayerAvatar(
      id: 'jordan_power',
      name: 'Jordan Ace',
      title: 'Baseline Cannon',
      badge: '🔥',
      gradientColors: [Color(0xFFDC2626), Color(0xFF991B1B)],
      borderColor: Color(0xFFF87171),
      icon: Icons.local_fire_department_rounded,
    ),
    PlayerAvatar(
      id: 'sophia_queen',
      name: 'Queen Sophia',
      title: 'Court Strategist',
      badge: '👑',
      gradientColors: [Color(0xFFDB2777), Color(0xFF9D174D)],
      borderColor: Color(0xFFF472B6),
      icon: Icons.military_tech_rounded,
    ),
    PlayerAvatar(
      id: 'kai_cyber',
      name: 'Kai Cyber',
      title: 'Precision Striker',
      badge: '🤖',
      gradientColors: [Color(0xFF059669), Color(0xFF047857)],
      borderColor: Color(0xFF34D399),
      icon: Icons.precision_manufacturing_rounded,
    ),
    PlayerAvatar(
      id: 'sam_titan',
      name: 'Sam Titan',
      title: 'Wall of Defense',
      badge: '🛡️',
      gradientColors: [Color(0xFFD97706), Color(0xFFB45309)],
      borderColor: Color(0xFFFBBF24),
      icon: Icons.shield_rounded,
    ),
    PlayerAvatar(
      id: 'nova_legend',
      name: 'Nova Legend',
      title: 'Cosmic Grandmaster',
      badge: '🌌',
      gradientColors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
      borderColor: Color(0xFF818CF8),
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  /// Opponent tournament bots catalog
  static const Map<String, PlayerAvatar> opponentAvatars = {
    'ben dinker': PlayerAvatar(
      id: 'ben_dinker',
      name: 'Ben Dinker',
      title: 'Kitchen Specialist',
      badge: '🥉',
      gradientColors: [Color(0xFF0284C7), Color(0xFF0369A1)],
      borderColor: Color(0xFF38BDF8),
      icon: Icons.sports_tennis_rounded,
    ),
    'sarah spin': PlayerAvatar(
      id: 'sarah_spin',
      name: 'Sarah Spin',
      title: 'Slice Maestro',
      badge: '🌀',
      gradientColors: [Color(0xFF9333EA), Color(0xFF7E22CE)],
      borderColor: Color(0xFFA855F7),
      icon: Icons.change_circle_rounded,
    ),
    'sammy smash': PlayerAvatar(
      id: 'sammy_smash',
      name: 'Sammy Smash',
      title: 'High Jumper',
      badge: '⚡',
      gradientColors: [Color(0xFFE11D48), Color(0xFFBE123C)],
      borderColor: Color(0xFFFB7185),
      icon: Icons.bolt_rounded,
    ),
    'rocky lob': PlayerAvatar(
      id: 'rocky_lob',
      name: 'Rocky Lob',
      title: 'Deep Court Specialist',
      badge: '🥈',
      gradientColors: [Color(0xFFD97706), Color(0xFFB45309)],
      borderColor: Color(0xFFFBBF24),
      icon: Icons.landscape_rounded,
    ),
    'max volley': PlayerAvatar(
      id: 'max_volley',
      name: 'Max Volley',
      title: 'Net Controller',
      badge: '🎯',
      gradientColors: [Color(0xFF16A34A), Color(0xFF15803D)],
      borderColor: Color(0xFF4ADE80),
      icon: Icons.adjust_rounded,
    ),
    'chloe ace': PlayerAvatar(
      id: 'chloe_ace',
      name: 'Chloe Ace',
      title: 'Service Ace Queen',
      badge: '⭐',
      gradientColors: [Color(0xFFC026D3), Color(0xFFA21CAF)],
      borderColor: Color(0xFFE879F9),
      icon: Icons.star_rounded,
    ),
    'iron paddle': PlayerAvatar(
      id: 'iron_paddle',
      name: 'Iron Paddle',
      title: 'Heavy Blocker',
      badge: '🥇',
      gradientColors: [Color(0xFF475569), Color(0xFF334155)],
      borderColor: Color(0xFF94A3B8),
      icon: Icons.shield_rounded,
    ),
    'viper vance': PlayerAvatar(
      id: 'viper_vance',
      name: 'Viper Vance',
      title: 'Speed Counterer',
      badge: '🐍',
      gradientColors: [Color(0xFF047857), Color(0xFF065F46)],
      borderColor: Color(0xFF10B981),
      icon: Icons.electric_bolt_rounded,
    ),
    'the pickle king': PlayerAvatar(
      id: 'the_pickle_king',
      name: 'The Pickle King',
      title: 'World Undefeated Champion',
      badge: '👑',
      gradientColors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
      borderColor: Color(0xFFFDE047),
      icon: Icons.emoji_events_rounded,
    ),
  };

  /// Factory resolving any avatar id (presets, opponents, custom photo URLs, or custom avatar studio codes)
  static PlayerAvatar getById(String? rawId) {
    if (rawId == null || rawId.trim().isEmpty) {
      return presetAvatars.first;
    }

    final id = rawId.trim();

    // 1. Check custom photo URL / file path
    if (id.startsWith('http://') ||
        id.startsWith('https://') ||
        id.startsWith('file://') ||
        id.startsWith('data:image') ||
        id.contains(':\\') ||
        id.contains(':/')) {
      return PlayerAvatar(
        id: id,
        name: 'Custom Photo',
        title: 'Player Upload',
        badge: '📷',
        gradientColors: const [Color(0xFF1E293B), Color(0xFF0F172A)],
        borderColor: const Color(0xFF38BDF8),
        icon: Icons.camera_alt_rounded,
        customImageUrl: id,
        isCustom: true,
      );
    }

    // 2. Check custom avatar studio payload: custom:initials:iconIndex:colorIndex
    if (id.startsWith('custom:')) {
      return _parseCustomAvatar(id);
    }

    // 3. Check presets
    for (final p in presetAvatars) {
      if (p.id == id) return p;
    }

    // 4. Check opponent bots
    for (final o in opponentAvatars.values) {
      if (o.id == id) return o;
    }

    // Fallback
    return presetAvatars.first;
  }

  /// Get signature avatar for an opponent name
  static PlayerAvatar getForOpponent(String opponentName) {
    final lower = opponentName.toLowerCase().trim();
    if (opponentAvatars.containsKey(lower)) {
      return opponentAvatars[lower]!;
    }
    // Check partial match
    for (final entry in opponentAvatars.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }
    // Generic CPU Challenger
    return const PlayerAvatar(
      id: 'cpu_challenger',
      name: 'CPU Challenger',
      title: 'Practice Opponent',
      badge: '🤖',
      gradientColors: [Color(0xFF374151), Color(0xFF1F2937)],
      borderColor: Color(0xFF9CA3AF),
      icon: Icons.smart_toy_rounded,
    );
  }

  static PlayerAvatar _parseCustomAvatar(String code) {
    final parts = code.split(':');
    final initials = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'ME';
    final iconIdx = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    final colorIdx = parts.length > 3 ? int.tryParse(parts[3]) ?? 0 : 0;

    final icons = [
      Icons.sports_tennis_rounded,
      Icons.bolt_rounded,
      Icons.star_rounded,
      Icons.local_fire_department_rounded,
      Icons.military_tech_rounded,
      Icons.rocket_launch_rounded,
      Icons.shield_rounded,
      Icons.auto_awesome_rounded,
    ];

    final colorPalettes = [
      [const Color(0xFF2563EB), const Color(0xFF1D4ED8)], // Blue
      [const Color(0xFF16A34A), const Color(0xFF15803D)], // Green
      [const Color(0xFFDC2626), const Color(0xFF991B1B)], // Red
      [const Color(0xFF7C3AED), const Color(0xFF5B21B6)], // Purple
      [const Color(0xFFD97706), const Color(0xFFB45309)], // Amber
      [const Color(0xFF0D9488), const Color(0xFF0F766E)], // Teal
      [const Color(0xFFDB2777), const Color(0xFF9D174D)], // Pink
      [const Color(0xFF090D16), const Color(0xFF1E293B)], // Dark Noir
    ];

    final palette = colorPalettes[colorIdx % colorPalettes.length];
    final selectedIcon = icons[iconIdx % icons.length];

    return PlayerAvatar(
      id: code,
      name: '$initials (Custom)',
      title: 'Custom Creator Avatar',
      badge: '🎨',
      gradientColors: palette,
      borderColor: palette.first,
      icon: selectedIcon,
      initials: initials,
      isCustom: true,
    );
  }
}

