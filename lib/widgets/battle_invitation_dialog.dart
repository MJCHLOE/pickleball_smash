import 'package:flutter/material.dart';
import '../models/multiplayer_models.dart';
import '../screens/battle_room_screen.dart';
import '../services/audio_service.dart';
import '../services/multiplayer_service.dart';
import '../theme/app_theme.dart';
import 'game_2d_button.dart';
import 'player_avatar.dart';

/// Interactive modal dialog for live battle invitations.
class BattleInvitationDialog extends StatelessWidget {
  final BattleInvitationModel invitation;

  const BattleInvitationDialog({super.key, required this.invitation});

  static void show(BuildContext context, BattleInvitationModel invitation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BattleInvitationDialog(invitation: invitation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final multi = MultiplayerService.instance;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.electricCyan, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.electricCyan.withValues(alpha: 0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Accent Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.electricCyan.withValues(alpha: 0.25),
                    const Color(0xFF0F172A),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_tennis_rounded, color: AppTheme.electricCyan, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'LIVE BATTLE INVITATION',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.electricCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.electricCyan, width: 1),
                    ),
                    child: Text(
                      invitation.roomCode,
                      style: const TextStyle(
                        color: AppTheme.electricCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Inviter Info & Court Specs
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: invitation.hostRankTier.color, width: 2.5),
                        ),
                        child: PlayerAvatarWidget(avatarId: invitation.hostAvatar, size: 64),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Text(invitation.hostRankTier.icon, style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    invitation.hostName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invitation.hostRankTier.title} • ${invitation.hostId}',
                    style: TextStyle(
                      color: invitation.hostRankTier.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildParam('GAME MODE', invitation.gameMode),
                        Container(width: 1, height: 24, color: Colors.white12),
                        _buildParam('TARGET SCORE', '${invitation.targetScore} PTS'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Has invited you to enter their private battle room for a live duel!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),

            // Action Buttons: [Accept] [Decline]
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: AppTheme.surfaceBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        AudioService.instance.playButtonTap();
                        multi.declineInvitation(invitation);
                        Navigator.of(context).pop();
                      },
                      child: const Text('DECLINE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Game2DButton(
                      onPressed: () async {
                        AudioService.instance.playButtonTap();
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        nav.pop();
                        final err = await multi.acceptInvitation(invitation);
                        if (err != null) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(err), backgroundColor: Colors.red),
                          );
                        } else {
                          nav.push(
                            MaterialPageRoute(
                              builder: (ctx) => const BattleRoomScreen(),
                            ),
                          );
                        }
                      },
                      text: 'ACCEPT',
                      icon: Icons.check_circle_rounded,
                      variant: GameButtonVariant.primary,
                      size: GameButtonSize.medium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParam(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
