import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import '../game/pickleball_game.dart';
import '../models/player_avatar.dart';
import '../services/game_state_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_picker_dialog.dart';
import '../widgets/game_2d_button.dart';
import '../widgets/game_2d_text.dart';
import '../widgets/player_avatar.dart';
import 'auth/register_screen.dart';
import 'views/in_game_settings_modal.dart';

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

  // Serve & Rules announcement state
  bool _isWaitingForServe = true;
  int _serverPlayer = 1;
  String _servingSide = 'right';
  String? _announcementTitle;
  String? _announcementSubtitle;
  Timer? _announcementTimer;

  @override
  void initState() {
    super.initState();
    // Switch to landscape orientation for gameplay
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final state = GameStateManager.instance;
    final targetScore = widget.matchType == 'tournament' ? 11 : 5;

    _game = PickleballGame(
      targetScore: targetScore,
      settings: state.settings,
      joystickOnLeft: state.settings.joystickOnLeft,
      onAnnouncement: (title, subtitle) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _announcementTitle = title;
              _announcementSubtitle = subtitle;
            });
            _announcementTimer?.cancel();
            _announcementTimer = Timer(const Duration(milliseconds: 2600), () {
              if (mounted) {
                setState(() {
                  _announcementTitle = null;
                  _announcementSubtitle = null;
                });
              }
            });
          }
        });
      },
      onServeStateChanged: (isWaiting, serverPlayer, servingSide) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isWaitingForServe = isWaiting;
              _serverPlayer = serverPlayer;
              _servingSide = servingSide;
            });
          }
        });
      },
      onScoreUpdated: (p1, p2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _p1Score = p1;
              _p2Score = p2;
            });
          }
        });
      },
      onSmash: () {
        _smashesCount++;
      },
      onMatchFinished: (won) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
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
        });
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

  void _openInGameSettings() {
    final wasPausedBefore = _isPaused;
    if (!_isPaused) {
      _game.pauseEngine();
      setState(() {
        _isPaused = true;
      });
    }

    InGameSettingsModal.show(
      context,
      onSettingsChanged: (newSettings) {
        _game.applySettings(newSettings);
      },
      onResume: () {
        if (!wasPausedBefore && mounted) {
          _togglePause();
        }
      },
    );
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

          // Top In-Game Scoreboard HUD & Serve / Fault Announcements
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Player 1 Avatar, Server Badge, Name & Score
                            InkWell(
                              onTap: () => AvatarPickerDialog.show(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PlayerAvatarWidget(
                                    avatarId: state.playerAvatarId,
                                    size: 24,
                                  ),
                                  _buildServerBadge(_serverPlayer == 1),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${state.playerName}  ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Game2DText.score(
                                    '$_p1Score',
                                    fontSize: 16,
                                    textColor: AppTheme.neonLime,
                                    strokeWidth: 2.2,
                                    shadowOffset: const Offset(0, 1.5),
                                  ),
                                ],
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('-', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                            ),

                            // Opponent Score, Server Badge, Avatar & Name
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Game2DText.score(
                                  '$_p2Score',
                                  fontSize: 16,
                                  textColor: AppTheme.electricCyan,
                                  strokeWidth: 2.2,
                                  shadowOffset: const Offset(0, 1.5),
                                ),
                                const SizedBox(width: 6),
                                _buildServerBadge(_serverPlayer == 2),
                                PlayerAvatarWidget(
                                  avatar: PlayerAvatar.getForOpponent(opponent),
                                  size: 24,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  opponent,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 12),
                            // In-Game Settings button
                            InkWell(
                              key: const ValueKey('ingame_settings_btn'),
                              onTap: _openInGameSettings,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonLime.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.3)),
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  color: AppTheme.neonLime,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Pause button
                            InkWell(
                              key: const ValueKey('ingame_pause_btn'),
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
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Rules Announcement Banner (Faults, Side-Outs, Points)
                    if (_announcementTitle != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _announcementTitle!.contains('FAULT') ? AppTheme.fireOrange : AppTheme.neonLime,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_announcementTitle!.contains('FAULT') ? AppTheme.fireOrange : AppTheme.neonLime)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _announcementTitle!,
                                style: TextStyle(
                                  color: _announcementTitle!.contains('FAULT') ? AppTheme.fireOrange : AppTheme.neonLime,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              if (_announcementSubtitle != null && _announcementSubtitle!.isNotEmpty)
                                Text(
                                  _announcementSubtitle!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Interactive Serve Prompt (when ball is waiting to be served)
                    if (_isWaitingForServe && !_isPaused && !_matchFinished) ...[
                      const SizedBox(height: 4),
                      if (_serverPlayer == 1)
                        GestureDetector(
                          key: const ValueKey('serve_action_prompt'),
                          onTap: () => _game.player1.strike(),
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppTheme.playButtonGradient,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.neonLime.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sports_tennis_rounded, color: Colors.black, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'YOUR SERVE (${_servingSide.toUpperCase()}) • TAP STRIKE TO SERVE',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.electricCyan.withValues(alpha: 0.6), width: 1.2),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sports_tennis_rounded, color: AppTheme.electricCyan, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  'CPU SERVING (${_servingSide.toUpperCase()}) • GET READY',
                                  style: const TextStyle(
                                    color: AppTheme.electricCyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: 360,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.surfaceBorder, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Game2DText.hero(
                          'MATCH PAUSED',
                          fontSize: 22,
                          strokeWidth: 3.5,
                          shadowOffset: const Offset(0, 3.0),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Game2DButton(
                          onPressed: _togglePause,
                          text: 'RESUME MATCH',
                          icon: Icons.play_arrow_rounded,
                          variant: GameButtonVariant.primary,
                          size: GameButtonSize.medium,
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 12),
                        Game2DButton(
                          key: const ValueKey('pause_menu_settings_btn'),
                          onPressed: _openInGameSettings,
                          text: 'MATCH SETTINGS',
                          icon: Icons.tune_rounded,
                          variant: GameButtonVariant.cyan,
                          size: GameButtonSize.medium,
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 12),
                        Game2DButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          text: 'QUIT TO DASHBOARD',
                          icon: Icons.exit_to_app_rounded,
                          variant: GameButtonVariant.dark,
                          size: GameButtonSize.medium,
                          isFullWidth: true,
                        ),
                      ],
                    ),
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
                        Game2DText.hero(
                          _playerWon ? 'VICTORY!' : 'MATCH DEFEAT',
                          fontSize: 24,
                          gradient: _playerWon ? AppTheme.playButtonGradient : null,
                          textColor: _playerWon ? AppTheme.neonLime : AppTheme.fireOrange,
                          strokeColor: const Color(0xFF070B16),
                          strokeWidth: 4.0,
                          shadowOffset: const Offset(0, 3.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Game2DText.score(
                          'Final Score: $_p1Score - $_p2Score',
                          fontSize: 16,
                          textColor: Colors.white,
                          strokeWidth: 2.2,
                          shadowOffset: const Offset(0, 1.5),
                          textAlign: TextAlign.center,
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

  Widget _buildServerBadge(bool isServer) {
    if (!isServer) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 4, right: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFF00),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFCCFF00),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_tennis_rounded, color: Colors.black, size: 10),
          const SizedBox(width: 2),
          Text(
            _servingSide == 'right' ? 'R' : 'L',
            style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _announcementTimer?.cancel();
    // Restore portrait orientation when leaving gameplay
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}

