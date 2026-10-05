import 'package:flutter/material.dart';
import '../models/multiplayer_models.dart';
import '../services/audio_service.dart';
import '../services/game_state_manager.dart';
import '../services/multiplayer_service.dart';
import '../theme/app_theme.dart';
import 'game_2d_button.dart';
import 'player_avatar.dart';
import 'player_profile_modal.dart';

/// Friends Hub modal for managing friends, searching players, and handling friend requests.
class FriendsModal extends StatefulWidget {
  final int initialTabIndex;

  const FriendsModal({super.key, this.initialTabIndex = 0});

  static void show(BuildContext context, {int initialTabIndex = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (ctx) => FriendsModal(initialTabIndex: initialTabIndex),
    );
  }

  @override
  State<FriendsModal> createState() => _FriendsModalState();
}

class _FriendsModalState extends State<FriendsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<FriendModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    final multi = MultiplayerService.instance;
    final results = await multi.searchPlayers(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final multi = MultiplayerService.instance;
    final screenHeight = MediaQuery.of(context).size.height;

    return ListenableBuilder(
      listenable: multi,
      builder: (context, _) {
        final pendingCount = multi.incomingRequests.length;

        return Container(
          height: screenHeight * 0.85,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppTheme.surfaceBorder, width: 2),
              left: BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
              right: BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
            ),
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Modal Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.electricCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.people_alt_rounded, color: AppTheme.electricCyan, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FRIENDS & PLAYERS HUB',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Connect, invite to private battles, and inspect player profiles',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                color: const Color(0xFF0F172A),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.electricCyan,
                  indicatorWeight: 3,
                  labelColor: AppTheme.electricCyan,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.group_rounded, size: 18),
                      text: 'Friends (${multi.friends.length})',
                    ),
                    const Tab(
                      icon: Icon(Icons.person_add_alt_1_rounded, size: 18),
                      text: 'Add Friend',
                    ),
                    Tab(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.mail_rounded, size: 18),
                          if (pendingCount > 0)
                            Positioned(
                              top: -4,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$pendingCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      text: 'Requests',
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsListTab(multi),
                    _buildAddFriendTab(multi),
                    _buildRequestsTab(multi),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendsListTab(MultiplayerService multi) {
    if (multi.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded, color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No friends added yet.',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Search by ID or username in the Add Friend tab to connect!',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Game2DButton(
              onPressed: () => _tabController.animateTo(1),
              text: 'SEARCH PLAYERS',
              icon: Icons.search_rounded,
              variant: GameButtonVariant.cyan,
              size: GameButtonSize.small,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: multi.friends.length,
      itemBuilder: (context, index) {
        final f = multi.friends[index];
        return _buildFriendCard(f, multi);
      },
    );
  }

  Widget _buildFriendCard(FriendModel f, MultiplayerService multi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          // Avatar with rank border & presence dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: f.rankTier.color, width: 2),
                ),
                child: PlayerAvatarWidget(
                  avatarId: f.avatarId,
                  size: 46,
                  showBadge: false,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: f.status.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0F172A), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Friend details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        f.nickname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LV.${f.level}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '${f.rankTier.icon} ${f.rankTier.title}',
                      style: TextStyle(
                        color: f.rankTier.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      f.status.label,
                      style: TextStyle(
                        color: f.status.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${f.playerId} • ${f.winRate.toStringAsFixed(0)}% WR',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Message / Chat button
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.electricCyan, size: 20),
                tooltip: 'Send Message',
                onPressed: () {
                  AudioService.instance.playButtonTap();
                  _showDirectMessageDialog(context, f);
                },
              ),
              // Profile button
              IconButton(
                icon: const Icon(Icons.account_box_outlined, color: AppTheme.textMuted, size: 22),
                tooltip: 'View Profile',
                onPressed: () {
                  AudioService.instance.playButtonTap();
                  PlayerProfileModal.show(context, playerId: f.playerId);
                },
              ),
              // Invite button
              Game2DButton(
                onPressed: () {
                  AudioService.instance.playButtonTap();
                  if (multi.isInRoom) {
                    final err = multi.inviteFriendToBattle(f);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err ?? 'Battle invite sent to ${f.nickname}!'),
                        backgroundColor: err != null ? Colors.red : AppTheme.surfaceLight,
                      ),
                    );
                  } else {
                    // Create battle room first, then invite
                    final nav = Navigator.of(context);
                    multi.createRoom().then((_) {
                      multi.inviteFriendToBattle(f);
                      nav.pop();
                    });
                  }
                },
                text: 'INVITE',
                icon: Icons.sports_tennis_rounded,
                variant: GameButtonVariant.primary,
                size: GameButtonSize.small,
              ),
              // Remove popup
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 20),
                color: const Color(0xFF1E293B),
                onSelected: (val) {
                  if (val == 'remove') {
                    multi.removeFriend(f.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Removed ${f.nickname} from friends.')),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Remove Friend', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddFriendTab(MultiplayerService multi) {
    return Column(
      children: [
        // Search Input Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter Player ID (e.g. #PB-7712) or Nickname...',
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.electricCyan),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF0F172A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.electricCyan, width: 1.5),
              ),
            ),
            onChanged: _performSearch,
          ),
        ),

        // Search Results
        Expanded(
          child: _searchController.text.trim().isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_search_rounded, color: AppTheme.textMuted, size: 44),
                      const SizedBox(height: 10),
                      const Text(
                        'Type a player ID or nickname to find rivals and friends',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      // Quick suggested players
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('#PB-7712 (Luna Ace)'),
                            backgroundColor: const Color(0xFF0F172A),
                            labelStyle: const TextStyle(color: AppTheme.neonLime, fontSize: 11),
                            onPressed: () {
                              _searchController.text = '#PB-7712';
                              _performSearch('#PB-7712');
                            },
                          ),
                          ActionChip(
                            label: const Text('#PB-6102 (Chloe Volley)'),
                            backgroundColor: const Color(0xFF0F172A),
                            labelStyle: const TextStyle(color: AppTheme.electricCyan, fontSize: 11),
                            onPressed: () {
                              _searchController.text = '#PB-6102';
                              _performSearch('#PB-6102');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : _searchResults.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching players found.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final target = _searchResults[index];
                        final isAlreadyFriend = multi.friends.any((f) => f.playerId == target.playerId);
                        final isPending = multi.outgoingRequests.any((r) => r.senderPlayerId == target.playerId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  AudioService.instance.playButtonTap();
                                  PlayerProfileModal.show(context, playerId: target.playerId);
                                },
                                child: PlayerAvatarWidget(avatarId: target.avatarId, size: 42),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    AudioService.instance.playButtonTap();
                                    PlayerProfileModal.show(context, playerId: target.playerId);
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        target.nickname,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${target.playerId} • ${target.rankTier.icon} ${target.rankTier.title}',
                                        style: TextStyle(color: target.rankTier.color, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.account_box_outlined, color: AppTheme.electricCyan, size: 20),
                                tooltip: 'View Profile',
                                onPressed: () {
                                  AudioService.instance.playButtonTap();
                                  PlayerProfileModal.show(context, playerId: target.playerId);
                                },
                              ),
                              if (isAlreadyFriend)
                                const Chip(
                                  label: Text('FRIEND', style: TextStyle(color: AppTheme.neonLime, fontSize: 10)),
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide(color: AppTheme.neonLime),
                                )
                              else if (isPending)
                                const Chip(
                                  label: Text('REQUESTED', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide(color: AppTheme.textMuted),
                                )
                              else
                                Game2DButton(
                                  onPressed: () {
                                    AudioService.instance.playButtonTap();
                                    if (GameStateManager.instance.isGuest) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Guest accounts cannot add friends. Please register or log in!'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      return;
                                    }
                                    multi.sendFriendRequest(target);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Friend request sent to ${target.nickname}!'),
                                      ),
                                    );
                                  },
                                  text: 'ADD',
                                  icon: Icons.person_add_rounded,
                                  variant: GameButtonVariant.cyan,
                                  size: GameButtonSize.small,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab(MultiplayerService multi) {
    if (multi.incomingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_rounded, color: AppTheme.textMuted, size: 44),
            SizedBox(height: 10),
            Text(
              'No pending friend requests.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: multi.incomingRequests.length,
      itemBuilder: (context, index) {
        final req = multi.incomingRequests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.electricCyan.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              PlayerAvatarWidget(avatarId: req.senderAvatarId, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.senderNickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${req.senderPlayerId} • ${req.senderRankTier.icon} ${req.senderRankTier.title}',
                      style: TextStyle(color: req.senderRankTier.color, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: AppTheme.neonLime, size: 28),
                tooltip: 'Accept',
                onPressed: () {
                  AudioService.instance.playButtonTap();
                  multi.acceptFriendRequest(req.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Accepted ${req.senderNickname} as friend!')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 28),
                tooltip: 'Decline',
                onPressed: () {
                  AudioService.instance.playButtonTap();
                  multi.declineFriendRequest(req.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDirectMessageDialog(BuildContext context, FriendModel friend) {
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.electricCyan, width: 1.5),
          ),
          title: Row(
            children: [
              PlayerAvatarWidget(avatarId: friend.avatarId, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message ${friend.nickname}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      friend.playerId,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QUICK SIGNALS',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  'Want to play 1v1? 🎾',
                  'Join my battle room! ⚔️',
                  'Let\'s team up! 👥',
                  'Ready when you are! ⚡',
                ].map((phrase) {
                  return InkWell(
                    onTap: () {
                      MultiplayerService.instance.sendChatMessage(phrase, isQuickChat: true);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Message sent to ${friend.nickname}!')),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.neonLime.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        phrase,
                        style: const TextStyle(
                          color: AppTheme.neonLime,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Type custom message...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Game2DButton(
              onPressed: () {
                final txt = textCtrl.text.trim();
                if (txt.isNotEmpty) {
                  MultiplayerService.instance.sendChatMessage(txt);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Message sent to ${friend.nickname}!')),
                  );
                } else {
                  Navigator.of(ctx).pop();
                }
              },
              text: 'SEND',
              icon: Icons.send_rounded,
              variant: GameButtonVariant.cyan,
              size: GameButtonSize.small,
            ),
          ],
        );
      },
    );
  }
}
