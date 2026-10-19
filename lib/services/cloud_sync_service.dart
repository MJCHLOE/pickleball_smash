import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'firebase_multiplayer_service.dart';

/// Resilient Cloud Sync Service connecting local SQLite with Firebase Realtime Database.
/// 
/// Local-first design:
/// - Local SQLite remains the instant, offline-capable source of truth.
/// - Whenever the player earns coins, XP, or wins matches, SQLite saves immediately.
/// - An asynchronous, non-blocking snapshot is pushed to Firebase in the background.
/// - If the device is offline, SQLite continues normally without interruption.
/// - When a player logs in on a new phone, data is restored from Firebase into SQLite!
class CloudSyncService {
  static final CloudSyncService instance = CloudSyncService._internal();
  factory CloudSyncService() => instance;
  CloudSyncService._internal();

  final http.Client _httpClient = http.Client();
  String get _databaseUrl => FirebaseMultiplayerService.instance.databaseUrl;

  /// Sanitizes key names for Firebase Realtime Database path compatibility
  String _sanitizeKey(String key) {
    return key.trim().replaceAll(RegExp(r'[.#$\[\]]'), '_');
  }

  /// Non-blocking, background sync of player progress to Firebase Realtime Database
  Future<void> syncPlayerToCloud({
    required String username,
    required String avatarId,
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
    required List<String> unlockedCharacters,
    required List<String> unlockedCourts,
    required String equippedCourt,
    required List<String> unlockedBalls,
    required String equippedBall,
  }) async {
    final cleanUsername = _sanitizeKey(username);
    if (cleanUsername.isEmpty || cleanUsername.toLowerCase() == 'guest_player' || cleanUsername.toLowerCase() == 'guest') {
      return;
    }

    try {
      final payload = {
        'username': username,
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
        'unlockedCharacters': unlockedCharacters,
        'unlockedCourts': unlockedCourts,
        'equippedCourt': equippedCourt,
        'unlockedBalls': unlockedBalls,
        'equippedBall': equippedBall,
        'lastSyncedAt': DateTime.now().toIso8601String(),
      };

      // 1. Upload player cloud backup to Firebase at /users/{cleanUsername}.json
      final userUri = Uri.parse('$_databaseUrl/users/$cleanUsername.json');
      await _httpClient.put(
        userUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      // 2. Publish summary to global leaderboard at /leaderboard/{cleanUsername}.json
      final winRate = matchesPlayed > 0 ? ((matchesWon / matchesPlayed) * 100).toStringAsFixed(1) : '0.0';
      final leaderboardUri = Uri.parse('$_databaseUrl/leaderboard/$cleanUsername.json');
      await _httpClient.put(
        leaderboardUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'avatarId': avatarId,
          'playerLevel': playerLevel,
          'trophies': trophies,
          'matchesWon': matchesWon,
          'matchesPlayed': matchesPlayed,
          'winRate': '$winRate%',
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      // Offline safe: network failures never disrupt local SQLite gameplay
      debugPrint('CloudSyncService: Background sync skipped: $e');
    }
  }

  /// Pulls cloud backup from Firebase if SQLite has no profile (e.g. freshly installed device)
  Future<Map<String, dynamic>?> fetchCloudProfile(String username) async {
    final cleanUsername = _sanitizeKey(username);
    if (cleanUsername.isEmpty) return null;

    try {
      final uri = Uri.parse('$_databaseUrl/users/$cleanUsername.json');
      final res = await _httpClient.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body != 'null') {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('CloudSyncService.fetchCloudProfile error: $e');
    }
    return null;
  }

  /// Fetches top players from Firebase Realtime Database for the global leaderboard
  Future<List<Map<String, dynamic>>> fetchGlobalLeaderboard() async {
    try {
      final uri = Uri.parse('$_databaseUrl/leaderboard.json');
      final res = await _httpClient.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body != 'null') {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final List<Map<String, dynamic>> list = [];
        data.forEach((key, val) {
          if (val is Map) {
            list.add(Map<String, dynamic>.from(val));
          }
        });
        list.sort((a, b) => ((b['trophies'] as num?) ?? 0).compareTo((a['trophies'] as num?) ?? 0));
        return list;
      }
    } catch (e) {
      debugPrint('CloudSyncService.fetchGlobalLeaderboard error: $e');
    }
    return [];
  }
}

