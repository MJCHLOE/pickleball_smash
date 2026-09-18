import 'package:flutter/material.dart';
import '../../models/challenge_model.dart';
import '../../models/tournament_model.dart';
import '../../services/game_state_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_character_display.dart';
import '../auth/register_screen.dart';
import 'player_stats_modal.dart';

class HomeView extends StatelessWidget {
  final VoidCallback onPlayQuickMatch;
  final VoidCallback onOpenTournament;
  final VoidCallback onOpenChallenges;

  const HomeView({
    super.key,
    required this.onPlayQuickMatch,
    required this.onOpenTournament,
    required this.onOpenChallenges,
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
                                  _buildHeroPlayCard(context),
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
                            _buildHeroPlayCard(context),
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

  Widget _buildHeroPlayCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF0F172A),
          ],
        ),
        border: Border.all(
          color: AppTheme.electricCyan.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricCyan.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative background graphics
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              Icons.sports_tennis,
              size: 200,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
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
                            color: AppTheme.neonLime.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.neonLime, width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, color: AppTheme.neonLime, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'READY TO SERVE',
                                style: TextStyle(
                                  color: AppTheme.neonLime,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '1280x720 Court',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Pickleball Smash',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Jump onto the court for a fast-paced singles duel. Use movement and timely smashes to dominate the match!',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: onPlayQuickMatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonLime,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: AppTheme.neonLime.withValues(alpha: 0.5),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 26),
                          label: const Text(
                            'QUICK MATCH',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onOpenTournament,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.emoji_events_outlined, size: 20),
                          label: const Text(
                            'Tournaments',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                      const Expanded(
                        flex: 2,
                        child: AnimatedCharacterDisplay(
                          height: 190,
                          showControls: true,
                        ),
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
                      const Center(
                        child: AnimatedCharacterDisplay(
                          height: 170,
                          showControls: true,
                        ),
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
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
                    Text(
                      activeTournament.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOpenTournament,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.trophyAmber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                currentMatch != null ? 'VIEW BRACKET' : 'START NEW CUP',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
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
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_rounded, color: AppTheme.electricCyan, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Active Challenge',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                ElevatedButton(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonLime,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('CLAIM', style: TextStyle(fontWeight: FontWeight.bold)),
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
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
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics_outlined, color: AppTheme.neonLime, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Career Performance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
              left: BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
              right: BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
            ),
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
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
}

