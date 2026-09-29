import 'package:flutter/material.dart';

enum BattleTechnique {
  none,
  leftSpin,   // K: Spin on the left (Cyclone Curve)
  rightSpin,  // L: Spin to the right (Vortex Hook)
  dash,       // Shift / I: Flash Dash / Burst Sprint
}

class TechniqueInfo {
  final BattleTechnique technique;
  final String id;
  final String name;
  final String title;
  final String description;
  final String icon;
  final double cooldownSeconds;
  final Color buttonColor;
  final Color bevelColor;
  final Color glowColor;
  final String hotkey;

  const TechniqueInfo({
    required this.technique,
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.icon,
    required this.cooldownSeconds,
    required this.buttonColor,
    required this.bevelColor,
    required this.glowColor,
    required this.hotkey,
  });
}

class TechniqueCatalog {
  static const TechniqueInfo leftSpin = TechniqueInfo(
    technique: BattleTechnique.leftSpin,
    id: 'left_spin',
    name: 'Cyclone Curve',
    title: 'Left Spin Slice',
    description: 'Wicked curving slice that bends left in the air and kicks sharply off the bounce.',
    icon: '🌪️',
    cooldownSeconds: 6.0,
    buttonColor: Color(0xFF059669), // Emerald Jade
    bevelColor: Color(0xFF047857),
    glowColor: Color(0xFF34D399),
    hotkey: 'K',
  );

  static const TechniqueInfo rightSpin = TechniqueInfo(
    technique: BattleTechnique.rightSpin,
    id: 'right_spin',
    name: 'Vortex Hook',
    title: 'Right Spin Hook',
    description: 'Fierce curving hook shot that bends right in the air and kicks sharply off the bounce.',
    icon: '⚡',
    cooldownSeconds: 6.0,
    buttonColor: Color(0xFF7C3AED), // Electric Violet / Purple Plasma
    bevelColor: Color(0xFF6D28D9),
    glowColor: Color(0xFFA78BFA),
    hotkey: 'L',
  );

  static const TechniqueInfo dash = TechniqueInfo(
    technique: BattleTechnique.dash,
    id: 'flash_dash',
    name: 'Flash Dash',
    title: 'Burst Sprint',
    description: 'Lightning-fast directional sprint to reach distant balls and recover court position.',
    icon: '💨',
    cooldownSeconds: 3.5,
    buttonColor: Color(0xFF0284C7), // Sky Blue / Cyan Burst
    bevelColor: Color(0xFF0369A1),
    glowColor: Color(0xFF38BDF8),
    hotkey: 'SHIFT',
  );

  // Backward compatibility getters
  static TechniqueInfo get thunderDrive => leftSpin;
  static TechniqueInfo get phantomDink => rightSpin;

  static TechniqueInfo get(BattleTechnique technique) {
    switch (technique) {
      case BattleTechnique.leftSpin:
        return leftSpin;
      case BattleTechnique.rightSpin:
        return rightSpin;
      case BattleTechnique.dash:
        return dash;
      case BattleTechnique.none:
        return leftSpin;
    }
  }
}
