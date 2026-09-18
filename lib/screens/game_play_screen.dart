import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/pickleball_game.dart';
import '../services/game_state_manager.dart';
import '../theme/app_theme.dart';
import 'auth/register_screen.dart';

class GamePlayScreen extends StatefulWidget {
  final String matchType; // 'quick' or 'tournament'
  final String? tournamentId;
  final String? opponentName;
  final String? matchTitle;

  const GamePlayScreen({
    super.key,
    this.matchType = 'quick',
    this.tournamentId,
    this.opponentName,
    this.matchTitle,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late PickleballGame _game;
  int _p1Score = 0;
  int _p2Score = 0;
  int _smashesCount = 0;
  bool _isPaused = false;
  bool _matchFinished = false;
  bool _playerWon = false;

  @override
  void initState() {
    super.initState();
    final state = GameStateManager.instance;
    final targetScore = widget.matchType == 'tournament' ? 11 : 5;

    _game = PickleballGame(
      targetScore: targetScore,
      joystickOnLeft: state.settings.joystickOnLeft,
      onScoreUpdated: (p1, p2) {
        if (mounted) {
          setState(() {
            _p1Score = p1;
            _p2Score = p2;
          });
        }
      },
      onSmash: () {
        _smashesCount++;
      },
      onMatchFinished: (won) {
        if (mounted) {
          setState(() {
            _matchFinished = true;
            _playerWon = won;
          });
          // Record results in state manager
          state.recordMatchResult(
            won: won,
            smashesHit: _smashesCount,
            tournamentId: widget.tournamentId,
            matchType: widget.matchType,
            opponentName: widget.opponentName ?? 'CPU Challenger',
            playerScore: _p1Score,
            opponentScore: _p2Score,
          );
        }
      },
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _game.pauseEngine();
      } else {
        _game.resumeEngine();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateManager.instance;
    final opponent = widget.opponentName ?? 'CPU Challenger';
    final title = widget.matchTitle ?? (widget.matchType == 'tournament' ? 'Tournament Match' : 'Quick Match');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The Flame Game
          Positioned.fill(
            child: GameWidget(game: _game),
          ),

          // Top In-Game Scoreboard HUD
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.neonLime.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.neonLime,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Score
                    Text(
                      '${state.playerName}  $_p1Score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('-', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                    ),
                    Text(
                      '$_p2Score  $opponent',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Pause button
                    InkWell(
                      onTap: _togglePause,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pause Menu Overlay
          if (_isPaused && !_matchFinished)
            Container(
              color: Colors.black87,
              child: Center(
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.surfaceBorder, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'MATCH PAUSED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _togglePause,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonLime,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('RESUME MATCH', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.surfaceBorder),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('QUIT TO DASHBOARD'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Match Finished Modal Overlay
          if (_matchFinished)
            Container(
              color: Colors.black87,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _playerWon ? AppTheme.neonLime : AppTheme.fireOrange,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_playerWon ? AppTheme.neonLime : AppTheme.fireOrange).withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _playerWon ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                          color: _playerWon ? AppTheme.trophyAmber : AppTheme.fireOrange,
                          size: 56,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _playerWon ? 'VICTORY!' : 'MATCH DEFEAT',
                          style: TextStyle(
                            color: _playerWon ? AppTheme.neonLime : AppTheme.fireOrange,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Final Score: $_p1Score - $_p2Score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Rewards summary
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    _playerWon ? '+100' : '+25',
                                    style: const TextStyle(color: AppTheme.goldCoin, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const Text('Coins', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    _playerWon ? '+80' : '+25',
                                    style: const TextStyle(color: AppTheme.electricCyan, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const Text('XP', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '$_smashesCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const Text('Smashes', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (state.isGuest) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.electricCyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.electricCyan.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_upload_outlined, color: AppTheme.electricCyan, size: 24),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Save Gameplay Data',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      Text(
                                        'Create an account to keep your stats & coins saved.',
                                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(preserveGuestData: true),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.electricCyan,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('REGISTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonLime,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 6,
                          ),
                          child: const Text(
                            'CONTINUE TO DASHBOARD',
                            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

