import 'dart:convert';
import 'dart:io' show Platform, Directory;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/challenge_model.dart';
import '../models/game_settings.dart';
import '../models/tournament_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;
  DatabaseService._internal();

  Database? _db;
  bool _initialized = false;

  // Resilient in-memory fallback store in case SQLite is unavailable
  final Map<int, Map<String, dynamic>> _fallbackUsers = {};
  final Map<int, Map<String, dynamic>> _fallbackPlayerData = {};
  final List<Map<String, dynamic>> _fallbackMatchHistory = [];
  final Map<int, List<Map<String, dynamic>>> _fallbackFriends = {};
  final Map<int, List<Map<String, dynamic>>> _fallbackFriendRequests = {};
  Map<String, dynamic>? _fallbackActiveSession;
  int _nextFallbackUserId = 1;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await database;
    } catch (e) {
      debugPrint('DatabaseService.initialize error: $e');
    }
    _initialized = true;
  }

  Future<Database?> get database async {
    if (_db != null && _db!.isOpen) return _db;
    _db = await _initDatabase();
    return _db;
  }

  Future<Database?> _initDatabase() async {
    try {
      if (kIsWeb) {
        // Web environments use resilient in-memory storage immediately
        debugPrint('Web platform detected: using resilient in-memory database store');
        return null;
      }

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final dbPath = await getDatabasesPath();
      try {
        await Directory(dbPath).create(recursive: true);
      } catch (_) {}
      final path = p.join(dbPath, 'pickleball_smash.db');

      final db = await openDatabase(
        path,
        version: 6,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      return db;
    } catch (e) {
      debugPrint('Database initialization warning: $e - using resilient store');
      return null;
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        avatar_id TEXT DEFAULT 'alex_classic',
        created_at TEXT NOT NULL,
        last_login TEXT NOT NULL
      );
    ''');

    // Player Data table linked to user
    await db.execute('''
      CREATE TABLE IF NOT EXISTS player_data (
        user_id INTEGER PRIMARY KEY,
        avatar_id TEXT DEFAULT 'alex_classic',
        player_level INTEGER NOT NULL,
        player_xp INTEGER NOT NULL,
        xp_to_next_level INTEGER NOT NULL,
        coins INTEGER NOT NULL,
        trophies INTEGER NOT NULL,
        matches_played INTEGER NOT NULL,
        matches_won INTEGER NOT NULL,
        total_smashes INTEGER NOT NULL,
        best_streak INTEGER NOT NULL,
        current_streak INTEGER NOT NULL,
        tournaments_json TEXT NOT NULL,
        challenges_json TEXT NOT NULL,
        settings_json TEXT NOT NULL,
        unlocked_characters TEXT DEFAULT 'alex_classic,maya_speed',
        unlocked_courts TEXT DEFAULT 'court_pro_stadium',
        equipped_court TEXT DEFAULT 'court_pro_stadium',
        unlocked_balls TEXT DEFAULT 'ball_elite',
        equipped_ball TEXT DEFAULT 'ball_elite',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');

    // Active Session table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id INTEGER NOT NULL,
        username TEXT NOT NULL,
        logged_in_at TEXT NOT NULL
      );
    ''');

    // Match History table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS match_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        match_type TEXT NOT NULL,
        opponent_name TEXT NOT NULL,
        player_score INTEGER NOT NULL,
        opponent_score INTEGER NOT NULL,
        won INTEGER NOT NULL,
        smashes_hit INTEGER NOT NULL,
        coins_earned INTEGER NOT NULL,
        played_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');

    // Friends table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS friends (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        friend_id TEXT NOT NULL,
        friend_player_id TEXT NOT NULL,
        friend_nickname TEXT NOT NULL,
        friend_avatar_id TEXT NOT NULL,
        friend_rank TEXT NOT NULL,
        friend_level INTEGER NOT NULL,
        friend_win_rate REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');

    // Friend Requests table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS friend_requests (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        sender_id TEXT NOT NULL,
        sender_player_id TEXT NOT NULL,
        sender_nickname TEXT NOT NULL,
        sender_avatar_id TEXT NOT NULL,
        sender_rank TEXT NOT NULL,
        sender_level INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS match_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          match_type TEXT NOT NULL,
          opponent_name TEXT NOT NULL,
          player_score INTEGER NOT NULL,
          opponent_score INTEGER NOT NULL,
          won INTEGER NOT NULL,
          smashes_hit INTEGER NOT NULL,
          coins_earned INTEGER NOT NULL,
          played_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        );
      ''');
    }
    if (oldVersion < 3) {
      try {
        await db.execute("ALTER TABLE player_data ADD COLUMN avatar_id TEXT DEFAULT 'alex_classic';");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE users ADD COLUMN avatar_id TEXT DEFAULT 'alex_classic';");
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE player_data ADD COLUMN unlocked_characters TEXT DEFAULT 'alex_classic,maya_speed';");
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE player_data ADD COLUMN unlocked_courts TEXT DEFAULT 'court_pro_stadium';");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE player_data ADD COLUMN equipped_court TEXT DEFAULT 'court_pro_stadium';");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE player_data ADD COLUMN unlocked_balls TEXT DEFAULT 'ball_elite';");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE player_data ADD COLUMN equipped_ball TEXT DEFAULT 'ball_elite';");
      } catch (_) {}
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS friends (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          friend_id TEXT NOT NULL,
          friend_player_id TEXT NOT NULL,
          friend_nickname TEXT NOT NULL,
          friend_avatar_id TEXT NOT NULL,
          friend_rank TEXT NOT NULL,
          friend_level INTEGER NOT NULL,
          friend_win_rate REAL NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS friend_requests (
          id TEXT PRIMARY KEY,
          user_id INTEGER NOT NULL,
          sender_id TEXT NOT NULL,
          sender_player_id TEXT NOT NULL,
          sender_nickname TEXT NOT NULL,
          sender_avatar_id TEXT NOT NULL,
          sender_rank TEXT NOT NULL,
          sender_level INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        );
      ''');
    }
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String password,
  }) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.length < 3) {
      throw Exception('Username must be at least 3 characters long');
    }
    if (password.length < 4) {
      throw Exception('Password must be at least 4 characters long');
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();
    final passwordHash = hashPassword(password);

    if (db != null) {
      try {
        final existing = await db.query(
          'users',
          where: 'LOWER(username) = ?',
          whereArgs: [trimmedUsername.toLowerCase()],
        );

        if (existing.isNotEmpty) {
          throw Exception('Username is already taken');
        }

        final userId = await db.insert('users', {
          'username': trimmedUsername,
          'password_hash': passwordHash,
          'created_at': now,
          'last_login': now,
        });

        // Save active session
        await _setActiveSession(userId, trimmedUsername);

        return {
          'userId': userId,
          'username': trimmedUsername,
        };
      } catch (e) {
        if (e.toString().contains('already taken') || e.toString().contains('characters')) {
          rethrow;
        }
        debugPrint('SQLite register error ($e); falling back to memory store');
      }
    }

    // Fallback store
    for (final u in _fallbackUsers.values) {
      if ((u['username'] as String).toLowerCase() == trimmedUsername.toLowerCase()) {
        throw Exception('Username is already taken');
      }
    }

    final userId = _nextFallbackUserId++;
    _fallbackUsers[userId] = {
      'id': userId,
      'username': trimmedUsername,
      'password_hash': passwordHash,
      'created_at': now,
      'last_login': now,
    };

    await _setActiveSession(userId, trimmedUsername);

    return {
      'userId': userId,
      'username': trimmedUsername,
    };
  }

  Future<Map<String, dynamic>> loginUser({
    required String username,
    required String password,
  }) async {
    final trimmedUsername = username.trim();
    final passwordHash = hashPassword(password);
    final db = await database;

    if (db != null) {
      try {
        final results = await db.query(
          'users',
          where: 'LOWER(username) = ? AND password_hash = ?',
          whereArgs: [trimmedUsername.toLowerCase(), passwordHash],
        );

        if (results.isNotEmpty) {
          final user = results.first;
          final userId = user['id'] as int;
          final actualUsername = user['username'] as String;

          await db.update(
            'users',
            {'last_login': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [userId],
          );

          await _setActiveSession(userId, actualUsername);

          return {
            'userId': userId,
            'username': actualUsername,
          };
        }
      } catch (e) {
        debugPrint('SQLite login error ($e); falling back to memory store');
      }
    }

    // Fallback store
    for (final entry in _fallbackUsers.entries) {
      final u = entry.value;
      if ((u['username'] as String).toLowerCase() == trimmedUsername.toLowerCase() &&
          u['password_hash'] == passwordHash) {
        final userId = entry.key;
        final actualUsername = u['username'] as String;
        await _setActiveSession(userId, actualUsername);
        return {
          'userId': userId,
          'username': actualUsername,
        };
      }
    }

    throw Exception('Invalid username or password');
  }

  Future<void> _setActiveSession(int userId, String username) async {
    _fallbackActiveSession = {
      'userId': userId,
      'username': username,
      'logged_in_at': DateTime.now().toIso8601String(),
    };

    final db = await database;
    if (db != null) {
      try {
        await db.insert(
          'active_session',
          {
            'id': 1,
            'user_id': userId,
            'username': username,
            'logged_in_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    final db = await database;
    if (db != null) {
      try {
        final results = await db.query('active_session', where: 'id = 1');
        if (results.isNotEmpty) {
          return {
            'userId': results.first['user_id'] as int,
            'username': results.first['username'] as String,
          };
        }
      } catch (_) {}
    }

    return _fallbackActiveSession;
  }

  Future<void> clearActiveSession() async {
    _fallbackActiveSession = null;
    final db = await database;
    if (db != null) {
      try {
        await db.delete('active_session');
      } catch (_) {}
    }
  }

  Future<void> savePlayerData({
    required int userId,
    String avatarId = 'alex_classic',
    required int playerLevel,
    required int playerXp,
    required int xpToNextLevel,
    required int coins,
    required int trophies,
    required int matchesPlayed,
    required int matchesWon,
    required int totalSmashes,
    required int bestStreak,
    required int currentStreak,
    required List<Tournament> tournaments,
    required List<ChallengeItem> challenges,
    required GameSettings settings,
    List<String> unlockedCharacters = const ['alex_classic', 'maya_speed'],
    List<String> unlockedCourts = const ['court_pro_stadium'],
    String equippedCourt = 'court_pro_stadium',
    List<String> unlockedBalls = const ['ball_elite'],
    String equippedBall = 'ball_elite',
  }) async {
    // Cache in fallback store
    _fallbackPlayerData[userId] = {
      'avatarId': avatarId,
      'playerLevel': playerLevel,
      'playerXp': playerXp,
      'xpToNextLevel': xpToNextLevel,
      'coins': coins,
      'trophies': trophies,
      'matchesPlayed': matchesPlayed,
      'matchesWon': matchesWon,
      'totalSmashes': totalSmashes,
      'bestStreak': bestStreak,
      'currentStreak': currentStreak,
      'tournaments': tournaments,
      'challenges': challenges,
      'settings': settings,
      'unlockedCharacters': unlockedCharacters,
      'unlockedCourts': unlockedCourts,
      'equippedCourt': equippedCourt,
      'unlockedBalls': unlockedBalls,
      'equippedBall': equippedBall,
    };

    final db = await database;
    if (db != null) {
      try {
        final tournamentsJson = jsonEncode(tournaments.map((t) => t.toMap()).toList());
        final challengesJson = jsonEncode(challenges.map((c) => c.toMap()).toList());
        final settingsJson = jsonEncode(settings.toMap());

        await db.insert(
          'player_data',
          {
            'user_id': userId,
            'avatar_id': avatarId,
            'player_level': playerLevel,
            'player_xp': playerXp,
            'xp_to_next_level': xpToNextLevel,
            'coins': coins,
            'trophies': trophies,
            'matches_played': matchesPlayed,
            'matches_won': matchesWon,
            'total_smashes': totalSmashes,
            'best_streak': bestStreak,
            'current_streak': currentStreak,
            'tournaments_json': tournamentsJson,
            'challenges_json': challengesJson,
            'settings_json': settingsJson,
            'unlocked_characters': unlockedCharacters.join(','),
            'unlocked_courts': unlockedCourts.join(','),
            'equipped_court': equippedCourt,
            'unlocked_balls': unlockedBalls.join(','),
            'equipped_ball': equippedBall,
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('SQLite savePlayerData error: $e');
      }
    }
  }

  Future<void> updateUserAvatar(int userId, String avatarId) async {
    if (_fallbackPlayerData.containsKey(userId)) {
      _fallbackPlayerData[userId]!['avatarId'] = avatarId;
    }
    if (_fallbackUsers.containsKey(userId)) {
      _fallbackUsers[userId]!['avatar_id'] = avatarId;
    }

    final db = await database;
    if (db != null) {
      try {
        await db.update('player_data', {'avatar_id': avatarId}, where: 'user_id = ?', whereArgs: [userId]);
        await db.update('users', {'avatar_id': avatarId}, where: 'id = ?', whereArgs: [userId]);
      } catch (e) {
        debugPrint('SQLite updateUserAvatar error: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> loadPlayerData(int userId) async {
    final db = await database;
    if (db != null) {
      try {
        final results = await db.query(
          'player_data',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        if (results.isNotEmpty) {
          final row = results.first;

          List<Tournament>? tournaments;
          try {
            final tList = jsonDecode(row['tournaments_json'] as String) as List;
            if (tList.isNotEmpty) {
              tournaments = tList.map((m) => Tournament.fromMap(Map<String, dynamic>.from(m as Map))).toList();
            }
          } catch (_) {}

          List<ChallengeItem>? challenges;
          try {
            final cList = jsonDecode(row['challenges_json'] as String) as List;
            if (cList.isNotEmpty) {
              challenges = cList.map((m) => ChallengeItem.fromMap(Map<String, dynamic>.from(m as Map))).toList();
            }
          } catch (_) {}

          GameSettings? settings;
          try {
            final sMap = jsonDecode(row['settings_json'] as String) as Map<String, dynamic>;
            settings = GameSettings.fromMap(sMap);
          } catch (_) {}

          List<String> unlockedCharacters = ['alex_classic', 'maya_speed'];
          try {
            final uStr = row['unlocked_characters'] as String?;
            if (uStr != null && uStr.isNotEmpty) {
              unlockedCharacters = uStr.split(',').map((s) => s.trim()).toList();
            }
          } catch (_) {}

          List<String> unlockedCourts = ['court_pro_stadium'];
          try {
            final cStr = row['unlocked_courts'] as String?;
            if (cStr != null && cStr.isNotEmpty) {
              unlockedCourts = cStr.split(',').map((s) => s.trim()).toList();
            }
          } catch (_) {}

          String equippedCourt = 'court_pro_stadium';
          try {
            final ec = row['equipped_court'] as String?;
            if (ec != null && ec.isNotEmpty) {
              equippedCourt = ec;
            }
          } catch (_) {}

          List<String> unlockedBalls = ['ball_elite'];
          try {
            final bStr = row['unlocked_balls'] as String?;
            if (bStr != null && bStr.isNotEmpty) {
              unlockedBalls = bStr.split(',').map((s) => s.trim()).toList();
            }
          } catch (_) {}

          String equippedBall = 'ball_elite';
          try {
            final eb = row['equipped_ball'] as String?;
            if (eb != null && eb.isNotEmpty) {
              equippedBall = eb;
            }
          } catch (_) {}

          return {
            'avatarId': row['avatar_id'] as String? ?? 'alex_classic',
            'playerLevel': row['player_level'] as int,
            'playerXp': row['player_xp'] as int,
            'xpToNextLevel': row['xp_to_next_level'] as int,
            'coins': row['coins'] as int,
            'trophies': row['trophies'] as int,
            'matchesPlayed': row['matches_played'] as int,
            'matchesWon': row['matches_won'] as int,
            'totalSmashes': row['total_smashes'] as int,
            'bestStreak': row['best_streak'] as int,
            'currentStreak': row['current_streak'] as int,
            'tournaments': tournaments,
            'challenges': challenges,
            'settings': settings,
            'unlockedCharacters': unlockedCharacters,
            'unlockedCourts': unlockedCourts,
            'equippedCourt': equippedCourt,
            'unlockedBalls': unlockedBalls,
            'equippedBall': equippedBall,
          };
        }
      } catch (e) {
        debugPrint('SQLite loadPlayerData error: $e');
      }
    }

    return _fallbackPlayerData[userId];
  }

  Future<void> recordMatch({
    required int userId,
    required String matchType,
    required String opponentName,
    required int playerScore,
    required int opponentScore,
    required bool won,
    required int smashesHit,
    required int coinsEarned,
  }) async {
    final now = DateTime.now().toIso8601String();

    _fallbackMatchHistory.insert(0, {
      'id': _fallbackMatchHistory.length + 1,
      'user_id': userId,
      'match_type': matchType,
      'opponent_name': opponentName,
      'player_score': playerScore,
      'opponent_score': opponentScore,
      'won': won ? 1 : 0,
      'smashes_hit': smashesHit,
      'coins_earned': coinsEarned,
      'played_at': now,
    });

    final db = await database;
    if (db != null) {
      try {
        await db.insert('match_history', {
          'user_id': userId,
          'match_type': matchType,
          'opponent_name': opponentName,
          'player_score': playerScore,
          'opponent_score': opponentScore,
          'won': won ? 1 : 0,
          'smashes_hit': smashesHit,
          'coins_earned': coinsEarned,
          'played_at': now,
        });
      } catch (e) {
        debugPrint('SQLite recordMatch error: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getMatchHistory(int userId, {int limit = 20}) async {
    final db = await database;
    if (db != null) {
      try {
        final results = await db.query(
          'match_history',
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'id DESC',
          limit: limit,
        );
        if (results.isNotEmpty) return results;
      } catch (e) {
        debugPrint('SQLite getMatchHistory error: $e');
      }
    }

    final list = _fallbackMatchHistory.where((m) => m['user_id'] == userId).take(limit).toList();
    return list;
  }

  Future<List<Map<String, dynamic>>> getAllPlayersLeaderboard({int limit = 50}) async {
    final db = await database;
    if (db != null) {
      try {
        final results = await db.rawQuery('''
          SELECT 
            u.id as user_id, 
            u.username, 
            u.created_at,
            COALESCE(p.avatar_id, 'alex_classic') as avatar_id,
            COALESCE(p.player_level, 1) as player_level,
            COALESCE(p.player_xp, 0) as player_xp,
            COALESCE(p.coins, 500) as coins,
            COALESCE(p.trophies, 0) as trophies,
            COALESCE(p.matches_played, 0) as matches_played,
            COALESCE(p.matches_won, 0) as matches_won,
            COALESCE(p.total_smashes, 0) as total_smashes,
            COALESCE(p.best_streak, 0) as best_streak,
            COALESCE(p.current_streak, 0) as current_streak
          FROM users u
          LEFT JOIN player_data p ON u.id = p.user_id
          ORDER BY COALESCE(p.trophies, 0) DESC, COALESCE(p.matches_won, 0) DESC, COALESCE(p.player_level, 1) DESC, u.id DESC
          LIMIT ?
        ''', [limit]);

        if (results.isNotEmpty) {
          return results.map((row) {
            final played = (row['matches_played'] as num?)?.toInt() ?? 0;
            final won = (row['matches_won'] as num?)?.toInt() ?? 0;
            final winRate = played > 0 ? ((won / played) * 100).round() : 0;
            return {
              ...row,
              'avatar_id': row['avatar_id'] as String? ?? 'alex_classic',
              'win_rate': winRate,
              'matches_lost': played - won,
            };
          }).toList();
        }
      } catch (e) {
        debugPrint('SQLite getAllPlayersLeaderboard error: $e');
      }
    }

    // Fallback store
    final list = <Map<String, dynamic>>[];
    for (final u in _fallbackUsers.values) {
      final userId = u['id'] as int;
      final data = _fallbackPlayerData[userId] ?? {};
      final played = (data['matchesPlayed'] as num?)?.toInt() ?? 0;
      final won = (data['matchesWon'] as num?)?.toInt() ?? 0;
      final winRate = played > 0 ? ((won / played) * 100).round() : 0;
      list.add({
        'user_id': userId,
        'username': u['username'] as String,
        'created_at': u['created_at'] as String,
        'avatar_id': (data['avatarId'] as String?) ?? (u['avatar_id'] as String?) ?? 'alex_classic',
        'player_level': (data['playerLevel'] as num?)?.toInt() ?? 1,
        'player_xp': (data['playerXp'] as num?)?.toInt() ?? 0,
        'coins': (data['coins'] as num?)?.toInt() ?? 500,
        'trophies': (data['trophies'] as num?)?.toInt() ?? 0,
        'matches_played': played,
        'matches_won': won,
        'matches_lost': played - won,
        'win_rate': winRate,
        'total_smashes': (data['totalSmashes'] as num?)?.toInt() ?? 0,
        'best_streak': (data['bestStreak'] as num?)?.toInt() ?? 0,
        'current_streak': (data['currentStreak'] as num?)?.toInt() ?? 0,
      });
    }

    list.sort((a, b) {
      final tA = a['trophies'] as int;
      final tB = b['trophies'] as int;
      if (tB != tA) return tB.compareTo(tA);
      final wA = a['matches_won'] as int;
      final wB = b['matches_won'] as int;
      return wB.compareTo(wA);
    });

    return list.take(limit).toList();
  }

  /// Searches real registered users by username or Player ID (e.g. #PB-0001)
  Future<List<Map<String, dynamic>>> searchRegisteredUsers(String query, {int limit = 20}) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final db = await database;
    if (db != null) {
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT u.id as user_id, u.username, u.avatar_id,
               COALESCE(pd.player_level, 1) as player_level,
               COALESCE(pd.matches_played, 0) as matches_played,
               COALESCE(pd.matches_won, 0) as matches_won,
               COALESCE(pd.trophies, 0) as trophies
        FROM users u
        LEFT JOIN player_data pd ON u.id = pd.user_id
        WHERE LOWER(u.username) LIKE ? OR '#pb-' || printf('%04d', u.id) LIKE ?
        ORDER BY pd.trophies DESC, pd.player_level DESC
        LIMIT ?
      ''', ['%$clean%', '%$clean%', limit]);
      return results;
    }

    // Fallback store
    final list = <Map<String, dynamic>>[];
    for (final entry in _fallbackUsers.entries) {
      final u = entry.value;
      final userId = entry.key;
      final username = (u['username'] as String).toLowerCase();
      final pid = '#pb-${userId.toString().padLeft(4, '0')}';
      if (username.contains(clean) || pid.contains(clean)) {
        final pd = _fallbackPlayerData[userId] ?? {};
        list.add({
          'user_id': userId,
          'username': u['username'] as String,
          'avatar_id': (pd['avatarId'] as String?) ?? (u['avatar_id'] as String?) ?? 'alex_classic',
          'player_level': (pd['playerLevel'] as num?)?.toInt() ?? 1,
          'matches_played': (pd['matchesPlayed'] as num?)?.toInt() ?? 0,
          'matches_won': (pd['matchesWon'] as num?)?.toInt() ?? 0,
          'trophies': (pd['trophies'] as num?)?.toInt() ?? 0,
        });
      }
    }
    return list.take(limit).toList();
  }

  /// Gets saved friends for a user
  Future<List<Map<String, dynamic>>> getFriends(int userId) async {
    final db = await database;
    if (db != null) {
      return await db.query(
        'friends',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    }
    return List.from(_fallbackFriends[userId] ?? []);
  }

  /// Saves a real friend to SQLite
  Future<void> saveFriend(int userId, Map<String, dynamic> friendData) async {
    final db = await database;
    if (db != null) {
      await db.insert('friends', {
        'user_id': userId,
        'friend_id': friendData['friend_id'],
        'friend_player_id': friendData['friend_player_id'],
        'friend_nickname': friendData['friend_nickname'],
        'friend_avatar_id': friendData['friend_avatar_id'],
        'friend_rank': friendData['friend_rank'],
        'friend_level': friendData['friend_level'],
        'friend_win_rate': friendData['friend_win_rate'],
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }
    _fallbackFriends.putIfAbsent(userId, () => []);
    _fallbackFriends[userId]!.removeWhere((f) => f['friend_id'] == friendData['friend_id']);
    _fallbackFriends[userId]!.insert(0, {
      ...friendData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Removes a friend from SQLite
  Future<void> removeFriend(int userId, String friendId) async {
    final db = await database;
    if (db != null) {
      await db.delete(
        'friends',
        where: 'user_id = ? AND (friend_id = ? OR friend_player_id = ?)',
        whereArgs: [userId, friendId, friendId],
      );
      return;
    }
    _fallbackFriends[userId]?.removeWhere((f) => f['friend_id'] == friendId || f['friend_player_id'] == friendId);
  }

  /// Gets pending friend requests for a user
  Future<List<Map<String, dynamic>>> getFriendRequests(int userId) async {
    final db = await database;
    if (db != null) {
      return await db.query(
        'friend_requests',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    }
    return List.from(_fallbackFriendRequests[userId] ?? []);
  }

  /// Saves an incoming friend request
  Future<void> saveFriendRequest(int userId, Map<String, dynamic> reqData) async {
    final db = await database;
    if (db != null) {
      await db.insert('friend_requests', {
        'id': reqData['id'],
        'user_id': userId,
        'sender_id': reqData['sender_id'],
        'sender_player_id': reqData['sender_player_id'],
        'sender_nickname': reqData['sender_nickname'],
        'sender_avatar_id': reqData['sender_avatar_id'],
        'sender_rank': reqData['sender_rank'],
        'sender_level': reqData['sender_level'],
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }
    _fallbackFriendRequests.putIfAbsent(userId, () => []);
    _fallbackFriendRequests[userId]!.removeWhere((r) => r['id'] == reqData['id']);
    _fallbackFriendRequests[userId]!.insert(0, {
      ...reqData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Deletes a friend request
  Future<void> deleteFriendRequest(int userId, String requestId) async {
    final db = await database;
    if (db != null) {
      await db.delete(
        'friend_requests',
        where: 'user_id = ? AND id = ?',
        whereArgs: [userId, requestId],
      );
      return;
    }
    _fallbackFriendRequests[userId]?.removeWhere((r) => r['id'] == requestId);
  }

  // Close database
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
