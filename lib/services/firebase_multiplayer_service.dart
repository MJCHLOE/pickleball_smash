import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/multiplayer_models.dart';

/// Firebase-backed online multiplayer service supporting authoritative 1v1 Singles
/// and 2v2 Doubles battle rooms, live presence, and real-time state synchronization.
class FirebaseMultiplayerService extends ChangeNotifier {
  static final FirebaseMultiplayerService instance = FirebaseMultiplayerService._internal();
  factory FirebaseMultiplayerService() => instance;

  FirebaseMultiplayerService._internal();

  // Active Firebase Project ID and Custom Database URL
  String _projectId = 'pickl-6d440';
  String? _customDatabaseUrl = 'https://pickl-6d440-default-rtdb.firebaseio.com';
  String get projectId => _projectId;

  void configureProject(String projectIdOrUrl) {
    final clean = projectIdOrUrl.trim();
    if (clean.isEmpty) return;

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      _customDatabaseUrl = clean.replaceAll(RegExp(r'/+$'), '');
      final match = RegExp(r'https?://([^.-]+)').firstMatch(clean);
      if (match != null) {
        _projectId = match.group(1)!;
      }
    } else {
      _projectId = clean;
      _customDatabaseUrl = 'https://$_projectId-default-rtdb.firebaseio.com';
    }
    notifyListeners();
  }

  String get databaseUrl => _customDatabaseUrl ?? 'https://$_projectId-default-rtdb.firebaseio.com';

  final http.Client _httpClient = http.Client();

  // Active room subscription
  String? _activeRoomCode;
  String? get activeRoomCode => _activeRoomCode;
  Timer? _syncPollTimer;
  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  // Streams for live room state and gameplay packets
  final StreamController<BattleRoomModel> _roomUpdatesController =
      StreamController<BattleRoomModel>.broadcast();
  Stream<BattleRoomModel> get onRoomUpdated => _roomUpdatesController.stream;

  final StreamController<MultiplayerPacket> _packetStreamController =
      StreamController<MultiplayerPacket>.broadcast();
  Stream<MultiplayerPacket> get onPacketReceived => _packetStreamController.stream;

  // In-memory synchronized room cache for rapid updates
  BattleRoomModel? _cachedRoom;
  BattleRoomModel? get cachedRoom => _cachedRoom;

  int _lastPacketTimestamp = 0;
  bool _isBroadcastingPacket = false;
  bool _isPollingRoomState = false;

  // ---------------------------------------------------------------------------
  // Room Creation (1v1 Singles & 2v2 Doubles)
  // ---------------------------------------------------------------------------

  /// Creates a live battle room on Firebase for either 1v1 Singles (2 players)
  /// or 2v2 Doubles (4 players).
  Future<bool> createRoom(BattleRoomModel room) async {
    _activeRoomCode = room.roomCode;
    _cachedRoom = room;
    _isConnecting = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$databaseUrl/rooms/${room.roomCode}.json');
      final body = jsonEncode({
        'roomId': room.roomId,
        'roomCode': room.roomCode,
        'roomName': room.roomName,
        'hostId': room.hostId,
        'hostName': room.hostName,
        'hostAvatar': room.hostAvatar,
        'gameMode': room.gameMode,
        'courtId': room.courtId,
        'targetScore': room.targetScore,
        'scoringRule': room.scoringRule,
        'maxPlayers': room.maxPlayers,
        'status': 'waiting',
        'isDoubles': room.isDoubles,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'slots': room.slots.map((s) => s.toJson()).toList(),
      });

      final response = await _httpClient.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 4));

      final success = response.statusCode >= 200 && response.statusCode < 300;
      if (success) {
        _startListeningToRoom(room.roomCode);
        return true;
      }
    } catch (e) {
      debugPrint('Firebase createRoom fallback notice: $e');
    } finally {
      _isConnecting = false;
      notifyListeners();
    }

    // Local loopback fallback if Firebase project isn't provisioned yet
    _startListeningToRoom(room.roomCode);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Room Joining (1v1 & 2v2)
  // ---------------------------------------------------------------------------

  /// Joins an existing Firebase battle room by 6-character room code.
  Future<BattleRoomModel?> joinRoom({
    required String roomCode,
    required PlayerProfileModel myProfile,
    required String characterId,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final candidateCodes = <String>[
      cleanCode,
      if (!cleanCode.startsWith('PB-')) 'PB-$cleanCode',
      if (cleanCode.startsWith('PB-')) cleanCode.substring(3),
    ];

    for (final candidate in candidateCodes) {
      _activeRoomCode = candidate;
      try {
        final uri = Uri.parse('$databaseUrl/rooms/$candidate.json');
        final response = await _httpClient.get(uri).timeout(const Duration(seconds: 4));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final body = response.body;
          if (body != 'null' && body.isNotEmpty) {
            final data = jsonDecode(body) as Map<String, dynamic>;
            final parsedRoom = _parseFirebaseRoom(data);

            // Find first empty slot
            final slots = List<RoomPlayerSlot>.from(parsedRoom.slots);
            int emptySlotIndex = -1;

            // For doubles: slot 1 is Team B, slot 2 is Team A, slot 3 is Team B
            for (int i = 0; i < slots.length; i++) {
              if (slots[i].isEmpty) {
                emptySlotIndex = i;
                break;
              }
            }

            if (emptySlotIndex != -1) {
              final targetSlot = slots[emptySlotIndex];
              slots[emptySlotIndex] = targetSlot.copyWith(
                playerId: myProfile.playerId,
                playerName: myProfile.nickname,
                playerAvatar: myProfile.avatarId,
                rankTier: myProfile.rankTier,
                characterId: characterId,
                isReady: false,
                isHost: false,
                pingMs: 25,
              );

              final updatedRoom = parsedRoom.copyWith(slots: slots);
              _cachedRoom = updatedRoom;

              // Write updated slots to Firebase
              await _updateRemoteRoomSlots(candidate, slots);
              _startListeningToRoom(candidate);
              return updatedRoom;
            }
          }
        }
      } catch (e) {
        debugPrint('Firebase joinRoom fetch notice: $e');
      }
    }

    return _cachedRoom;
  }

  Future<void> _updateRemoteRoomSlots(String roomCode, List<RoomPlayerSlot> slots) async {
    try {
      final uri = Uri.parse('$databaseUrl/rooms/$roomCode/slots.json');
      await _httpClient.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(slots.map((s) => s.toJson()).toList()),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Slot & Team Updates (Team A vs Team B for 1v1 and 2v2)
  // ---------------------------------------------------------------------------

  Future<void> toggleSlotReady(String roomCode, int slotIndex) async {
    if (_cachedRoom == null) return;
    final slots = List<RoomPlayerSlot>.from(_cachedRoom!.slots);
    if (slotIndex < 0 || slotIndex >= slots.length) return;

    final slot = slots[slotIndex];
    if (slot.isEmpty || slot.isHost) return;

    slots[slotIndex] = slot.copyWith(isReady: !slot.isReady);
    _cachedRoom = _cachedRoom!.copyWith(slots: slots);
    _roomUpdatesController.add(_cachedRoom!);
    notifyListeners();

    await _updateRemoteRoomSlots(roomCode, slots);
  }

  Future<void> switchSlotTeam(String roomCode, int slotIndex) async {
    if (_cachedRoom == null) return;
    final slots = List<RoomPlayerSlot>.from(_cachedRoom!.slots);
    if (slotIndex < 0 || slotIndex >= slots.length) return;

    final slot = slots[slotIndex];
    if (slot.isEmpty) return;

    final newTeam = slot.team == 'A' ? 'B' : 'A';
    slots[slotIndex] = slot.copyWith(team: newTeam);
    _cachedRoom = _cachedRoom!.copyWith(slots: slots);
    _roomUpdatesController.add(_cachedRoom!);
    notifyListeners();

    await _updateRemoteRoomSlots(roomCode, slots);
  }

  Future<void> updateSlotCharacter(String roomCode, String playerId, String characterId) async {
    if (_cachedRoom == null) return;
    final slots = List<RoomPlayerSlot>.from(_cachedRoom!.slots);
    final idx = slots.indexWhere((s) => s.playerId == playerId);
    if (idx != -1) {
      slots[idx] = slots[idx].copyWith(
        characterId: characterId,
        playerAvatar: characterId,
      );
      _cachedRoom = _cachedRoom!.copyWith(slots: slots);
      _roomUpdatesController.add(_cachedRoom!);
      notifyListeners();
      await _updateRemoteRoomSlots(roomCode, slots);
    }
  }

  // ---------------------------------------------------------------------------
  // Match Launch & State Sync
  // ---------------------------------------------------------------------------

  Future<bool> launchMatch(String roomCode) async {
    if (_cachedRoom == null) return false;
    _cachedRoom = _cachedRoom!.copyWith(status: 'inMatch');
    _roomUpdatesController.add(_cachedRoom!);
    notifyListeners();

    try {
      final uri = Uri.parse('$databaseUrl/rooms/$roomCode/status.json');
      await _httpClient.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode('inMatch'),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}

    // Dispatch local packet
    _packetStreamController.add(
      MultiplayerPacket(
        type: PacketType.matchStart,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        senderId: _cachedRoom!.hostId,
        data: {
          'gameMode': _cachedRoom!.gameMode,
          'courtId': _cachedRoom!.courtId,
          'targetScore': _cachedRoom!.targetScore,
          'isDoubles': _cachedRoom!.isDoubles,
        },
      ),
    );

    return true;
  }

  /// Streams real-time live match packets across Firebase
  Future<void> broadcastLivePacket(String roomCode, MultiplayerPacket packet) async {
    // Deliver locally immediately for zero-lag responsiveness
    _packetStreamController.add(packet);

    if (_isBroadcastingPacket) return;
    _isBroadcastingPacket = true;
    try {
      final uri = Uri.parse('$databaseUrl/rooms/$roomCode/liveState.json');
      await _httpClient.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(packet.toJson()),
      ).timeout(const Duration(milliseconds: 600));
    } catch (_) {
    } finally {
      _isBroadcastingPacket = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Live Room Listening (High-frequency Polling with Concurrency Guard)
  // ---------------------------------------------------------------------------

  void _startListeningToRoom(String roomCode) {
    _stopListeningToRoom();

    // High frequency poll timer for instant synchronization
    _syncPollTimer = Timer.periodic(const Duration(milliseconds: 250), (_) async {
      await _pollRoomState(roomCode);
    });
  }

  Future<void> _pollRoomState(String roomCode) async {
    if (_isPollingRoomState) return;
    _isPollingRoomState = true;
    try {
      final uri = Uri.parse('$databaseUrl/rooms/$roomCode.json');
      final response = await _httpClient.get(uri).timeout(const Duration(milliseconds: 800));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body;
        if (body == 'null' || body.isEmpty) {
          if (_cachedRoom != null) {
            _packetStreamController.add(
              MultiplayerPacket(
                type: PacketType.leaveRoom,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                senderId: _cachedRoom?.hostId ?? 'host',
                data: {'isHost': true, 'reason': 'Host has disconnected. The match has ended.'},
              ),
            );
            _cachedRoom = null;
            notifyListeners();
          }
          return;
        }

        final data = jsonDecode(body) as Map<String, dynamic>;
        if (data['status'] == 'closed') {
          if (_cachedRoom != null) {
            _packetStreamController.add(
              MultiplayerPacket(
                type: PacketType.leaveRoom,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                senderId: _cachedRoom?.hostId ?? 'host',
                data: {'isHost': true, 'reason': 'Host has disconnected. The match has ended.'},
              ),
            );
            _cachedRoom = null;
            notifyListeners();
          }
          return;
        }

        final parsed = _parseFirebaseRoom(data);

          // Check for status change to inMatch
          if (parsed.status == 'inMatch' && _cachedRoom?.status != 'inMatch') {
            _packetStreamController.add(
              MultiplayerPacket(
                type: PacketType.matchStart,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                senderId: parsed.hostId,
                data: {
                  'gameMode': parsed.gameMode,
                  'courtId': parsed.courtId,
                  'targetScore': parsed.targetScore,
                  'isDoubles': parsed.isDoubles,
                },
              ),
            );
          }

          // Check for live packet updates
          if (data.containsKey('liveState') && data['liveState'] != null) {
            final packetMap = data['liveState'] as Map<String, dynamic>;
            final ts = packetMap['timestamp'] as int? ?? 0;
            if (ts > _lastPacketTimestamp) {
              _lastPacketTimestamp = ts;
              final pkt = MultiplayerPacket.fromJson(packetMap);
              _packetStreamController.add(pkt);
            }
          }

          _cachedRoom = parsed;
          _roomUpdatesController.add(parsed);
          notifyListeners();
        }
      } catch (_) {
      } finally {
        _isPollingRoomState = false;
      }
    }

  void _stopListeningToRoom() {
    _syncPollTimer?.cancel();
    _syncPollTimer = null;
  }

  Future<void> leaveRoom(String roomCode, String myPlayerId, bool isHost) async {
    _stopListeningToRoom();

    if (_cachedRoom != null) {
      if (isHost) {
        try {
          final uri = Uri.parse('$databaseUrl/rooms/$roomCode.json');
          await _httpClient.delete(uri).timeout(const Duration(seconds: 2));
        } catch (_) {}
      } else {
        final slots = List<RoomPlayerSlot>.from(_cachedRoom!.slots);
        final idx = slots.indexWhere((s) => s.playerId == myPlayerId);
        if (idx != -1) {
          slots[idx] = slots[idx].copyWith(clearPlayer: true);
          await _updateRemoteRoomSlots(roomCode, slots);
        }
      }
    }

    _cachedRoom = null;
    _activeRoomCode = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // JSON Parser Helper
  // ---------------------------------------------------------------------------

  BattleRoomModel _parseFirebaseRoom(Map<String, dynamic> json) {
    final gameMode = json['gameMode'] as String? ?? '1v1 Singles';
    final isDoubles = gameMode.contains('2v2') || gameMode.contains('Doubles');
    final maxPlayers = json['maxPlayers'] as int? ?? (isDoubles ? 4 : 2);

    List<RoomPlayerSlot> slots = [];
    if (json['slots'] != null) {
      final rawSlots = json['slots'] as List<dynamic>;
      slots = rawSlots.map((s) => RoomPlayerSlot.fromJson(Map<String, dynamic>.from(s as Map))).toList();
    }

    return BattleRoomModel(
      roomId: json['roomId'] as String? ?? 'room_live',
      roomCode: json['roomCode'] as String? ?? 'PB-0000',
      roomName: json['roomName'] as String? ?? 'Court Battle',
      hostId: json['hostId'] as String? ?? '',
      hostName: json['hostName'] as String? ?? 'Host',
      hostAvatar: json['hostAvatar'] as String? ?? 'alex_classic',
      gameMode: gameMode,
      courtId: json['courtId'] as String? ?? 'court_pro_stadium',
      targetScore: json['targetScore'] as int? ?? 11,
      scoringRule: json['scoringRule'] as String? ?? 'Official Side-Out',
      maxPlayers: maxPlayers,
      slots: slots,
      status: json['status'] as String? ?? 'waiting',
      hostAddress: databaseUrl,
      connectionMode: MultiplayerConnectionMode.onlineCloud,
    );
  }
}
