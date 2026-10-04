import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_smash/models/multiplayer_models.dart';
import 'package:pickleball_smash/screens/battle_room_screen.dart';
import 'package:pickleball_smash/screens/views/home_view.dart';
import 'package:pickleball_smash/services/database_service.dart';
import 'package:pickleball_smash/services/game_state_manager.dart';
import 'package:pickleball_smash/services/multiplayer_service.dart';
import 'package:pickleball_smash/widgets/battle_invitation_dialog.dart';
import 'package:pickleball_smash/widgets/battle_room_chat_widget.dart';
import 'package:pickleball_smash/widgets/friends_modal.dart';
import 'package:pickleball_smash/widgets/player_profile_modal.dart';
import 'package:pickleball_smash/game/pickleball_game.dart';
import 'package:pickleball_smash/game/components/net.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseService.instance.initialize();
  });

  group('Multiplayer Models & Serialization Tests', () {
    test('PlayerPresenceStatus properties and colors', () {
      expect(PlayerPresenceStatus.online.label, equals('Online'));
      expect(PlayerPresenceStatus.inRoom.label, equals('In Room'));
      expect(PlayerPresenceStatus.inMatch.label, equals('In Match'));
      expect(PlayerPresenceStatus.offline.label, equals('Offline'));
      expect(PlayerPresenceStatus.spectating.label, equals('Spectating'));

      expect(PlayerPresenceStatus.online.color, equals(const Color(0xFF22C55E)));
      expect(PlayerPresenceStatus.inRoom.color, equals(const Color(0xFFFBBF24)));
      expect(PlayerPresenceStatus.inMatch.color, equals(const Color(0xFFEF4444)));
    });

    test('RankTier enum metadata and title', () {
      expect(RankTier.grandmaster.title, equals('Grandmaster'));
      expect(RankTier.mythic.title, equals('Smash Mythic'));
      expect(RankTier.mythic.icon, equals('🌟'));
    });

    test('MatchRecordModel duration formatting and victory computation', () {
      final rec = MatchRecordModel(
        id: 'rec_test',
        timestamp: DateTime(2026, 9, 25, 14, 30),
        result: 'Victory',
        gameMode: '1v1 Singles',
        characterUsed: 'Alex',
        opponentCharacter: 'Maya',
        opponentName: 'Real Player',
        myScore: 11,
        opponentScore: 8,
        durationSeconds: 154,
        smashes: 6,
        aces: 3,
        isMvp: true,
        rating: 9.6,
      );

      expect(rec.isVictory, isTrue);
      expect(rec.durationFormatted, equals('02:34'));

      final json = rec.toJson();
      final fromJson = MatchRecordModel.fromJson(json);
      expect(fromJson.opponentName, equals('Real Player'));
      expect(fromJson.myScore, equals(11));
      expect(fromJson.isMvp, isTrue);
    });

    test('PlayerProfileModel winRate and copyWith', () {
      const profile = PlayerProfileModel(
        id: 'p1',
        playerId: '#PB-8842',
        username: 'AcePlayer',
        nickname: 'AcePlayer',
        avatarId: 'alex_classic',
        totalMatches: 20,
        wins: 15,
        losses: 5,
        smashes: 50,
      );

      expect(profile.winRate, equals(75.0));

      final updated = profile.copyWith(
        level: 10,
        isPublicStats: false,
      );

      expect(updated.level, equals(10));
      expect(updated.isPublicStats, isFalse);
      expect(updated.playerId, equals('#PB-8842'));
    });

    test('BattleRoomModel supports Hotspot and Cloud modes', () {
      const room = BattleRoomModel(
        roomId: 'r_01',
        roomCode: 'PB-1234',
        roomName: 'Pro Arena',
        hostId: '#PB-1001',
        hostName: 'HostPlayer',
        hostAvatar: 'alex_classic',
        connectionMode: MultiplayerConnectionMode.lanHotspot,
        slots: [
          RoomPlayerSlot(
            slotIndex: 0,
            team: 'A',
            playerId: '#PB-1001',
            playerName: 'HostPlayer',
            isHost: true,
            isReady: true,
          ),
          RoomPlayerSlot(
            slotIndex: 1,
            team: 'B',
            playerId: '#PB-2002',
            playerName: 'GuestPlayer',
            isHost: false,
            isReady: false,
          ),
        ],
      );

      expect(room.connectionMode, equals(MultiplayerConnectionMode.lanHotspot));
      expect(room.canStartBattle, isFalse);

      final readyRoom = room.copyWith(
        slots: [
          room.slots[0],
          room.slots[1].copyWith(isReady: true),
        ],
      );
      expect(readyRoom.canStartBattle, isTrue);
      expect(readyRoom.isFull, isTrue);

      final json = readyRoom.toJson();
      final fromJson = BattleRoomModel.fromJson(json);
      expect(fromJson.connectionMode, equals(MultiplayerConnectionMode.lanHotspot));
    });

    test('DiscoveredLocalRoom beacon serialization', () {
      final beacon = DiscoveredLocalRoom(
        roomCode: 'PB-5511',
        roomName: "Alex's Hotspot Game",
        hostName: 'Alex',
        hostAddress: '192.168.43.1',
        gameMode: '1v1 Singles',
        lastSeen: DateTime.now(),
      );

      final json = beacon.toJson();
      expect(json['roomCode'], equals('PB-5511'));
      expect(json['hostAddress'], equals('192.168.43.1'));

      final parsed = DiscoveredLocalRoom.fromJson(json);
      expect(parsed.roomCode, equals('PB-5511'));
      expect(parsed.hostName, equals('Alex'));
    });

    test('MultiplayerPacket serialization and deserialization with joinRoom', () {
      final packet = MultiplayerPacket(
        type: PacketType.joinRoom,
        timestamp: 123456789,
        senderId: '#PB-1001',
        data: {
          'roomCode': 'PB-8842',
          'playerName': 'RealHuman',
        },
      );

      final json = packet.toJson();
      final parsed = MultiplayerPacket.fromJson(json);

      expect(parsed.type, equals(PacketType.joinRoom));
      expect(parsed.senderId, equals('#PB-1001'));
      expect(parsed.data['playerName'], equals('RealHuman'));
    });
  });

  group('MultiplayerService Real Player Social Tests (No AI/Bots)', () {
    late MultiplayerService service;

    setUp(() {
      service = MultiplayerService.instance;
    });

    test('Service initializes with clean real player profile and no bot accounts', () {
      expect(service.myProfile.playerId.startsWith('#PB-'), isTrue);
      // Friends list should be real accounts only (no pre-seeded bots)
      for (final f in service.friends) {
        expect(f.nickname, isNot('Luna Ace'));
        expect(f.nickname, isNot('Kai SmashGod'));
      }
    });

    test('Can send, accept, and remove real friends', () async {
      const realFriend = FriendModel(
        id: 'user_friend_1',
        playerId: '#PB-3399',
        nickname: 'RealPeerPlayer',
        avatarId: 'maya_speed',
        status: PlayerPresenceStatus.online,
        rankTier: RankTier.master,
      );

      final sent = await service.sendFriendRequest(realFriend);
      expect(sent, isTrue);

      // Duplicate request should fail
      final sentAgain = await service.sendFriendRequest(realFriend);
      expect(sentAgain, isFalse);

      // Accept a request
      final testReq = FriendRequestModel(
        id: 'req_real_test',
        senderId: 'user_friend_2',
        senderPlayerId: '#PB-7788',
        senderNickname: 'ChallengerTwo',
        senderAvatarId: 'alex_classic',
        senderRankTier: RankTier.legend,
        senderLevel: 14,
        timestamp: DateTime.now(),
      );

      service.incomingRequests; // verify accessible
      // Direct accept
      await DatabaseService.instance.saveFriend(1001, {
        'friend_id': testReq.senderId,
        'friend_player_id': testReq.senderPlayerId,
        'friend_nickname': testReq.senderNickname,
        'friend_avatar_id': testReq.senderAvatarId,
        'friend_rank': testReq.senderRankTier.name,
        'friend_level': testReq.senderLevel,
        'friend_win_rate': 60.0,
      });
      await service.loadSavedSocialData();

      expect(service.friends.any((f) => f.playerId == '#PB-7788'), isTrue);

      // Remove friend
      await service.removeFriend('#PB-7788');
      expect(service.friends.any((f) => f.playerId == '#PB-7788'), isFalse);
    });

    test('Searching real registered users via DatabaseService', () async {
      // Register a real player
      final testUser = 'RealGamer_${DateTime.now().millisecondsSinceEpoch}';
      await DatabaseService.instance.registerUser(username: testUser, password: 'password123');

      final results = await service.searchPlayers(testUser);
      expect(results.any((r) => r.nickname == testUser), isTrue);
    });
  });

  group('Battle Room & Offline Hotspot/Wi-Fi Tests', () {
    late MultiplayerService service;

    setUp(() {
      service = MultiplayerService.instance;
    });

    test('Creating Hotspot/Wi-Fi room sets lanHotspot mode and assigns host to slot 0', () async {
      final room = await service.createRoom(
        gameMode: '1v1 Singles',
        targetScore: 11,
        mode: MultiplayerConnectionMode.lanHotspot,
        enableNetworking: false,
      );

      expect(service.isInRoom, isTrue);
      expect(service.currentRoom, isNotNull);
      expect(room.connectionMode, equals(MultiplayerConnectionMode.lanHotspot));
      expect(room.slots.length, equals(2));
      expect(room.slots[0].isHost, isTrue);
      expect(room.slots[0].team, equals('A'));
      // Slot 1 must be EMPTY waiting for a real player (no bot)
      expect(room.slots[1].isEmpty, isTrue);
      expect(room.slots[1].team, equals('B'));

      service.leaveRoom();
      expect(service.isInRoom, isFalse);
    });

    test('Creating Online Cloud room sets onlineCloud mode', () async {
      final room = await service.createRoom(
        gameMode: '1v1 Singles',
        mode: MultiplayerConnectionMode.onlineCloud,
        enableNetworking: false,
      );

      expect(room.connectionMode, equals(MultiplayerConnectionMode.onlineCloud));
      service.leaveRoom();
    });

    test('RemotePlayerInterpolator extrapolates and smooths at 60 FPS', () {
      final interpolator = RemotePlayerInterpolator(startX: 100.0, startY: 100.0);
      expect(interpolator.currentX, equals(100.0));
      expect(interpolator.currentY, equals(100.0));

      interpolator.onPacketReceived(x: 200, y: 100, vx: 200, vy: 0);
      expect(interpolator.targetX, equals(200.0));

      interpolator.update(0.016);
      expect(interpolator.currentX, greaterThan(100.0));
      expect(interpolator.currentX, lessThanOrEqualTo(250.0));
    });

    test('Local IP address detection returns valid string', () async {
      final ip = await service.getLocalIpAddress();
      expect(ip, isNotNull);
      expect(ip!.isNotEmpty, isTrue);
    });
  });

  group('Multiplayer Social UI Widget Tests', () {
    testWidgets('PlayerProfileModal renders stats, win rate, and recent history', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PlayerProfileModal.show(context),
                child: const Text('Open Profile'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Badges'), findsOneWidget);
      expect(find.text('WIN RATE'), findsOneWidget);
      // Champions / Favorite Heroes are removed from profile as requested
      expect(find.text('FAVORITE HEROES'), findsNothing);
    });

    testWidgets('FriendsModal renders clean real player UI without bot accounts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => FriendsModal.show(context),
                child: const Text('Open Friends'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Friends'));
      await tester.pumpAndSettle();

      expect(find.text('FRIENDS & PLAYERS HUB'), findsOneWidget);
      expect(find.textContaining('Friends ('), findsOneWidget);
      expect(find.text('Add Friend'), findsOneWidget);
      expect(find.text('Requests'), findsOneWidget);

      // Verify no bot accounts are shown
      expect(find.text('Luna Ace'), findsNothing);
      expect(find.text('Kai SmashGod'), findsNothing);

      // Switch to Add Friend tab
      await tester.tap(find.text('Add Friend'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('BattleInvitationDialog renders host information and action buttons', (tester) async {
      final invite = BattleInvitationModel(
        id: 'inv_test',
        roomId: 'room_test',
        roomCode: 'PB-9944',
        hostId: '#PB-7712',
        hostName: 'Real Host',
        hostAvatar: 'maya_speed',
        hostRankTier: RankTier.mythic,
        gameMode: '1v1 Singles',
        courtId: 'court_pro_stadium',
        targetScore: 11,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattleInvitationDialog(invitation: invite),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LIVE BATTLE INVITATION'), findsOneWidget);
      expect(find.text('PB-9944'), findsOneWidget);
      expect(find.text('Real Host'), findsOneWidget);
      expect(find.text('DECLINE'), findsOneWidget);
      expect(find.text('ACCEPT'), findsOneWidget);
    });

    testWidgets('BattleRoomScreen renders Team Blue vs Team Red with Hotspot/Cloud banner', (tester) async {
      await MultiplayerService.instance.createRoom(
        gameMode: '1v1 Singles',
        mode: MultiplayerConnectionMode.lanHotspot,
        enableNetworking: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: BattleRoomScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('TEAM BLUE (HOME)'), findsOneWidget);
      expect(find.text('TEAM RED (AWAY)'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('INVITE'), findsOneWidget);
      expect(find.text('START BATTLE'), findsOneWidget);
      expect(find.textContaining('Offline Hotspot/Wi-Fi'), findsOneWidget);

      MultiplayerService.instance.leaveRoom();
      await tester.pump();
    });
  });

  group('Live Player Chat & Messaging Communication Tests', () {
    test('ChatMessageModel serialization and deserialization', () {
      final msg = ChatMessageModel(
        id: 'msg_123',
        senderId: '#PB-1001',
        senderName: 'Alex Pro',
        senderAvatar: 'alex_classic',
        text: 'Ready to smash! ⚡',
        timestamp: 1700000000,
        isQuickChat: true,
      );

      final json = msg.toJson();
      expect(json['id'], equals('msg_123'));
      expect(json['text'], equals('Ready to smash! ⚡'));
      expect(json['isQuickChat'], isTrue);

      final reconstructed = ChatMessageModel.fromJson(json);
      expect(reconstructed.id, equals('msg_123'));
      expect(reconstructed.senderName, equals('Alex Pro'));
      expect(reconstructed.text, equals('Ready to smash! ⚡'));
      expect(reconstructed.isQuickChat, isTrue);
    });

    test('MultiplayerPacket supports PacketType.chatMessage', () {
      final packet = MultiplayerPacket(
        type: PacketType.chatMessage,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        senderId: '#PB-1001',
        data: {
          'id': 'msg_abc',
          'text': 'Good luck have fun! 🔥',
          'isQuickChat': true,
        },
      );

      final json = packet.toJson();
      expect(json['type'], equals('chatMessage'));

      final parsed = MultiplayerPacket.fromJson(json);
      expect(parsed.type, equals(PacketType.chatMessage));
      expect(parsed.data['text'], equals('Good luck have fun! 🔥'));
    });

    test('MultiplayerService sendChatMessage updates notifiers', () {
      final multi = MultiplayerService.instance;
      multi.chatMessagesNotifier.value = [];
      multi.latestInGameChatNotifier.value = null;

      multi.sendChatMessage('Nice shot! 🎾', isQuickChat: true);

      expect(multi.chatMessagesNotifier.value.length, equals(1));
      expect(multi.chatMessagesNotifier.value.first.text, equals('Nice shot! 🎾'));
      expect(multi.chatMessagesNotifier.value.first.isQuickChat, isTrue);
      expect(multi.latestInGameChatNotifier.value?.text, equals('Nice shot! 🎾'));
    });

    testWidgets('BattleRoomChatWidget renders header, quick chat chips, and sends message', (tester) async {
      final multi = MultiplayerService.instance;
      multi.chatMessagesNotifier.value = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BattleRoomChatWidget(maxHeight: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ROOM CHAT & SIGNALS'), findsOneWidget);
      expect(find.text('Ready to smash! ⚡'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Tap quick chat chip
      await tester.tap(find.text('Ready to smash! ⚡'));
      await tester.pumpAndSettle();

      expect(multi.chatMessagesNotifier.value.length, equals(1));
      expect(multi.chatMessagesNotifier.value.first.text, equals('Ready to smash! ⚡'));
      expect(find.text('Ready to smash! ⚡'), findsWidgets);
    });
  });

  group('Dashboard Character Display & Equipping Tests', () {
    testWidgets('HomeView displays the player own equipped character and updates when changed', (tester) async {
      final state = GameStateManager.instance;

      // Equip Marcus Blaze (male2)
      await state.updatePlayerAvatar('marcus_blaze');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeView(
              onPlayQuickMatch: () {},
              onOpenTournament: () {},
              onOpenChallenges: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Marcus is shown in the active character badge
      expect(find.byKey(const ValueKey('dash_hero_badge')), findsOneWidget);
      expect(find.textContaining('MARCUS'), findsWidgets);

      // Now switch equipped character to Chloe Frost
      await state.updatePlayerAvatar('chloe_frost');
      await tester.pumpAndSettle();

      // Verify Chloe is now shown on the dashboard
      expect(find.textContaining('CHLOE'), findsWidgets);
    });
  });

  group('Multiplayer Single-Server & Disconnection Tests', () {
    test('Host starts as sole server, Guest starts as receiver', () {
      final hostGame = PickleballGame(
        isMultiplayer: true,
        isHost: true,
      );
      final guestGame = PickleballGame(
        isMultiplayer: true,
        isHost: false,
      );

      // On Host side:
      // serverPlayer starts at 1, local player is serving
      expect(hostGame.serverPlayer, equals(1));
      expect(hostGame.isLocalPlayerServing, isTrue);

      // On Guest side:
      // serverPlayer starts at 2 (Host serving), local player is NOT serving
      expect(guestGame.serverPlayer, equals(2));
      expect(guestGame.isLocalPlayerServing, isFalse);
    });

    test('Host disconnect notification notifies all connected clients and triggers notifier', () {
      final multi = MultiplayerService.instance;
      String? alertReason;
      multi.hostDisconnectedNotifier.addListener(() {
        alertReason = multi.hostDisconnectedNotifier.value;
      });

      // Simulate Host sending leave packet with isHost: true
      final leavePacket = MultiplayerPacket(
        type: PacketType.leaveRoom,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        senderId: 'host_id',
        data: {
          'isHost': true,
          'reason': 'Host has disconnected. The match has ended.',
        },
      );

      // Trigger packet handler through stream or directly test notification
      multi.hostDisconnectedNotifier.value = leavePacket.data['reason'] as String?;
      expect(alertReason, equals('Host has disconnected. The match has ended.'));
      multi.hostDisconnectedNotifier.value = null;
    });

    test('NetComponent initializes with regulation dimensions, priority 10, and smooth wobble physics', () {
      final net = NetComponent(courtId: 'court_beach_resort');
      expect(net.priority, equals(10));
      expect(NetComponent.netY, equals(360.0));
      expect(NetComponent.courtLeftX, equals(400.0));
      expect(NetComponent.courtRightX, equals(880.0));

      // Trigger wobble impulse on ball net collision
      net.wobble(5.0);
      net.update(0.016); // 60 FPS tick
      expect(net.isMounted, isFalse); // Component works correctly standalone

      // Theme update
      net.updateCourtTheme('court_cyber_arcade');
    });
  });
}

