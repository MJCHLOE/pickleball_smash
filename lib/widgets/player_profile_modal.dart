import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/multiplayer_models.dart';
import '../services/audio_service.dart';
import '../services/multiplayer_service.dart';
import '../theme/app_theme.dart';
import 'avatar_picker_dialog.dart';
import 'game_2d_button.dart';
import 'game_2d_text.dart';
import 'player_avatar.dart';

/// Comprehensive Mobile Legends: Bang Bang style Player Profile Modal.
class PlayerProfileModal extends StatefulWidget {
  final String playerId;
  final bool isMyProfile;

  const PlayerProfileModal({
    super.key,
    required this.playerId,
    this.isMyProfile = false,
  });

  static void show(BuildContext context, {String? playerId}) {
    final multi = MultiplayerService.instance;
    final isMe = playerId == null || playerId == multi.myProfile.playerId;
    final targetId = playerId ?? multi.myProfile.playerId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (ctx) => PlayerProfileModal(
        playerId: targetId,
        isMyProfile: isMe,
      ),
    );
  }

  @override
  State<PlayerProfileModal> createState() => _PlayerProfileModalState();
}

class _PlayerProfileModalState extends State<PlayerProfileModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _historyDisplayLimit = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isMyProfile ? 4 : 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multi = MultiplayerService.instance;
    final profile = multi.getProfileForPlayer(widget.playerId);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.90,
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
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header Hero Banner
          _buildHeroHeader(profile, multi),

          // Tab Bar
          Container(
            color: const Color(0xFF0F172A),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.neonLime,
              indicatorWeight: 3,
              labelColor: AppTheme.neonLime,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                const Tab(icon: Icon(Icons.analytics_outlined, size: 18), text: 'Overview'),
                const Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'History'),
                const Tab(icon: Icon(Icons.military_tech_outlined, size: 18), text: 'Badges'),
                if (widget.isMyProfile)
                  const Tab(icon: Icon(Icons.security_rounded, size: 18), text: 'Privacy'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(profile),
                _buildHistoryTab(profile),
                _buildBadgesTab(profile),
                if (widget.isMyProfile) _buildPrivacyTab(profile, multi),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(PlayerProfileModel profile, MultiplayerService multi) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            profile.rankTier.color.withValues(alpha: 0.25),
            const Color(0xFF0B132B),
          ],
        ),
        border: const Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with rank border
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: profile.rankTier.color, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: profile.rankTier.color.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: PlayerAvatarWidget(
                  avatarId: profile.avatarId,
                  size: 58,
                  showBadge: false,
                  onTap: widget.isMyProfile
                      ? () async {
                          AudioService.instance.playButtonTap();
                          await AvatarPickerDialog.show(context);
                          if (mounted) setState(() {});
                        }
                      : null,
                ),
              ),
              if (widget.isMyProfile)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCyan,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.black, size: 10),
                  ),
                ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: profile.rankTier.color, width: 1),
                  ),
                  child: Text(
                    'LV.${profile.level}',
                    style: TextStyle(
                      color: profile.rankTier.color,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Player Name, ID, Rank Tier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Game2DText(
                        profile.nickname,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        textColor: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: profile.status.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: profile.status.color, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(profile.status.icon, color: profile.status.color, size: 10),
                          const SizedBox(width: 4),
                          Text(
                            profile.status.label,
                            style: TextStyle(
                              color: profile.status.color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Player ID with copy
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: profile.playerId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied ID ${profile.playerId} to clipboard!'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.playerId,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, color: AppTheme.textMuted, size: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Rank Tier Tag
                Row(
                  children: [
                    Text(profile.rankTier.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      profile.rankTier.title,
                      style: TextStyle(
                        color: profile.rankTier.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      children: List.generate(
                        profile.rankStars,
                        (index) => const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Button (Invite or Close)
          if (!widget.isMyProfile)
            Game2DButton(
              onPressed: () {
                Navigator.of(context).pop();
                final friend = multi.friends.firstWhere(
                  (f) => f.playerId == profile.playerId,
                  orElse: () => FriendModel(
                    id: profile.id,
                    playerId: profile.playerId,
                    nickname: profile.nickname,
                    avatarId: profile.avatarId,
                    status: profile.status,
                    rankTier: profile.rankTier,
                  ),
                );
                final err = multi.inviteFriendToBattle(friend);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err ?? 'Battle invitation sent to ${profile.nickname}!'),
                    backgroundColor: err != null ? Colors.red : AppTheme.surfaceLight,
                  ),
                );
              },
              text: 'INVITE',
              icon: Icons.sports_tennis_rounded,
              variant: GameButtonVariant.primary,
              size: GameButtonSize.small,
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(PlayerProfileModel profile) {
    if (!profile.isPublicStats && !widget.isMyProfile) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, color: AppTheme.textMuted, size: 40),
            SizedBox(height: 12),
            Text(
              'This player has kept their statistics private.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Win Rate & Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Row(
            children: [
              // Win Rate Circular Meter
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: profile.winRate / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonLime),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${profile.winRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'WIN RATE',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Match Counts
              Expanded(
                child: Column(
                  children: [
                    _buildStatRow('Total Matches', '${profile.totalMatches}'),
                    const Divider(color: Colors.white10, height: 12),
                    _buildStatRow('Victories', '${profile.wins}', valueColor: AppTheme.neonLime),
                    const Divider(color: Colors.white10, height: 12),
                    _buildStatRow('Defeats', '${profile.losses}', valueColor: const Color(0xFFEF4444)),
                    const Divider(color: Colors.white10, height: 12),
                    _buildStatRow('Win Streak', '🔥 ${profile.winStreak} Streak', valueColor: const Color(0xFFFBBF24)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Gameplay Performance Metrics
        const Text(
          'COMBAT STATISTICS',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Total Smashes',
                value: '${profile.smashes}',
                icon: Icons.bolt_rounded,
                accentColor: AppTheme.neonLime,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Service Aces',
                value: '${profile.aces}',
                icon: Icons.adjust_rounded,
                accentColor: AppTheme.electricCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Longest Rally',
                value: '${profile.longestRally} Hits',
                icon: Icons.local_fire_department_rounded,
                accentColor: const Color(0xFFF97316),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'Flawless Rallies',
                value: '${profile.flawlessRallies}',
                icon: Icons.shield_rounded,
                accentColor: const Color(0xFFA855F7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {Color valueColor = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(PlayerProfileModel profile) {
    if (!profile.isPublicHistory && !widget.isMyProfile) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off_rounded, color: AppTheme.textMuted, size: 40),
            SizedBox(height: 12),
            Text(
              'Match history is set to private by this player.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (profile.recentMatches.isEmpty) {
      return const Center(
        child: Text(
          'No recent matches found.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
      );
    }

    final visibleMatches = profile.recentMatches.take(_historyDisplayLimit).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...visibleMatches.map((m) => _buildMatchCard(m)),
        if (visibleMatches.length < profile.recentMatches.length)
          Center(
            child: TextButton.icon(
              onPressed: () {
                AudioService.instance.playButtonTap();
                setState(() {
                  _historyDisplayLimit += 5;
                });
              },
              icon: const Icon(Icons.expand_more_rounded, color: AppTheme.neonLime),
              label: const Text(
                'LOAD MORE MATCHES',
                style: TextStyle(
                  color: AppTheme.neonLime,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMatchCard(MatchRecordModel m) {
    final winColor = m.isVictory ? AppTheme.neonLime : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: m.isVictory
              ? AppTheme.neonLime.withValues(alpha: 0.35)
              : Colors.red.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          // Top Ribbon: Result, Mode, Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: winColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: winColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    m.result.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (m.isMvp) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded, size: 11, color: Colors.black),
                        SizedBox(width: 2),
                        Text(
                          'MVP',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  m.gameMode,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '⏱ ${m.durationFormatted}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),

          // Match Body: Characters & Score
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // My Hero
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: winColor, width: 1.5),
                      ),
                      child: PlayerAvatarWidget(
                        avatarId: m.characterUsed.toLowerCase().contains('maya')
                            ? 'maya_speed'
                            : 'alex_classic',
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.characterUsed,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Score Display
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${m.myScore}',
                            style: TextStyle(
                              color: winColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '-',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 18),
                            ),
                          ),
                          Text(
                            '${m.opponentScore}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('⚡ ${m.smashes} Smashes', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          const SizedBox(width: 10),
                          Text('🎯 ${m.aces} Aces', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Opponent
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: PlayerAvatarWidget(
                        avatarId: m.opponentCharacter.toLowerCase().contains('maya')
                            ? 'maya_speed'
                            : (m.opponentCharacter.toLowerCase().contains('jax')
                                ? 'male3_power'
                                : 'male2_allround'),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.opponentName,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab(PlayerProfileModel profile) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: profile.badges.length,
      itemBuilder: (context, index) {
        final b = profile.badges[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: b.isUnlocked
                  ? AppTheme.electricCyan.withValues(alpha: 0.3)
                  : Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(b.icon, style: const TextStyle(fontSize: 24)),
                  const Spacer(),
                  if (b.isUnlocked)
                    const Icon(Icons.check_circle_rounded, color: AppTheme.neonLime, size: 16)
                  else
                    const Icon(Icons.lock_rounded, color: AppTheme.textMuted, size: 16),
                ],
              ),
              const Spacer(),
              Text(
                b.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                b.description,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacyTab(PlayerProfileModel profile, MultiplayerService multi) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'PRIVACY & PROFILE VISIBILITY',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Public Combat Statistics', style: TextStyle(color: Colors.white)),
          subtitle: const Text(
            'Allow other players and friends to view your win rate, smashes, and records.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          value: profile.isPublicStats,
          activeThumbColor: AppTheme.neonLime,
          onChanged: (val) {
            AudioService.instance.playButtonTap();
            multi.updatePrivacySettings(
              isPublicStats: val,
              isPublicHistory: profile.isPublicHistory,
            );
          },
        ),
        const Divider(color: AppTheme.surfaceBorder),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Public Match History', style: TextStyle(color: Colors.white)),
          subtitle: const Text(
            'Allow other players to inspect your recent matches and scorelines.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          value: profile.isPublicHistory,
          activeThumbColor: AppTheme.neonLime,
          onChanged: (val) {
            AudioService.instance.playButtonTap();
            multi.updatePrivacySettings(
              isPublicStats: profile.isPublicStats,
              isPublicHistory: val,
            );
          },
        ),
      ],
    );
  }
}
