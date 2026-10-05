import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/ball_catalog.dart';
import '../models/character_roster.dart';
import '../models/court_catalog.dart';
import '../services/audio_service.dart';
import '../services/game_state_manager.dart';
import '../theme/app_theme.dart';
import 'animated_character_display.dart';
import 'dashboard_character_card_feature.dart';
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

  Widget _buildCharacterShowcase(CharacterInfo char, GameStateManager state) {
    final isUnlocked = state.isCharacterUnlocked(char.id);
    final isEquipped = state.playerAvatarId == char.id;
    final canAfford = state.coins >= char.price;

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: char.borderColor.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: char.borderColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Header Row: Status tag & Coin chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    const Icon(Icons.bolt, color: AppTheme.neonLime, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'FEATURED FIGHTER',
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.goldCoin.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.goldCoin, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: AppTheme.goldCoin, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${char.price} COINS',
                        style: const TextStyle(
                          color: AppTheme.goldCoin,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Arcade Character Feature with Top Pill, Spotlight, and Interactive Paddle Sprite
          DashboardCharacterCardFeature(
            character: char,
            height: 155,
            showBadge: true,
            showSwapIcon: true,
            onBadgeTap: () {
              final all = CharacterRoster.allCharacters;
              final idx = all.indexWhere((c) => c.id == char.id);
              final next = all[(idx + 1) % all.length];
              setState(() {
                _selectedCharacterId = next.id;
              });
              AudioService.instance.playButtonTap();
            },
            showSpotlight: true,
            showCharacterSwitcher: true,
            showActionControls: true,
            onGenderChanged: (newGender) {
              final targetChar = CharacterRoster.getByType(AnimatedCharacterDisplay.typeFromGender(newGender));
              setState(() {
                _selectedCharacterId = targetChar.id;
              });
            },
          ),

          const SizedBox(height: 6),
          // Character description & quick buy/equip actions
          Row(
            children: [
              Expanded(
                child: Text(
                  char.description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              if (isEquipped)
                Game2DButton(
                  onPressed: () {},
                  text: 'EQUIPPED',
                  icon: Icons.check_circle_rounded,
                  variant: GameButtonVariant.cyan,
                  size: GameButtonSize.small,
                )
              else if (isUnlocked)
                Game2DButton(
                  onPressed: () {
                    AudioService.instance.playButtonTap();
                    state.equipCharacter(char.id);
                    _showNotice('Equipped ${char.name}!');
                  },
                  text: 'EQUIP',
                  icon: Icons.sports_tennis_rounded,
                  variant: GameButtonVariant.primary,
                  size: GameButtonSize.small,
                )
              else
                Game2DButton(
                  onPressed: () {
                    if (state.purchaseCharacter(char.id)) {
                      AudioService.instance.playPointScored();
                      _showNotice('Unlocked & equipped ${char.name}!');
                    } else {
                      AudioService.instance.playButtonTap();
                      _showNotice(
                        'Need ${char.price - state.coins} more coins to purchase ${char.name}!',
                        isSuccess: false,
                      );
                    }
                  },
                  text: 'BUY (${char.price})',
                  icon: Icons.shopping_bag_outlined,
                  variant: canAfford ? GameButtonVariant.amber : GameButtonVariant.dark,
                  size: GameButtonSize.small,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharactersTab(GameStateManager state) {
    final selectedChar = _resolveSelectedCharacter(state);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _buildCharacterSelectorBar(state, selectedChar),
        const SizedBox(height: 10),
        _buildCharacterShowcase(selectedChar, state),
      ],
    );
  }

  Widget _buildCharacterSelectorBar(GameStateManager state, CharacterInfo selectedChar) {
    final characters = CharacterRoster.allCharacters;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final char in characters) ...[
            _buildCharacterChip(
              key: ValueKey('shop_char_${char.id}'),
              char: char,
              isSelected: char.id == selectedChar.id,
              isEquipped: state.playerAvatarId == char.id,
              isUnlocked: state.isCharacterUnlocked(char.id),
              onTap: () {
                AudioService.instance.playButtonTap();
                setState(() {
                  _selectedCharacterId = char.id;
                });
              },
              onEquip: () {
                AudioService.instance.playButtonTap();
                state.equipCharacter(char.id);
                setState(() {
                  _selectedCharacterId = char.id;
                });
                _showNotice('Equipped ${char.name}!');
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildCharacterChip({
    Key? key,
    required CharacterInfo char,
    required bool isSelected,
    required bool isEquipped,
    required bool isUnlocked,
    required VoidCallback onTap,
    required VoidCallback onEquip,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? char.borderColor.withValues(alpha: 0.25) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? char.borderColor : AppTheme.surfaceBorder,
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: char.borderColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(char.badge, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  char.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                if (isEquipped)
                  const Text(
                    'EQUIPPED',
                    style: TextStyle(
                      color: AppTheme.neonLime,
                      fontWeight: FontWeight.w800,
                      fontSize: 8.5,
                    ),
                  )
                else if (isUnlocked)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onEquip,
                    child: const Text(
                      'EQUIP',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.w800,
                        fontSize: 8.5,
                      ),
                    ),
                  )
                else
                  Text(
                    '${char.price} 🪙',
                    style: const TextStyle(
                      color: AppTheme.goldCoin,
                      fontWeight: FontWeight.w800,
                      fontSize: 8.5,
                    ),
                  ),
              ],
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
      decoration: BoxDecoration(
        color: court.apronColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: court.accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: court.accentColor.withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              court.fullAssetPath,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: court.courtColor,
                child: Center(
                  child: Text(court.badge, style: const TextStyle(fontSize: 20)),
                ),
              ),
            ),
            // Center Court Logo
            Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5A823), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 4,
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
            Positioned(
              bottom: 3,
              right: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: court.accentColor.withValues(alpha: 0.6), width: 1),
                ),
                child: Text(court.badge, style: const TextStyle(fontSize: 10)),
              ),
            ),
          ],
        ),
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

