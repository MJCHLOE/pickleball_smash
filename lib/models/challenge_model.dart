enum ChallengeType {
  daily,
  career,
}

class ChallengeItem {
  final String id;
  final String title;
  final String description;
  final int goal;
  int currentProgress;
  final int rewardCoins;
  final int rewardXp;
  bool isClaimed;
  final ChallengeType type;
  final String iconName;

  ChallengeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.goal,
    this.currentProgress = 0,
    required this.rewardCoins,
    required this.rewardXp,
    this.isClaimed = false,
    required this.type,
    this.iconName = 'tennis',
  });

  bool get isCompleted => currentProgress >= goal;
  double get progressRatio => (currentProgress / goal).clamp(0.0, 1.0);

  ChallengeItem copyWith({
    int? currentProgress,
    bool? isClaimed,
  }) {
    return ChallengeItem(
      id: id,
      title: title,
      description: description,
      goal: goal,
      currentProgress: currentProgress ?? this.currentProgress,
      rewardCoins: rewardCoins,
      rewardXp: rewardXp,
      isClaimed: isClaimed ?? this.isClaimed,
      type: type,
      iconName: iconName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'goal': goal,
      'currentProgress': currentProgress,
      'rewardCoins': rewardCoins,
      'rewardXp': rewardXp,
      'isClaimed': isClaimed ? 1 : 0,
      'type': type.name,
      'iconName': iconName,
    };
  }

  factory ChallengeItem.fromMap(Map<String, dynamic> map) {
    return ChallengeItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      goal: map['goal'] as int,
      currentProgress: map['currentProgress'] as int? ?? 0,
      rewardCoins: map['rewardCoins'] as int,
      rewardXp: map['rewardXp'] as int,
      isClaimed: (map['isClaimed'] as int? ?? 0) == 1,
      type: ChallengeType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ChallengeType.daily,
      ),
      iconName: map['iconName'] as String? ?? 'tennis',
    );
  }
}

