import 'package:flutter/foundation.dart';
import '../models/challenge_model.dart';
import '../models/tournament_model.dart';
import '../models/game_settings.dart';
import 'database_service.dart';

class GameStateManager extends ChangeNotifier {
  // Singleton pattern for easy global access
  static final GameStateManager instance = GameStateManager._internal();
  factory GameStateManager() => instance;
  GameStateManager._internal() {
    _initDefaultData();
  }

  // Account State
  int? currentUserId;
  String currentUsername = 'Guest Player';
  bool isGuest = true;

  // Player Profile State
  String get playerName => isGuest ? 'Guest Player' : currentUsername;
  int playerLevel = 1;
  int playerXp = 0;
  int xpToNextLevel = 500;
  int coins = 500;
  int trophies = 50;

  // Stats
  int matchesPlayed = 24;
  int matchesWon = 19;
  int totalSmashes = 187;
  int bestStreak = 6;
  int currentStreak = 3;

  // In-memory match history for guest sessions
  final List<Map<String, dynamic>> _guestMatchHistory = [];

  double get winRate => matchesPlayed > 0 ? (matchesWon / matchesPlayed) * 100 : 0.0;
  double get xpProgress => (playerXp / xpToNextLevel).clamp(0.0, 1.0);

  // Settings
  GameSettings settings = const GameSettings();

  // Tournaments
  List<Tournament> tournaments = [];

  // Challenges
  List<ChallengeItem> challenges = [];

  void _initDefaultData() {
    _initDefaultTournaments();
    _initDefaultChallenges();
  }

  void _initDefaultTournaments() {
    tournaments = [
      Tournament(
        id: 'rookie_open',
        title: 'Rookie Open',
        subtitle: 'Entry-level knockout cup for upcoming talent',
        badge: '🥉',
        difficulty: TournamentDifficulty.easy,
        entryFee: 0,
        rewardCoins: 250,
        rewardTrophies: 50,
        isUnlocked: true,
        currentMatchIndex: 1, // Currently on Semi-Finals
        matches: [
          BracketMatch(
            id: 'rookie_qf',
            roundTitle: 'Quarter-Final',
            player1Name: playerName,
            player2Name: 'Ben Dinker',
            player1Score: 11,
            player2Score: 4,
            isCompleted: true,
            isPlayerWinner: true,
          ),
          BracketMatch(
            id: 'rookie_sf',
            roundTitle: 'Semi-Final',
            player1Name: playerName,
            player2Name: 'Sarah Spin',
            isCurrentMatch: true,
          ),
          BracketMatch(
            id: 'rookie_final',
            roundTitle: 'Championship Final',
            player1Name: 'TBD',
            player2Name: 'Sammy Smash',
          ),
        ],
      ),
      Tournament(
        id: 'pro_circuit',
        title: 'Pro Smash Circuit',
        subtitle: 'High-speed volleys against regional champions',
        badge: '🥈',
        difficulty: TournamentDifficulty.medium,
        entryFee: 150,
        rewardCoins: 800,
        rewardTrophies: 120,
        isUnlocked: true,
        currentMatchIndex: 0,
        matches: [
          BracketMatch(
            id: 'pro_qf',
            roundTitle: 'Quarter-Final',
            player1Name: playerName,
            player2Name: 'Rocky Lob',
            isCurrentMatch: true,
          ),
          BracketMatch(
            id: 'pro_sf',
            roundTitle: 'Semi-Final',
            player1Name: 'TBD',
            player2Name: 'Max Volley',
          ),
          BracketMatch(
            id: 'pro_final',
            roundTitle: 'Championship Final',
            player1Name: 'TBD',
            player2Name: 'Chloe Ace',
          ),
        ],
      ),
      Tournament(
        id: 'grand_slam',
        title: 'Grand Slam Masters',
        subtitle: 'The pinnacle tournament. Facing world legends',
        badge: '🥇',
        difficulty: TournamentDifficulty.hard,
        entryFee: 500,
        rewardCoins: 2500,
        rewardTrophies: 300,
        isUnlocked: false,
        currentMatchIndex: 0,
        matches: [
          BracketMatch(
            id: 'masters_qf',
            roundTitle: 'Quarter-Final',
            player1Name: playerName,
            player2Name: 'Iron Paddle',
            isCurrentMatch: true,
          ),
          BracketMatch(
            id: 'masters_sf',
            roundTitle: 'Semi-Final',
            player1Name: 'TBD',
            player2Name: 'Viper Vance',
          ),
          BracketMatch(
            id: 'masters_final',
            roundTitle: 'Championship Final',
            player1Name: 'TBD',
            player2Name: 'The Pickle King',
          ),
        ],
      ),
    ];
  }

  void _initDefaultChallenges() {
    challenges = [
      ChallengeItem(
        id: 'c_daily_1',
        title: 'First Serve',
        description: 'Play 1 match today in any mode',
        goal: 1,
        currentProgress: 1,
        rewardCoins: 100,
        rewardXp: 50,
        isClaimed: false,
        type: ChallengeType.daily,
      ),
      ChallengeItem(
        id: 'c_daily_2',
        title: 'Power Smasher',
        description: 'Execute 8 powerful smash strikes',
        goal: 8,
        currentProgress: 5,
        rewardCoins: 150,
        rewardXp: 80,
        isClaimed: false,
        type: ChallengeType.daily,
      ),
      ChallengeItem(
        id: 'c_daily_3',
        title: 'Net Dominance',
        description: 'Win a rally lasting longer than 10 hits',
        goal: 1,
        currentProgress: 0,
        rewardCoins: 200,
        rewardXp: 100,
        isClaimed: false,
        type: ChallengeType.daily,
      ),
      ChallengeItem(
        id: 'c_career_1',
        title: 'Smash Centurion',
        description: 'Perform 100 smash attacks across all matches',
        goal: 100,
        currentProgress: 100,
        rewardCoins: 500,
        rewardXp: 300,
        isClaimed: false,
        type: ChallengeType.career,
      ),
      ChallengeItem(
        id: 'c_career_2',
        title: 'Tournament Contender',
        description: 'Win your first tournament knockout match',
        goal: 1,
        currentProgress: 1,
        rewardCoins: 350,
        rewardXp: 200,
        isClaimed: true,
        type: ChallengeType.career,
      ),
      ChallengeItem(
        id: 'c_career_3',
        title: 'Trophy Hunter',
        description: 'Accumulate 500 total championship trophies',
        goal: 500,
        currentProgress: 420,
        rewardCoins: 1000,
        rewardXp: 500,
        isClaimed: false,
        type: ChallengeType.career,
      ),
      ChallengeItem(
        id: 'c_career_4',
        title: 'Rising Star',
        description: 'Reach Player Level 5',
        goal: 5,
        currentProgress: 3,
        rewardCoins: 600,
        rewardXp: 250,
        isClaimed: false,
        type: ChallengeType.career,
      ),
    ];
  }

  void updateSettings(GameSettings newSettings) {
    settings = newSettings;
    saveCurrentProgress();
    notifyListeners();
  }

  bool claimChallenge(String challengeId) {
    final index = challenges.indexWhere((c) => c.id == challengeId);
    if (index != -1) {
      final challenge = challenges[index];
      if (challenge.isCompleted && !challenge.isClaimed) {
        challenge.isClaimed = true;
        addCoins(challenge.rewardCoins);
        addXp(challenge.rewardXp);
        saveCurrentProgress();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void addCoins(int amount) {
    coins += amount;
    saveCurrentProgress();
    notifyListeners();
  }

  void addTrophies(int amount) {
    trophies += amount;
    // Check trophy challenge
    _incrementChallengeProgress('c_career_3', trophies, isAbsolute: true);
    // Auto-unlock Grand Slam at 500 trophies
    if (trophies >= 500) {
      final gsIndex = tournaments.indexWhere((t) => t.id == 'grand_slam');
      if (gsIndex != -1 && !tournaments[gsIndex].isUnlocked) {
        tournaments[gsIndex] = tournaments[gsIndex].copyWith(isUnlocked: true);
      }
    }
    saveCurrentProgress();
    notifyListeners();
  }

  void addXp(int amount) {
    playerXp += amount;
    while (playerXp >= xpToNextLevel) {
      playerXp -= xpToNextLevel;
      playerLevel++;
      xpToNextLevel = (xpToNextLevel * 1.3).round();
      _incrementChallengeProgress('c_career_4', playerLevel, isAbsolute: true);
    }
    saveCurrentProgress();
    notifyListeners();
  }

  void recordMatchResult({
    required bool won,
    required int smashesHit,
    String? tournamentId,
    String matchType = 'quick',
    String opponentName = 'CPU Challenger',
    int playerScore = 0,
    int opponentScore = 0,
  }) {
    matchesPlayed++;
    totalSmashes += smashesHit;
    final coinsEarned = won ? 100 : 25;
    final xpEarned = won ? 80 : 25;

    if (won) {
      matchesWon++;
      currentStreak++;
      if (currentStreak > bestStreak) bestStreak = currentStreak;
      addCoins(coinsEarned);
      addXp(xpEarned);
    } else {
      currentStreak = 0;
      addCoins(coinsEarned);
      addXp(xpEarned);
    }

    // Update challenges progress
    _incrementChallengeProgress('c_daily_1', 1);
    _incrementChallengeProgress('c_daily_2', smashesHit);
    _incrementChallengeProgress('c_career_1', totalSmashes, isAbsolute: true);

    // If this was a tournament match
    if (tournamentId != null) {
      advanceTournamentMatch(tournamentId, won);
    }

    // Record into SQLite match history if signed in, or memory if guest
    if (!isGuest && currentUserId != null) {
      DatabaseService.instance.recordMatch(
        userId: currentUserId!,
        matchType: matchType,
        opponentName: opponentName,
        playerScore: playerScore,
        opponentScore: opponentScore,
        won: won,
        smashesHit: smashesHit,
        coinsEarned: coinsEarned,
      );
    } else {
      _guestMatchHistory.insert(0, {
        'match_type': matchType,
        'opponent_name': opponentName,
        'player_score': playerScore,
        'opponent_score': opponentScore,
        'won': won ? 1 : 0,
        'smashes_hit': smashesHit,
        'coins_earned': coinsEarned,
        'played_at': DateTime.now().toIso8601String(),
      });
    }

    saveCurrentProgress();
    notifyListeners();
  }

  void advanceTournamentMatch(String tournamentId, bool playerWon) {
    final tIndex = tournaments.indexWhere((t) => t.id == tournamentId);
    if (tIndex == -1) return;

    final tournament = tournaments[tIndex];
    final currentIdx = tournament.currentMatchIndex;
    if (currentIdx >= tournament.matches.length) return;

    final updatedMatches = List<BracketMatch>.from(tournament.matches);
    final currentMatch = updatedMatches[currentIdx];

    if (playerWon) {
      updatedMatches[currentIdx] = currentMatch.copyWith(
        player1Score: 11,
        player2Score: 6,
        isCompleted: true,
        isPlayerWinner: true,
        isCurrentMatch: false,
      );

      final nextIdx = currentIdx + 1;
      if (nextIdx < updatedMatches.length) {
        // Prepare next match
        updatedMatches[nextIdx] = updatedMatches[nextIdx].copyWith(
          player1Name: playerName,
          isCurrentMatch: true,
        );
        tournaments[tIndex] = tournament.copyWith(
          matches: updatedMatches,
          currentMatchIndex: nextIdx,
        );
      } else {
        // Completed tournament!
        tournaments[tIndex] = tournament.copyWith(
          matches: updatedMatches,
          currentMatchIndex: nextIdx,
          isCompleted: true,
        );
        addCoins(tournament.rewardCoins);
        addTrophies(tournament.rewardTrophies);
        _incrementChallengeProgress('c_career_2', 1);
      }
    } else {
      // Player lost the match
      updatedMatches[currentIdx] = currentMatch.copyWith(
        player1Score: 8,
        player2Score: 11,
        isCompleted: true,
        isPlayerWinner: false,
        isCurrentMatch: false,
      );
      tournaments[tIndex] = tournament.copyWith(
        matches: updatedMatches,
      );
    }
    saveCurrentProgress();
    notifyListeners();
  }

  void restartTournament(String tournamentId) {
    final tIndex = tournaments.indexWhere((t) => t.id == tournamentId);
    if (tIndex == -1) return;
    final tournament = tournaments[tIndex];

    final resetMatches = tournament.matches.map((m) {
      return BracketMatch(
        id: m.id,
        roundTitle: m.roundTitle,
        player1Name: m.id.endsWith('_qf') ? playerName : 'TBD',
        player2Name: m.player2Name,
        isCurrentMatch: m.id.endsWith('_qf'),
      );
    }).toList();

    tournaments[tIndex] = tournament.copyWith(
      matches: resetMatches,
      currentMatchIndex: 0,
      isCompleted: false,
    );
    saveCurrentProgress();
    notifyListeners();
  }

  void _incrementChallengeProgress(String challengeId, int amount, {bool isAbsolute = false}) {
    final index = challenges.indexWhere((c) => c.id == challengeId);
    if (index != -1) {
      final item = challenges[index];
      if (!item.isCompleted) {
        if (isAbsolute) {
          item.currentProgress = amount.clamp(0, item.goal);
        } else {
          item.currentProgress = (item.currentProgress + amount).clamp(0, item.goal);
        }
      }
    }
  }

  Future<void> loginWithUser(
    int userId,
    String username, {
    bool preserveCurrentDataIfNew = false,
  }) async {
    final wasGuest = isGuest;
    currentUserId = userId;
    currentUsername = username;
    isGuest = false;

    final saved = await DatabaseService.instance.loadPlayerData(userId);
    if (saved != null) {
      playerLevel = (saved['playerLevel'] as num?)?.toInt() ?? 1;
      playerXp = (saved['playerXp'] as num?)?.toInt() ?? 0;
      xpToNextLevel = (saved['xpToNextLevel'] as num?)?.toInt() ?? 500;
      coins = (saved['coins'] as num?)?.toInt() ?? 500;
      trophies = (saved['trophies'] as num?)?.toInt() ?? 50;
      matchesPlayed = (saved['matchesPlayed'] as num?)?.toInt() ?? 0;
      matchesWon = (saved['matchesWon'] as num?)?.toInt() ?? 0;
      totalSmashes = (saved['totalSmashes'] as num?)?.toInt() ?? 0;
      bestStreak = (saved['bestStreak'] as num?)?.toInt() ?? 0;
      currentStreak = (saved['currentStreak'] as num?)?.toInt() ?? 0;
      final savedTournaments = saved['tournaments'] as List<Tournament>?;
      if (savedTournaments != null && savedTournaments.isNotEmpty) {
        tournaments = savedTournaments;
      } else {
        _initDefaultTournaments();
      }
      final savedChallenges = saved['challenges'] as List<ChallengeItem>?;
      if (savedChallenges != null && savedChallenges.isNotEmpty) {
        challenges = savedChallenges;
      } else {
        _initDefaultChallenges();
      }
      if (saved['settings'] != null) {
        settings = saved['settings'] as GameSettings;
      }
    } else {
      // New registered user!
      // If user played as guest and wanted to save their progress, preserve it!
      if (!preserveCurrentDataIfNew && (!wasGuest || matchesPlayed == 0)) {
        _initDefaultData();
      } else if (preserveCurrentDataIfNew && _guestMatchHistory.isNotEmpty) {
        // Migrate in-memory guest match history into SQLite
        for (final m in _guestMatchHistory.reversed) {
          await DatabaseService.instance.recordMatch(
            userId: userId,
            matchType: m['match_type'] as String? ?? 'quick',
            opponentName: m['opponent_name'] as String? ?? 'CPU Challenger',
            playerScore: (m['player_score'] as num?)?.toInt() ?? 0,
            opponentScore: (m['opponent_score'] as num?)?.toInt() ?? 0,
            won: (m['won'] as num?)?.toInt() == 1,
            smashesHit: (m['smashes_hit'] as num?)?.toInt() ?? 0,
            coinsEarned: (m['coins_earned'] as num?)?.toInt() ?? 25,
          );
        }
        _guestMatchHistory.clear();
      }
      if (tournaments.isEmpty) _initDefaultTournaments();
      if (challenges.isEmpty) _initDefaultChallenges();
      await saveCurrentProgress();
    }
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getMatchHistory({int limit = 20}) async {
    if (isGuest || currentUserId == null) {
      return List.unmodifiable(_guestMatchHistory.take(limit).toList());
    }
    return await DatabaseService.instance.getMatchHistory(currentUserId!, limit: limit);
  }

  void loginAsGuest() {
    currentUserId = null;
    currentUsername = 'Guest Player';
    isGuest = true;
    _guestMatchHistory.clear();
    _initDefaultData();
    notifyListeners();
  }

  Future<void> logout() async {
    await DatabaseService.instance.clearActiveSession();
    loginAsGuest();
  }

  Future<void> saveCurrentProgress() async {
    if (!isGuest && currentUserId != null) {
      await DatabaseService.instance.savePlayerData(
        userId: currentUserId!,
        playerLevel: playerLevel,
        playerXp: playerXp,
        xpToNextLevel: xpToNextLevel,
        coins: coins,
        trophies: trophies,
        matchesPlayed: matchesPlayed,
        matchesWon: matchesWon,
        totalSmashes: totalSmashes,
        bestStreak: bestStreak,
        currentStreak: currentStreak,
        tournaments: tournaments,
        challenges: challenges,
        settings: settings,
      );
    }
  }

  void resetAllData() {
    playerLevel = 1;
    playerXp = 0;
    xpToNextLevel = 500;
    coins = 500;
    trophies = 50;
    matchesPlayed = 0;
    matchesWon = 0;
    totalSmashes = 0;
    bestStreak = 0;
    currentStreak = 0;
    settings = const GameSettings();
    _initDefaultData();
    saveCurrentProgress();
    notifyListeners();
  }
}

