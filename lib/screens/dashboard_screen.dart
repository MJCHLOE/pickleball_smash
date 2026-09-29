import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/multiplayer_models.dart';
import '../services/audio_service.dart';
import '../services/game_state_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_picker_dialog.dart';
import '../widgets/game_2d_button.dart';
import '../widgets/game_2d_text.dart';
import '../widgets/player_avatar.dart';
import '../widgets/smooth_lights_background.dart';
import 'views/home_view.dart';
import 'views/tournament_view.dart';
import 'views/challenges_view.dart';
import 'views/settings_view.dart';
import 'views/player_stats_modal.dart';
import '../widgets/battle_invitation_dialog.dart';
import '../widgets/friends_modal.dart';
import '../widgets/inventory_modal.dart';
import '../widgets/player_profile_modal.dart';
import '../widgets/shop_modal.dart';
import '../services/multiplayer_service.dart';
import 'battle_room_screen.dart';
import 'game_play_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _lockPortraitOrientation();
    AudioService.instance.playBgm();
    MultiplayerService.instance.incomingInvitationNotifier.addListener(_onInvitationChanged);
  }

  @override
  void dispose() {
    MultiplayerService.instance.incomingInvitationNotifier.removeListener(_onInvitationChanged);
    super.dispose();
  }

  void _onInvitationChanged() {
    final invite = MultiplayerService.instance.incomingInvitationNotifier.value;
    if (invite != null && mounted) {
      BattleInvitationDialog.show(context, invite);
    }
  }

  void _openBattleRoom() async {
    AudioService.instance.playButtonTap();
    await _showBattleRoomLauncher(context);
  }

  Future<void> _showBattleRoomLauncher(BuildContext context) async {
    final multi = MultiplayerService.instance;
    final codeCtrl = TextEditingController();
    final rootNav = Navigator.of(context);
    multi.startLocalBeaconDiscovery();

    String detectedIp = '127.0.0.1';
    multi.getLocalIpAddress().then((ip) {
      if (ip != null) detectedIp = ip;
    });

    MultiplayerConnectionMode selectedMode = MultiplayerConnectionMode.lanHotspot;
    bool isConnecting = false;
    String? connectionError;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.electricCyan, width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.sports_tennis_rounded, color: AppTheme.electricCyan, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'MULTIPLAYER BATTLE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mode Selector Tabs (Hotspot/Wi-Fi vs Online Cloud)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedMode = MultiplayerConnectionMode.lanHotspot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selectedMode == MultiplayerConnectionMode.lanHotspot
                                ? AppTheme.electricCyan.withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedMode == MultiplayerConnectionMode.lanHotspot
                                  ? AppTheme.electricCyan
                                  : Colors.transparent,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_tethering_rounded, size: 16, color: AppTheme.electricCyan),
                              SizedBox(width: 6),
                              Text(
                                'Hotspot / Wi-Fi (Offline)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedMode = MultiplayerConnectionMode.onlineCloud),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selectedMode == MultiplayerConnectionMode.onlineCloud
                                ? AppTheme.neonLime.withValues(alpha: 0.25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedMode == MultiplayerConnectionMode.onlineCloud
                                  ? AppTheme.neonLime
                                  : Colors.transparent,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_sync_rounded, size: 16, color: AppTheme.neonLime),
                              SizedBox(width: 6),
                              Text(
                                'Online Cloud (Play Store)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (connectionError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          connectionError!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Create / Host Button
              Game2DButton(
                onPressed: isConnecting
                    ? null
                    : () async {
                        Navigator.of(ctx).pop();
                        await multi.createRoom(mode: selectedMode);
                        rootNav.push(
                          MaterialPageRoute(builder: (c) => const BattleRoomScreen()),
                        );
                      },
                text: selectedMode == MultiplayerConnectionMode.lanHotspot
                    ? 'HOST HOTSPOT / WI-FI ROOM'
                    : 'HOST ONLINE CLOUD ROOM',
                icon: selectedMode == MultiplayerConnectionMode.lanHotspot
                    ? Icons.wifi_tethering_rounded
                    : Icons.cloud_upload_rounded,
                variant: selectedMode == MultiplayerConnectionMode.lanHotspot
                    ? GameButtonVariant.primary
                    : GameButtonVariant.cyan,
                size: GameButtonSize.medium,
              ),

              const SizedBox(height: 16),

              // Discovered Local Rooms (Hotspot/Wi-Fi mode)
              if (selectedMode == MultiplayerConnectionMode.lanHotspot) ...[
                const Text(
                  'NEARBY HOTSPOT / WI-FI GAMES (AUTO-DISCOVERED)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ValueListenableBuilder<List<DiscoveredLocalRoom>>(
                  valueListenable: multi.discoveredRoomsNotifier,
                  builder: (context, rooms, _) {
                    if (rooms.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.electricCyan),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Listening for rooms on your hotspot or Wi-Fi network...',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: rooms.map((r) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.electricCyan.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.wifi_rounded, color: AppTheme.electricCyan, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.roomName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      '${r.hostAddress} • ${r.gameMode} • ${r.targetScore} PTS',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Game2DButton(
                                onPressed: isConnecting
                                    ? null
                                    : () async {
                                        final sheetNav = Navigator.of(ctx);
                                        setSheetState(() {
                                          isConnecting = true;
                                          connectionError = null;
                                        });
                                        final err = await multi.joinRoom(
                                          hostAddress: r.hostAddress,
                                          roomCode: r.roomCode,
                                          port: r.port,
                                          mode: MultiplayerConnectionMode.lanHotspot,
                                        );
                                        if (err != null) {
                                          setSheetState(() {
                                            isConnecting = false;
                                            connectionError = err;
                                          });
                                        } else {
                                          sheetNav.pop();
                                          rootNav.push(
                                            MaterialPageRoute(builder: (c) => const BattleRoomScreen()),
                                          );
                                        }
                                      },
                                text: 'JOIN',
                                icon: Icons.login_rounded,
                                variant: GameButtonVariant.cyan,
                                size: GameButtonSize.small,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Manual Join Field
              Text(
                selectedMode == MultiplayerConnectionMode.lanHotspot
                    ? 'OR ENTER HOST IP / ROOM CODE DIRECTLY'
                    : 'OR JOIN ONLINE ROOM BY 4-DIGIT CODE',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeCtrl,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: selectedMode == MultiplayerConnectionMode.lanHotspot
                            ? 'e.g. 192.168.43.1 or PB-8842'
                            : 'e.g. PB-8842',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Game2DButton(
                    onPressed: isConnecting
                        ? null
                        : () async {
                            final input = codeCtrl.text.trim();
                            if (input.isEmpty) return;

                            final sheetNav = Navigator.of(ctx);
                            setSheetState(() {
                              isConnecting = true;
                              connectionError = null;
                            });

                            final hostAddr = input.contains('.') ? input : detectedIp;
                            final err = await multi.joinRoom(
                              hostAddress: hostAddr,
                              roomCode: input,
                              mode: selectedMode,
                            );

                            if (err != null) {
                              setSheetState(() {
                                isConnecting = false;
                                connectionError = err;
                              });
                            } else {
                              sheetNav.pop();
                              rootNav.push(
                                MaterialPageRoute(builder: (c) => const BattleRoomScreen()),
                              );
                            }
                          },
                    text: isConnecting ? 'CONNECTING...' : 'JOIN',
                    icon: Icons.login_rounded,
                    variant: GameButtonVariant.cyan,
                    size: GameButtonSize.small,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    multi.stopLocalBeaconDiscovery();
  }

  void _lockPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _navigateToGame({
    String matchType = 'quick',
    String? tournamentId,
    String? opponentName,
    String? matchTitle,
    bool isDoubles = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GamePlayScreen(
          matchType: matchType,
          tournamentId: tournamentId,
          opponentName: opponentName,
          matchTitle: matchTitle,
          isDoubles: isDoubles,
        ),
      ),
    );
    // When returning to dashboard, restore portrait orientation
    if (mounted) {
      _lockPortraitOrientation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateManager.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppTheme.compactBreakpoint;

            return Scaffold(
              backgroundColor: AppTheme.background,
              body: SmoothLightsAlphabetBackground(
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top Player Profile & Currencies Header
                      _buildTopHeader(context, state),
                      const Divider(color: AppTheme.surfaceBorder, height: 1),
                      // Body Area
                      Expanded(
                        child: isWide
                            ? Row(
                                children: [
                                  _buildNavigationRail(),
                                  const VerticalDivider(color: AppTheme.surfaceBorder, width: 1),
                                  Expanded(child: _buildCurrentView()),
                                ],
                              )
                            : _buildCurrentView(),
                      ),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: isWide ? null : _buildBottomNavigationBar(),
            );
          },
        );
      },
    );
  }

  Widget _buildTopHeader(BuildContext context, GameStateManager state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: AppTheme.surface,
      child: Row(
        children: [
          // Player Avatar & Info - Tap to view individual stats and records
          Expanded(
            child: InkWell(
              onTap: () => PlayerProfileModal.show(context),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
                child: Row(
                  children: [
                    PlayerAvatarWidget(
                      avatarId: state.playerAvatarId,
                      size: 40,
                      showBadge: true,
                      onTap: () => AvatarPickerDialog.show(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Game2DText(
                                  state.playerName,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  textColor: Colors.white,
                                  strokeWidth: 2.0,
                                  shadowOffset: const Offset(0, 1.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B5E20),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF090D16), width: 1),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 1.5),
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neonLime,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'LVL ${state.playerLevel}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // XP Progress bar
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: state.xpProgress,
                                    backgroundColor: AppTheme.surfaceLight,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.electricCyan),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                flex: 4,
                                child: Text(
                                  '${state.playerXp}/${state.xpToNextLevel} XP',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 380) ...[
            const SizedBox(width: 4),
            // Friends & Social Hub Icon Button
            IconButton(
              key: const ValueKey('dashboard_friends_btn'),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.people_alt_rounded, color: AppTheme.electricCyan, size: 20),
              tooltip: 'Friends & Social Hub',
              onPressed: () {
                AudioService.instance.playButtonTap();
                FriendsModal.show(context);
              },
            ),
          ],
          const SizedBox(width: 2),
          // Leaderboard Icon Button
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.leaderboard_rounded, color: AppTheme.neonLime, size: 20),
            tooltip: 'All Players Leaderboard',
            onPressed: () {
              AudioService.instance.playButtonTap();
              PlayerStatsModal.show(context, initialTabIndex: 1);
            },
          ),
          if (MediaQuery.sizeOf(context).width >= 520) ...[
            const SizedBox(width: 2),
            // Locker & Inventory Icon Button
            IconButton(
              key: const ValueKey('dashboard_inventory_btn'),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.inventory_2_rounded, color: AppTheme.electricCyan, size: 20),
              tooltip: 'Locker & Inventory',
              onPressed: () {
                AudioService.instance.playButtonTap();
                InventoryModal.show(context);
              },
            ),
            const SizedBox(width: 2),
            // Smash Pro Shop Icon Button
            IconButton(
              key: const ValueKey('dashboard_shop_btn'),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.storefront_rounded, color: AppTheme.goldCoin, size: 20),
              tooltip: 'Smash Pro Shop',
              onPressed: () {
                AudioService.instance.playButtonTap();
                ShopModal.show(context);
              },
            ),
          ],
          const SizedBox(width: 2),
          // Currencies Chips
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => ShopModal.show(context),
                borderRadius: BorderRadius.circular(10),
                child: _buildCurrencyChip(
                  icon: Icons.monetization_on_rounded,
                  iconColor: AppTheme.goldCoin,
                  value: '${state.coins}',
                ),
              ),
              const SizedBox(width: 4),
              _buildCurrencyChip(
                icon: Icons.emoji_events_rounded,
                iconColor: AppTheme.trophyAmber,
                value: '${state.trophies}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyChip({
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF090D16), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: iconColor.withValues(alpha: 0.35), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 4),
            Game2DText.score(
              value,
              fontSize: 12,
              textColor: Colors.white,
              strokeWidth: 2.0,
              shadowOffset: const Offset(0, 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      color: AppTheme.surface,
      width: 110,
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildRailItem(0, Icons.sports_tennis_rounded, 'Court'),
          _buildRailItem(1, Icons.emoji_events_rounded, 'Tournaments'),
          _buildRailItem(2, Icons.military_tech_rounded, 'Challenges'),
          _buildRailItem(3, Icons.tune_rounded, 'Settings'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'SMASH\nv1.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailItem(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: InkWell(
        key: ValueKey('rail_item_$index'),
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.neonLime.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.neonLime : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.neonLime : AppTheme.textMuted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.surfaceBorder, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedTabIndex,
        backgroundColor: Colors.transparent,
        indicatorColor: AppTheme.neonLime.withValues(alpha: 0.25),
        elevation: 0,
        height: 65,
        onDestinationSelected: (index) {
          AudioService.instance.playButtonTap();
          setState(() {
            _selectedTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            key: ValueKey('nav_dest_0'),
            icon: Icon(Icons.sports_tennis_rounded, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.sports_tennis_rounded, color: AppTheme.neonLime),
            label: 'Home',
          ),
          NavigationDestination(
            key: ValueKey('nav_dest_1'),
            icon: Icon(Icons.emoji_events_rounded, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.emoji_events_rounded, color: AppTheme.neonLime),
            label: 'Tournaments',
          ),
          NavigationDestination(
            key: ValueKey('nav_dest_2'),
            icon: Icon(Icons.military_tech_rounded, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.military_tech_rounded, color: AppTheme.neonLime),
            label: 'Challenges',
          ),
          NavigationDestination(
            key: ValueKey('nav_dest_3'),
            icon: Icon(Icons.tune_rounded, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.tune_rounded, color: AppTheme.neonLime),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedTabIndex) {
      case 0:
        return HomeView(
          onPlayQuickMatch: () => _navigateToGame(matchType: 'quick', isDoubles: false),
          onPlayDoublesMatch: () => _navigateToGame(matchType: 'doubles', isDoubles: true),
          onOpenBattleRoom: _openBattleRoom,
          onOpenFriends: () => FriendsModal.show(context),
          onOpenProfile: () => PlayerProfileModal.show(context),
          onOpenTournament: () {
            setState(() {
              _selectedTabIndex = 1;
            });
          },
          onOpenChallenges: () {
            setState(() {
              _selectedTabIndex = 2;
            });
          },
        );
      case 1:
        return TournamentView(
          onStartMatch: (tournament, match) {
            _navigateToGame(
              matchType: 'tournament',
              tournamentId: tournament.id,
              matchTitle: match.roundTitle,
              opponentName: match.player2Name,
            );
          },
        );
      case 2:
        return ChallengesView(
          onGoPlay: () => _navigateToGame(matchType: 'quick'),
        );
      case 3:
        return const SettingsView();
      default:
        return const SizedBox.shrink();
    }
  }
}

