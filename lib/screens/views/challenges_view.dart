import 'package:flutter/material.dart';
import '../../models/challenge_model.dart';
import '../../services/game_state_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_2d_button.dart';
import '../../widgets/game_2d_text.dart';

class ChallengesView extends StatefulWidget {
  final VoidCallback onGoPlay;

  const ChallengesView({
    super.key,
    required this.onGoPlay,
  });

  @override
  State<ChallengesView> createState() => _ChallengesViewState();
}

class _ChallengesViewState extends State<ChallengesView> {
  ChallengeType _selectedTab = ChallengeType.daily;

  @override
  Widget build(BuildContext context) {
    final state = GameStateManager.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final filteredChallenges = state.challenges
            .where((c) => c.type == _selectedTab)
            .toList();

        final completedCount = filteredChallenges.where((c) => c.isCompleted).length;
        final totalCount = filteredChallenges.length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 750;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, completedCount, totalCount),
                      const SizedBox(height: 16),
                      _buildTabSelector(),
                      const SizedBox(height: 20),
                      if (filteredChallenges.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No challenges found in this section.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ),
                        )
                      else if (isWide)
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: filteredChallenges.map((challenge) {
                            final cardWidth = (constraints.maxWidth - 48) / 2;
                            return SizedBox(
                              width: cardWidth,
                              child: _buildChallengeCard(context, challenge, state),
                            );
                          }).toList(),
                        )
                      else
                        Column(
                          children: filteredChallenges.map((challenge) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: _buildChallengeCard(context, challenge, state),
                            );
                          }).toList(),
                        ),
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

  Widget _buildHeader(BuildContext context, int completed, int total) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.electricCyan.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.military_tech_rounded, color: AppTheme.electricCyan, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Game2DText.title(
                'Smash Challenges',
                fontSize: 22,
                textColor: Colors.white,
                strokeWidth: 3.0,
                shadowOffset: const Offset(0, 2.5),
              ),
              Text(
                'Completed $completed of $total challenges',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTabButton(
            title: 'Daily Quests',
            icon: Icons.calendar_today_rounded,
            isSelected: _selectedTab == ChallengeType.daily,
            onTap: () {
              setState(() {
                _selectedTab = ChallengeType.daily;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTabButton(
            title: 'Career Milestones',
            icon: Icons.workspace_premium_rounded,
            isSelected: _selectedTab == ChallengeType.career,
            onTap: () {
              setState(() {
                _selectedTab = ChallengeType.career;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.electricCyan.withValues(alpha: 0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.electricCyan : AppTheme.surfaceBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.electricCyan : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, ChallengeItem challenge, GameStateManager state) {
    final isDone = challenge.isCompleted;
    final isClaimed = challenge.isClaimed;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone && !isClaimed ? AppTheme.neonLime : AppTheme.surfaceBorder,
          width: isDone && !isClaimed ? 1.5 : 1.0,
        ),
        boxShadow: isDone && !isClaimed
            ? [
                BoxShadow(
                  color: AppTheme.neonLime.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDone ? AppTheme.neonLime.withValues(alpha: 0.15) : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDone ? Icons.verified_rounded : Icons.sports_tennis_rounded,
                  color: isDone ? AppTheme.neonLime : AppTheme.electricCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Game2DText.title(
                      challenge.title,
                      fontSize: 16,
                      textColor: Colors.white,
                      strokeWidth: 2.2,
                      shadowOffset: const Offset(0, 1.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: challenge.progressRatio,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? AppTheme.neonLime : AppTheme.electricCyan,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${challenge.currentProgress} / ${challenge.goal}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Rewards & Claim action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.goldCoin.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: AppTheme.goldCoin, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+${challenge.rewardCoins}',
                          style: const TextStyle(
                            color: AppTheme.goldCoin,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: AppTheme.electricCyan, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+${challenge.rewardXp} XP',
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
              if (isClaimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check, color: AppTheme.textMuted, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Claimed',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else if (isDone)
                Game2DButton(
                  onPressed: () {
                    state.claimChallenge(challenge.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppTheme.neonLime,
                        content: Text(
                          'Reward Claimed: +${challenge.rewardCoins} Coins, +${challenge.rewardXp} XP!',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  text: 'CLAIM',
                  icon: Icons.check_circle_outline_rounded,
                  variant: GameButtonVariant.primary,
                  size: GameButtonSize.small,
                )
              else
                Game2DButton(
                  onPressed: widget.onGoPlay,
                  text: 'PLAY',
                  icon: Icons.play_arrow_rounded,
                  variant: GameButtonVariant.dark,
                  size: GameButtonSize.small,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

