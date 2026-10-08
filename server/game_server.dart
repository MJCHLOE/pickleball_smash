// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Production Real-Time WebSocket Server for Pickleball Smash.
/// Deployable to any cloud hosting provider (Render, Railway, Fly.io, Heroku, VPS).
///
/// Run locally or on server:
///   dart run server/game_server.dart
void main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8088') ?? 8088;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('====================================================');
  print('🏓 PICKLEBALL SMASH PRODUCTION LIVE BATTLE SERVER');
  print('   Listening on: ws://0.0.0.0:$port');
  print('   Ready for Google Play Store worldwide matchmaking');
  print('====================================================');

  final manager = GameRoomManager();

  server.listen((HttpRequest request) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocketTransformer.upgrade(request).then((socket) {
        manager.handleClient(socket, request.uri);
      }).catchError((e) {
        print('[ERROR] WebSocket upgrade failure: $e');
      });
    } else {
      // Basic HTTP health check endpoint for cloud load balancers (e.g. Render / AWS)
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'status': 'online',
          'game': 'Pickleball Smash',
          'activeRooms': manager.activeRoomCount,
          'connectedClients': manager.activeClientCount,
          'timestamp': DateTime.now().toIso8601String(),
        }))
        ..close();
    }
  });
}

class GameRoom {
  final String roomCode;
  WebSocket? hostSocket;
  final List<WebSocket> clientSockets = [];
  Map<String, dynamic>? cachedRoomState;
  final DateTime createdAt = DateTime.now();

  GameRoom(this.roomCode);

  bool get isEmpty => hostSocket == null && clientSockets.isEmpty;
}

class GameRoomManager {
  final Map<String, GameRoom> _rooms = {};
  final Map<WebSocket, String> _socketToRoom = {};

  int get activeRoomCount => _rooms.length;
  int get activeClientCount => _socketToRoom.length;

  void handleClient(WebSocket socket, Uri uri) {
    final queryRoom = uri.queryParameters['room'];
    final isHostQuery = uri.queryParameters['host'] == 'true';

    socket.listen(
      (data) {
        try {
          final jsonMap = jsonDecode(data as String) as Map<String, dynamic>;
          final type = jsonMap['type'] as String? ?? '';
          final senderId = jsonMap['senderId'] as String? ?? '';
          final packetData = Map<String, dynamic>.from(jsonMap['data'] as Map? ?? {});

          if (type == 'ping') {
            socket.add(jsonEncode({
              'type': 'pong',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'senderId': 'server',
              'data': {'echo': jsonMap['timestamp']},
            }));
            return;
          }

          if (type == 'joinRoom') {
            final code = packetData['roomCode'] as String? ?? queryRoom ?? 'GLOBAL';
            _joinRoom(socket, code, senderId, packetData, isHost: isHostQuery);
            return;
          }

          final roomCode = _socketToRoom[socket];
          if (roomCode != null && _rooms.containsKey(roomCode)) {
            final room = _rooms[roomCode]!;

            if (type == 'roomSync') {
              room.cachedRoomState = packetData;
            }

            // Relay raw string packet directly to save CPU (No re-encoding needed)
            final raw = data as String;
            if (room.hostSocket != null && room.hostSocket != socket) {
              if (room.hostSocket!.readyState == WebSocket.open) {
                room.hostSocket!.add(raw);
              }
            }
            for (final client in room.clientSockets) {
              if (client != socket && client.readyState == WebSocket.open) {
                client.add(raw);
              }
            }
          }
        } catch (e) {
          print('[ERROR] Client packet parsing: $e');
        }
      },
      onDone: () => _removeSocket(socket),
      onError: (_) => _removeSocket(socket),
    );
  }

  void _joinRoom(WebSocket socket, String roomCode, String senderId, Map<String, dynamic> data, {bool isHost = false}) {
    final room = _rooms.putIfAbsent(roomCode, () => GameRoom(roomCode));
    _socketToRoom[socket] = roomCode;

    if (isHost || room.hostSocket == null) {
      room.hostSocket = socket;
      print('[ROOM $roomCode] Host registered ($senderId). Active rooms: ${_rooms.length}');
    } else {
      if (!room.clientSockets.contains(socket)) {
        room.clientSockets.add(socket);
        print('[ROOM $roomCode] Guest joined ($senderId). Total in room: ${room.clientSockets.length + 1}');
      }
    }

    // Forward join packet to the host
    if (room.hostSocket != null && room.hostSocket != socket) {
      room.hostSocket!.add(jsonEncode({
        'type': 'joinRoom',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'senderId': senderId,
        'data': data,
      }));
    } else if (room.cachedRoomState != null) {
      // Send latest state back to newly joined socket
      socket.add(jsonEncode({
        'type': 'roomSync',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'senderId': 'server',
        'data': room.cachedRoomState!,
      }));
    }
  }

  void _removeSocket(WebSocket socket) {
    final roomCode = _socketToRoom.remove(socket);
    if (roomCode != null && _rooms.containsKey(roomCode)) {
      final room = _rooms[roomCode]!;
      if (room.hostSocket == socket) {
        room.hostSocket = null;
        print('[ROOM $roomCode] Host disconnected');
      } else {
        room.clientSockets.remove(socket);
        print('[ROOM $roomCode] Client disconnected');
      }

      if (room.isEmpty) {
        _rooms.remove(roomCode);
        print('[ROOM $roomCode] Closed (empty). Active rooms: ${_rooms.length}');
      }
    }
  }
}
