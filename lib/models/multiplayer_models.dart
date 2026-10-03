import 'package:flutter/material.dart';

/// Online presence status inspired by competitive esports games (e.g. MLBB)
enum PlayerPresenceStatus {
  online,
  inRoom,
  inMatch,
  offline,
  spectating;

  String get label {
    switch (this) {
      case PlayerPresenceStatus.online:
        return 'Online';
      case PlayerPresenceStatus.inRoom:
        return 'In Room';
      case PlayerPresenceStatus.inMatch:
        return 'In Match';
      case PlayerPresenceStatus.offline:
        return 'Offline';
      case PlayerPresenceStatus.spectating:
        return 'Spectating';
    }
  }

  Color get color {
    switch (this) {
      case PlayerPresenceStatus.online:
        return const Color(0xFF22C55E); // 🟢 Green
      case PlayerPresenceStatus.inRoom:
        return const Color(0xFFFBBF24); // 🟡 Yellow/Amber
      case PlayerPresenceStatus.inMatch:
        return const Color(0xFFEF4444); // 🔴 Red
      case PlayerPresenceStatus.offline:
        return const Color(0xFF64748B); // ⚫ Slate / Dark Grey
      case PlayerPresenceStatus.spectating:
        return const Color(0xFF38BDF8); // 🔵 Light Cyan/Blue
    }
  }

  IconData get icon {
    switch (this) {
      case PlayerPresenceStatus.online:
        return Icons.circle;
      case PlayerPresenceStatus.inRoom:
        return Icons.meeting_room_rounded;
      case PlayerPresenceStatus.inMatch:
        return Icons.sports_tennis_rounded;
      case PlayerPresenceStatus.offline:
        return Icons.circle_outlined;
      case PlayerPresenceStatus.spectating:
        return Icons.visibility_rounded;
    }
  }
}

/// Competitive rank tiers
enum RankTier {
  warrior('Warrior', '⚔️', Color(0xFF94A3B8)),
  elite('Elite', '🛡️', Color(0xFF60A5FA)),
  master('Master', '⚡', Color(0xFF34D399)),
  grandmaster('Grandmaster', '🏆', Color(0xFFFBBF24)),
  epic('Epic', '🔮', Color(0xFFA855F7)),
  legend('Legend', '👑', Color(0xFFF97316)),
  mythic('Smash Mythic', '🌟', Color(0xFFEC4899));

  final String title;
  final String icon;
  final Color color;

  const RankTier(this.title, this.icon, this.color);
}

/// Favorite hero statistic in player profile
class FavoriteHeroStat {
  final String characterId;
  final String name;
  final String avatarId;
  final int matches;
  final double winRate;

  const FavoriteHeroStat({
    required this.characterId,
    required this.name,
    required this.avatarId,
    required this.matches,
    required this.winRate,
  });

  Map<String, dynamic> toJson() => {
        'characterId': characterId,
        'name': name,
        'avatarId': avatarId,
        'matches': matches,
        'winRate': winRate,
      };

  factory FavoriteHeroStat.fromJson(Map<String, dynamic> json) => FavoriteHeroStat(
        characterId: json['characterId'] as String? ?? 'alex_classic',
        name: json['name'] as String? ?? 'Alex',
        avatarId: json['avatarId'] as String? ?? 'alex_classic',
        matches: json['matches'] as int? ?? 0,
        winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Achievement badge in player profile
class ProfileBadge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;

  const ProfileBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'isUnlocked': isUnlocked,
      };

  factory ProfileBadge.fromJson(Map<String, dynamic> json) => ProfileBadge(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        icon: json['icon'] as String? ?? '🏅',
        isUnlocked: json['isUnlocked'] as bool? ?? true,
      );
}

/// Match Record in player profile match history
class MatchRecordModel {
  final String id;
  final DateTime timestamp;
  final String result; // 'Victory' or 'Defeat'
  final String gameMode; // '1v1 Singles', '2v2 Doubles', 'Ranked Duel', 'Custom Room'
  final String characterUsed;
  final String opponentCharacter;
  final String opponentName;
  final int myScore;
  final int opponentScore;
  final int durationSeconds;
  final int smashes;
  final int aces;
  final bool isMvp;
  final double rating;

  const MatchRecordModel({
    required this.id,
    required this.timestamp,
    required this.result,
    required this.gameMode,
    required this.characterUsed,
    required this.opponentCharacter,
    required this.opponentName,
    required this.myScore,
    required this.opponentScore,
    required this.durationSeconds,
    this.smashes = 0,
    this.aces = 0,
    this.isMvp = false,
    this.rating = 8.5,
  });

  bool get isVictory => result == 'Victory';

  String get durationFormatted {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'result': result,
        'gameMode': gameMode,
        'characterUsed': characterUsed,
        'opponentCharacter': opponentCharacter,
        'opponentName': opponentName,
        'myScore': myScore,
        'opponentScore': opponentScore,
        'durationSeconds': durationSeconds,
        'smashes': smashes,
        'aces': aces,
        'isMvp': isMvp,
        'rating': rating,
      };

  factory MatchRecordModel.fromJson(Map<String, dynamic> json) => MatchRecordModel(
        id: json['id'] as String? ?? 'rec_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        result: json['result'] as String? ?? 'Victory',
        gameMode: json['gameMode'] as String? ?? '1v1 Singles',
        characterUsed: json['characterUsed'] as String? ?? 'Alex',
        opponentCharacter: json['opponentCharacter'] as String? ?? 'Maya',
        opponentName: json['opponentName'] as String? ?? 'Rival',
        myScore: json['myScore'] as int? ?? 11,
        opponentScore: json['opponentScore'] as int? ?? 7,
        durationSeconds: json['durationSeconds'] as int? ?? 145,
        smashes: json['smashes'] as int? ?? 4,
        aces: json['aces'] as int? ?? 2,
        isMvp: json['isMvp'] as bool? ?? false,
        rating: (json['rating'] as num?)?.toDouble() ?? 8.5,
      );
}

/// Comprehensive Player Profile Model
class PlayerProfileModel {
  final String id;
  final String playerId; // e.g. "#PB-8842"
  final String username;
  final String nickname;
  final String avatarId;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final RankTier rankTier;
  final int rankStars;
  final int totalMatches;
  final int wins;
  final int losses;
  final int smashes;
  final int aces;
  final int flawlessRallies;
  final int longestRally;
  final int winStreak;
  final List<FavoriteHeroStat> favoriteHeroes;
  final List<MatchRecordModel> recentMatches;
  final List<ProfileBadge> badges;
  final bool isPublicStats;
  final bool isPublicHistory;
  final PlayerPresenceStatus status;

  const PlayerProfileModel({
    required this.id,
    required this.playerId,
    required this.username,
    required this.nickname,
    required this.avatarId,
    this.level = 1,
    this.xp = 0,
    this.xpToNextLevel = 500,
    this.rankTier = RankTier.warrior,
    this.rankStars = 1,
    this.totalMatches = 0,
    this.wins = 0,
    this.losses = 0,
    this.smashes = 0,
    this.aces = 0,
    this.flawlessRallies = 0,
    this.longestRally = 0,
    this.winStreak = 0,
    this.favoriteHeroes = const [],
    this.recentMatches = const [],
    this.badges = const [],
    this.isPublicStats = true,
    this.isPublicHistory = true,
    this.status = PlayerPresenceStatus.online,
  });

  double get winRate => totalMatches > 0 ? (wins / totalMatches) * 100 : 0.0;

  PlayerProfileModel copyWith({
    String? id,
    String? playerId,
    String? username,
    String? nickname,
    String? avatarId,
    int? level,
    int? xp,
    int? xpToNextLevel,
    RankTier? rankTier,
    int? rankStars,
    int? totalMatches,
    int? wins,
    int? losses,
    int? smashes,
    int? aces,
    int? flawlessRallies,
    int? longestRally,
    int? winStreak,
    List<FavoriteHeroStat>? favoriteHeroes,
    List<MatchRecordModel>? recentMatches,
    List<ProfileBadge>? badges,
    bool? isPublicStats,
    bool? isPublicHistory,
    PlayerPresenceStatus? status,
  }) {
    return PlayerProfileModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatarId: avatarId ?? this.avatarId,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      rankTier: rankTier ?? this.rankTier,
      rankStars: rankStars ?? this.rankStars,
      totalMatches: totalMatches ?? this.totalMatches,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      smashes: smashes ?? this.smashes,
      aces: aces ?? this.aces,
      flawlessRallies: flawlessRallies ?? this.flawlessRallies,
      longestRally: longestRally ?? this.longestRally,
      winStreak: winStreak ?? this.winStreak,
      favoriteHeroes: favoriteHeroes ?? this.favoriteHeroes,
      recentMatches: recentMatches ?? this.recentMatches,
      badges: badges ?? this.badges,
      isPublicStats: isPublicStats ?? this.isPublicStats,
      isPublicHistory: isPublicHistory ?? this.isPublicHistory,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerId': playerId,
        'username': username,
        'nickname': nickname,
        'avatarId': avatarId,
        'level': level,
        'xp': xp,
        'xpToNextLevel': xpToNextLevel,
        'rankTier': rankTier.name,
        'rankStars': rankStars,
        'totalMatches': totalMatches,
        'wins': wins,
        'losses': losses,
        'smashes': smashes,
        'aces': aces,
        'flawlessRallies': flawlessRallies,
        'longestRally': longestRally,
        'winStreak': winStreak,
        'favoriteHeroes': favoriteHeroes.map((e) => e.toJson()).toList(),
        'recentMatches': recentMatches.map((e) => e.toJson()).toList(),
        'badges': badges.map((e) => e.toJson()).toList(),
        'isPublicStats': isPublicStats,
        'isPublicHistory': isPublicHistory,
        'status': status.name,
      };

  factory PlayerProfileModel.fromJson(Map<String, dynamic> json) => PlayerProfileModel(
        id: json['id'] as String? ?? 'player_1',
        playerId: json['playerId'] as String? ?? '#PB-1001',
        username: json['username'] as String? ?? 'SmashMaster',
        nickname: json['nickname'] as String? ?? 'SmashMaster',
        avatarId: json['avatarId'] as String? ?? 'alex_classic',
        level: json['level'] as int? ?? 1,
        xp: json['xp'] as int? ?? 0,
        xpToNextLevel: json['xpToNextLevel'] as int? ?? 500,
        rankTier: RankTier.values.firstWhere(
          (t) => t.name == json['rankTier'],
          orElse: () => RankTier.warrior,
        ),
        rankStars: json['rankStars'] as int? ?? 1,
        totalMatches: json['totalMatches'] as int? ?? 0,
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        smashes: json['smashes'] as int? ?? 0,
        aces: json['aces'] as int? ?? 0,
        flawlessRallies: json['flawlessRallies'] as int? ?? 0,
        longestRally: json['longestRally'] as int? ?? 0,
        winStreak: json['winStreak'] as int? ?? 0,
        favoriteHeroes: (json['favoriteHeroes'] as List?)
                ?.map((e) => FavoriteHeroStat.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        recentMatches: (json['recentMatches'] as List?)
                ?.map((e) => MatchRecordModel.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        badges: (json['badges'] as List?)
                ?.map((e) => ProfileBadge.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        isPublicStats: json['isPublicStats'] as bool? ?? true,
        isPublicHistory: json['isPublicHistory'] as bool? ?? true,
        status: PlayerPresenceStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => PlayerPresenceStatus.online,
        ),
      );
}

/// Friend Entry Model in Friends Hub
class FriendModel {
  final String id;
  final String playerId; // e.g. "#PB-2041"
  final String nickname;
  final String avatarId;
  final PlayerPresenceStatus status;
  final RankTier rankTier;
  final int level;
  final double winRate;
  final String favoriteCharacter;
  final bool isSimulated;
  final String? activeRoomId;

  const FriendModel({
    required this.id,
    required this.playerId,
    required this.nickname,
    required this.avatarId,
    required this.status,
    required this.rankTier,
    this.level = 1,
    this.winRate = 50.0,
    this.favoriteCharacter = 'Alex',
    this.isSimulated = false,
    this.activeRoomId,
  });

  FriendModel copyWith({
    String? id,
    String? playerId,
    String? nickname,
    String? avatarId,
    PlayerPresenceStatus? status,
    RankTier? rankTier,
    int? level,
    double? winRate,
    String? favoriteCharacter,
    bool? isSimulated,
    String? activeRoomId,
  }) {
    return FriendModel(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      nickname: nickname ?? this.nickname,
      avatarId: avatarId ?? this.avatarId,
      status: status ?? this.status,
      rankTier: rankTier ?? this.rankTier,
      level: level ?? this.level,
      winRate: winRate ?? this.winRate,
      favoriteCharacter: favoriteCharacter ?? this.favoriteCharacter,
      isSimulated: isSimulated ?? this.isSimulated,
      activeRoomId: activeRoomId ?? this.activeRoomId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerId': playerId,
        'nickname': nickname,
        'avatarId': avatarId,
        'status': status.name,
        'rankTier': rankTier.name,
        'level': level,
        'winRate': winRate,
        'favoriteCharacter': favoriteCharacter,
        'isSimulated': isSimulated,
        'activeRoomId': activeRoomId,
      };

  factory FriendModel.fromJson(Map<String, dynamic> json) => FriendModel(
        id: json['id'] as String? ?? '',
        playerId: json['playerId'] as String? ?? '#PB-0000',
        nickname: json['nickname'] as String? ?? 'Player',
        avatarId: json['avatarId'] as String? ?? 'alex_classic',
        status: PlayerPresenceStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => PlayerPresenceStatus.online,
        ),
        rankTier: RankTier.values.firstWhere(
          (t) => t.name == json['rankTier'],
          orElse: () => RankTier.warrior,
        ),
        level: json['level'] as int? ?? 1,
        winRate: (json['winRate'] as num?)?.toDouble() ?? 50.0,
        favoriteCharacter: json['favoriteCharacter'] as String? ?? 'Alex',
        isSimulated: json['isSimulated'] as bool? ?? false,
        activeRoomId: json['activeRoomId'] as String?,
      );
}

/// Friend Request Model
class FriendRequestModel {
  final String id;
  final String senderId;
  final String senderPlayerId;
  final String senderNickname;
  final String senderAvatarId;
  final RankTier senderRankTier;
  final int senderLevel;
  final DateTime timestamp;

  const FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.senderPlayerId,
    required this.senderNickname,
    required this.senderAvatarId,
    required this.senderRankTier,
    required this.senderLevel,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderPlayerId': senderPlayerId,
        'senderNickname': senderNickname,
        'senderAvatarId': senderAvatarId,
        'senderRankTier': senderRankTier.name,
        'senderLevel': senderLevel,
        'timestamp': timestamp.toIso8601String(),
      };

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) => FriendRequestModel(
        id: json['id'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        senderPlayerId: json['senderPlayerId'] as String? ?? '#PB-0000',
        senderNickname: json['senderNickname'] as String? ?? 'Player',
        senderAvatarId: json['senderAvatarId'] as String? ?? 'alex_classic',
        senderRankTier: RankTier.values.firstWhere(
          (t) => t.name == json['senderRankTier'],
          orElse: () => RankTier.warrior,
        ),
        senderLevel: json['senderLevel'] as int? ?? 1,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Slot in a Private Battle Room
class RoomPlayerSlot {
  final int slotIndex;
  final String team; // 'A' (Blue) or 'B' (Red)
  final String? playerId;
  final String? playerName;
  final String? playerAvatar;
  final RankTier? rankTier;
  final bool isHost;
  final bool isReady;
  final bool isBot;
  final int pingMs;
  final String characterId;
  final String ballId;
  final String courtId;
  final bool hasSelectedLoadout;

  const RoomPlayerSlot({
    required this.slotIndex,
    required this.team,
    this.playerId,
    this.playerName,
    this.playerAvatar,
    this.rankTier,
    this.isHost = false,
    this.isReady = false,
    this.isBot = false,
    this.pingMs = 24,
    this.characterId = 'alex_classic',
    this.ballId = 'ball_elite',
    this.courtId = 'court_pro_stadium',
    this.hasSelectedLoadout = false,
  });

  bool get isEmpty => playerId == null;

  RoomPlayerSlot copyWith({
    int? slotIndex,
    String? team,
    String? playerId,
    String? playerName,
    String? playerAvatar,
    RankTier? rankTier,
    bool? isHost,
    bool? isReady,
    bool? isBot,
    int? pingMs,
    String? characterId,
    String? ballId,
    String? courtId,
    bool? hasSelectedLoadout,
    bool clearPlayer = false,
  }) {
    if (clearPlayer) {
      return RoomPlayerSlot(
        slotIndex: slotIndex ?? this.slotIndex,
        team: team ?? this.team,
        playerId: null,
        playerName: null,
        playerAvatar: null,
        rankTier: null,
        isHost: false,
        isReady: false,
        isBot: false,
        pingMs: 0,
        characterId: 'alex_classic',
        ballId: 'ball_elite',
        courtId: 'court_pro_stadium',
        hasSelectedLoadout: false,
      );
    }
    return RoomPlayerSlot(
      slotIndex: slotIndex ?? this.slotIndex,
      team: team ?? this.team,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      playerAvatar: playerAvatar ?? this.playerAvatar,
      rankTier: rankTier ?? this.rankTier,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      isBot: isBot ?? this.isBot,
      pingMs: pingMs ?? this.pingMs,
      characterId: characterId ?? this.characterId,
      ballId: ballId ?? this.ballId,
      courtId: courtId ?? this.courtId,
      hasSelectedLoadout: hasSelectedLoadout ?? this.hasSelectedLoadout,
    );
  }

  Map<String, dynamic> toJson() => {
        'slotIndex': slotIndex,
        'team': team,
        'playerId': playerId,
        'playerName': playerName,
        'playerAvatar': playerAvatar,
        'rankTier': rankTier?.name,
        'isHost': isHost,
        'isReady': isReady,
        'isBot': isBot,
        'pingMs': pingMs,
        'characterId': characterId,
        'ballId': ballId,
        'courtId': courtId,
        'hasSelectedLoadout': hasSelectedLoadout,
      };

  factory RoomPlayerSlot.fromJson(Map<String, dynamic> json) => RoomPlayerSlot(
        slotIndex: json['slotIndex'] as int? ?? 0,
        team: json['team'] as String? ?? 'A',
        playerId: json['playerId'] as String?,
        playerName: json['playerName'] as String?,
        playerAvatar: json['playerAvatar'] as String?,
        rankTier: json['rankTier'] != null
            ? RankTier.values.firstWhere(
                (t) => t.name == json['rankTier'],
                orElse: () => RankTier.warrior,
              )
            : null,
        isHost: json['isHost'] as bool? ?? false,
        isReady: json['isReady'] as bool? ?? false,
        isBot: json['isBot'] as bool? ?? false,
        pingMs: json['pingMs'] as int? ?? 24,
        characterId: (json['characterId'] as String?)?.isNotEmpty == true
            ? json['characterId'] as String
            : ((json['playerAvatar'] as String?)?.isNotEmpty == true
                ? json['playerAvatar'] as String
                : 'alex_classic'),
        ballId: (json['ballId'] as String?)?.isNotEmpty == true ? json['ballId'] as String : 'ball_elite',
        courtId: (json['courtId'] as String?)?.isNotEmpty == true ? json['courtId'] as String : 'court_pro_stadium',
        hasSelectedLoadout: (json['isBot'] as bool? ?? false)
            ? true
            : (json['hasSelectedLoadout'] as bool? ?? false),
      );
}

/// Connection mode for multiplayer battle
enum MultiplayerConnectionMode {
  lanHotspot, // Offline Hotspot or Local Wi-Fi (no internet needed)
  onlineCloud, // Online WebSocket relay (Google Play Store worldwide)
}

extension MultiplayerConnectionModeExt on MultiplayerConnectionMode {
  String get label {
    switch (this) {
      case MultiplayerConnectionMode.lanHotspot:
        return 'Offline Hotspot / Wi-Fi';
      case MultiplayerConnectionMode.onlineCloud:
        return 'Online Cloud (Play Store)';
    }
  }

  String get icon {
    switch (this) {
      case MultiplayerConnectionMode.lanHotspot:
        return '📶';
      case MultiplayerConnectionMode.onlineCloud:
        return '🌐';
    }
  }
}

/// Private Battle Room Model
class BattleRoomModel {
  final String roomId;
  final String roomCode; // e.g. "PB-8842"
  final String roomName;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final String gameMode; // '1v1 Singles' or '2v2 Doubles'
  final String courtId;
  final int targetScore; // 11, 15, or 21
  final String scoringRule; // 'Official Side-Out' or 'Rally Point'
  final int maxPlayers;
  final List<RoomPlayerSlot> slots;
  final String status; // 'waiting', 'inMatch', 'closed'
  final String? hostAddress; // IP or WebSocket endpoint
  final MultiplayerConnectionMode connectionMode;

  const BattleRoomModel({
    required this.roomId,
    required this.roomCode,
    required this.roomName,
    required this.hostId,
    required this.hostName,
    required this.hostAvatar,
    this.gameMode = '1v1 Singles',
    this.courtId = 'court_pro_stadium',
    this.targetScore = 11,
    this.scoringRule = 'Official Side-Out',
    this.maxPlayers = 2,
    required this.slots,
    this.status = 'waiting',
    this.hostAddress,
    this.connectionMode = MultiplayerConnectionMode.lanHotspot,
  });

  bool get isFull => slots.every((s) => !s.isEmpty);
  bool get isDoubles => maxPlayers == 4;

  bool get canStartBattle {
    final activeSlots = slots.where((s) => !s.isEmpty).toList();
    if (activeSlots.length < 2) return false;

    // All non-host players must be ready, and there must be at least one guest player
    final guestPlayers = activeSlots.where((s) => !s.isHost).toList();
    if (guestPlayers.isEmpty) return false;
    return guestPlayers.every((s) => s.isReady);
  }

  BattleRoomModel copyWith({
    String? roomId,
    String? roomCode,
    String? roomName,
    String? hostId,
    String? hostName,
    String? hostAvatar,
    String? gameMode,
    String? courtId,
    int? targetScore,
    String? scoringRule,
    int? maxPlayers,
    List<RoomPlayerSlot>? slots,
    String? status,
    String? hostAddress,
    MultiplayerConnectionMode? connectionMode,
  }) {
    return BattleRoomModel(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      roomName: roomName ?? this.roomName,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostAvatar: hostAvatar ?? this.hostAvatar,
      gameMode: gameMode ?? this.gameMode,
      courtId: courtId ?? this.courtId,
      targetScore: targetScore ?? this.targetScore,
      scoringRule: scoringRule ?? this.scoringRule,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      slots: slots ?? this.slots,
      status: status ?? this.status,
      hostAddress: hostAddress ?? this.hostAddress,
      connectionMode: connectionMode ?? this.connectionMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'roomCode': roomCode,
        'roomName': roomName,
        'hostId': hostId,
        'hostName': hostName,
        'hostAvatar': hostAvatar,
        'gameMode': gameMode,
        'courtId': courtId,
        'targetScore': targetScore,
        'scoringRule': scoringRule,
        'maxPlayers': maxPlayers,
        'slots': slots.map((s) => s.toJson()).toList(),
        'status': status,
        'hostAddress': hostAddress,
        'connectionMode': connectionMode.name,
      };

  factory BattleRoomModel.fromJson(Map<String, dynamic> json) => BattleRoomModel(
        roomId: json['roomId'] as String? ?? '',
        roomCode: json['roomCode'] as String? ?? 'PB-0000',
        roomName: json['roomName'] as String? ?? 'Battle Room',
        hostId: json['hostId'] as String? ?? '',
        hostName: json['hostName'] as String? ?? 'Host',
        hostAvatar: json['hostAvatar'] as String? ?? 'alex_classic',
        gameMode: json['gameMode'] as String? ?? '1v1 Singles',
        courtId: json['courtId'] as String? ?? 'court_pro_stadium',
        targetScore: json['targetScore'] as int? ?? 11,
        scoringRule: json['scoringRule'] as String? ?? 'Official Side-Out',
        maxPlayers: json['maxPlayers'] as int? ?? 2,
        slots: (json['slots'] as List?)
                ?.map((s) => RoomPlayerSlot.fromJson(Map<String, dynamic>.from(s as Map)))
                .toList() ??
            const [],
        status: json['status'] as String? ?? 'waiting',
        hostAddress: json['hostAddress'] as String?,
        connectionMode: MultiplayerConnectionMode.values.firstWhere(
          (m) => m.name == json['connectionMode'],
          orElse: () => MultiplayerConnectionMode.lanHotspot,
        ),
      );
}

/// Battle Invitation Model
class BattleInvitationModel {
  final String id;
  final String roomId;
  final String roomCode;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final RankTier hostRankTier;
  final String gameMode;
  final String courtId;
  final int targetScore;
  final DateTime timestamp;

  const BattleInvitationModel({
    required this.id,
    required this.roomId,
    required this.roomCode,
    required this.hostId,
    required this.hostName,
    required this.hostAvatar,
    required this.hostRankTier,
    required this.gameMode,
    required this.courtId,
    required this.targetScore,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'roomCode': roomCode,
        'hostId': hostId,
        'hostName': hostName,
        'hostAvatar': hostAvatar,
        'hostRankTier': hostRankTier.name,
        'gameMode': gameMode,
        'courtId': courtId,
        'targetScore': targetScore,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BattleInvitationModel.fromJson(Map<String, dynamic> json) => BattleInvitationModel(
        id: json['id'] as String? ?? '',
        roomId: json['roomId'] as String? ?? '',
        roomCode: json['roomCode'] as String? ?? '',
        hostId: json['hostId'] as String? ?? '',
        hostName: json['hostName'] as String? ?? 'Host',
        hostAvatar: json['hostAvatar'] as String? ?? 'alex_classic',
        hostRankTier: RankTier.values.firstWhere(
          (t) => t.name == json['hostRankTier'],
          orElse: () => RankTier.warrior,
        ),
        gameMode: json['gameMode'] as String? ?? '1v1 Singles',
        courtId: json['courtId'] as String? ?? 'court_pro_stadium',
        targetScore: json['targetScore'] as int? ?? 11,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Local Hotspot / Wi-Fi Discovered Room Beacon
class DiscoveredLocalRoom {
  final String roomCode;
  final String roomName;
  final String hostName;
  final String hostAvatar;
  final String hostAddress; // e.g. "192.168.43.1"
  final int port; // e.g. 8088
  final String gameMode;
  final String courtId;
  final int targetScore;
  final int currentPlayers;
  final int maxPlayers;
  final DateTime lastSeen;

  const DiscoveredLocalRoom({
    required this.roomCode,
    required this.roomName,
    required this.hostName,
    this.hostAvatar = 'alex_classic',
    required this.hostAddress,
    this.port = 8088,
    required this.gameMode,
    this.courtId = 'court_pro_stadium',
    this.targetScore = 11,
    this.currentPlayers = 1,
    this.maxPlayers = 2,
    required this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
        'roomCode': roomCode,
        'roomName': roomName,
        'hostName': hostName,
        'hostAvatar': hostAvatar,
        'hostAddress': hostAddress,
        'port': port,
        'gameMode': gameMode,
        'courtId': courtId,
        'targetScore': targetScore,
        'currentPlayers': currentPlayers,
        'maxPlayers': maxPlayers,
      };

  factory DiscoveredLocalRoom.fromJson(Map<String, dynamic> json) => DiscoveredLocalRoom(
        roomCode: json['roomCode'] as String? ?? 'PB-0000',
        roomName: json['roomName'] as String? ?? 'Court',
        hostName: json['hostName'] as String? ?? 'Host',
        hostAvatar: json['hostAvatar'] as String? ?? 'alex_classic',
        hostAddress: json['hostAddress'] as String? ?? '127.0.0.1',
        port: json['port'] as int? ?? 8088,
        gameMode: json['gameMode'] as String? ?? '1v1 Singles',
        courtId: json['courtId'] as String? ?? 'court_pro_stadium',
        targetScore: json['targetScore'] as int? ?? 11,
        currentPlayers: json['currentPlayers'] as int? ?? 1,
        maxPlayers: json['maxPlayers'] as int? ?? 2,
        lastSeen: DateTime.now(),
      );
}

/// Real-time live battle packets
enum PacketType {
  handshake,
  joinRoom,
  leaveRoom,
  roomSync,
  playerState,
  ballStrike,
  ballSync,
  serveAction,
  scoreSync,
  matchStart,
  matchEnd,
  techniqueTrigger,
  ping,
  pong,
  chatMessage,
}

class MultiplayerPacket {
  final PacketType type;
  final int timestamp;
  final String senderId;
  final Map<String, dynamic> data;

  const MultiplayerPacket({
    required this.type,
    required this.timestamp,
    required this.senderId,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp,
        'senderId': senderId,
        'data': data,
      };

  factory MultiplayerPacket.fromJson(Map<String, dynamic> json) => MultiplayerPacket(
        type: PacketType.values.firstWhere(
          (p) => p.name == json['type'],
          orElse: () => PacketType.ping,
        ),
        timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        senderId: json['senderId'] as String? ?? '',
        data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      );
}

/// Chat / Message model for live player communication
class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String text;
  final int timestamp;
  final bool isQuickChat;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.text,
    required this.timestamp,
    this.isQuickChat = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'text': text,
        'timestamp': timestamp,
        'isQuickChat': isQuickChat,
      };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => ChatMessageModel(
        id: json['id'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        senderName: json['senderName'] as String? ?? 'Player',
        senderAvatar: json['senderAvatar'] as String? ?? 'alex_classic',
        text: json['text'] as String? ?? '',
        timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        isQuickChat: json['isQuickChat'] as bool? ?? false,
      );
}

