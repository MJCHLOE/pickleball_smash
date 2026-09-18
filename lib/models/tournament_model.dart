enum TournamentDifficulty { easy, medium, hard }

class BracketMatch {
  final String id;
  final String roundTitle; // e.g. 'Quarter-Final', 'Semi-Final', 'Championship Final'
  final String player1Name;
  final String player2Name;
  final int player1Score;
  final int player2Score;
  final bool isCompleted;
  final bool isPlayerWinner;
  final bool isCurrentMatch;

  BracketMatch({
    required this.id,
    required this.roundTitle,
    required this.player1Name,
    required this.player2Name,
    this.player1Score = 0,
    this.player2Score = 0,
    this.isCompleted = false,
    this.isPlayerWinner = false,
    this.isCurrentMatch = false,
  });

  BracketMatch copyWith({
    String? player1Name,
    String? player2Name,
    int? player1Score,
    int? player2Score,
    bool? isCompleted,
    bool? isPlayerWinner,
    bool? isCurrentMatch,
  }) {
    return BracketMatch(
      id: id,
      roundTitle: roundTitle,
      player1Name: player1Name ?? this.player1Name,
      player2Name: player2Name ?? this.player2Name,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      isCompleted: isCompleted ?? this.isCompleted,
      isPlayerWinner: isPlayerWinner ?? this.isPlayerWinner,
      isCurrentMatch: isCurrentMatch ?? this.isCurrentMatch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roundTitle': roundTitle,
      'player1Name': player1Name,
      'player2Name': player2Name,
      'player1Score': player1Score,
      'player2Score': player2Score,
      'isCompleted': isCompleted ? 1 : 0,
      'isPlayerWinner': isPlayerWinner ? 1 : 0,
      'isCurrentMatch': isCurrentMatch ? 1 : 0,
    };
  }

  factory BracketMatch.fromMap(Map<String, dynamic> map) {
    return BracketMatch(
      id: map['id'] as String,
      roundTitle: map['roundTitle'] as String,
      player1Name: map['player1Name'] as String,
      player2Name: map['player2Name'] as String,
      player1Score: map['player1Score'] as int? ?? 0,
      player2Score: map['player2Score'] as int? ?? 0,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      isPlayerWinner: (map['isPlayerWinner'] as int? ?? 0) == 1,
      isCurrentMatch: (map['isCurrentMatch'] as int? ?? 0) == 1,
    );
  }
}

class Tournament {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final TournamentDifficulty difficulty;
  final int entryFee;
  final int rewardCoins;
  final int rewardTrophies;
  final bool isUnlocked;
  final List<BracketMatch> matches;
  final int currentMatchIndex;
  final bool isCompleted;

  Tournament({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.difficulty,
    required this.entryFee,
    required this.rewardCoins,
    required this.rewardTrophies,
    this.isUnlocked = true,
    required this.matches,
    this.currentMatchIndex = 0,
    this.isCompleted = false,
  });

  BracketMatch? get currentMatch {
    if (isCompleted || currentMatchIndex >= matches.length) return null;
    return matches[currentMatchIndex];
  }

  Tournament copyWith({
    bool? isUnlocked,
    List<BracketMatch>? matches,
    int? currentMatchIndex,
    bool? isCompleted,
  }) {
    return Tournament(
      id: id,
      title: title,
      subtitle: subtitle,
      badge: badge,
      difficulty: difficulty,
      entryFee: entryFee,
      rewardCoins: rewardCoins,
      rewardTrophies: rewardTrophies,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      matches: matches ?? this.matches,
      currentMatchIndex: currentMatchIndex ?? this.currentMatchIndex,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'badge': badge,
      'difficulty': difficulty.name,
      'entryFee': entryFee,
      'rewardCoins': rewardCoins,
      'rewardTrophies': rewardTrophies,
      'isUnlocked': isUnlocked ? 1 : 0,
      'currentMatchIndex': currentMatchIndex,
      'isCompleted': isCompleted ? 1 : 0,
      'matches': matches.map((m) => m.toMap()).toList(),
    };
  }

  factory Tournament.fromMap(Map<String, dynamic> map) {
    return Tournament(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
      badge: map['badge'] as String,
      difficulty: TournamentDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => TournamentDifficulty.easy,
      ),
      entryFee: map['entryFee'] as int? ?? 0,
      rewardCoins: map['rewardCoins'] as int? ?? 0,
      rewardTrophies: map['rewardTrophies'] as int? ?? 0,
      isUnlocked: (map['isUnlocked'] as int? ?? 1) == 1,
      currentMatchIndex: map['currentMatchIndex'] as int? ?? 0,
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      matches: (map['matches'] as List<dynamic>?)
              ?.map((m) => BracketMatch.fromMap(Map<String, dynamic>.from(m as Map)))
              .toList() ??
          [],
    );
  }
}

