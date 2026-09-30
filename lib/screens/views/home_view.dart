import 'package:flutter/material.dart';
import '../../models/ball_catalog.dart';
import '../../models/challenge_model.dart';
import '../../models/character_roster.dart';
import '../../models/court_catalog.dart';
import '../../models/player_avatar.dart';
import '../../models/tournament_model.dart';
import '../../services/game_state_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_character_display.dart';
import '../../widgets/game_2d_button.dart';
import '../../widgets/game_2d_text.dart';
import '../../widgets/inventory_modal.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/avatar_picker_dialog.dart';
import '../../widgets/friends_modal.dart';
import '../../widgets/player_profile_modal.dart';
import '../../widgets/shop_modal.dart';
import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../auth/register_screen.dart';
import 'player_stats_modal.dart';

class HomeView extends StatelessWidget {
  final VoidCallback onPlayQuickMatch;
  final VoidCallback? onPlayDoublesMatch;
  final VoidCallback onOpenTournament;
  final VoidCallback onOpenChallenges;
  final VoidCallback? onOpenBattleRoom;
  final VoidCallback? onOpenFriends;
  final VoidCallback? onOpenProfile;

  const HomeView({
    super.key,
    required this.onPlayQuickMatch,
    this.onPlayDoublesMatch,
    required this.onOpenTournament,
    required this.onOpenChallenges,
    this.onOpenBattleRoom,
    this.onOpenFriends,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final state = GameStateManager.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 750;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  _buildHeroPlayCard(context, state),
                                  const SizedBox(height: 16),
                                  _buildShopAndLockerBanner(context, state),
                                  const SizedBox(height: 16),
                                  _buildStatsOverviewCard(context, state),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  _buildMultiplayerLobbyBanner(context),
                                  const SizedBox(height: 16),
                                  _buildTournamentBanner(context, state),
                                  const SizedBox(height: 16),
                                  _buildDailyQuestSnapshot(context, state),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildHeroPlayCard(context, state),
                            const SizedBox(height: 16),
                            _buildMultiplayerLobbyBanner(context),
                            const SizedBox(height: 16),
                            _buildShopAndLockerBanner(context, state),
                            const SizedBox(height: 16),
                            _buildTournamentBanner(context, state),
                            const SizedBox(height: 16),
                            _buildDailyQuestSnapshot(context, state),
                            const SizedBox(height: 16),
                            _buildStatsOverviewCard(context, state),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeroPlayCard(BuildContext context, GameStateManager state) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF06090F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.electricCyan,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricCyan.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pixel grid background
          Positioned.fill(
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomPaint(painter: _PixelGridPainter.instance),
              ),
            ),
          ),
          // Scanline overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Opacity(
                opacity: 0.15,
                child: CustomPaint(painter: _ScanlinePainter.instance),
              ),
            ),
          ),
          // Pixel corner notches
          Positioned(top: 0, left: 0, child: Container(width: 6, height: 6, color: const Color(0xFF06090F))),
          Positioned(top: 0, right: 0, child: Container(width: 6, height: 6, color: const Color(0xFF06090F))),
          Positioned(bottom: 0, left: 0, child: Container(width: 6, height: 6, color: const Color(0xFF06090F))),
          Positioned(bottom: 0, right: 0, child: Container(width: 6, height: 6, color: const Color(0xFF06090F))),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: LayoutBuilder(
              builder: (context, heroConstraints) {
                final isWide = heroConstraints.maxWidth >= 600;

                final leftInfoColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.neonLime.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.neonLime, width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, color: AppTheme.neonLime, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'READY TO SERVE',
                                style: TextStyle(
                                  color: AppTheme.neonLime,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: const Text(
                            '1280x720 Court',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Game2DText.hero(
                      'PICKL',
                      fontSize: 28,
                      gradient: AppTheme.playButtonGradient,
                      strokeColor: const Color(0xFF060B18),
                      strokeWidth: 4.0,
                      shadowOffset: const Offset(0, 3.5),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Jump onto the court for a fast-paced singles duel. Use movement and timely smashes to dominate the match!',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Game2DButton(
                          key: const ValueKey('dashboard_1v1_btn'),
                          onPressed: onPlayQuickMatch,
                          text: '1v1 SINGLES',
                          icon: Icons.person_rounded,
                          variant: GameButtonVariant.primary,
                          size: GameButtonSize.medium,
                        ),
                        if (onPlayDoublesMatch != null)
                          Game2DButton(
                            key: const ValueKey('dashboard_2v2_btn'),
                            onPressed: onPlayDoublesMatch,
                            text: '2v2 DOUBLES',
                            icon: Icons.people_rounded,
                            variant: GameButtonVariant.cyan,
                            size: GameButtonSize.medium,
                          ),
                        if (onOpenBattleRoom != null)
                          Game2DButton(
                            key: const ValueKey('dashboard_battle_room_btn'),
                            onPressed: onOpenBattleRoom,
                            text: 'BATTLE ROOM (ONLINE)',
                            icon: Icons.language_rounded,
                            variant: GameButtonVariant.primary,
                            size: GameButtonSize.medium,
                          ),
                        Game2DButton(
                          key: const ValueKey('dashboard_tournaments_btn'),
                          onPressed: onOpenTournament,
                          text: 'TOURNAMENTS',
                          icon: Icons.emoji_events_outlined,
                          variant: GameButtonVariant.amber,
                          size: GameButtonSize.medium,
                        ),
                      ],
                    ),
                  ],
                );

                final equippedChar = CharacterRoster.getById(state.playerAvatarId);
                CharacterGender genderFromType(CharacterType type) {
                  switch (type) {
                    case CharacterType.female1:
                      return CharacterGender.female;
                    case CharacterType.female2:
                      return CharacterGender.female2;
                    case CharacterType.male2:
                      return CharacterGender.male2;
                    case CharacterType.male3:
                      return CharacterGender.male3;
                    case CharacterType.male1:
                      return CharacterGender.male;
                  }
                }

                CharacterType typeFromGender(CharacterGender gender) {
                  switch (gender) {
                    case CharacterGender.female:
                      return CharacterType.female1;
                    case CharacterGender.female2:
                      return CharacterType.female2;
                    case CharacterGender.male2:
                      return CharacterType.male2;
                    case CharacterGender.male3:
                      return CharacterType.male3;
                    case CharacterGender.male:
                      return CharacterType.male1;
                  }
                }

                final characterSection = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Active Character Tag with tap-to-swap
                    InkWell(
                      key: const ValueKey('dash_hero_badge'),
                      onTap: () => AvatarPickerDialog.show(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: equippedChar.gradientColors),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: equippedChar.borderColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: equippedChar.borderColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(equippedChar.badge, style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                '${equippedChar.name.toUpperCase()} • ${equippedChar.title.toUpperCase()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.swap_horiz_rounded, color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),
                    // Pixel spotlight under character
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: isWide ? 140 : 120,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: [
                                BoxShadow(
                                  color: equippedChar.borderColor.withValues(alpha: 0.25),
                                  blurRadius: 24,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedCharacterDisplay(
                          key: ValueKey('dash_char_${state.playerAvatarId}'),
                          initialGender: genderFromType(equippedChar.type),
                          height: isWide ? 190 : 170,
                          showControls: true,
                          onGenderChanged: (newGender) {
                            final targetChar = CharacterRoster.getByType(typeFromGender(newGender));
                            if (state.isCharacterUnlocked(targetChar.id) || targetChar.isDefaultUnlocked) {
                              state.updatePlayerAvatar(targetChar.id);
                            } else {
                              AvatarPickerDialog.show(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 3, child: leftInfoColumn),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: characterSection,
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      leftInfoColumn,
                      const SizedBox(height: 16),
                      Center(
                        child: characterSection,
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildShopAndLockerBanner(BuildContext context, GameStateManager state) {
    final activeChar = CharacterRoster.getById(state.playerAvatarId);
    final activeCourt = CourtCatalog.getById(state.equippedCourtId);
    final activeBall = BallCatalog.getById(state.equippedBallId);

    return Stack(
      children: [
        // Pixel corner notches
        Positioned(top: 0, left: 0, child: Container(width: 5, height: 5, color: AppTheme.background)),
        Positioned(top: 0, right: 0, child: Container(width: 5, height: 5, color: AppTheme.background)),
        Positioned(bottom: 0, left: 0, child: Container(width: 5, height: 5, color: AppTheme.background)),
        Positioned(bottom: 0, right: 0, child: Container(width: 5, height: 5, color: AppTheme.background)),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1525),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.goldCoin.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldCoin.withValues(alpha: 0.4), width: 1.5),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppTheme.goldCoin, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Game2DText(
                      'PRO SHOP & LOCKER',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      textColor: Colors.white,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Equip obtained gear or buy courts, balls & characters',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Active Loadout Pill row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF090D16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniLoadoutItem('CHAR', activeChar.name, activeChar.badge, activeChar.borderColor),
                Container(width: 1, height: 28, color: const Color(0xFF1E293B)),
                _buildMiniLoadoutItem('COURT', activeCourt.name, activeCourt.badge, activeCourt.accentColor),
                Container(width: 1, height: 28, color: const Color(0xFF1E293B)),
                _buildMiniLoadoutItem('BALL', activeBall.name, activeBall.badge, activeBall.glowColor),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Game2DButton(
                  key: const ValueKey('home_open_shop_btn'),
                  onPressed: () => ShopModal.show(context),
                  text: 'PRO SHOP',
                  icon: Icons.storefront_rounded,
                  variant: GameButtonVariant.amber,
                  size: GameButtonSize.small,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Game2DButton(
                  key: const ValueKey('home_open_inventory_btn'),
                  onPressed: () => InventoryModal.show(context),
                  text: 'LOCKER',
                  icon: Icons.inventory_2_rounded,
                  variant: GameButtonVariant.cyan,
                  size: GameButtonSize.small,
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ],
    );
  }

  Widget _buildMiniLoadoutItem(String category, String name, String badge, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            category,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(badge, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentBanner(BuildContext context, GameStateManager state) {
    // Find first active tournament
    final activeTournament = state.tournaments.isNotEmpty
        ? state.tournaments.firstWhere(
            (t) => t.isUnlocked && !t.isCompleted,
            orElse: () => state.tournaments.first,
          )
        : Tournament(
            id: 'rookie_open',
            title: 'Rookie Open',
            subtitle: 'Entry-level knockout cup for upcoming talent',
            badge: '🥉',
            difficulty: TournamentDifficulty.easy,
            entryFee: 0,
            rewardCoins: 250,
            rewardTrophies: 50,
            isUnlocked: true,
            currentMatchIndex: 0,
            matches: [],
          );

    final currentMatch = activeTournament.currentMatch;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1525),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                activeTournament.badge,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Game2DText.title(
                      activeTournament.title,
                      fontSize: 18,
                      textColor: Colors.white,
                      strokeWidth: 2.5,
                      shadowOffset: const Offset(0, 2),
                    ),
                    Text(
                      currentMatch != null
                          ? 'Up next: ${currentMatch.roundTitle}'
                          : 'Tournament Complete!',
                      style: const TextStyle(
                        color: AppTheme.trophyAmber,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 18),
                onPressed: onOpenTournament,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (currentMatch != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PlayerAvatarWidget(
                          avatarId: state.playerAvatarId,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            state.playerName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        color: AppTheme.neonLime,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            currentMatch.player2Name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        PlayerAvatarWidget(
                          avatar: PlayerAvatar.getForOpponent(currentMatch.player2Name),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: Game2DButton(
              onPressed: onOpenTournament,
              text: currentMatch != null ? 'VIEW BRACKET' : 'START NEW CUP',
              icon: Icons.emoji_events_rounded,
              variant: GameButtonVariant.amber,
              size: GameButtonSize.medium,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyQuestSnapshot(BuildContext context, GameStateManager state) {
    // Look for first uncompleted or uncollected challenge
    final pendingChallenge = state.challenges.isNotEmpty
        ? state.challenges.firstWhere(
            (c) => !c.isClaimed,
            orElse: () => state.challenges.first,
          )
        : ChallengeItem(
            id: 'c_default',
            title: 'Court Warmup',
            description: 'Win 1 match to earn rewards',
            rewardCoins: 100,
            rewardXp: 50,
            goal: 1,
            type: ChallengeType.daily,
          );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1525),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag_rounded, color: AppTheme.electricCyan, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Game2DText.title(
                      'Active Challenge',
                      fontSize: 16,
                      textColor: Colors.white,
                      strokeWidth: 2.2,
                      shadowOffset: const Offset(0, 1.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onOpenChallenges,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.electricCyan,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pendingChallenge.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pendingChallenge.description,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pendingChallenge.progressRatio,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pendingChallenge.isCompleted ? AppTheme.neonLime : AppTheme.electricCyan,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${pendingChallenge.currentProgress} / ${pendingChallenge.goal}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.goldCoin.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: AppTheme.goldCoin, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+${pendingChallenge.rewardCoins}',
                          style: const TextStyle(
                            color: AppTheme.goldCoin,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: AppTheme.electricCyan, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+${pendingChallenge.rewardXp} XP',
                          style: const TextStyle(
                            color: AppTheme.electricCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (pendingChallenge.isCompleted && !pendingChallenge.isClaimed)
                Game2DButton(
                  onPressed: () {
                    state.claimChallenge(pendingChallenge.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.neonLime,
                        content: Text(
                          'Claimed ${pendingChallenge.rewardCoins} Coins & ${pendingChallenge.rewardXp} XP!',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  text: 'CLAIM',
                  icon: Icons.card_giftcard_rounded,
                  variant: GameButtonVariant.primary,
                  size: GameButtonSize.small,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverviewCard(BuildContext context, GameStateManager state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1525),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.analytics_outlined, color: AppTheme.neonLime, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Game2DText.title(
                      'Career Performance',
                      fontSize: 16,
                      textColor: Colors.white,
                      strokeWidth: 2.2,
                      shadowOffset: const Offset(0, 1.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () => PlayerStatsModal.show(context),
                    icon: const Icon(Icons.leaderboard_rounded, size: 16, color: AppTheme.neonLime),
                    label: const Text(
                      'All Records',
                      style: TextStyle(
                        color: AppTheme.neonLime,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showMatchHistory(context, state),
                    icon: const Icon(Icons.history_rounded, size: 16, color: AppTheme.electricCyan),
                    label: const Text(
                      'Match History',
                      style: TextStyle(
                        color: AppTheme.electricCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatItem('Matches', '${state.matchesPlayed}')),
              const SizedBox(width: 8),
              Expanded(child: _buildStatItem('Win Rate', '${state.winRate.toStringAsFixed(0)}%')),
              const SizedBox(width: 8),
              Expanded(child: _buildStatItem('Total Smashes', '${state.totalSmashes}')),
            ],
          ),
        ],
      ),
    );
  }

  void _showMatchHistory(BuildContext context, GameStateManager state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            maxWidth: 600,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, color: AppTheme.electricCyan, size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Match History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              if (state.isGuest)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.electricCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.electricCyan.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppTheme.electricCyan, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Playing as Guest. Create an account to permanently sync matches to SQLite.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(preserveGuestData: true),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('REGISTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              const Divider(color: AppTheme.surfaceBorder, height: 1),
              // Matches List
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: state.getMatchHistory(limit: 30),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.electricCyan));
                    }
                    final matches = snapshot.data ?? [];
                    if (matches.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sports_tennis, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              const Text(
                                'No matches recorded yet',
                                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Play Quick Matches or Tournament cups to build your SQLite match log!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: matches.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        final won = (match['won'] as num?)?.toInt() == 1;
                        final opponent = match['opponent_name'] as String? ?? 'CPU Challenger';
                        final matchType = (match['match_type'] as String? ?? 'quick') == 'tournament'
                            ? 'Tournament Cup'
                            : 'Quick Match';
                        final pScore = (match['player_score'] as num?)?.toInt() ?? 0;
                        final oScore = (match['opponent_score'] as num?)?.toInt() ?? 0;
                        final smashes = (match['smashes_hit'] as num?)?.toInt() ?? 0;
                        final coins = (match['coins_earned'] as num?)?.toInt() ?? 0;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: won
                                  ? AppTheme.neonLime.withValues(alpha: 0.3)
                                  : AppTheme.fireOrange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Result Badge
                              Container(
                                width: 50,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: (won ? AppTheme.neonLime : AppTheme.fireOrange).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: won ? AppTheme.neonLime : AppTheme.fireOrange,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  won ? 'WIN' : 'LOSS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: won ? AppTheme.neonLime : AppTheme.fireOrange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Opponent & Type
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'vs $opponent',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      matchType,
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Score & Coins
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$pScore - $oScore',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$smashes 💥',
                                        style: const TextStyle(
                                          color: AppTheme.electricCyan,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '+$coins 🪙',
                                        style: const TextStyle(
                                          color: AppTheme.goldCoin,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Game2DText.score(
            value,
            fontSize: 18,
            textColor: Colors.white,
            strokeWidth: 2.2,
            shadowOffset: const Offset(0, 1.5),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplayerLobbyBanner(BuildContext context) {
    final multi = MultiplayerService.instance;
    final onlineCount = multi.friends.where((f) => f.status == PlayerPresenceStatus.online).length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF020617),
          ],
        ),
        border: Border.all(
          color: AppTheme.electricCyan.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricCyan.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top pill & badges
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.electricCyan.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.electricCyan, width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_tethering_rounded, color: AppTheme.electricCyan, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'LIVE BATTLE',
                        style: TextStyle(
                          color: AppTheme.electricCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                // Online Friends count badge
                InkWell(
                  onTap: () {
                    if (onOpenFriends != null) {
                      onOpenFriends!();
                    } else {
                      FriendsModal.show(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF22C55E), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF22C55E), size: 8),
                        const SizedBox(width: 4),
                        Text(
                          '$onlineCount Online',
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'MULTIPLAYER BATTLE ROOMS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Challenge friends or rivals in private 1v1 & 2v2 live battle rooms with zero-lag prediction and spectator flow.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onOpenBattleRoom != null)
                  Game2DButton(
                    onPressed: onOpenBattleRoom,
                    text: 'ENTER BATTLE ROOM',
                    icon: Icons.meeting_room_rounded,
                    variant: GameButtonVariant.primary,
                    size: GameButtonSize.small,
                  ),
                Game2DButton(
                  onPressed: () {
                    if (onOpenFriends != null) {
                      onOpenFriends!();
                    } else {
                      FriendsModal.show(context);
                    }
                  },
                  text: 'FRIENDS HUB',
                  icon: Icons.people_alt_rounded,
                  variant: GameButtonVariant.cyan,
                  size: GameButtonSize.small,
                ),
                Game2DButton(
                  onPressed: () {
                    if (onOpenProfile != null) {
                      onOpenProfile!();
                    } else {
                      PlayerProfileModal.show(context);
                    }
                  },
                  text: 'MY PROFILE',
                  icon: Icons.account_box_rounded,
                  variant: GameButtonVariant.dark,
                  size: GameButtonSize.small,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



// ============================================================================
// CustomPainter: Pixel Grid Background (nearly invisible dark grid)
// ============================================================================

/// Subtle pixel grid background painter (very dark, nearly invisible).
class _PixelGridPainter extends CustomPainter {
  _PixelGridPainter._();
  static final _PixelGridPainter instance = _PixelGridPainter._();

  static final Paint _p = Paint()
    ..color = const Color(0x08FFFFFF)
    ..strokeWidth = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 16.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _p);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _p);
    }
  }

  @override
  bool shouldRepaint(_PixelGridPainter old) => false;
}

// ============================================================================
// CustomPainter: Horizontal Scanline Overlay
// ============================================================================

/// Horizontal scanline overlay painter.
class _ScanlinePainter extends CustomPainter {
  _ScanlinePainter._();
  static final _ScanlinePainter instance = _ScanlinePainter._();

  static final Paint _p = Paint()
    ..color = const Color(0x12000000)
    ..strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (double y = 0; y <= size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _p);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}
