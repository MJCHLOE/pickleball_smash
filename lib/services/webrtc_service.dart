import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import '../models/multiplayer_models.dart';
import 'firebase_multiplayer_service.dart';

/// WebRTC Peer-to-Peer Service for low-latency online multiplayer gameplay.
/// Uses Firebase Realtime Database as the signaling server to exchange
/// SDP Offers, Answers, and ICE candidates, then transmits all in-game
/// physics and player updates directly between devices via RTCDataChannel.
class WebRTCService extends ChangeNotifier {
  static final WebRTCService instance = WebRTCService._internal();
  factory WebRTCService() => instance;
  WebRTCService._internal();

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  final http.Client _httpClient = http.Client();

  String? _activeRoomCode;
  bool _isHost = false;
  Timer? _signalingPollTimer;
  final Set<String> _processedCandidateIds = {};

  // Connection State Notifier
  bool _isConnected = false;
  bool get isConnected => _isConnected && _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;

  // Stream controller for live packets arriving over WebRTC
  final StreamController<MultiplayerPacket> _packetController =
      StreamController<MultiplayerPacket>.broadcast();
  Stream<MultiplayerPacket> get onPacketReceived => _packetController.stream;

  // Google Public STUN Configuration
  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  String get _databaseUrl => FirebaseMultiplayerService.instance.databaseUrl;

  // ---------------------------------------------------------------------------
  // Host Initialization: Create Offer & Wait for Answer
  // ---------------------------------------------------------------------------

  Future<void> startAsHost(String roomCode) async {
    await close();
    _activeRoomCode = roomCode;
    _isHost = true;
    _processedCandidateIds.clear();

    try {
      // 1. Create Peer Connection
      _peerConnection = await createPeerConnection(_iceServers);

      // 2. Create high-performance Data Channel (unreliable/ordered: false for minimal lag)
      final dcInit = RTCDataChannelInit()
        ..ordered = false
        ..maxRetransmits = 0;
      _dataChannel = await _peerConnection!.createDataChannel('pickleball_p2p', dcInit);
      _setupDataChannelListeners(_dataChannel!);

      // 3. Listen for ICE candidates generated locally and upload to Firebase
      _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate != null) {
          _uploadCandidate(roomCode, isHostCandidate: true, candidate: candidate);
        }
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('WebRTC Host connection state: $state');
      };

      // 4. Create and upload SDP Offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      await _uploadOffer(roomCode, offer);

      // 5. Poll signaling node for Guest Answer and Guest Candidates
      _startSignalingPolling(roomCode, isHost: true);
    } catch (e) {
      debugPrint('WebRTC startAsHost error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Guest Initialization: Accept Offer & Send Answer
  // ---------------------------------------------------------------------------

  Future<void> startAsGuest(String roomCode) async {
    await close();
    _activeRoomCode = roomCode;
    _isHost = false;
    _processedCandidateIds.clear();

    try {
      _peerConnection = await createPeerConnection(_iceServers);

      _peerConnection!.onDataChannel = (RTCDataChannel channel) {
        _dataChannel = channel;
        _setupDataChannelListeners(channel);
      };

      _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate != null) {
          _uploadCandidate(roomCode, isHostCandidate: false, candidate: candidate);
        }
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('WebRTC Guest connection state: $state');
      };

      // 1. Wait for Host Offer from Firebase
      final offer = await _waitForHostOffer(roomCode);
      if (offer == null) {
        debugPrint('WebRTC Guest: Timeout waiting for Host Offer.');
        return;
      }

      await _peerConnection!.setRemoteDescription(offer);

      // 2. Create and upload SDP Answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      await _uploadAnswer(roomCode, answer);

      // 3. Poll signaling node for Host Candidates
      _startSignalingPolling(roomCode, isHost: false);
    } catch (e) {
      debugPrint('WebRTC startAsGuest error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Data Channel Lifecycle & Packet Transmission
  // ---------------------------------------------------------------------------

  void _setupDataChannelListeners(RTCDataChannel channel) {
    channel.onDataChannelState = (RTCDataChannelState state) {
      debugPrint('WebRTC DataChannel State Changed: $state');
      _isConnected = (state == RTCDataChannelState.RTCDataChannelOpen);
      notifyListeners();
    };

    channel.onMessage = (RTCDataChannelMessage message) {
      if (message.isBinary) return;
      try {
        final decoded = jsonDecode(message.text) as Map<String, dynamic>;
        final packet = MultiplayerPacket.fromJson(decoded);
        _packetController.add(packet);
      } catch (e) {
        debugPrint('WebRTC packet decode error: $e');
      }
    };
  }

  /// Sends a live gameplay packet directly through the P2P DataChannel
  bool sendPacket(MultiplayerPacket packet) {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      try {
        final jsonStr = jsonEncode(packet.toJson());
        _dataChannel!.send(RTCDataChannelMessage(jsonStr));
        return true;
      } catch (e) {
        debugPrint('WebRTC sendPacket error: $e');
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Firebase Signaling Helpers (REST)
  // ---------------------------------------------------------------------------

  Future<void> _uploadOffer(String roomCode, RTCSessionDescription offer) async {
    try {
      final uri = Uri.parse('$_databaseUrl/rooms/$roomCode/webrtc/offer.json');
      await _httpClient.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sdp': offer.sdp,
          'type': offer.type,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (e) {
      debugPrint('WebRTC _uploadOffer error: $e');
    }
  }

  Future<void> _uploadAnswer(String roomCode, RTCSessionDescription answer) async {
    try {
      final uri = Uri.parse('$_databaseUrl/rooms/$roomCode/webrtc/answer.json');
      await _httpClient.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sdp': answer.sdp,
          'type': answer.type,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } catch (e) {
      debugPrint('WebRTC _uploadAnswer error: $e');
    }
  }

  Future<void> _uploadCandidate(
    String roomCode, {
    required bool isHostCandidate,
    required RTCIceCandidate candidate,
  }) async {
    try {
      final target = isHostCandidate ? 'hostCandidates' : 'guestCandidates';
      final uri = Uri.parse('$_databaseUrl/rooms/$roomCode/webrtc/$target.json');
      await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }),
      );
    } catch (e) {
      debugPrint('WebRTC _uploadCandidate error: $e');
    }
  }

  Future<RTCSessionDescription?> _waitForHostOffer(String roomCode) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < const Duration(seconds: 15)) {
      try {
        final uri = Uri.parse('$_databaseUrl/rooms/$roomCode/webrtc/offer.json');
        final res = await _httpClient.get(uri);
        if (res.statusCode == 200 && res.body != 'null') {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final sdp = data['sdp'] as String?;
          final type = data['type'] as String?;
          if (sdp != null && type != null) {
            return RTCSessionDescription(sdp, type);
          }
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  void _startSignalingPolling(String roomCode, {required bool isHost}) {
    _signalingPollTimer?.cancel();
    _signalingPollTimer = Timer.periodic(const Duration(milliseconds: 800), (_) async {
      if (_isConnected) {
        _signalingPollTimer?.cancel();
        return;
      }

      try {
        // If Host: check for Guest Answer
        if (isHost && _peerConnection != null) {
          final remoteDesc = await _peerConnection!.getRemoteDescription();
          if (remoteDesc == null) {
            final uri = Uri.parse('$_databaseUrl/rooms/$roomCode/webrtc/answer.json');
            final res = await _httpClient.get(uri);
            if (res.statusCode == 200 && res.body != 'null') {
              final data = jsonDecode(res.body) as Map<String, dynamic>;
              final sdp = data['sdp'] as String?;
              final type = data['type'] as String?;
              if (sdp != null && type != null) {
                await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, type));
              }
            }
          }
        }

        // Fetch peer ICE candidates
        final target = isHost ? 'guestCandidates' : 'hostCandidates';
        final uri = Uri.parse('$_databaseUrl/rooms/$roomCode/webrtc/$target.json');
        final res = await _httpClient.get(uri);
        if (res.statusCode == 200 && res.body != 'null') {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          for (final entry in data.entries) {
            if (!_processedCandidateIds.contains(entry.key) && entry.value is Map) {
              _processedCandidateIds.add(entry.key);
              final cData = entry.value as Map<String, dynamic>;
              final c = RTCIceCandidate(
                cData['candidate'] as String?,
                cData['sdpMid'] as String?,
                cData['sdpMLineIndex'] as int?,
              );
              await _peerConnection?.addCandidate(c);
            }
          }
        }
      } catch (e) {
        debugPrint('WebRTC signaling poll error: $e');
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  Future<void> close() async {
    _signalingPollTimer?.cancel();
    _signalingPollTimer = null;
    _isConnected = false;

    try {
      await _dataChannel?.close();
    } catch (_) {}
    _dataChannel = null;

    try {
      await _peerConnection?.close();
      await _peerConnection?.dispose();
    } catch (_) {}
    _peerConnection = null;

    _activeRoomCode = null;
    _processedCandidateIds.clear();
    notifyListeners();
  }
}

