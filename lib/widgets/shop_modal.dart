import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ball_catalog.dart';
import '../models/character_roster.dart';
import '../models/court_catalog.dart';
import '../services/audio_service.dart';
import '../services/game_state_manager.dart';
import '../theme/app_theme.dart';
import 'game_2d_button.dart';
import 'game_2d_text.dart';

class ShopModal extends StatefulWidget {
  final int initialTabIndex;

  const ShopModal({
    super.key,
    this.initialTabIndex = 0,
  });

  static Future<void> show(BuildContext context, {int initialTabIndex = 0}) {
    AudioService.instance.playButtonTap();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ShopModal(initialTabIndex: initialTabIndex),
    );
  }

  @override
  State<ShopModal> createState() => _ShopModalState();
}

class _ShopModalState extends State<ShopModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCharacterId;
  String _previewAction = 'idle'; // 'idle', 'run', 'smash'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showNotice(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: isSuccess ? AppTheme.neonLime : const Color(0xFFF97316),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSuccess ? AppTheme.neonLime : const Color(0xFFF97316),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateManager.instance;
    final screenSize = MediaQuery.sizeOf(context);
    final isShortHeight = screenSize.height < 520;
    final dialogWidth = math.min(screenSize.width * 0.96, 820.0);
    final dialogHeight = math.min(screenSize.height * 0.92, 700.0);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: isShortHeight ? 6 : 14,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogWidth,
                maxHeight: dialogHeight,
              ),
              child: Material(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.surfaceBorder, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(context, state),
                      const Divider(color: AppTheme.surfaceBorder, height: 1),

                      // Tabs
                      _buildTabBar(),
                      const Divider(color: AppTheme.surfaceBorder, height: 1),

                      // Tab Views
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildCharactersTab(state),
                            _buildCourtsTab(state),
                            _buildBallsTab(state),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, GameStateManager state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.goldCoin.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldCoin.withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Icon(Icons.storefront_rounded, color: AppTheme.goldCoin, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Game2DText.hero(
                  'SMASH PRO SHOP',
                  fontSize: 18,
                  strokeWidth: 2.5,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Unlock premium characters, courts & balls',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Coin Balance Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF090D16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.goldCoin, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldCoin.withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded, color: AppTheme.goldCoin, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${state.coins}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 22),
            onPressed: () {
              AudioService.instance.playButtonTap();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF0B1120),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.neonLime,
        indicatorWeight: 3,
        labelColor: AppTheme.neonLime,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
        tabs: const [
          Tab(
            icon: Icon(Icons.person_outline_rounded, size: 18),
            text: 'CHARACTERS',
          ),
          Tab(
            icon: Icon(Icons.stadium_outlined, size: 18),
            text: 'COURTS',
          ),
          Tab(
            icon: Icon(Icons.sports_tennis_rounded, size: 18),
            text: 'BALLS',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. CHARACTERS TAB
  // ---------------------------------------------------------------------------
  CharacterInfo _resolveSelectedCharacter(GameStateManager state) {
    final characters = CharacterRoster.allCharacters;
    if (_selectedCharacterId != null) {
      final found = characters.where((c) => c.id == _selectedCharacterId).firstOrNull;
      if (found != null) return found;
    }
    final equipped = characters.where((c) => c.id == state.playerAvatarId).firstOrNull;
    return equipped ?? characters.first;
  }

  Widget _buildFrontViewSprite({
    required String assetPath,
    required int totalFrames,
    int frameIndex = 0,
    required double size,
  }) {
    final factor = 1.0 / totalFrames;
    final alignmentX = totalFrames > 1
        ? -1.0 + 2.0 * (frameIndex.clamp(0, totalFrames - 1) / (totalFrames - 1))
        : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Align(
          alignment: Alignment(alignmentX, 0.0),
          widthFactor: factor,
          child: Image.asset(
            assetPath,
            width: size * totalFrames,
            height: size,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) => const Icon(Icons.person, color: Colors.white, size: 36),
          ),
        ),
      ),
    );
  }

  Widget _buildPoseChip(String label, String action, Color accent) {
    final isSelected = _previewAction == action;
    return InkWell(
      onTap: () {
        AudioService.instance.playButtonTap();
        setState(() {
          _previewAction = action;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.25) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accent : const Color(0xFF334155),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterShowcase(CharacterInfo char, GameStateManager state) {
    final isUnlocked = state.isCharacterUnlocked(char.id);
    final isEquipped = state.playerAvatarId == char.id;

    String currentAsset;
    int currentFrames;
    int currentFrameIndex;

    switch (_previewAction) {
      case 'run':
        currentAsset = char.frontRunPath;
        currentFrames = 8;
        currentFrameIndex = 1;
        break;
      case 'smash':
        currentAsset = char.frontSlashPath;
        currentFrames = 6;
        currentFrameIndex = 2;
        break;
      case 'idle':
      default:
        currentAsset = char.charSelectIdlePath;
        currentFrames = 2;
        currentFrameIndex = 0;
        break;
    }

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: char.borderColor.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: char.borderColor.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: char.borderColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: char.borderColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.remove_red_eye_outlined, color: char.borderColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'FRONT VIEW SPOTLIGHT: ${char.name.toUpperCase()}',
                      style: TextStyle(
                        color: char.borderColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEquipped)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.neonLime.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.neonLime, width: 1),
                  ),
                  child: const Text(
                    'EQUIPPED',
                    style: TextStyle(
                      color: AppTheme.neonLime,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                  ),
                  child: const Text(
                    'UNLOCKED',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      char.borderColor.withValues(alpha: 0.28),
                      const Color(0xFF090D16),
                    ],
                    radius: 0.85,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: char.borderColor.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: 6,
                      child: Container(
                        width: 48,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    _buildFrontViewSprite(
                      assetPath: currentAsset,
                      totalFrames: currentFrames,
                      frameIndex: currentFrameIndex,
                      size: 68,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          char.badge,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            char.title,
                            style: TextStyle(
                              color: char.borderColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      char.description,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildPoseChip('Idle', 'idle', char.borderColor),
                        _buildPoseChip('Run', 'run', char.borderColor),
                        _buildPoseChip('Smash', 'smash', char.borderColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharactersTab(GameStateManager state) {
    final characters = CharacterRoster.allCharacters;
    final selectedChar = _resolveSelectedCharacter(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: _buildCharacterShowcase(selectedChar, state),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: AppTheme.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(
                'CHARACTER ROSTER (TAP TO PREVIEW)',
                style: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: characters.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final char = characters[index];
              final isUnlocked = state.isCharacterUnlocked(char.id);
              final isEquipped = state.playerAvatarId == char.id;
              final isInspected = char.id == selectedChar.id;
              final canAfford = state.coins >= char.price;

              return _buildItemCard(
                key: ValueKey('shop_char_${char.id}'),
                badge: char.badge,
                title: char.name,
                subtitle: char.title,
                description: char.description,
                accentColor: char.borderColor,
                previewWidget: _buildCharacterPreview(char),
                isUnlocked: isUnlocked,
                isEquipped: isEquipped,
                isInspected: isInspected,
                price: char.price,
                canAfford: canAfford,
                onTap: () {
                  AudioService.instance.playButtonTap();
                  setState(() {
                    _selectedCharacterId = char.id;
                  });
                },
                onEquip: () {
                  AudioService.instance.playButtonTap();
                  state.equipCharacter(char.id);
                  _showNotice('Equipped ${char.name}!');
                },
                onBuy: () {
                  if (state.purchaseCharacter(char.id)) {
                    AudioService.instance.playPointScored();
                    _showNotice('Unlocked & equipped ${char.name}!');
                  } else {
                    AudioService.instance.playButtonTap();
                    _showNotice('Need ${char.price - state.coins} more coins to purchase ${char.name}!', isSuccess: false);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterPreview(CharacterInfo char) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: char.gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: char.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: char.borderColor.withValues(alpha: 0.35),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Character Front-View Pixel Sprite (Frame 0 of charselectidle)
            SizedBox(
              width: 58,
              height: 58,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.5,
                  child: Image.asset(
                    char.charSelectIdlePath,
                    width: 116,
                    height: 58,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(char.badge, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
              ),
            ),
            // Badge in bottom-right corner
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: Text(char.badge, style: const TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. COURTS TAB
  // ---------------------------------------------------------------------------
  Widget _buildCourtsTab(GameStateManager state) {
    final courts = CourtCatalog.allCourts;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: courts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final court = courts[index];
        final isUnlocked = state.isCourtUnlocked(court.id);
        final isEquipped = state.equippedCourtId == court.id;
        final canAfford = state.coins >= court.price;

        return _buildItemCard(
          key: ValueKey('shop_court_${court.id}'),
          badge: court.badge,
          title: court.name,
          subtitle: court.subtitle,
          description: court.description,
          accentColor: court.accentColor,
          previewWidget: _buildCourtPreview(court),
          isUnlocked: isUnlocked,
          isEquipped: isEquipped,
          price: court.price,
          canAfford: canAfford,
          onEquip: () {
            AudioService.instance.playButtonTap();
            state.equipCourt(court.id);
            _showNotice('Equipped ${court.name}!');
          },
          onBuy: () {
            if (state.purchaseCourt(court.id)) {
              AudioService.instance.playPointScored();
              _showNotice('Unlocked & equipped ${court.name}!');
            } else {
              AudioService.instance.playButtonTap();
              _showNotice('Need ${court.price - state.coins} more coins to purchase ${court.name}!', isSuccess: false);
            }
          },
        );
      },
    );
  }

  Widget _buildCourtPreview(CourtInfo court) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: court.apronColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: court.accentColor, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simulated 2D court floor
          Container(
            decoration: BoxDecoration(
              color: court.courtColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: court.lineColor.withValues(alpha: 0.8), width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 16,
                decoration: BoxDecoration(
                  color: court.kitchenColor,
                  border: Border(
                    top: BorderSide(color: court.lineColor, width: 1),
                    bottom: BorderSide(color: court.lineColor, width: 1),
                  ),
                ),
              ),
            ),
          ),
          // Badge
          Text(court.badge, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. BALLS TAB
  // ---------------------------------------------------------------------------
  Widget _buildBallsTab(GameStateManager state) {
    final balls = BallCatalog.allBalls;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: balls.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ball = balls[index];
        final isUnlocked = state.isBallUnlocked(ball.id);
        final isEquipped = state.equippedBallId == ball.id;
        final canAfford = state.coins >= ball.price;

        return _buildItemCard(
          key: ValueKey('shop_ball_${ball.id}'),
          badge: ball.badge,
          title: ball.name,
          subtitle: ball.effectDescription,
          description: ball.description,
          accentColor: ball.glowColor,
          previewWidget: _buildBallPreview(ball),
          isUnlocked: isUnlocked,
          isEquipped: isEquipped,
          price: ball.price,
          canAfford: canAfford,
          onEquip: () {
            AudioService.instance.playButtonTap();
            state.equipBall(ball.id);
            _showNotice('Equipped ${ball.name}!');
          },
          onBuy: () {
            if (state.purchaseBall(ball.id)) {
              AudioService.instance.playPointScored();
              _showNotice('Unlocked & equipped ${ball.name}!');
            } else {
              AudioService.instance.playButtonTap();
              _showNotice('Need ${ball.price - state.coins} more coins to purchase ${ball.name}!', isSuccess: false);
            }
          },
        );
      },
    );
  }

  Widget _buildBallPreview(BallInfo ball) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ball.glowColor.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: ball.glowColor.withValues(alpha: 0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.35),
              radius: 0.85,
              colors: ball.gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: ball.glowColor.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Perforations
              for (final offset in [
                const Offset(-6, -6),
                const Offset(6, -6),
                const Offset(-6, 6),
                const Offset(6, 6),
                Offset.zero,
              ])
                Positioned(
                  left: 22 + offset.dx - 2,
                  top: 22 + offset.dy - 2,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ball.holeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED ITEM CARD
  // ---------------------------------------------------------------------------
  Widget _buildItemCard({
    required Key key,
    required String badge,
    required String title,
    required String subtitle,
    required String description,
    required Color accentColor,
    required Widget previewWidget,
    required bool isUnlocked,
    required bool isEquipped,
    required int price,
    required bool canAfford,
    required VoidCallback onEquip,
    required VoidCallback onBuy,
    VoidCallback? onTap,
    bool isInspected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        key: key,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isEquipped
              ? accentColor.withValues(alpha: 0.12)
              : isInspected
                  ? accentColor.withValues(alpha: 0.08)
                  : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isEquipped
                ? accentColor
                : isInspected
                    ? accentColor.withValues(alpha: 0.8)
                    : isUnlocked
                        ? AppTheme.surfaceBorder
                        : const Color(0xFF1E293B),
            width: (isEquipped || isInspected) ? 2 : 1.5,
          ),
          boxShadow: isInspected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            previewWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isEquipped)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.neonLime.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.neonLime, width: 1),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: AppTheme.neonLime,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (isInspected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accentColor.withValues(alpha: 0.7), width: 1),
                          ),
                          child: Text(
                            'PREVIEW',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
          const SizedBox(width: 12),
          // Action Button
          if (isEquipped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.neonLime.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.neonLime, width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: AppTheme.neonLime, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'EQUIPPED',
                    style: TextStyle(
                      color: AppTheme.neonLime,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else if (isUnlocked)
            Game2DButton(
              onPressed: onEquip,
              text: 'EQUIP',
              icon: Icons.check_circle_outline_rounded,
              variant: GameButtonVariant.cyan,
              size: GameButtonSize.small,
            )
          else
            Game2DButton(
              onPressed: onBuy,
              text: '🪙 $price',
              icon: Icons.shopping_bag_outlined,
              variant: canAfford ? GameButtonVariant.amber : GameButtonVariant.dark,
              size: GameButtonSize.small,
            ),
        ],
      ),
    ),
  );
}
}

