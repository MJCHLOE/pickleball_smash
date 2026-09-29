import 'package:flutter/material.dart';
import '../models/multiplayer_models.dart';
import '../services/audio_service.dart';
import '../services/multiplayer_service.dart';
import '../theme/app_theme.dart';
import 'player_avatar.dart';

/// Real-time live room chat & communication widget for offline Wi-Fi, Hotspot, and online rooms.
class BattleRoomChatWidget extends StatefulWidget {
  final double maxHeight;
  final bool isCompact;

  const BattleRoomChatWidget({
    super.key,
    this.maxHeight = 240,
    this.isCompact = false,
  });

  @override
  State<BattleRoomChatWidget> createState() => _BattleRoomChatWidgetState();
}

class _BattleRoomChatWidgetState extends State<BattleRoomChatWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    MultiplayerService.instance.chatMessagesNotifier.addListener(_onMessagesUpdated);
  }

  @override
  void dispose() {
    MultiplayerService.instance.chatMessagesNotifier.removeListener(_onMessagesUpdated);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onMessagesUpdated() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? quickChatText]) {
    final text = quickChatText ?? _textController.text;
    if (text.trim().isEmpty) return;

    AudioService.instance.playButtonTap();
    MultiplayerService.instance.sendChatMessage(
      text,
      isQuickChat: quickChatText != null,
    );

    if (quickChatText == null) {
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final multi = MultiplayerService.instance;
    final myPlayerId = multi.myProfile.playerId;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_rounded, color: AppTheme.electricCyan, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'ROOM CHAT & SIGNALS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<List<ChatMessageModel>>(
                  valueListenable: multi.chatMessagesNotifier,
                  builder: (context, msgs, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.electricCyan.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${msgs.length} MSG',
                        style: const TextStyle(
                          color: AppTheme.electricCyan,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Message List
          SizedBox(
            height: widget.maxHeight,
            child: ValueListenableBuilder<List<ChatMessageModel>>(
              valueListenable: multi.chatMessagesNotifier,
              builder: (context, messages, _) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 28,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Say hi or send a quick chat to your opponent!',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == myPlayerId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment:
                            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            PlayerAvatarWidget(
                              avatarId: msg.senderAvatar,
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Column(
                              crossAxisAlignment:
                                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                                    child: Text(
                                      msg.senderName,
                                      style: const TextStyle(
                                        color: AppTheme.electricCyan,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppTheme.electricCyan.withValues(alpha: 0.22)
                                        : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(12).copyWith(
                                      bottomRight: isMe ? const Radius.circular(2) : null,
                                      bottomLeft: !isMe ? const Radius.circular(2) : null,
                                    ),
                                    border: Border.all(
                                      color: isMe
                                          ? AppTheme.electricCyan.withValues(alpha: 0.5)
                                          : AppTheme.surfaceBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (msg.isQuickChat) ...[
                                        const Icon(
                                          Icons.flash_on_rounded,
                                          size: 13,
                                          color: AppTheme.goldCoin,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Flexible(
                                        child: Text(
                                          msg.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            PlayerAvatarWidget(
                              avatarId: msg.senderAvatar,
                              size: 26,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Quick Chat Chips Carousel
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF090D16),
              border: Border(
                top: BorderSide(color: AppTheme.surfaceBorder, width: 0.8),
                bottom: BorderSide(color: AppTheme.surfaceBorder, width: 0.8),
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: MultiplayerService.quickChatPresets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final phrase = MultiplayerService.quickChatPresets[index];
                return InkWell(
                  onTap: () => _sendMessage(phrase),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.neonLime.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        phrase,
                        style: const TextStyle(
                          color: AppTheme.neonLime,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Text Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type message or signal...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.electricCyan),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  key: const ValueKey('chat_send_button'),
                  onTap: () => _sendMessage(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: AppTheme.playButtonGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonLime.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
