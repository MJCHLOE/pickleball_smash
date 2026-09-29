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
          Text(badge, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
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
  Widget _buildCharactersTab(GameStateManager state) {
    final characters = CharacterRoster.allCharacters;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: characters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final char = characters[index];
        final isUnlocked = state.isCharacterUnlocked(char.id);
        final isEquipped = state.playerAvatarId == char.id;

        return _buildInventoryCard(
          key: ValueKey('inv_char_${char.id}'),
          badge: char.badge,
          title: char.name,
          subtitle: char.title,
          description: char.description,
          accentColor: char.borderColor,
          isUnlocked: isUnlocked,
          isEquipped: isEquipped,
          isPurchasable: char.isPurchasable,
          previewWidget: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isUnlocked
                    ? char.gradientColors
                    : [const Color(0xFF334155), const Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked ? char.borderColor : const Color(0xFF475569),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                isUnlocked ? char.badge : '🔒',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          onEquip: () {
            AudioService.instance.playButtonTap();
            state.equipCharacter(char.id);
            _showNotice('Equipped ${char.name}!');
          },
          onSell: char.isPurchasable && isUnlocked
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
        );
      },
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isUnlocked ? court.apronColor : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked ? court.accentColor : const Color(0xFF475569),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isUnlocked)
                  Container(
                    decoration: BoxDecoration(
                      color: court.courtColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: court.lineColor.withValues(alpha: 0.8), width: 1.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 14,
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
                Text(isUnlocked ? court.badge : '🔒', style: const TextStyle(fontSize: 20)),
              ],
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
    required bool isPurchasable,
    required VoidCallback onEquip,
    VoidCallback? onSell,
    required VoidCallback onGoToShop,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEquipped
            ? accentColor.withValues(alpha: 0.12)
            : isUnlocked
                ? const Color(0xFF0F172A)
                : const Color(0xFF090D16).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEquipped
              ? accentColor
              : isUnlocked
                  ? AppTheme.surfaceBorder
                  : const Color(0xFF1E293B),
          width: isEquipped ? 2 : 1.5,
        ),
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
    );
  }
}

