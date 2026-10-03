import 'package:flutter/material.dart';
import '../models/ball_catalog.dart';
import '../models/character_roster.dart';
import '../models/court_catalog.dart';
import '../services/audio_service.dart';
import '../services/game_state_manager.dart';
import '../services/multiplayer_service.dart';
import '../theme/app_theme.dart';
import 'game_2d_button.dart';
import 'game_2d_text.dart';
import 'ready_to_serve_character_widget.dart';

/// Pre-Match Loadout Selection Modal
/// Required sequence before starting a match: Character -> Ball -> Court
/// Uses a smooth left/right swipe carousel with the selected item centered
/// and previous/next items partially visible.
class PreMatchLoadoutModal extends StatefulWidget {
  final bool isHost;
  final String? initialCharacterId;
  final String? initialBallId;
  final String? initialCourtId;

  const PreMatchLoadoutModal({
    super.key,
    required this.isHost,
    this.initialCharacterId,
    this.initialBallId,
    this.initialCourtId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required bool isHost,
    String? initialCharacterId,
    String? initialBallId,
    String? initialCourtId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PreMatchLoadoutModal(
        isHost: isHost,
        initialCharacterId: initialCharacterId,
        initialBallId: initialBallId,
        initialCourtId: initialCourtId,
      ),
    );
  }

  @override
  State<PreMatchLoadoutModal> createState() => _PreMatchLoadoutModalState();
}

class _PreMatchLoadoutModalState extends State<PreMatchLoadoutModal> {
  // 0 = Character, 1 = Ball, 2 = Court
  int _currentStep = 0;

  late PageController _charPageCtrl;
  late PageController _ballPageCtrl;
  late PageController _courtPageCtrl;

  late int _selectedCharIdx;
  late int _selectedBallIdx;
  late int _selectedCourtIdx;

  final List<CharacterInfo> _characters = CharacterRoster.allCharacters;
  final List<BallInfo> _balls = BallCatalog.allBalls;
  final List<CourtInfo> _courts = CourtCatalog.allCourts;

  @override
  void initState() {
    super.initState();
    final state = GameStateManager.instance;

    final initialCharId = widget.initialCharacterId ?? state.playerAvatarId;
    _selectedCharIdx = _characters.indexWhere((c) => c.id == initialCharId);
    if (_selectedCharIdx == -1) _selectedCharIdx = 0;

    final initialBallId = widget.initialBallId ?? state.equippedBallId;
    _selectedBallIdx = _balls.indexWhere((b) => b.id == initialBallId);
    if (_selectedBallIdx == -1) _selectedBallIdx = 0;

    final initialCourtId = widget.initialCourtId ?? state.equippedCourtId;
    _selectedCourtIdx = _courts.indexWhere((c) => c.id == initialCourtId);
    if (_selectedCourtIdx == -1) _selectedCourtIdx = 0;

    _charPageCtrl = PageController(initialPage: _selectedCharIdx, viewportFraction: 0.72);
    _ballPageCtrl = PageController(initialPage: _selectedBallIdx, viewportFraction: 0.72);
    _courtPageCtrl = PageController(initialPage: _selectedCourtIdx, viewportFraction: 0.72);
  }

  @override
  void dispose() {
    _charPageCtrl.dispose();
    _ballPageCtrl.dispose();
    _courtPageCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    AudioService.instance.playButtonTap();
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _confirmLoadout();
    }
  }

  void _prevStep() {
    AudioService.instance.playButtonTap();
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _confirmLoadout() async {
    final char = _characters[_selectedCharIdx];
    final ball = _balls[_selectedBallIdx];
    final court = _courts[_selectedCourtIdx];

    AudioService.instance.playServe();
    await MultiplayerService.instance.updateMyLoadout(
      characterId: char.id,
      ballId: ball.id,
      courtId: court.id,
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: const Color(0xFF070B18),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.electricCyan, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricCyan.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag handle & Close header
            _buildTopHeader(),

            // Step Progress Navigation Bar (1. Fighter -> 2. Ball -> 3. Court)
            _buildStepIndicator(),

            const SizedBox(height: 8),

            // Step Description & Privacy Notice Banner
            _buildStepPrivacyBanner(),

            const SizedBox(height: 12),

            // Main Carousel Area with Smooth Left/Right Swipe
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildCurrentCarousel(),
              ),
            ),

            const SizedBox(height: 12),

            // Bottom Navigation Actions (Back / Next / Lock In)
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.electricCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: AppTheme.electricCyan, size: 18),
              ),
              const SizedBox(width: 8),
              const Game2DText(
                'PRE-MATCH LOADOUT',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                textColor: Colors.white,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 22),
            onPressed: () {
              AudioService.instance.playButtonTap();
              Navigator.of(context).pop(false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      {'title': '1. FIGHTER', 'icon': Icons.person_rounded, 'secret': false},
      {'title': '2. BALL', 'icon': Icons.sports_tennis_rounded, 'secret': true},
      {'title': '3. COURT', 'icon': Icons.stadium_rounded, 'secret': true},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length, (idx) {
          final isCurrent = idx == _currentStep;
          final isDone = idx < _currentStep;
          final isSecret = steps[idx]['secret'] as bool;

          Color itemColor = AppTheme.textMuted;
          Color bgColor = Colors.transparent;
          Color borderColor = Colors.transparent;

          if (isCurrent) {
            itemColor = AppTheme.neonLime;
            bgColor = AppTheme.neonLime.withValues(alpha: 0.15);
            borderColor = AppTheme.neonLime;
          } else if (isDone) {
            itemColor = AppTheme.electricCyan;
            bgColor = AppTheme.electricCyan.withValues(alpha: 0.12);
            borderColor = AppTheme.electricCyan.withValues(alpha: 0.4);
          }

          return InkWell(
            onTap: () {
              AudioService.instance.playButtonTap();
              setState(() {
                _currentStep = idx;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDone ? Icons.check_circle_rounded : (steps[idx]['icon'] as IconData),
                    color: itemColor,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    steps[idx]['title'] as String,
                    style: TextStyle(
                      color: itemColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isSecret) ...[
                    const SizedBox(width: 3),
                    const Icon(Icons.lock_rounded, size: 10, color: Color(0xFFFBBF24)),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepPrivacyBanner() {
    String title;
    String subtitle;
    IconData icon;
    Color accentColor;

    if (_currentStep == 0) {
      title = 'STEP 1: CHOOSE YOUR FIGHTER';
      subtitle = '👁️ PUBLIC: Opponent will see your chosen character in lobby';
      icon = Icons.visibility_rounded;
      accentColor = AppTheme.electricCyan;
    } else if (_currentStep == 1) {
      title = 'STEP 2: CHOOSE YOUR BALL';
      subtitle = '🔒 SECRET LOADOUT: Opponent cannot see your ball until match begins!';
      icon = Icons.lock_outline_rounded;
      accentColor = const Color(0xFFFBBF24);
    } else {
      title = 'STEP 3: CHOOSE YOUR COURT';
      subtitle = '🔒 SECRET LOADOUT: Opponent cannot see your court until match begins!';
      icon = Icons.lock_outline_rounded;
      accentColor = const Color(0xFFFBBF24);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentCarousel() {
    switch (_currentStep) {
      case 0:
        return _buildCharacterCarousel(const ValueKey('carousel_step_characters'));
      case 1:
        return _buildBallCarousel(const ValueKey('carousel_step_balls'));
      case 2:
      default:
        return _buildCourtCarousel(const ValueKey('carousel_step_courts'));
    }
  }

  // ---------------------------------------------------------------------------
  // Step 1: Character Swipe Carousel
  // ---------------------------------------------------------------------------

  Widget _buildCharacterCarousel([Key? key]) {
    return _buildCarouselContainer(
      key: key,
      itemCount: _characters.length,
      pageController: _charPageCtrl,
      selectedIndex: _selectedCharIdx,
      onPageChanged: (idx) {
        AudioService.instance.playButtonTap();
        setState(() {
          _selectedCharIdx = idx;
        });
      },
      itemBuilder: (context, idx, isSelected, scale, opacity) {
        final char = _characters[idx];
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: _buildCharacterCard(char, isSelected),
          ),
        );
      },
    );
  }

  Widget _buildCharacterCard(CharacterInfo char, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A),
            char.gradientColors[0].withValues(alpha: 0.35),
            const Color(0xFF0A0F1E),
          ],
        ),
        border: Border.all(
          color: isSelected ? AppTheme.neonLime : char.borderColor.withValues(alpha: 0.4),
          width: isSelected ? 2.5 : 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.neonLime.withValues(alpha: 0.3),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Top Badges: Class Badge & Selection status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: char.borderColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: char.borderColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(char.badge, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        char.title.toUpperCase(),
                        style: TextStyle(
                          color: char.borderColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.neonLime,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 12, color: Colors.black),
                        SizedBox(width: 3),
                        Text(
                          'SELECTED',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Character Large Display: Front-facing sprite holding paddle with radial spotlight
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow aura circle
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          char.borderColor.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Animated front-facing pixel sprite holding paddle
                  ReadyToServeCharacterWidget(
                    character: char,
                    size: 110,
                    action: 'idle',
                  ),
                ],
              ),
            ),
          ),

          // Character Name & Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF090E1B),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  char.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  char.description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Ball Swipe Carousel
  // ---------------------------------------------------------------------------

  Widget _buildBallCarousel([Key? key]) {
    return _buildCarouselContainer(
      key: key,
      itemCount: _balls.length,
      pageController: _ballPageCtrl,
      selectedIndex: _selectedBallIdx,
      onPageChanged: (idx) {
        AudioService.instance.playButtonTap();
        setState(() {
          _selectedBallIdx = idx;
        });
      },
      itemBuilder: (context, idx, isSelected, scale, opacity) {
        final ball = _balls[idx];
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: _buildBallCard(ball, isSelected),
          ),
        );
      },
    );
  }

  Widget _buildBallCard(BallInfo ball, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A),
            ball.glowColor.withValues(alpha: 0.25),
            const Color(0xFF0A0F1E),
          ],
        ),
        border: Border.all(
          color: isSelected ? AppTheme.neonLime : ball.glowColor.withValues(alpha: 0.4),
          width: isSelected ? 2.5 : 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: ball.glowColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Tier & Secret Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ball.badgeBgColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ball.glowColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ball.badge, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        ball.tierName,
                        style: TextStyle(
                          color: ball.glowColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFBBF24), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 10, color: Color(0xFFFBBF24)),
                      SizedBox(width: 4),
                      Text(
                        'HIDDEN',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ball Graphical Visual
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing Glow Aura
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          ball.glowColor.withValues(alpha: 0.4),
                          ball.rippleColor.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Styled Ball Sphere with Perforations
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.3),
                        colors: ball.gradientColors,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ball.glowColor.withValues(alpha: 0.6),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Ball holes
                        Positioned(
                          top: 18,
                          left: 20,
                          child: _buildBallHole(ball.holeColor, 8),
                        ),
                        Positioned(
                          top: 26,
                          right: 18,
                          child: _buildBallHole(ball.holeColor, 7),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 28,
                          child: _buildBallHole(ball.holeColor, 9),
                        ),
                        Positioned(
                          bottom: 22,
                          right: 22,
                          child: _buildBallHole(ball.holeColor, 7),
                        ),
                        Positioned(
                          top: 38,
                          left: 36,
                          child: _buildBallHole(ball.holeColor, 8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ball Info & Visual Trail Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF090E1B),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ball.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.neonLime,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SELECTED',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ball.effectDescription,
                  style: TextStyle(
                    color: ball.glowColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ball.description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBallHole(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Court Swipe Carousel
  // ---------------------------------------------------------------------------

  Widget _buildCourtCarousel([Key? key]) {
    return _buildCarouselContainer(
      key: key,
      itemCount: _courts.length,
      pageController: _courtPageCtrl,
      selectedIndex: _selectedCourtIdx,
      onPageChanged: (idx) {
        AudioService.instance.playButtonTap();
        setState(() {
          _selectedCourtIdx = idx;
        });
      },
      itemBuilder: (context, idx, isSelected, scale, opacity) {
        final court = _courts[idx];
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: _buildCourtCard(court, isSelected),
          ),
        );
      },
    );
  }

  Widget _buildCourtCard(CourtInfo court, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A),
            court.accentColor.withValues(alpha: 0.25),
            const Color(0xFF0A0F1E),
          ],
        ),
        border: Border.all(
          color: isSelected ? AppTheme.neonLime : court.accentColor.withValues(alpha: 0.4),
          width: isSelected ? 2.5 : 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: court.accentColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Environment Badge & Secret Tag
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: court.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: court.accentColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(court.badge, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        court.subtitle.toUpperCase(),
                        style: TextStyle(
                          color: court.accentColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFBBF24), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 10, color: Color(0xFFFBBF24)),
                      SizedBox(width: 4),
                      Text(
                        'HIDDEN',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Court Mini Visual Mockup
          Expanded(
            child: Center(
              child: Container(
                width: 170,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: court.previewGradient,
                  ),
                  border: Border.all(color: court.lineColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: court.accentColor.withValues(alpha: 0.4),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Center Net line
                    Center(
                      child: Container(
                        height: 3,
                        color: court.netTapeColor,
                      ),
                    ),
                    // Kitchen Line
                    Positioned(
                      top: 36,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1.5,
                        color: court.lineColor.withValues(alpha: 0.7),
                      ),
                    ),
                    Positioned(
                      bottom: 36,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1.5,
                        color: court.lineColor.withValues(alpha: 0.7),
                      ),
                    ),
                    // Center court logo seal
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE5A823), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo/court_center_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Court Name & Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF090E1B),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      court.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.neonLime,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SELECTED',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  court.description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable Carousel Frame with Chevrons and Dot Indicators
  // ---------------------------------------------------------------------------

  Widget _buildCarouselContainer({
    Key? key,
    required int itemCount,
    required PageController pageController,
    required int selectedIndex,
    required ValueChanged<int> onPageChanged,
    required Widget Function(BuildContext context, int index, bool isSelected, double scale, double opacity) itemBuilder,
  }) {
    return Column(
      key: key,
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: pageController,
                itemCount: itemCount,
                onPageChanged: onPageChanged,
                itemBuilder: (context, idx) {
                  return AnimatedBuilder(
                    animation: pageController,
                    builder: (context, child) {
                      double page = selectedIndex.toDouble();
                      if (pageController.hasClients && pageController.position.haveDimensions) {
                        page = pageController.page ?? pageController.initialPage.toDouble();
                      }
                      final diff = (idx - page).abs();
                      final scale = (1.0 - (diff * 0.16)).clamp(0.82, 1.0);
                      final opacity = (1.0 - (diff * 0.45)).clamp(0.55, 1.0);
                      final isSelected = idx == selectedIndex;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (pageController.hasClients) {
                            pageController.animateToPage(
                              idx,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          }
                          onPageChanged(idx);
                        },
                        child: itemBuilder(context, idx, isSelected, scale, opacity),
                      );
                    },
                  );
                },
              ),

              // Left chevron button
              if (selectedIndex > 0)
                Positioned(
                  left: 6,
                  child: InkWell(
                    onTap: () {
                      pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),

              // Right chevron button
              if (selectedIndex < itemCount - 1)
                Positioned(
                  right: 6,
                  child: InkWell(
                    onTap: () {
                      pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Carousel Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(itemCount, (dotIdx) {
            final isDotActive = dotIdx == selectedIndex;
            return InkWell(
              onTap: () {
                if (pageController.hasClients) {
                  pageController.animateToPage(
                    dotIdx,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                }
                onPageChanged(dotIdx);
              },
              borderRadius: BorderRadius.circular(3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                width: isDotActive ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isDotActive ? AppTheme.neonLime : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Action Bar (Back / Next / Lock In)
  // ---------------------------------------------------------------------------

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.surfaceBorder, width: 1.5)),
      ),
      child: Row(
        children: [
          // Previous step or cancel button
          if (_currentStep > 0) ...[
            Game2DButton(
              onPressed: _prevStep,
              text: 'BACK',
              icon: Icons.arrow_back_rounded,
              variant: GameButtonVariant.dark,
              size: GameButtonSize.medium,
            ),
            const SizedBox(width: 12),
          ] else ...[
            Game2DButton(
              onPressed: () {
                AudioService.instance.playButtonTap();
                Navigator.of(context).pop(false);
              },
              text: 'CANCEL',
              variant: GameButtonVariant.dark,
              size: GameButtonSize.medium,
            ),
            const SizedBox(width: 12),
          ],

          // Next / Lock In Button
          Expanded(
            child: _currentStep < 2
                ? Game2DButton(
                    onPressed: _nextStep,
                    text: _currentStep == 0 ? 'NEXT: BALL ➔' : 'NEXT: COURT ➔',
                    icon: Icons.arrow_forward_rounded,
                    variant: GameButtonVariant.primary,
                    size: GameButtonSize.medium,
                  )
                : Game2DButton(
                    onPressed: _confirmLoadout,
                    text: widget.isHost ? 'LOCK IN LOADOUT ⚡' : 'LOCK IN & READY ⚡',
                    icon: Icons.check_circle_rounded,
                    variant: GameButtonVariant.primary,
                    size: GameButtonSize.medium,
                  ),
          ),
        ],
      ),
    );
  }
}
