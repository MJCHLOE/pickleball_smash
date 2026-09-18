import 'package:flutter/material.dart';
import '../../models/tournament_model.dart';
import '../../services/game_state_manager.dart';
import '../../theme/app_theme.dart';

class TournamentView extends StatefulWidget {
  final Function(Tournament tournament, BracketMatch match) onStartMatch;

  const TournamentView({
    super.key,
    required this.onStartMatch,
  });

  @override
  State<TournamentView> createState() => _TournamentViewState();
}

class _TournamentViewState extends State<TournamentView> {
  int _selectedTournamentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = GameStateManager.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final tournaments = state.tournaments;
        if (_selectedTournamentIndex >= tournaments.length) {
          _selectedTournamentIndex = 0;
        }
        final currentTournament = tournaments[_selectedTournamentIndex];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 16),
                      // Tournament selector tabs
                      _buildTournamentSelector(tournaments),
                      const SizedBox(height: 20),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildTournamentInfoCard(currentTournament, state),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 6,
                              child: _buildBracketTreeCard(currentTournament, state),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildTournamentInfoCard(currentTournament, state),
                            const SizedBox(height: 20),
                            _buildBracketTreeCard(currentTournament, state),
                          ],
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.trophyAmber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.emoji_events, color: AppTheme.trophyAmber, size: 24),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Championship Tournaments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Climb the knockout brackets and earn prestigious trophies',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTournamentSelector(List<Tournament> tournaments) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tournaments.length, (index) {
          final t = tournaments[index];
          final isSelected = _selectedTournamentIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTournamentIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.surfaceLight : AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.trophyAmber : AppTheme.surfaceBorder,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.trophyAmber.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Text(t.badge, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      t.title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (!t.isUnlocked) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lock, color: AppTheme.textMuted, size: 16),
                    ] else if (t.isCompleted) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: AppTheme.neonLime, size: 16),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTournamentInfoCard(Tournament tournament, GameStateManager state) {
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
              Text(tournament.badge, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildDifficultyChip(tournament.difficulty),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tournament.subtitle,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const Divider(color: AppTheme.surfaceBorder, height: 28),
          // Prize Pool & Entry Fee
          _buildInfoRow(
            icon: Icons.monetization_on,
            iconColor: AppTheme.goldCoin,
            label: 'Prize Reward',
            value: '+${tournament.rewardCoins} Coins',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.emoji_events,
            iconColor: AppTheme.trophyAmber,
            label: 'Trophy Bonus',
            value: '+${tournament.rewardTrophies} Trophies',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.confirmation_number,
            iconColor: AppTheme.electricCyan,
            label: 'Entry Fee',
            value: tournament.entryFee == 0 ? 'Free Entry' : '${tournament.entryFee} Coins',
          ),
          const SizedBox(height: 24),
          // Action button
          if (!tournament.isUnlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: AppTheme.textMuted, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Unlocked at 500 Trophies',
                    style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else if (tournament.isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  state.restartTournament(tournament.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppTheme.neonLime),
                  ),
                ),
                icon: const Icon(Icons.refresh, color: AppTheme.neonLime),
                label: const Text(
                  'REPLAY TOURNAMENT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else if (tournament.currentMatch != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onStartMatch(tournament, tournament.currentMatch!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.trophyAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                  shadowColor: AppTheme.trophyAmber.withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.sports_tennis_rounded),
                label: Text(
                  'PLAY ${tournament.currentMatch!.roundTitle.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(TournamentDifficulty diff) {
    Color color;
    String text;
    switch (diff) {
      case TournamentDifficulty.easy:
        color = AppTheme.neonLime;
        text = 'BEGINNER';
        break;
      case TournamentDifficulty.medium:
        color = AppTheme.electricCyan;
        text = 'PRO LEVEL';
        break;
      case TournamentDifficulty.hard:
        color = AppTheme.fireOrange;
        text = 'CHAMPION';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBracketTreeCard(Tournament tournament, GameStateManager state) {
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
          const Row(
            children: [
              Icon(Icons.account_tree_rounded, color: AppTheme.electricCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'Knockout Bracket',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bracket cards flow
          ...List.generate(tournament.matches.length, (index) {
            final match = tournament.matches[index];
            final isLast = index == tournament.matches.length - 1;

            return Column(
              children: [
                _buildBracketMatchItem(match, tournament, index),
                if (!isLast) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 2,
                    height: 24,
                    color: match.isCompleted ? AppTheme.neonLime : AppTheme.surfaceBorder,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBracketMatchItem(BracketMatch match, Tournament tournament, int index) {
    Color borderColor = AppTheme.surfaceBorder;
    if (match.isCurrentMatch) {
      borderColor = AppTheme.trophyAmber;
    } else if (match.isCompleted) {
      borderColor = match.isPlayerWinner ? AppTheme.neonLime : AppTheme.fireOrange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: match.isCurrentMatch
            ? AppTheme.trophyAmber.withValues(alpha: 0.08)
            : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: match.isCurrentMatch ? 2 : 1),
      ),
      child: Row(
        children: [
          // Round indicator icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: match.isCompleted
                  ? (match.isPlayerWinner ? AppTheme.neonLime : AppTheme.fireOrange)
                  : (match.isCurrentMatch ? AppTheme.trophyAmber : Colors.white12),
            ),
            child: Center(
              child: match.isCompleted
                  ? Icon(
                      match.isPlayerWinner ? Icons.check : Icons.close,
                      color: Colors.black,
                      size: 20,
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: match.isCurrentMatch ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.roundTitle,
                  style: TextStyle(
                    color: match.isCurrentMatch ? AppTheme.trophyAmber : AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      match.player1Name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('vs', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ),
                    Text(
                      match.player2Name,
                      style: TextStyle(
                        color: match.isCurrentMatch ? AppTheme.electricCyan : Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Score or status badge
          if (match.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${match.player1Score} - ${match.player2Score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )
          else if (match.isCurrentMatch && tournament.isUnlocked)
            ElevatedButton(
              onPressed: () {
                widget.onStartMatch(tournament, match);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.trophyAmber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('PLAY', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else
            const Text(
              'Locked',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

