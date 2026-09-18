import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/game_state_manager.dart';
import '../../theme/app_theme.dart';
import '../auth/register_screen.dart';

class PlayerStatsModal extends StatefulWidget {
  final int initialTabIndex;

  const PlayerStatsModal({super.key, this.initialTabIndex = 0});

  static void show(BuildContext context, {int initialTabIndex = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 700),
      builder: (ctx) => PlayerStatsModal(initialTabIndex: initialTabIndex),
    );
  }

  @override
  State<PlayerStatsModal> createState() => _PlayerStatsModalState();
}

class _PlayerStatsModalState extends State<PlayerStatsModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateManager.instance;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.surfaceBorder, width: 2),
          left: BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
          right: BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.neonLime.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: AppTheme.neonLime, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLAYER STATISTICS & RECORDS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Career stats, individual match logs, & rankings',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.neonLime,
            indicatorWeight: 3,
            labelColor: AppTheme.neonLime,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(
                icon: Icon(Icons.person_rounded, size: 18),
                text: 'My Career Records',
              ),
              Tab(
                icon: Icon(Icons.leaderboard_rounded, size: 18),
                text: 'All Players Leaderboard',
              ),
            ],
          ),
          const Divider(color: AppTheme.surfaceBorder, height: 1),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyCareerRecordsTab(context, state),
                _buildAllPlayersLeaderboardTab(context, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCareerRecordsTab(BuildContext context, GameStateManager state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player Identity Card
          _buildPlayerProfileCard(context, state),
          const SizedBox(height: 18),

          // Career Numbers Grid
          const Text(
            'CAREER PERFORMANCE',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          _buildStatsGrid(state),
          const SizedBox(height: 24),

          // Match History Log
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PERSONAL MATCH HISTORY',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                '${state.matchesPlayed} Recorded',
                style: const TextStyle(color: AppTheme.electricCyan, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildMatchHistoryList(state),
        ],
      ),
    );
  }

  Widget _buildPlayerProfileCard(BuildContext context, GameStateManager state) {
    final isGuest = state.isGuest;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.neonLime, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.sports_tennis, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        state.playerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.neonLime,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LVL ${state.playerLevel}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isGuest ? Icons.account_circle_outlined : Icons.verified_user_rounded,
                      size: 14,
                      color: isGuest ? AppTheme.trophyAmber : AppTheme.pickleGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGuest ? 'Guest Session (Unsaved)' : 'SQLite Synced Account',
                      style: TextStyle(
                        color: isGuest ? AppTheme.trophyAmber : AppTheme.pickleGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isGuest)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(preserveGuestData: true),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonLime,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('SAVE ACCOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(GameStateManager state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 480 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: constraints.maxWidth > 480 ? 1.8 : 1.4,
          children: [
            _buildStatBox(
              icon: Icons.sports_kabaddi_rounded,
              title: 'Matches',
              value: '${state.matchesPlayed}',
              subtitle: '${state.matchesWon}W - ${state.matchesLost}L',
              accentColor: AppTheme.electricCyan,
            ),
            _buildStatBox(
              icon: Icons.pie_chart_rounded,
              title: 'Win Rate',
              value: '${state.winRate.toStringAsFixed(0)}%',
              subtitle: state.matchesPlayed > 0 ? '${state.matchesWon} Victories' : '0 Matches',
              accentColor: AppTheme.neonLime,
            ),
            _buildStatBox(
              icon: Icons.bolt_rounded,
              title: 'Total Smashes',
              value: '${state.totalSmashes}',
              subtitle: '${state.averageSmashesPerMatch.toStringAsFixed(1)} per match',
              accentColor: AppTheme.fireOrange,
            ),
            _buildStatBox(
              icon: Icons.local_fire_department_rounded,
              title: 'Win Streak',
              value: '${state.currentStreak} 🔥',
              subtitle: 'Best: ${state.bestStreak} in a row',
              accentColor: AppTheme.trophyAmber,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accentColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: accentColor.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistoryList(GameStateManager state) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: state.getMatchHistory(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: AppTheme.neonLime),
            ),
          );
        }

        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 40, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 10),
                const Text(
                  'No Matches Recorded Yet',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Play Quick Matches or Tournament Cups to build your personal record history!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final match = history[index];
            final won = (match['won'] as num?)?.toInt() == 1;
            final playerScore = (match['player_score'] as num?)?.toInt() ?? 0;
            final opponentScore = (match['opponent_score'] as num?)?.toInt() ?? 0;
            final opponentName = match['opponent_name'] as String? ?? 'Challenger';
            final matchType = (match['match_type'] as String? ?? 'quick') == 'tournament'
                ? 'Tournament Cup'
                : 'Quick Match';
            final smashes = (match['smashes_hit'] as num?)?.toInt() ?? 0;
            final coins = (match['coins_earned'] as num?)?.toInt() ?? 0;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: won ? AppTheme.pickleGreen.withValues(alpha: 0.3) : AppTheme.fireOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  // Outcome badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: won ? AppTheme.pickleGreen.withValues(alpha: 0.2) : AppTheme.fireOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: won ? AppTheme.pickleGreen : AppTheme.fireOrange,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      won ? 'WIN' : 'LOSS',
                      style: TextStyle(
                        color: won ? AppTheme.pickleGreen : AppTheme.fireOrange,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Match details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              matchType,
                              style: const TextStyle(color: AppTheme.electricCyan, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            const SizedBox(width: 6),
                            Text(
                              'vs $opponentName',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Score: $playerScore - $opponentScore',
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$smashes smashes',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Coins
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.goldCoin.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: AppTheme.goldCoin, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+$coins',
                          style: const TextStyle(color: AppTheme.goldCoin, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllPlayersLeaderboardTab(BuildContext context, GameStateManager state) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseService.instance.getAllPlayersLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppTheme.neonLime),
            ),
          );
        }

        final players = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Info Header Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: AppTheme.trophyAmber, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Official Pickleball Smash Rankings. Sorted by Trophies and Match Victories.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  Text(
                    '${players.length} Players',
                    style: const TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (players.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No players registered in database yet.\nCreate an account to be #1 on the leaderboard!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: players.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final player = players[index];
                  final rank = index + 1;
                  final isCurrentPlayer = !state.isGuest && player['user_id'] == state.currentUserId;
                  final username = player['username'] as String? ?? 'Player';
                  final level = player['player_level'] as int? ?? 1;
                  final trophies = player['trophies'] as int? ?? 0;
                  final wins = player['matches_won'] as int? ?? 0;
                  final winRate = player['win_rate'] as int? ?? 0;

                  Color rankColor = AppTheme.textMuted;
                  String rankBadge = '#$rank';
                  if (rank == 1) {
                    rankColor = const Color(0xFFFFD700);
                    rankBadge = '🥇 #1';
                  } else if (rank == 2) {
                    rankColor = const Color(0xFFC0C0C0);
                    rankBadge = '🥈 #2';
                  } else if (rank == 3) {
                    rankColor = const Color(0xFFCD7F32);
                    rankBadge = '🥉 #3';
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrentPlayer ? AppTheme.neonLime.withValues(alpha: 0.1) : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrentPlayer ? AppTheme.neonLime : AppTheme.surfaceBorder,
                        width: isCurrentPlayer ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Rank
                        SizedBox(
                          width: 48,
                          child: Text(
                            rankBadge,
                            style: TextStyle(
                              color: rankColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        // Avatar
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isCurrentPlayer ? AppTheme.neonLime : AppTheme.surfaceBorder,
                          child: Text(
                            username.isNotEmpty ? username[0].toUpperCase() : 'P',
                            style: TextStyle(
                              color: isCurrentPlayer ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Username + You chip
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      username,
                                      style: TextStyle(
                                        color: isCurrentPlayer ? AppTheme.neonLime : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCurrentPlayer) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.neonLime,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'YOU',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                'LVL $level • $winRate% Win Rate',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        // Trophies and Wins
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.emoji_events_rounded, color: AppTheme.trophyAmber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$trophies',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$wins Wins',
                              style: const TextStyle(color: AppTheme.pickleGreen, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
