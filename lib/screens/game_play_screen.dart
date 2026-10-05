import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import '../game/pickleball_game.dart';
import '../models/ball_catalog.dart';
import '../models/character_roster.dart';
import '../models/court_catalog.dart';
import '../models/multiplayer_models.dart';
import '../models/player_avatar.dart';
import '../services/audio_service.dart';
import '../services/game_state_manager.dart';
import '../services/multiplayer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_picker_dialog.dart';
import '../widgets/game_2d_button.dart';
import '../widgets/game_2d_text.dart';
import '../widgets/player_avatar.dart';
import 'auth/register_screen.dart';
import 'views/in_game_settings_modal.dart';
import '../widgets/hud_controls_adjuster_modal.dart';
import '../widgets/pickleball_rules_modal.dart';

class GamePlayScreen extends StatefulWidget {
  final String matchType; // 'quick' or 'tournament'
  final String? tournamentId;
  final String? opponentName;
  final String? matchTitle;
  final bool isDoubles;
  final String? opponentCharacterId;
  final String? opponentBallId;
  final String? opponentCourtId;

  const GamePlayScreen({
    super.key,
    this.matchType = 'quick',
    this.tournamentId,
    this.opponentName,
    this.matchTitle,
    this.isDoubles = false,
    this.opponentCharacterId,
    this.opponentBallId,
    this.opponentCourtId,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> with WidgetsBindingObserver {
  late PickleballGame _game;
  int _p1Score = 0;
  int _p2Score = 0;
  int _smashesCount = 0;
  bool _isPaused = false;
  bool _matchFinished = false;
  bool _playerWon = false;
  int _currentRallyStreak = 0;
  int _longestRally = 0;
  Timer? _autoRestartTimer;

  // Serve & Rules announcement state
  bool _isWaitingForServe = true;
  int _serverPlayer = 1;
  String _servingSide = 'right';
  String? _announcementTitle;
  String? _announcementSubtitle;
  Timer? _announcementTimer;

  // Dedicated Violation Display state
  String? _violationType;
  String? _violationDescription;
  String? _violationRuleDetail;
  Timer? _violationTimer;

  // Multiplayer opponent & partner info
  String? _myAvatarId;
  String? _opponentAvatarId;
  String? _opponentPlayerName;
  String? _partnerAvatarId;
  String? _opponentPartnerAvatarId;
  bool _isOpponentBot = false;
  ChatMessageModel? _activeFloatingChat;
  Timer? _chatBubbleTimer;

  void _onInGameChatReceived() {
    final msg = MultiplayerService.instance.latestInGameChatNotifier.value;
    if (msg != null && mounted) {
      setState(() {
        _activeFloatingChat = msg;
      });
      AudioService.instance.playPaddleHit();
      _chatBubbleTimer?.cancel();
      _chatBubbleTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) {
          setState(() {
            _activeFloatingChat = null;
          });
        }
      });
    }
  }

  @visibleForTesting
  void setViolationForTest(String type, String desc, String ruleDetail) {
    setState(() {
      _violationType = type;
      _violationDescription = desc;
      _violationRuleDetail = ruleDetail;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // Auto-pause game match if user went to home screen, locked phone, or switched apps
      if (!_isPaused && !_matchFinished) {
        _game.pauseEngine();
        setState(() {
          _isPaused = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MultiplayerService.instance.latestInGameChatNotifier.addListener(_onInGameChatReceived);
    // Switch to landscape orientation and immersive full-screen for gameplay
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    AudioService.instance.playInGameBgm();

    final state = GameStateManager.instance;
    const targetScore = 11; // Standard Pickleball Game is 11 points
    final p1Char = CharacterRoster.getById(state.playerAvatarId);
    CharacterType p1Type = p1Char.type;

    // AI bot opponents select among characters including male2, male3, male4, female2, female3, and female4
    CharacterType p2Type;
    final oppLower = (widget.opponentName ?? '').toLowerCase();
    if (oppLower.contains('female4') || oppLower.contains('ashley')) {
      p2Type = CharacterType.female4;
    } else if (oppLower.contains('male4') || oppLower.contains('nard')) {
      p2Type = CharacterType.male4;
    } else if (oppLower.contains('female3') || oppLower.contains('surge') || oppLower.contains('disney')) {
      p2Type = CharacterType.female3;
    } else if (oppLower.contains('frost') || oppLower.contains('chloe') || oppLower.contains('luna') || oppLower.contains('female2') || oppLower.contains('joy')) {
      p2Type = CharacterType.female2;
    } else if (oppLower.contains('smash') || oppLower.contains('sammy') || oppLower.contains('jax')) {
      p2Type = CharacterType.male3;
    } else if (oppLower.contains('blaze') || oppLower.contains('rocky') || oppLower.contains('iron') || oppLower.contains('viper') || oppLower.contains('marcus')) {
      p2Type = CharacterType.male2;
    } else if (oppLower.contains('sarah') || oppLower.contains('maya')) {
      p2Type = CharacterType.female1;
    } else {
      p2Type = CharacterType.male1;
    }

    CharacterType partner1Type = CharacterType.female1;
    CharacterType partner2Type = CharacterType.male2;

    final bool isMultiplayer = widget.matchType == 'multiplayer';
    final multi = MultiplayerService.instance;
    final bool isHost = multi.isHost;
    final room = multi.currentRoom;

    final effectiveTargetScore = (isMultiplayer && room != null) ? room.targetScore : targetScore;
    final effectiveCourtId = (isMultiplayer && room != null) ? room.courtId : state.equippedCourtId;
    String effectiveBallId = state.equippedBallId;

    if (isMultiplayer && room != null) {
      // Find my own slot
      final mySlot = room.slots.firstWhere(
        (s) => s.playerId == multi.myProfile.playerId,
        orElse: () => isHost ? room.slots.first : (room.slots.length > 1 ? room.slots[1] : room.slots.first),
      );
      final myCharId = mySlot.characterId.isNotEmpty ? mySlot.characterId : (mySlot.playerAvatar ?? state.playerAvatarId);
      final myChar = CharacterRoster.getById(myCharId);
      p1Type = myChar.type;
      _myAvatarId = myChar.id;

      // Find primary opponent slot
      final oppSlot = room.slots.firstWhere(
        (s) => !s.isEmpty && s.playerId != mySlot.playerId && (widget.isDoubles ? s.team != mySlot.team : true),
        orElse: () => room.slots.firstWhere(
          (s) => isHost ? (!s.isHost && !s.isEmpty) : (s.isHost && !s.isEmpty),
          orElse: () => room.slots.firstWhere((s) => s.playerId != multi.myProfile.playerId, orElse: () => room.slots.first),
        ),
      );
      final oppCharId = oppSlot.characterId.isNotEmpty ? oppSlot.characterId : (oppSlot.playerAvatar ?? 'alex_classic');
      final oppChar = CharacterRoster.getById(oppCharId);
      p2Type = oppChar.type;
      _opponentAvatarId = oppChar.id;
      _isOpponentBot = oppSlot.isBot || oppSlot.isEmpty;
      _opponentPlayerName = oppSlot.playerName ?? widget.opponentName ?? (_isOpponentBot ? 'CPU Challenger' : 'Opponent');

      effectiveBallId = isHost ? mySlot.ballId : oppSlot.ballId;

      final oppBall = BallCatalog.getById(oppSlot.ballId);
      final oppCourt = CourtCatalog.getById(oppSlot.courtId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _game.onAnnouncement?.call(
            'LOADOUTS REVEALED!',
            'VS ${oppChar.name} • Secret Ball: ${oppBall.name} (${oppBall.badge}) • Court: ${oppCourt.name}',
          );
        }
      });

      if (widget.isDoubles) {
        // Find partner (same team as mySlot)
        final myPartnerSlot = room.slots.firstWhere(
          (s) => s.slotIndex != mySlot.slotIndex && s.team == mySlot.team && !s.isEmpty,
          orElse: () => room.slots.firstWhere(
            (s) => s.slotIndex != mySlot.slotIndex && s.team == mySlot.team,
            orElse: () => mySlot,
          ),
        );
        if (!myPartnerSlot.isEmpty) {
          final p1pCharId = myPartnerSlot.characterId.isNotEmpty ? myPartnerSlot.characterId : (myPartnerSlot.playerAvatar ?? 'kai');
          final p1pChar = CharacterRoster.getById(p1pCharId);
          partner1Type = p1pChar.type;
          _partnerAvatarId = p1pChar.id;
        }

        // Find opponent partner (same team as oppSlot)
        final oppPartnerSlot = room.slots.firstWhere(
          (s) => s.slotIndex != oppSlot.slotIndex && s.team == oppSlot.team && !s.isEmpty,
          orElse: () => room.slots.firstWhere(
            (s) => s.slotIndex != oppSlot.slotIndex && s.team == oppSlot.team,
            orElse: () => oppSlot,
          ),
        );
        if (!oppPartnerSlot.isEmpty) {
          final p2pCharId = oppPartnerSlot.characterId.isNotEmpty ? oppPartnerSlot.characterId : (oppPartnerSlot.playerAvatar ?? 'female1');
          final p2pChar = CharacterRoster.getById(p2pCharId);
          partner2Type = p2pChar.type;
          _opponentPartnerAvatarId = p2pChar.id;
        }
      }
    }

    _game = PickleballGame(
      targetScore: effectiveTargetScore,
      settings: state.settings,
      joystickOnLeft: state.settings.joystickOnLeft,
      player1IsFemale: p1Type == CharacterType.female1 ||
          p1Type == CharacterType.female2 ||
          p1Type == CharacterType.female3 ||
          p1Type == CharacterType.female4,
      player1CharacterType: p1Type,
      player2CharacterType: p2Type,
      partner1CharacterType: partner1Type,
      partner2CharacterType: partner2Type,
      isDoubles: widget.isDoubles,
      courtId: effectiveCourtId,
      ballId: effectiveBallId,
      isMultiplayer: isMultiplayer,
      isHost: isHost,
      isOpponentAI: _isOpponentBot,
      player1Name: state.playerName,
      player2Name: _opponentPlayerName ?? widget.opponentName ?? (_isOpponentBot ? 'CPU Challenger' : 'Opponent'),
      partner1Name: widget.isDoubles ? 'Partner' : null,
      partner2Name: widget.isDoubles ? 'Opponent 2' : null,
      onViolation: (type, desc, ruleDetail) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _violationType = type;
              _violationDescription = desc;
              _violationRuleDetail = ruleDetail;
            });
            _violationTimer?.cancel();
            _violationTimer = Timer(const Duration(milliseconds: 3200), () {
              if (mounted) {
                setState(() {
                  _violationType = null;
                  _violationDescription = null;
                  _violationRuleDetail = null;
                });
              }
            });
          }
        });
      },
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
      onRallyStreakUpdated: (streak, longest) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentRallyStreak = streak;
              _longestRally = longest;
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
            if (won) {
              AudioService.instance.playVictory();
            } else {
              AudioService.instance.playDefeat();
            }
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

            if (widget.matchType == 'multiplayer') {
              MultiplayerService.instance.recordOnlineMatch(
                won: won,
                opponentName: widget.opponentName ?? 'Online Challenger',
                opponentCharacter: p2Type.name,
                myScore: _p1Score,
                opponentScore: _p2Score,
                smashes: _smashesCount,
                aces: 2,
                durationSeconds: _game.elapsedTime.toInt(),
                gameMode: widget.isDoubles ? '2v2 Doubles' : '1v1 Singles',
              );
            }

            _autoRestartTimer?.cancel();
          }
        });
      },
    );

    if (widget.matchType == 'multiplayer') {
      MultiplayerService.instance.hostDisconnectedNotifier.addListener(_onHostDisconnected);
    }
  }

  void _onHostDisconnected() {
    final reason = MultiplayerService.instance.hostDisconnectedNotifier.value;
    if (reason != null && mounted) {
      _game.pauseEngine();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEF4444), width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Color(0xFFEF4444), size: 28),
              SizedBox(width: 10),
              Text(
                'HOST DISCONNECTED',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Text(
            reason,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonLime,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('BACK TO LOBBY', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _restartForNextMatch() {
    _autoRestartTimer?.cancel();
    setState(() {
      _matchFinished = false;
      _isPaused = false;
      _p1Score = 0;
      _p2Score = 0;
      _smashesCount = 0;
      _isWaitingForServe = true;
      _currentRallyStreak = 0;
    });
    _game.resetForNewMatch();
  }

  void _togglePause() {
    AudioService.instance.playButtonTap();
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _game.pauseEngine();
        AudioService.instance.pauseBgm();
      } else {
        _game.resumeEngine();
        AudioService.instance.resumeBgm();
      }
    });
  }

  void _openInGameSettings() {
    AudioService.instance.playButtonTap();
    final wasPausedBefore = _isPaused;
    if (!_isPaused) {
      _game.pauseEngine();
      AudioService.instance.pauseBgm();
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

  void _openRulesModal({String? violation}) {
    AudioService.instance.playButtonTap();
    final wasPausedBefore = _isPaused;
    if (!_isPaused) {
      _game.pauseEngine();
      AudioService.instance.pauseBgm();
      setState(() {
        _isPaused = true;
      });
    }

    PickleballRulesModal.show(
      context,
      highlightedViolation: violation,
      onResume: () {
        if (!wasPausedBefore && mounted) {
          _togglePause();
        }
      },
    );
  }

  void _openHudAdjusterModal() {
    AudioService.instance.playButtonTap();
    final wasPausedBefore = _isPaused;
    if (!_isPaused) {
      _game.pauseEngine();
      AudioService.instance.pauseBgm();
      setState(() {
        _isPaused = true;
      });
    }

    HudControlsAdjusterModal.show(
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
    final opponent = _opponentPlayerName ?? widget.opponentName ?? 'CPU Challenger';
    final title = widget.matchTitle ??
        (widget.isDoubles
            ? '2v2 Doubles'
            : (widget.matchType == 'tournament' ? 'Tournament Match' : 'Quick Match'));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          AudioService.instance.playMenuBgm();
        }
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The Flame Game (Isolated in RepaintBoundary to prevent Flutter UI overlay repaints from invalidating canvas)
          Positioned.fill(
            child: RepaintBoundary(
              child: GameWidget(game: _game),
            ),
          ),

          // Top In-Game Header: Top-Left Scoreboard, Top-Center Violation/Serve, Top-Right Unified Controls
          SafeArea(
            child: RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final bool isWideScreen = availableWidth >= 660;

                  if (isWideScreen) {
                    final scoreboardWidth = math.min(320.0, availableWidth * 0.38);
                    final centerMaxWidth = math.min(440.0, availableWidth - scoreboardWidth - 145.0);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 1. Top-Left: Score Board
                        Align(
                          alignment: Alignment.topLeft,
                          child: _buildTopLeftScoreBoard(context, state, opponent, title, maxWidth: scoreboardWidth),
                        ),

                        // 2. Top-Center: Status Display & Serve Prompt
                        Align(
                          alignment: Alignment.topCenter,
                          child: _buildTopCenterStatusDisplay(context, maxWidth: centerMaxWidth),
                        ),

                        // 3. Top-Right: Settings, Rules, and Pause, with Violation Display underneath
                        Align(
                          alignment: Alignment.topRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTopRightUnifiedControls(),
                              if (_violationType != null)
                                _buildRightSideViolationDisplay(context, maxWidth: math.min(280.0, availableWidth * 0.42)),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Compact / Portrait Screen Layout: Scoreboard & Controls on top, Center HUD cleanly below
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: _buildTopLeftScoreBoard(context, state, opponent, title, maxWidth: availableWidth - 140.0),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTopRightUnifiedControls(),
                                if (_violationType != null)
                                  _buildRightSideViolationDisplay(context, maxWidth: math.min(240.0, availableWidth * 0.5)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildTopCenterStatusDisplay(context, maxWidth: availableWidth - 12.0),
                      ],
                    );
                  }
                },
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
                    constraints: const BoxConstraints(maxWidth: 360),
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
                          key: const ValueKey('pause_menu_rules_btn'),
                          onPressed: () => _openRulesModal(),
                          text: 'OFFICIAL RULES GUIDE',
                          icon: Icons.menu_book_rounded,
                          variant: GameButtonVariant.cyan,
                          size: GameButtonSize.medium,
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 12),
                        Game2DButton(
                          key: const ValueKey('pause_menu_hud_adjuster_btn'),
                          onPressed: _openHudAdjusterModal,
                          text: 'HUD & CONTROLS ADJUSTER',
                          icon: Icons.gamepad_rounded,
                          variant: GameButtonVariant.amber,
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
                    constraints: const BoxConstraints(maxWidth: 380),
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
                        const SizedBox(height: 18),
                        // Continuous Play: Instant Play Next Match button
                        Game2DButton(
                          key: const ValueKey('play_next_match_btn'),
                          onPressed: _restartForNextMatch,
                          text: 'PLAY NEXT MATCH (CONTINUOUS)',
                          icon: Icons.play_arrow_rounded,
                          variant: GameButtonVariant.primary,
                          size: GameButtonSize.medium,
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 10),
                        Game2DButton(
                          key: const ValueKey('rematch_btn'),
                          onPressed: _restartForNextMatch,
                          text: 'REMATCH',
                          icon: Icons.replay_rounded,
                          variant: GameButtonVariant.cyan,
                          size: GameButtonSize.medium,
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          key: const ValueKey('return_dashboard_btn'),
                          onPressed: () {
                            _autoRestartTimer?.cancel();
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'RETURN TO DASHBOARD',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Floating In-Game Multiplayer Chat Bubble
          if (_activeFloatingChat != null)
            Positioned(
              top: 55,
              left: 20,
              right: 20,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, val, child) {
                    return Transform.scale(
                      scale: 0.85 + 0.15 * val,
                      child: Opacity(opacity: val, child: child),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xF00A0F1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _activeFloatingChat!.senderId == MultiplayerService.instance.myProfile.playerId
                            ? AppTheme.neonLime
                            : AppTheme.electricCyan,
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerAvatarWidget(avatarId: _activeFloatingChat!.senderAvatar, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '${_activeFloatingChat!.senderName}: ',
                          style: TextStyle(
                            color: _activeFloatingChat!.senderId == MultiplayerService.instance.myProfile.playerId
                                ? AppTheme.neonLime
                                : AppTheme.electricCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _activeFloatingChat!.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
    ),
  );
}

  Widget _buildTopLeftScoreBoard(
    BuildContext context,
    GameStateManager state,
    String opponent,
    String title, {
    double? maxWidth,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? math.min(320.0, MediaQuery.of(context).size.width * 0.42),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.neonLime.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (_game.isDoubles ? '2V2 DOUBLES' : title).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.neonLime,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _game.isDoubles
                      ? 'CALL: ${_game.doublesScoreCallout} • FIRST TO 11'
                      : 'FIRST TO 11 • WIN BY 2',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.matchType == 'multiplayer') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppTheme.neonLime.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_rounded, color: AppTheme.neonLime, size: 9),
                        const SizedBox(width: 3),
                        Text(
                          '${MultiplayerService.instance.currentPingMs} ms',
                          style: const TextStyle(
                            color: AppTheme.neonLime,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => AvatarPickerDialog.show(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlayerAvatarWidget(
                        avatarId: (widget.matchType == 'multiplayer' && _myAvatarId != null)
                            ? _myAvatarId!
                            : state.playerAvatarId,
                        size: 24,
                      ),
                      if (_game.isDoubles) ...[
                        const SizedBox(width: 2),
                        PlayerAvatarWidget(
                          avatarId: (widget.matchType == 'multiplayer' && _partnerAvatarId != null)
                              ? _partnerAvatarId!
                              : 'kai',
                          size: 20,
                        ),
                      ],
                      _buildServerBadge(_serverPlayer == 1),
                      const SizedBox(width: 5),
                      Text(
                        _game.isDoubles ? '${state.playerName} & Partner' : state.playerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Game2DText.score(
                        '$_p1Score',
                        fontSize: 17,
                        textColor: AppTheme.neonLime,
                        strokeWidth: 2.2,
                        shadowOffset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.0),
                  child: Text('-', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Game2DText.score(
                      '$_p2Score',
                      fontSize: 17,
                      textColor: AppTheme.electricCyan,
                      strokeWidth: 2.2,
                      shadowOffset: const Offset(0, 1.5),
                    ),
                    const SizedBox(width: 6),
                    _buildServerBadge(_serverPlayer == 2),
                    Text(
                      _game.isDoubles ? '$opponent & Bot' : opponent,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    (widget.matchType == 'multiplayer' && _opponentAvatarId != null)
                        ? PlayerAvatarWidget(
                            avatarId: _opponentAvatarId!,
                            size: 24,
                          )
                        : PlayerAvatarWidget(
                            avatar: PlayerAvatar.getForOpponent(opponent),
                            size: 24,
                          ),
                    if (_game.isDoubles) ...[
                      const SizedBox(width: 2),
                      (widget.matchType == 'multiplayer' && _opponentPartnerAvatarId != null)
                          ? PlayerAvatarWidget(
                              avatarId: _opponentPartnerAvatarId!,
                              size: 20,
                            )
                          : PlayerAvatarWidget(
                              avatar: PlayerAvatar.getForOpponent('CPU 2'),
                              size: 20,
                            ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightSideViolationDisplay(BuildContext context, {double? maxWidth}) {
    if (_violationType == null) return const SizedBox.shrink();
    final double defaultMaxWidth = maxWidth ?? math.min(280.0, MediaQuery.of(context).size.width * 0.42);

    return GestureDetector(
      onTap: () => _openRulesModal(violation: _violationType),
      child: Container(
        key: const ValueKey('violation_display_box'),
        constraints: BoxConstraints(
          maxWidth: defaultMaxWidth,
        ),
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.fireOrange, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: AppTheme.fireOrange.withValues(alpha: 0.55),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.fireOrange, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    'VIOLATION: $_violationType',
                    style: const TextStyle(
                      color: AppTheme.fireOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              if (_violationDescription != null) ...[
                const SizedBox(height: 2),
                Text(
                  _violationDescription!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
              if (_violationRuleDetail != null) ...[
                const SizedBox(height: 1),
                Text(
                  _violationRuleDetail!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.fireOrange.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.fireOrange.withValues(alpha: 0.55)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded, color: AppTheme.fireOrange, size: 11),
                    SizedBox(width: 4),
                    Text(
                      'TAP TO INSPECT RULE',
                      style: TextStyle(
                        color: AppTheme.fireOrange,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCenterStatusDisplay(BuildContext context, {double? maxWidth}) {
    final double defaultMaxWidth = maxWidth ?? math.min(360.0, MediaQuery.of(context).size.width * 0.46);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Rally & Side-out Announcements (when in play)
        if (_announcementTitle != null && !_isWaitingForServe)
          Container(
            constraints: BoxConstraints(
              maxWidth: defaultMaxWidth,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (_announcementTitle!.contains('FAULT') || _announcementTitle!.contains('VIOLATION'))
                    ? AppTheme.fireOrange
                    : AppTheme.neonLime,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_announcementTitle!.contains('FAULT') || _announcementTitle!.contains('VIOLATION'))
                    ? AppTheme.fireOrange.withValues(alpha: 0.4)
                    : AppTheme.neonLime.withValues(alpha: 0.4),
                  blurRadius: 10,
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
                      color: (_announcementTitle!.contains('FAULT') || _announcementTitle!.contains('VIOLATION'))
                          ? AppTheme.fireOrange
                          : AppTheme.neonLime,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
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
          )
        // 3. Continuous Rally Streak Banner (Active during continuous rallies)
        else if (!_isWaitingForServe && !_isPaused && !_matchFinished && _currentRallyStreak >= 2)
          Container(
            constraints: BoxConstraints(
              maxWidth: defaultMaxWidth,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.electricCyan.withValues(alpha: 0.22),
                  AppTheme.neonLime.withValues(alpha: 0.22),
                ],
              ),
              color: Colors.black.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.neonLime, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonLime.withValues(alpha: 0.40),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: AppTheme.goldCoin, size: 16),
                const SizedBox(width: 4),
                Text(
                  'RALLY STREAK: $_currentRallyStreak HITS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_longestRally > _currentRallyStreak) ...[
                  const SizedBox(width: 5),
                  Text(
                    '(BEST: $_longestRally)',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ],
            ),
          )
        // 4. Live Kitchen NVZ Caution (when Player 1 enters Kitchen during active rally)
        else if (!_isWaitingForServe && !_isPaused && !_matchFinished && _game.player1.isInKitchen)
          Container(
            constraints: BoxConstraints(
              maxWidth: defaultMaxWidth,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_game.ball.bounceCountCurrentSide == 0)
                    ? AppTheme.fireOrange
                    : AppTheme.neonLime,
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_game.ball.bounceCountCurrentSide == 0)
                      ? AppTheme.fireOrange.withValues(alpha: 0.4)
                      : AppTheme.neonLime.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (_game.ball.bounceCountCurrentSide == 0)
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                    color: (_game.ball.bounceCountCurrentSide == 0)
                        ? AppTheme.fireOrange
                        : AppTheme.neonLime,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    (_game.ball.bounceCountCurrentSide == 0)
                        ? 'IN KITCHEN (NVZ) • DINK ONLY (WAIT FOR BOUNCE!)'
                        : 'LEGAL DINK ZONE (BOUNCED)',
                    style: TextStyle(
                      color: (_game.ball.bounceCountCurrentSide == 0)
                          ? AppTheme.fireOrange
                          : AppTheme.neonLime,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          )
        // 4. In-Rally Two-Bounce Rule Coaching Prompt
        else if (!_isWaitingForServe && !_isPaused && !_matchFinished && _game.rallyHitCount < 2)
          Container(
            constraints: BoxConstraints(
              maxWidth: defaultMaxWidth,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_game.ball.bounceCountCurrentSide == 0)
                    ? AppTheme.trophyAmber
                    : AppTheme.neonLime,
                width: 1.2,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (_game.ball.bounceCountCurrentSide == 0)
                        ? Icons.hourglass_bottom_rounded
                        : Icons.sports_tennis_rounded,
                    color: (_game.ball.bounceCountCurrentSide == 0)
                        ? AppTheme.trophyAmber
                        : AppTheme.neonLime,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    (_game.ball.bounceCountCurrentSide == 0)
                        ? 'LET IT BOUNCE! (Two-Bounce Rule)'
                        : 'BOUNCED • STRIKE NOW!',
                    style: TextStyle(
                      color: (_game.ball.bounceCountCurrentSide == 0)
                          ? AppTheme.trophyAmber
                          : AppTheme.neonLime,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 5. Interactive Serve Action Prompt / Serving Indicator
        if (_isWaitingForServe && !_isPaused && !_matchFinished)
          if (_game.isLocalPlayerServing)
            GestureDetector(
              key: const ValueKey('serve_action_prompt'),
              onTap: () => _game.player1.strike(),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: defaultMaxWidth,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.playButtonGradient,
                  borderRadius: BorderRadius.circular(16),
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
                        'YOUR SERVE (${_servingSide.toUpperCase()}) • TAP SMASH TO SERVE',
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
          else if (_game.isDoubles && _serverPlayer == 1)
            Container(
              constraints: BoxConstraints(
                maxWidth: defaultMaxWidth,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.6), width: 1.2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sports_tennis_rounded, color: AppTheme.neonLime, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'PARTNER SERVING (${_servingSide.toUpperCase()}) • GET READY',
                      style: const TextStyle(
                        color: AppTheme.neonLime,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              constraints: BoxConstraints(
                maxWidth: defaultMaxWidth,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
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
                      '${widget.matchType == 'multiplayer' ? 'OPPONENT' : 'CPU'} SERVING (${_servingSide.toUpperCase()}) • GET READY',
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
    );
  }

  Widget _buildTopRightUnifiedControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: const ValueKey('ingame_pause_btn'),
            onTap: _togglePause,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(
                _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),
          InkWell(
            key: const ValueKey('ingame_rules_btn'),
            onTap: () => _openRulesModal(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppTheme.electricCyan,
                size: 20,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),
          InkWell(
            key: const ValueKey('ingame_hud_adjuster_btn'),
            onTap: _openHudAdjusterModal,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: const Icon(
                Icons.gamepad_rounded,
                color: AppTheme.goldCoin,
                size: 20,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 2),
          ),
          InkWell(
            key: const ValueKey('ingame_settings_btn'),
            onTap: _openInGameSettings,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: const Icon(
                Icons.tune_rounded,
                color: AppTheme.neonLime,
                size: 20,
              ),
            ),
          ),
          if (widget.matchType == 'multiplayer') ...[
            Container(
              width: 1,
              height: 20,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 2),
            ),
            InkWell(
              key: const ValueKey('ingame_chat_btn'),
              onTap: () => _showInGameChatSheet(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: AppTheme.electricCyan,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showInGameChatSheet(BuildContext context) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: AppTheme.electricCyan, width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_rounded, color: AppTheme.electricCyan, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'IN-GAME TACTICAL CHAT',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MultiplayerService.quickChatPresets.map((preset) {
                  return ActionChip(
                    backgroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: AppTheme.surfaceBorder),
                    label: Text(
                      preset,
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      MultiplayerService.instance.sendChatMessage(preset, isQuickChat: true);
                      Navigator.of(ctx).pop();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Type custom message...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.electricCyan),
                        ),
                      ),
                      onSubmitted: (txt) {
                        if (txt.trim().isNotEmpty) {
                          MultiplayerService.instance.sendChatMessage(txt.trim());
                          Navigator.of(ctx).pop();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Game2DButton(
                    onPressed: () {
                      final txt = textController.text.trim();
                      if (txt.isNotEmpty) {
                        MultiplayerService.instance.sendChatMessage(txt);
                        Navigator.of(ctx).pop();
                      }
                    },
                    icon: Icons.send_rounded,
                    variant: GameButtonVariant.cyan,
                    size: GameButtonSize.small,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServerBadge(bool isServer) {
    if (!isServer) return const SizedBox.shrink();
    final badgeText = _game.isDoubles
        ? '${_servingSide == 'right' ? 'R' : 'L'}-${_game.serverNumber}'
        : (_servingSide == 'right' ? 'R' : 'L');
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
            badgeText,
            style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MultiplayerService.instance.latestInGameChatNotifier.removeListener(_onInGameChatReceived);
    _chatBubbleTimer?.cancel();
    _autoRestartTimer?.cancel();
    _announcementTimer?.cancel();
    _violationTimer?.cancel();
    if (widget.matchType == 'multiplayer') {
      MultiplayerService.instance.hostDisconnectedNotifier.removeListener(_onHostDisconnected);
      MultiplayerService.instance.leaveRoom();
    }
    // Restore system UI mode and portrait orientation when leaving gameplay
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    AudioService.instance.playMenuBgm();
    super.dispose();
  }
}

