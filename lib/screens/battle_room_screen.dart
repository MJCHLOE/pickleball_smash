import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ball_catalog.dart';
import '../models/character_roster.dart';
import '../models/court_catalog.dart';
import '../models/multiplayer_models.dart';
import '../services/audio_service.dart';
import '../services/connectivity_service.dart';
import '../services/multiplayer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/friends_modal.dart';
import '../widgets/game_2d_button.dart';
import '../widgets/game_2d_text.dart';
import '../widgets/player_avatar.dart';
import '../widgets/pre_match_loadout_modal.dart';
import '../widgets/battle_room_chat_widget.dart';
import 'game_play_screen.dart';

/// Private Battle Room Lobby (similar to MLBB custom room).
class BattleRoomScreen extends StatefulWidget {
  const BattleRoomScreen({super.key});

  @override
  State<BattleRoomScreen> createState() => _BattleRoomScreenState();
}

class _BattleRoomScreenState extends State<BattleRoomScreen> {
  StreamSubscription<MultiplayerPacket>? _networkPacketSub;
  bool _battleLaunched = false;

  @override
  void initState() {
    super.initState();
    _lockPortrait();

    // Listen for live WebSocket match start packet
    _networkPacketSub = MultiplayerService.instance.packetStream.listen((packet) {
      if (packet.type == PacketType.matchStart && mounted && !_battleLaunched) {
        final room = MultiplayerService.instance.currentRoom;
        if (room != null) {
          _launchLiveBattle(room, fromHost: false);
        }
      }
    });

    MultiplayerService.instance.addListener(_onRoomStateChanged);
    MultiplayerService.instance.hostDisconnectedNotifier.addListener(_onHostDisconnected);

    // Post-frame check: If room state is already inMatch, navigate immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onRoomStateChanged();
    });
  }

  void _onHostDisconnected() {
    final reason = MultiplayerService.instance.hostDisconnectedNotifier.value;
    if (reason != null && mounted && !MultiplayerService.instance.isHost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text(
            reason,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _onRoomStateChanged() {
    final multi = MultiplayerService.instance;
    if (multi.currentRoom?.status == 'inMatch' && mounted && !_battleLaunched) {
      _launchLiveBattle(multi.currentRoom!, fromHost: multi.isHost);
    }
  }

  @override
  void dispose() {
    MultiplayerService.instance.hostDisconnectedNotifier.removeListener(_onHostDisconnected);
    MultiplayerService.instance.removeListener(_onRoomStateChanged);
    _networkPacketSub?.cancel();
    super.dispose();
  }

  void _lockPortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _launchLiveBattle(BattleRoomModel room, {required bool fromHost}) async {
    if (_battleLaunched) return;
    _battleLaunched = true;

    if (room.connectionMode == MultiplayerConnectionMode.onlineCloud && mounted) {
      final hasNet = await ConnectivityService.instance.requireInternetAccess(context);
      if (!hasNet) {
        _battleLaunched = false;
        return;
      }
    }

    final multi = MultiplayerService.instance;
    if (fromHost) {
      final success = multi.startBattle();
      if (!success) {
        _battleLaunched = false;
        return;
      }
    }

    final isHost = multi.isHost;
    // For Host: opponent is guest in Team B
    // For Guest: opponent is host in Team A
    final opponentSlot = room.slots.firstWhere(
      (s) => isHost ? (!s.isHost && !s.isEmpty) : (s.isHost && !s.isEmpty),
      orElse: () => room.slots.firstWhere((s) => s.playerId != multi.myProfile.playerId, orElse: () => room.slots.first),
    );

    AudioService.instance.playServe();

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GamePlayScreen(
          matchType: 'multiplayer',
          opponentName: opponentSlot.playerName ?? (isHost ? 'Guest Challenger' : 'Host Player'),
          matchTitle: '${room.gameMode} • ${room.roomCode}',
          isDoubles: room.isDoubles,
          opponentCharacterId: opponentSlot.characterId,
          opponentBallId: opponentSlot.ballId,
          opponentCourtId: opponentSlot.courtId,
        ),
      ),
    );

    _battleLaunched = false;
    if (mounted) {
      _lockPortrait();
    }
  }

  @override
  Widget build(BuildContext context) {
    final multi = MultiplayerService.instance;

    return ListenableBuilder(
      listenable: multi,
      builder: (context, _) {
        final room = multi.currentRoom;
        if (room == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No active battle room found.', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  Game2DButton(
                    onPressed: () => Navigator.of(context).pop(),
                    text: 'RETURN',
                    variant: GameButtonVariant.dark,
                    size: GameButtonSize.medium,
                  ),
                ],
              ),
            ),
          );
        }

        final isHost = multi.isHost;
        final myPlayerId = multi.myProfile.playerId;
        final mySlot = room.slots.firstWhere(
          (s) => s.playerId == myPlayerId,
          orElse: () => isHost
              ? (room.slots.isNotEmpty ? room.slots.first : const RoomPlayerSlot(slotIndex: 0, team: 'A', isHost: true))
              : (room.slots.firstWhere((s) => !s.isHost, orElse: () => room.slots.length > 1 ? room.slots[1] : room.slots.first)),
        );

        final teamASlots = room.slots.where((s) => s.team == 'A').toList();
        final teamBSlots = room.slots.where((s) => s.team == 'B').toList();

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () {
                AudioService.instance.playButtonTap();
                multi.leaveRoom();
                Navigator.of(context).pop();
              },
            ),
            title: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppTheme.electricCyan, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    room.roomName,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              // Room Code Copy
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: room.roomCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Room Code ${room.roomCode} copied to clipboard!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.electricCyan.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        room.roomCode,
                        style: const TextStyle(
                          color: AppTheme.electricCyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, color: AppTheme.electricCyan, size: 14),
                    ],
                  ),
                ),
              ),
              // Room Settings Dialog (Host only)
              if (isHost)
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppTheme.neonLime),
                  tooltip: 'Room Settings',
                  onPressed: () => _showRoomSettingsDialog(context, multi, room),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Top Info Banner: Court, Mode, Target Score
                _buildRoomHeaderBanner(room),

                // Offline internet warning banner for Cloud mode
                if (room.connectionMode == MultiplayerConnectionMode.onlineCloud)
                  ValueListenableBuilder<bool>(
                    valueListenable: ConnectivityService.instance.isOnlineNotifier,
                    builder: (context, isOnline, _) {
                      if (isOnline) return const SizedBox.shrink();
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        color: const Color(0xFFDC2626),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'NO INTERNET ACCESS — ONLINE CLOUD MATCH PAUSED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => ConnectivityService.instance.checkInternetAccess(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'RETRY',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                // Main Team A vs Team B Battlefield
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Team A (Blue Team)
                      _buildTeamHeader('TEAM BLUE (HOME)', const Color(0xFF38BDF8), Icons.security_rounded),
                      const SizedBox(height: 8),
                      ...teamASlots.map((slot) => _buildSlotCard(slot, multi, room, mySlot)),

                      const SizedBox(height: 16),
                      // VS Divider
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, color: AppTheme.neonLime, size: 16),
                              SizedBox(width: 4),
                              Game2DText(
                                'VS',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                textColor: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.bolt, color: AppTheme.neonLime, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Team B (Red Team)
                      _buildTeamHeader('TEAM RED (AWAY)', const Color(0xFFF43F5E), Icons.sports_tennis_rounded),
                      const SizedBox(height: 8),
                      ...teamBSlots.map((slot) => _buildSlotCard(slot, multi, room, mySlot)),

                      const SizedBox(height: 18),
                      // Live Room Chat & Communication
                      const BattleRoomChatWidget(maxHeight: 180),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // Bottom Action Bar
                _buildBottomControls(multi, room, mySlot, isHost),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomHeaderBanner(BattleRoomModel room) {
    final court = CourtCatalog.getById(room.courtId);
    final isHotspot = room.connectionMode == MultiplayerConnectionMode.lanHotspot;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stadium_rounded, color: AppTheme.neonLime, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    court.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      room.gameMode,
                      style: const TextStyle(color: AppTheme.electricCyan, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.goldCoin.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${room.targetScore} PTS',
                      style: const TextStyle(color: AppTheme.goldCoin, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isHotspot ? Icons.wifi_tethering_rounded : Icons.cloud_done_rounded,
                size: 13,
                color: isHotspot ? AppTheme.electricCyan : AppTheme.neonLime,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isHotspot
                      ? 'Offline Hotspot/Wi-Fi • Host: ${room.hostAddress ?? '127.0.0.1'}:8088'
                      : 'Online Cloud • Code: ${room.roomCode}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(String title, Color teamColor, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: teamColor, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: teamColor,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotCard(
    RoomPlayerSlot slot,
    MultiplayerService multi,
    BattleRoomModel room,
    RoomPlayerSlot mySlot,
  ) {
    final isMe = slot.playerId == mySlot.playerId;

    if (slot.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12, style: BorderStyle.solid),
        ),
        child: InkWell(
          onTap: () {
            AudioService.instance.playButtonTap();
            FriendsModal.show(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_rounded, color: AppTheme.textMuted, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'EMPTY SLOT — TAP TO INVITE FRIEND',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final readyColor = slot.isReady ? AppTheme.neonLime : const Color(0xFFFBBF24);
    final charId = slot.characterId.isNotEmpty ? slot.characterId : (slot.playerAvatar ?? 'alex_classic');
    final charInfo = CharacterRoster.getById(charId);
    final ballInfo = BallCatalog.getById(slot.ballId);
    final courtInfo = CourtCatalog.getById(slot.courtId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? AppTheme.electricCyan : AppTheme.surfaceBorder,
          width: isMe ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Player Avatar & Host Crown
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: isMe
                    ? () async {
                        AudioService.instance.playButtonTap();
                        await PreMatchLoadoutModal.show(
                          context,
                          isHost: slot.isHost,
                          initialCharacterId: slot.characterId,
                          initialBallId: slot.ballId,
                          initialCourtId: slot.courtId,
                        );
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: slot.rankTier?.color ?? charInfo.borderColor, width: 2),
                  ),
                  child: PlayerAvatarWidget(avatarId: charInfo.id, size: 44),
                ),
              ),
              if (slot.isHost)
                Positioned(
                  top: -8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBBF24),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.black),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Player Name, Ping & Character Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        slot.playerName ?? 'Player',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.electricCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: AppTheme.electricCyan,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      slot.rankTier?.title ?? 'Warrior',
                      style: TextStyle(
                        color: slot.rankTier?.color ?? AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Ping
                    Row(
                      children: [
                        const Icon(Icons.wifi_rounded, color: AppTheme.neonLime, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${slot.pingMs} ms',
                          style: const TextStyle(color: AppTheme.neonLime, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Loadout Badges Wrap (Fighter -> Ball -> Court)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    // 1. Fighter (Always visible for all players)
                    InkWell(
                      onTap: isMe
                          ? () async {
                              AudioService.instance.playButtonTap();
                              await PreMatchLoadoutModal.show(
                                context,
                                isHost: slot.isHost,
                                initialCharacterId: slot.characterId,
                                initialBallId: slot.ballId,
                                initialCourtId: slot.courtId,
                              );
                            }
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: charInfo.borderColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: charInfo.borderColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(charInfo.badge, style: const TextStyle(fontSize: 10)),
                            const SizedBox(width: 3),
                            Text(
                              charInfo.name.toUpperCase(),
                              style: TextStyle(
                                color: charInfo.borderColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 3),
                              Icon(Icons.edit_rounded, size: 9, color: charInfo.borderColor),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // 2. Ball (Visible for YOU, HIDDEN for Opponent until match starts!)
                    if (isMe)
                      InkWell(
                        onTap: () async {
                          AudioService.instance.playButtonTap();
                          await PreMatchLoadoutModal.show(
                            context,
                            isHost: slot.isHost,
                            initialCharacterId: slot.characterId,
                            initialBallId: slot.ballId,
                            initialCourtId: slot.courtId,
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ballInfo.glowColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: ballInfo.glowColor.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(ballInfo.badge, style: const TextStyle(fontSize: 10)),
                              const SizedBox(width: 3),
                              Text(
                                ballInfo.name.toUpperCase(),
                                style: TextStyle(
                                  color: ballInfo.glowColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Opponent's Ball is Hidden
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 9, color: Color(0xFFFBBF24)),
                            SizedBox(width: 3),
                            Text(
                              'SECRET BALL',
                              style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 3. Court (Visible for YOU, HIDDEN for Opponent until match starts!)
                    if (isMe)
                      InkWell(
                        onTap: () async {
                          AudioService.instance.playButtonTap();
                          await PreMatchLoadoutModal.show(
                            context,
                            isHost: slot.isHost,
                            initialCharacterId: slot.characterId,
                            initialBallId: slot.ballId,
                            initialCourtId: slot.courtId,
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: courtInfo.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: courtInfo.accentColor.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(courtInfo.badge, style: const TextStyle(fontSize: 10)),
                              const SizedBox(width: 3),
                              Text(
                                courtInfo.name.toUpperCase(),
                                style: TextStyle(
                                  color: courtInfo.accentColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Opponent's Court is Hidden
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 9, color: Color(0xFFFBBF24)),
                            SizedBox(width: 3),
                            Text(
                              'SECRET COURT',
                              style: TextStyle(
                                color: Color(0xFFFBBF24),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Ready Status & Switch Team Action
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ready indicator badge (interactive for guest player)
              InkWell(
                onTap: (isMe && !slot.isHost)
                    ? () async {
                        if (room.connectionMode == MultiplayerConnectionMode.onlineCloud) {
                          final hasNet = await ConnectivityService.instance.requireInternetAccess(context);
                          if (!hasNet) return;
                        }
                        AudioService.instance.playButtonTap();
                        multi.toggleReady(slot.slotIndex);
                      }
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: readyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: readyColor, width: 1),
                  ),
                  child: Text(
                    slot.isReady ? 'READY' : 'PREPARING',
                    style: TextStyle(
                      color: readyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Switch Team button (for own slot)
              if (isMe)
                IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.electricCyan),
                  tooltip: 'Switch Team',
                  onPressed: () {
                    AudioService.instance.playButtonTap();
                    multi.switchTeam(slot.slotIndex);
                  },
                ),

              // Host kick button (for guests)
              if (mySlot.isHost && !slot.isHost)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'Kick Player',
                  onPressed: () {
                    AudioService.instance.playButtonTap();
                    multi.kickPlayer(slot.slotIndex);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    MultiplayerService multi,
    BattleRoomModel room,
    RoomPlayerSlot mySlot,
    bool isHost,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.surfaceBorder, width: 1.5)),
      ),
      child: Row(
        children: [
          // Invite Friends button
          Game2DButton(
            onPressed: () {
              AudioService.instance.playButtonTap();
              FriendsModal.show(context);
            },
            text: 'INVITE',
            icon: Icons.person_add_alt_1_rounded,
            variant: GameButtonVariant.dark,
            size: GameButtonSize.medium,
          ),
          const SizedBox(width: 8),

          // Pre-Match Loadout Selection button (Character -> Ball -> Court)
          Game2DButton(
            onPressed: () async {
              AudioService.instance.playButtonTap();
              await PreMatchLoadoutModal.show(
                context,
                isHost: isHost,
                initialCharacterId: mySlot.characterId,
                initialBallId: mySlot.ballId,
                initialCourtId: mySlot.courtId,
              );
            },
            text: 'LOADOUT',
            icon: Icons.tune_rounded,
            variant: mySlot.hasSelectedLoadout ? GameButtonVariant.cyan : GameButtonVariant.amber,
            size: GameButtonSize.medium,
          ),
          const SizedBox(width: 8),

          // Main Ready / Start Battle Action
          if (isHost && !room.canStartBattle && room.slots.any((s) => s.isEmpty)) ...[
            Game2DButton(
              onPressed: () {
                AudioService.instance.playButtonTap();
                multi.addCpuOpponent();
              },
              text: '+ CPU',
              icon: Icons.smart_toy_outlined,
              variant: GameButtonVariant.cyan,
              size: GameButtonSize.medium,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: isHost
                ? Game2DButton(
                    onPressed: () async {
                      if (!mySlot.hasSelectedLoadout) {
                        AudioService.instance.playButtonTap();
                        final chosen = await PreMatchLoadoutModal.show(
                          context,
                          isHost: true,
                          initialCharacterId: mySlot.characterId,
                          initialBallId: mySlot.ballId,
                          initialCourtId: mySlot.courtId,
                        );
                        if (chosen != true || !mounted) return;
                      }
                      if (!room.canStartBattle) {
                        if (room.slots.where((s) => !s.isEmpty && !s.isHost).isEmpty) {
                          multi.addCpuOpponent();
                          if (room.connectionMode == MultiplayerConnectionMode.onlineCloud) {
                            if (!mounted) return;
                            final hasNet = await ConnectivityService.instance.requireInternetAccess(context);
                            if (!hasNet || !mounted) return;
                          }
                          _launchLiveBattle(multi.currentRoom ?? room, fromHost: true);
                          return;
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Waiting for all players to tap READY before launching!',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        return;
                      }
                      if (room.connectionMode == MultiplayerConnectionMode.onlineCloud) {
                        if (!mounted) return;
                        final hasNet = await ConnectivityService.instance.requireInternetAccess(context);
                        if (!hasNet || !mounted) return;
                      }
                      _launchLiveBattle(room, fromHost: true);
                    },
                    text: 'START BATTLE',
                    icon: Icons.sports_tennis_rounded,
                    variant: room.canStartBattle ? GameButtonVariant.primary : GameButtonVariant.dark,
                    size: GameButtonSize.medium,
                  )
                : Game2DButton(
                    onPressed: () async {
                      if (!mySlot.isReady && !mySlot.hasSelectedLoadout) {
                        AudioService.instance.playButtonTap();
                        final chosen = await PreMatchLoadoutModal.show(
                          context,
                          isHost: false,
                          initialCharacterId: mySlot.characterId,
                          initialBallId: mySlot.ballId,
                          initialCourtId: mySlot.courtId,
                        );
                        if (chosen != true || !mounted) return;
                      }
                      if (room.connectionMode == MultiplayerConnectionMode.onlineCloud) {
                        if (!mounted) return;
                        final hasNet = await ConnectivityService.instance.requireInternetAccess(context);
                        if (!hasNet || !mounted) return;
                      }
                      AudioService.instance.playButtonTap();
                      multi.toggleReady(mySlot.slotIndex);
                    },
                    text: mySlot.isReady ? 'CANCEL READY' : 'READY',
                    icon: mySlot.isReady ? Icons.close_rounded : Icons.check_circle_rounded,
                    variant: mySlot.isReady ? GameButtonVariant.amber : GameButtonVariant.primary,
                    size: GameButtonSize.medium,
                  ),
          ),
        ],
      ),
    );
  }

  void _showRoomSettingsDialog(
    BuildContext context,
    MultiplayerService multi,
    BattleRoomModel room,
  ) {
    int currentScore = room.targetScore;
    String currentMode = room.gameMode;
    String currentCourt = room.courtId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.surfaceBorder),
          ),
          title: const Text('Battle Room Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Game Mode', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButton<String>(
                value: currentMode,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: '1v1 Singles', child: Text('1v1 Singles Duel')),
                  DropdownMenuItem(value: '2v2 Doubles', child: Text('2v2 Doubles Battle')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => currentMode = val);
                },
              ),
              const SizedBox(height: 14),
              const Text('Target Score', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [11, 15, 21].map((pts) {
                  final isSel = currentScore == pts;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$pts PTS'),
                      selected: isSel,
                      selectedColor: AppTheme.neonLime,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setDlgState(() => currentScore = pts),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonLime),
              onPressed: () {
                multi.changeRoomSettings(
                  gameMode: currentMode,
                  targetScore: currentScore,
                  courtId: currentCourt,
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('SAVE SETTINGS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
