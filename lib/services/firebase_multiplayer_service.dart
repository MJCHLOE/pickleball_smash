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
  http.Client? _streamClient;
  StreamSubscription? _sseSubscription;
  Timer? _sseReconnectTimer;

  // Active room subscription
  String? _activeRoomCode;
  String? get activeRoomCode => _activeRoomCode;
  String? _myPlayerId;
  String? get myPlayerId => _myPlayerId;
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

  final Map<String, int> _lastTimestampBySender = {};
  int _lastSseEventTime = 0;
  int _lastHostPacketTimestamp = 0;

  // Ultra-responsive latest-state coalescing movement dispatch per player
  final Map<String, MultiplayerPacket> _latestPendingMovements = {};
  final Map<String, bool> _isMovementInFlight = {};
  bool _isPollingRoomState = false;

  // ---------------------------------------------------------------------------
  // Room Creation (1v1 Singles & 2v2 Doubles)
  // ---------------------------------------------------------------------------

  /// Creates a live battle room on Firebase for either 1v1 Singles (2 players)
  /// or 2v2 Doubles (4 players).
  Future<bool> createRoom(BattleRoomModel room) async {
    _activeRoomCode = room.roomCode;
    _myPlayerId = room.hostId;
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
    _myPlayerId = myProfile.playerId;
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

  Future<void> updateRoomSlots(String roomCode, List<RoomPlayerSlot> slots) async {
    _cachedRoom = _cachedRoom?.copyWith(slots: slots);
    notifyListeners();
    await _updateRemoteRoomSlots(roomCode, slots);
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

  Future<void> updateSlotLoadout(
    String roomCode,
    String playerId, {
    required String characterId,
    required String ballId,
    required String courtId,
  }) async {
    if (_cachedRoom == null) return;
    final slots = List<RoomPlayerSlot>.from(_cachedRoom!.slots);
    final idx = slots.indexWhere((s) => s.playerId == playerId);
    if (idx != -1) {
      final isHost = slots[idx].isHost;
      slots[idx] = slots[idx].copyWith(
        characterId: characterId,
        playerAvatar: characterId,
        ballId: ballId,
        courtId: courtId,
        hasSelectedLoadout: true,
      );
      _cachedRoom = _cachedRoom!.copyWith(
        slots: slots,
        courtId: isHost ? courtId : _cachedRoom!.courtId,
      );
      _roomUpdatesController.add(_cachedRoom!);
      notifyListeners();
      await _updateRemoteRoomSlots(roomCode, slots);
      if (isHost) {
        try {
          final uri = Uri.parse('$databaseUrl/rooms/$roomCode/courtId.json');
          await _httpClient.put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(courtId),
          ).timeout(const Duration(seconds: 3));
        } catch (_) {}
      }
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

  // ---------------------------------------------------------------------------
  // Ultra-Responsive Decoupled Network Dispatch
  // ---------------------------------------------------------------------------

  void broadcastLivePacket(String roomCode, MultiplayerPacket packet) {
    if (packet.type == PacketType.playerState) {
      // High-frequency coalesced movement dispatch (up to 20-30 Hz without queue backlogs)
      final senderKey = (_cachedRoom?.hostId == _myPlayerId) ? 'p1' : 'p2';
      _latestPendingMovements[senderKey] = packet;
      _triggerMovementDispatch(roomCode, senderKey);
    } else {
      // Immediate parallel dispatch for critical events (ball strikes, techniques, scores, chats)
      _dispatchPriorityPacket(roomCode, packet);
    }
  }

  void _triggerMovementDispatch(String roomCode, String senderKey) async {
    if (_isMovementInFlight[senderKey] == true) return;
    _isMovementInFlight[senderKey] = true;

    try {
      while (_latestPendingMovements[senderKey] != null && _activeRoomCode == roomCode) {
        final packetToSend = _latestPendingMovements.remove(senderKey);
        if (packetToSend == null) break;

        final uri = Uri.parse('$databaseUrl/rooms/$roomCode/players/$senderKey.json');
        await _httpClient.put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(packetToSend.toJson()),
        ).timeout(const Duration(milliseconds: 1500));
      }
    } catch (_) {
    } finally {
      _isMovementInFlight[senderKey] = false;
    }
  }

  void _dispatchPriorityPacket(String roomCode, MultiplayerPacket packet) async {
    try {
      final jsonStr = jsonEncode(packet.toJson());
      final String endpoint;
      if (packet.type == PacketType.ballStrike) {
        endpoint = 'ball';
        // Also write to dedicated ballStrike endpoint to guarantee no ballSync overwrites it
        final strikeUri = Uri.parse('$databaseUrl/rooms/$roomCode/ballStrike.json');
        _httpClient.put(strikeUri, headers: {'Content-Type': 'application/json'}, body: jsonStr).timeout(const Duration(seconds: 3));
      } else if (packet.type == PacketType.ballSync) {
        endpoint = 'ball';
      } else if (packet.type == PacketType.scoreSync) {
        endpoint = 'score';
      } else if (packet.type == PacketType.chatMessage) {
        endpoint = 'chat';
      } else if (packet.type == PacketType.ping) {
        final senderKey = (_cachedRoom?.hostId == _myPlayerId) ? 'p1' : 'p2';
        endpoint = 'heartbeat/$senderKey';
      } else {
        endpoint = 'action';
      }

      final uri = Uri.parse('$databaseUrl/rooms/$roomCode/$endpoint.json');
      await _httpClient.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonStr,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Real-Time Server-Sent Events (SSE) Streaming & Resilient Fallback Polling
  // ---------------------------------------------------------------------------

  void _startListeningToRoom(String roomCode) {
    _stopListeningToRoom();

    // 1. Establish persistent real-time SSE stream connection
    _connectSseStream(roomCode);

    // 2. Resilient fallback health check / timeout monitor (3.0s interval)
    _syncPollTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check host connection timeout if guest in active match
      if (_cachedRoom != null && _cachedRoom!.hostId != _myPlayerId && _cachedRoom!.status == 'inMatch') {
        // If quiet for > 12s, proactively poll to verify match status
        if (_lastHostPacketTimestamp > 0 && (now - _lastHostPacketTimestamp) > 12000) {
          await _pollRoomState(roomCode);
        }

        // Only declare host disconnect if silence exceeds 28s and room is confirmed closed/gone
        if (_lastHostPacketTimestamp > 0 && (now - _lastHostPacketTimestamp) > 28000) {
          final isStillValid = await _verifyRoomStillActive(roomCode);
          if (!isStillValid) {
            _packetStreamController.add(
              MultiplayerPacket(
                type: PacketType.leaveRoom,
                timestamp: now,
                senderId: _cachedRoom?.hostId ?? 'host',
                data: {'isHost': true, 'reason': 'Host has disconnected. The match has ended.'},
              ),
            );
            _cachedRoom = null;
            notifyListeners();
            return;
          } else {
            // Room is still active on Firebase! Reconnect SSE stream and continue battle
            _lastHostPacketTimestamp = DateTime.now().millisecondsSinceEpoch;
            _connectSseStream(roomCode);
          }
        }
      }

      // If SSE stream has been quiet for > 5.0 seconds, poll as safety net
      if (now - _lastSseEventTime > 5000) {
        await _pollRoomState(roomCode);
      }
    });
  }

  Future<bool> _verifyRoomStillActive(String roomCode) async {
    try {
      final uri = Uri.parse('$databaseUrl/rooms/$roomCode/status.json');
      final res = await _httpClient.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = res.body.trim();
        if (body == 'null' || body.isEmpty || body == '"closed"') {
          return false;
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _connectSseStream(String roomCode) {
    _sseSubscription?.cancel();
    _streamClient?.close();
    _streamClient = http.Client();

    try {
      final uri = Uri.parse('$databaseUrl/rooms/$roomCode.json');
      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Cache-Control'] = 'no-cache';

      _streamClient!.send(request).then((streamedResponse) {
        if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
          String sseBuffer = '';
          _sseSubscription = streamedResponse.stream
              .transform(utf8.decoder)
              .listen(
            (chunk) {
              _lastSseEventTime = DateTime.now().millisecondsSinceEpoch;
              sseBuffer += chunk;
              while (sseBuffer.contains('\n\n')) {
                final splitIndex = sseBuffer.indexOf('\n\n');
                final rawEvent = sseBuffer.substring(0, splitIndex);
                sseBuffer = sseBuffer.substring(splitIndex + 2);
                _handleSseEvent(rawEvent, roomCode);
              }
            },
            onError: (err) {
              _scheduleSseReconnect(roomCode);
            },
            onDone: () {
              _scheduleSseReconnect(roomCode);
            },
            cancelOnError: true,
          );
        } else {
          _scheduleSseReconnect(roomCode);
        }
      }).catchError((_) {
        _scheduleSseReconnect(roomCode);
      });
    } catch (_) {
      _scheduleSseReconnect(roomCode);
    }
  }

  void _scheduleSseReconnect(String roomCode) {
    if (_activeRoomCode != roomCode) return;
    _sseReconnectTimer?.cancel();
    _sseReconnectTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_activeRoomCode == roomCode) {
        _connectSseStream(roomCode);
      }
    });
  }

  void _handleSseEvent(String rawEvent, String roomCode) {
    String eventType = 'put';
    String dataStr = '';

    for (final line in rawEvent.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('event:')) {
        eventType = trimmed.substring(6).trim();
      } else if (trimmed.startsWith('data:')) {
        dataStr = trimmed.substring(5).trim();
      }
    }

    if (eventType == 'keep-alive') {
      _lastSseEventTime = DateTime.now().millisecondsSinceEpoch;
      _lastHostPacketTimestamp = _lastSseEventTime;
      return;
    }

    if ((eventType == 'put' || eventType == 'patch') && dataStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(dataStr);
        if (decoded is Map<String, dynamic>) {
          final path = decoded['path'] as String? ?? '/';
          final data = decoded['data'];

          // Room deleted by host
          if (data == null && (path == '/' || path.isEmpty)) {
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

          if (path.endsWith('status') || (data is Map && data.containsKey('status'))) {
            final status = path.endsWith('status') ? data as String : data['status'] as String;
            if (status == 'closed') {
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
            } else if (status == 'inMatch' && _cachedRoom?.status != 'inMatch') {
              if (_cachedRoom != null) {
                _cachedRoom = _cachedRoom!.copyWith(status: 'inMatch');
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
                _roomUpdatesController.add(_cachedRoom!);
                notifyListeners();
              }
            }
          }

          if (path == '/' && data is Map<String, dynamic>) {
            final parsed = _parseFirebaseRoom(data);
            _cachedRoom = parsed;
            _roomUpdatesController.add(parsed);
            notifyListeners();
          } else if (path.endsWith('slots') && data is List) {
            if (_cachedRoom != null) {
              final newSlots = data
                  .map((s) => RoomPlayerSlot.fromJson(Map<String, dynamic>.from(s as Map)))
                  .toList();
              _cachedRoom = _cachedRoom!.copyWith(slots: newSlots);
              _roomUpdatesController.add(_cachedRoom!);
              notifyListeners();
            }
          }

          // Deliver all game packets across multi-channels
          _processIncomingFirebasePayload(path, data);
        }
      } catch (_) {}
    }
  }

  void _processIncomingFirebasePayload(String path, dynamic data) {
    if (data == null) return;
    if (data is! Map<String, dynamic>) return;

    // 1. Direct packet structure
    if (data.containsKey('type') && data.containsKey('senderId')) {
      _deliverIncomingPacket(data);
      return;
    }

    // 2. Sub-channel extraction across all game events
    if (data['players'] is Map<String, dynamic>) {
      final players = data['players'] as Map<String, dynamic>;
      if (players['p1'] is Map<String, dynamic>) _processIncomingFirebasePayload('$path/players/p1', players['p1']);
      if (players['p2'] is Map<String, dynamic>) _processIncomingFirebasePayload('$path/players/p2', players['p2']);
    }
    if (data['p1'] is Map<String, dynamic>) _processIncomingFirebasePayload('$path/p1', data['p1']);
    if (data['p2'] is Map<String, dynamic>) _processIncomingFirebasePayload('$path/p2', data['p2']);
    if (data['ball'] is Map<String, dynamic>) _processIncomingFirebasePayload('$path/ball', data['ball']);
    if (data['ballStrike'] is Map<String, dynamic>) _processIncomingFirebasePayload('$path/ballStrike', data['ballStrike']);
    if (data['action'] is Map<String, dynamic>) _processIncomingFirebasePayload('$path/action', data['action']);
    if (data['score'] is Map<String, dynamic>) _processIncomingFirebasePayload('$path/score', data['score']);
    if (data['chat'] is Map<String, dynamic>) _processIncomingFirebasePayload('$path/chat', data['chat']);
    if (data['liveState'] is Map<String, dynamic>) _processIncomingFirebasePayload('$path/liveState', data['liveState']);
  }

  void _deliverIncomingPacket(Map<String, dynamic> packetMap) {
    try {
      final sender = packetMap['senderId'] as String? ?? '';
      // Filter out self-sent packets so local responsiveness is never interrupted
      if (sender == _myPlayerId && _myPlayerId != null && _myPlayerId!.isNotEmpty) return;

      final ts = packetMap['timestamp'] as int? ?? 0;
      final typeStr = packetMap['type'] as String? ?? '';
      final isCritical = typeStr == 'ballStrike' ||
          typeStr == 'ballSync' ||
          typeStr == 'scoreSync' ||
          typeStr == 'leaveRoom' ||
          typeStr == 'matchStart' ||
          typeStr == 'techniqueTrigger' ||
          typeStr == 'chatMessage' ||
          typeStr == 'ping';

      final lastTs = _lastTimestampBySender[sender] ?? 0;
      if (isCritical || ts >= lastTs) {
        _lastTimestampBySender[sender] = ts;
        _lastHostPacketTimestamp = DateTime.now().millisecondsSinceEpoch;
        _lastSseEventTime = _lastHostPacketTimestamp;
        final pkt = MultiplayerPacket.fromJson(packetMap);
        _packetStreamController.add(pkt);
      }
    } catch (_) {}
  }

  Future<void> _pollRoomState(String roomCode) async {
    if (_isPollingRoomState) return;
    _isPollingRoomState = true;
    try {
      final uri = Uri.parse('$databaseUrl/rooms/$roomCode.json');
      final response = await _httpClient.get(uri).timeout(const Duration(seconds: 4));

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

        // Check for live packet updates across all multi-channels
        _processIncomingFirebasePayload('/', data);

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
    _sseReconnectTimer?.cancel();
    _sseReconnectTimer = null;
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _streamClient?.close();
    _streamClient = null;
  }

  Future<void> leaveRoom(String roomCode, String myPlayerId, bool isHost) async {
    _stopListeningToRoom();

    if (_cachedRoom != null) {
      if (isHost) {
        try {
          final statusUri = Uri.parse('$databaseUrl/rooms/$roomCode/status.json');
          await _httpClient.put(
            statusUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode('closed'),
          ).timeout(const Duration(seconds: 1));

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
    _latestPendingMovements.clear();
    _isMovementInFlight.clear();
    _lastTimestampBySender.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Public Cloud Rooms Discovery
  // ---------------------------------------------------------------------------

  /// Fetches all active waiting cloud rooms on Firebase RTDB
  Future<List<BattleRoomModel>> fetchPublicCloudRooms() async {
    final list = <BattleRoomModel>[];
    try {
      final uri = Uri.parse('$databaseUrl/rooms.json');
      final response = await _httpClient.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body;
        if (body != 'null' && body.isNotEmpty) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          for (final entry in data.entries) {
            if (entry.value is Map) {
              final roomMap = Map<String, dynamic>.from(entry.value as Map);
              final status = roomMap['status'] as String? ?? 'waiting';
              if (status == 'waiting') {
                final room = _parseFirebaseRoom(roomMap);
                list.add(room);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('fetchPublicCloudRooms notice: $e');
    }
    return list;
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
