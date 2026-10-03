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
import 'ready_to_serve_character_widget.dart';
import 'shop_modal.dart';

class InventoryModal extends StatefulWidget {
  final int initialTabIndex;

  const InventoryModal({
    super.key,
    this.initialTabIndex = 0,
  });

  static Future<void> show(BuildContext context, {int initialTabIndex = 0}) {
    AudioService.instance.playButtonTap();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => InventoryModal(initialTabIndex: initialTabIndex),
    );
  }

  @override
  State<InventoryModal> createState() => _InventoryModalState();
}

class _InventoryModalState extends State<InventoryModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _inspectedCharacterId;

  CharacterInfo _resolveInspectedCharacter(GameStateManager state) {
    final characters = CharacterRoster.allCharacters;
    if (_inspectedCharacterId != null) {
      final found = characters.where((c) => c.id == _inspectedCharacterId).firstOrNull;
      if (found != null) return found;
    }
    return CharacterRoster.getById(state.playerAvatarId);
  }

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

                      // Active Loadout Banner
                      _buildActiveLoadoutBanner(state),
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
              color: AppTheme.electricCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.electricCyan.withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: AppTheme.electricCyan, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Game2DText.hero(
                  'LOCKER & INVENTORY',
                  fontSize: 18,
                  strokeWidth: 2.5,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Manage your obtained equipment and active loadout',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Open Shop Button
          Game2DButton(
            onPressed: () {
              Navigator.of(context).pop();
              ShopModal.show(context, initialTabIndex: _tabController.index);
            },
            text: MediaQuery.sizeOf(context).width < 450 ? 'SHOP' : 'PRO SHOP',
            icon: Icons.storefront_rounded,
            variant: GameButtonVariant.amber,
            size: GameButtonSize.small,
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

  Widget _buildActiveLoadoutBanner(GameStateManager state) {
    final activeChar = CharacterRoster.getById(state.playerAvatarId);
    final activeCourt = CourtCatalog.getById(state.equippedCourtId);
    final activeBall = BallCatalog.getById(state.equippedBallId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF090D16),
      child: Row(
        children: [
          const Text(
            'ACTIVE LOADOUT:',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLoadoutBadge(
                    icon: Icons.person_rounded,
                    label: activeChar.name,
                    badge: activeChar.badge,
                    color: activeChar.borderColor,
                    character: activeChar,
                  ),
                  const SizedBox(width: 8),
                  _buildLoadoutBadge(
                    icon: Icons.stadium_rounded,
                    label: activeCourt.name,
                    badge: activeCourt.badge,
                    color: activeCourt.accentColor,
                  ),
                  const SizedBox(width: 8),
                  _buildLoadoutBadge(
                    icon: Icons.sports_tennis_rounded,
                    label: activeBall.name,
                    badge: activeBall.badge,
                    color: activeBall.glowColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadoutBadge({
    required IconData icon,
    required String label,
    required String badge,
    required Color color,
    CharacterInfo? character,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (character != null) ...[
            ReadyToServeCharacterWidget(
              character: character,
              action: 'serve',
              size: 20,
            ),
            const SizedBox(width: 4),
          ],
          Text(badge, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
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
        indicatorColor: AppTheme.electricCyan,
        indicatorWeight: 3,
        labelColor: AppTheme.electricCyan,
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
  Widget _buildFighterShowcase(CharacterInfo char, GameStateManager state) {
    final isEquipped = state.playerAvatarId == char.id;
    final isUnlocked = state.isCharacterUnlocked(char.id);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
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
          // Top Header Row
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
                    const Icon(Icons.shield_outlined, color: AppTheme.neonLime, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'LOCKER SPOTLIGHT: ${char.name.toUpperCase()}',
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
                _inspectedCharacterId = next.id;
              });
              AudioService.instance.playButtonTap();
            },
            showSpotlight: true,
            showCharacterSwitcher: true,
            showActionControls: true,
            onGenderChanged: (newGender) {
              final targetChar = CharacterRoster.getByType(AnimatedCharacterDisplay.typeFromGender(newGender));
              setState(() {
                _inspectedCharacterId = targetChar.id;
              });
            },
          ),

          const SizedBox(height: 6),
          // Character description & quick equip action
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.neonLime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.neonLime, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppTheme.neonLime, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'EQUIPPED',
                        style: TextStyle(
                          color: AppTheme.neonLime,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
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
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharactersTab(GameStateManager state) {
    final characters = CharacterRoster.allCharacters;
    final activeChar = _resolveInspectedCharacter(state);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: [
        _buildFighterShowcase(activeChar, state),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: AppTheme.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(
                'YOUR ROSTER (TAP TO PREVIEW & TEST SMASH)',
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
        const SizedBox(height: 6),
        for (final char in characters) ...[
          _buildInventoryCard(
            key: ValueKey('inv_char_${char.id}'),
            badge: char.badge,
            title: char.name,
            subtitle: char.title,
            description: char.description,
            accentColor: char.borderColor,
            isUnlocked: state.isCharacterUnlocked(char.id),
            isEquipped: state.playerAvatarId == char.id,
            isInspected: char.id == activeChar.id,
            isPurchasable: char.isPurchasable,
            onTap: () {
              setState(() {
                _inspectedCharacterId = char.id;
              });
              AudioService.instance.playButtonTap();
            },
            previewWidget: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: state.isCharacterUnlocked(char.id)
                      ? char.gradientColors
                      : [const Color(0xFF334155), const Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: state.isCharacterUnlocked(char.id) ? char.borderColor : const Color(0xFF475569),
                  width: 2,
                ),
                boxShadow: state.isCharacterUnlocked(char.id)
                    ? [
                        BoxShadow(
                          color: char.borderColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ReadyToServeCharacterWidget(
                      character: char,
                      action: 'idle',
                      size: 56,
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          char.badge,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            onEquip: () {
              AudioService.instance.playButtonTap();
              state.equipCharacter(char.id);
              setState(() {
                _inspectedCharacterId = char.id;
              });
              _showNotice('Equipped ${char.name}!');
            },
            onSell: char.isPurchasable && state.isCharacterUnlocked(char.id)
                ? () {
                    final refund = char.sellRefund;
                    if (state.sellCharacter(char.id)) {
                      AudioService.instance.playPointScored();
                      _showNotice('Sold ${char.name} for 🪙 $refund coins!');
                    }
                  }
                : null,
            onGoToShop: () {
              Navigator.of(context).pop();
              ShopModal.show(context, initialTabIndex: 0);
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
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

        return _buildInventoryCard(
          key: ValueKey('inv_court_${court.id}'),
          badge: court.badge,
          title: court.name,
          subtitle: court.subtitle,
          description: court.description,
          accentColor: court.accentColor,
          isUnlocked: isUnlocked,
          isEquipped: isEquipped,
          isPurchasable: court.isPurchasable,
          previewWidget: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isUnlocked ? court.apronColor : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked ? court.accentColor : const Color(0xFF475569),
                width: 2,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: court.accentColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isUnlocked) ...[
                    Image.asset(
                      court.fullAssetPath,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: court.courtColor,
                        child: Center(
                          child: Text(court.badge, style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                    // Center Court Logo
                    Center(
                      child: Container(
                        width: 26,
                        height: 26,
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
                  ],
                  Positioned(
                    bottom: 3,
                    right: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isUnlocked
                              ? court.accentColor.withValues(alpha: 0.6)
                              : const Color(0xFF475569),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isUnlocked ? court.badge : '🔒',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          onEquip: () {
            AudioService.instance.playButtonTap();
            state.equipCourt(court.id);
            _showNotice('Equipped ${court.name}!');
          },
          onGoToShop: () {
            Navigator.of(context).pop();
            ShopModal.show(context, initialTabIndex: 1);
          },
        );
      },
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

        return _buildInventoryCard(
          key: ValueKey('inv_ball_${ball.id}'),
          badge: ball.badge,
          title: ball.name,
          subtitle: ball.effectDescription,
          description: ball.description,
          accentColor: ball.glowColor,
          isUnlocked: isUnlocked,
          isEquipped: isEquipped,
          isPurchasable: ball.isPurchasable,
          previewWidget: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF090D16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked ? ball.glowColor.withValues(alpha: 0.6) : const Color(0xFF475569),
                width: 2,
              ),
            ),
            child: Center(
              child: isUnlocked
                  ? Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.35, -0.35),
                          radius: 0.85,
                          colors: ball.gradientColors,
                        ),
                      ),
                      child: Center(
                        child: Text(ball.badge, style: const TextStyle(fontSize: 16)),
                      ),
                    )
                  : const Text('🔒', style: TextStyle(fontSize: 22)),
            ),
          ),
          onEquip: () {
            AudioService.instance.playButtonTap();
            state.equipBall(ball.id);
            _showNotice('Equipped ${ball.name}!');
          },
          onGoToShop: () {
            Navigator.of(context).pop();
            ShopModal.show(context, initialTabIndex: 2);
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED INVENTORY CARD
  // ---------------------------------------------------------------------------
  Widget _buildInventoryCard({
    required Key key,
    required String badge,
    required String title,
    required String subtitle,
    required String description,
    required Color accentColor,
    required Widget previewWidget,
    required bool isUnlocked,
    required bool isEquipped,
    bool isInspected = false,
    VoidCallback? onTap,
    required bool isPurchasable,
    required VoidCallback onEquip,
    VoidCallback? onSell,
    required VoidCallback onGoToShop,
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
                  : isUnlocked
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF090D16).withValues(alpha: 0.7),
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
                    color: accentColor.withValues(alpha: 0.25),
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
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : AppTheme.textMuted,
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF0284C7), width: 1),
                        ),
                        child: const Text(
                          'OBTAINED',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LOCKED',
                          style: TextStyle(
                            color: AppTheme.textMuted,
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
                    color: isUnlocked ? accentColor : AppTheme.textMuted,
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
          // Action Buttons
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
                    'ACTIVE',
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onSell != null) ...[
                  IconButton(
                    icon: const Icon(Icons.currency_exchange_rounded, color: AppTheme.goldCoin, size: 20),
                    tooltip: 'Sell for Coins',
                    onPressed: onSell,
                  ),
                  const SizedBox(width: 4),
                ],
                Game2DButton(
                  onPressed: onEquip,
                  text: 'EQUIP',
                  icon: Icons.check_circle_outline_rounded,
                  variant: GameButtonVariant.primary,
                  size: GameButtonSize.small,
                ),
              ],
            )
          else
            Game2DButton(
              onPressed: onGoToShop,
              text: 'SHOP',
              icon: Icons.storefront_rounded,
              variant: GameButtonVariant.amber,
              size: GameButtonSize.small,
            ),
        ],
      ),
    ),
  );
}
}

