import 'package:flutter/material.dart';
import '../models/character_roster.dart';
import 'animated_character_display.dart';

/// Reusable arcade character feature card matching the dashboard presentation.
/// Features:
/// - Distinctive top character badge: `[badge] [NAME] • [TITLE] ⇄` with gradient background & glow border
/// - Pixel spotlight with dynamic character border color glow
/// - Authentic interactive pixel-art character sprite holding paddle with "TAP TO SMASH"
/// - Idle, Run, and Smash animations with power smash impact feedback
/// - Action switcher controls and character swap callbacks
class DashboardCharacterCardFeature extends StatelessWidget {
  final CharacterInfo character;
  final double height;
  final bool showBadge;
  final bool showSwapIcon;
  final VoidCallback? onBadgeTap;
  final bool showSpotlight;
  final bool showCharacterSwitcher;
  final bool showActionControls;
  final ValueChanged<CharacterGender>? onGenderChanged;
  final VoidCallback? onSmashTriggered;
  final Widget? bottomActionWidget;

  const DashboardCharacterCardFeature({
    super.key,
    required this.character,
    this.height = 165,
    this.showBadge = true,
    this.showSwapIcon = true,
    this.onBadgeTap,
    this.showSpotlight = true,
    this.showCharacterSwitcher = false,
    this.showActionControls = true,
    this.onGenderChanged,
    this.onSmashTriggered,
    this.bottomActionWidget,
  });

  @override
  Widget build(BuildContext context) {
    final gender = AnimatedCharacterDisplay.genderFromType(character.type);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── 1. Top Character Badge Pill ──────────────────────────────────────
        if (showBadge)
          InkWell(
            onTap: onBadgeTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: character.gradientColors),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: character.borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: character.borderColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(character.badge, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '${character.name.toUpperCase()} • ${character.title.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (showSwapIcon) ...[
                    const SizedBox(width: 5),
                    const Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 15),
                  ],
                ],
              ),
            ),
          ),

        // ── 2. Pixel Spotlight & Animated Character Display ──────────────────
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (showSpotlight)
              Positioned(
                bottom: showActionControls || showCharacterSwitcher ? 40 : 4,
                child: Container(
                  width: 140,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: character.borderColor.withValues(alpha: 0.35),
                        blurRadius: 26,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),

            AnimatedCharacterDisplay(
              key: ValueKey('dash_feature_char_${character.id}'),
              initialGender: gender,
              height: height,
              showControls: showCharacterSwitcher || showActionControls,
              showCharacterSwitcher: showCharacterSwitcher,
              showActionControls: showActionControls,
              onSmashTriggered: onSmashTriggered,
              onGenderChanged: onGenderChanged,
            ),
          ],
        ),

        // ── 3. Bottom Optional Action Widget ────────────────────────────────
        if (bottomActionWidget != null) ...[
          const SizedBox(height: 10),
          bottomActionWidget!,
        ],
      ],
    );
  }
}
