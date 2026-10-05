import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/character_roster.dart';
import '../models/player_avatar.dart';
import '../services/audio_service.dart';
import '../services/game_state_manager.dart';
import '../theme/app_theme.dart';
import 'animated_character_display.dart';
import 'dashboard_character_card_feature.dart';
import 'game_2d_button.dart';
import 'player_avatar.dart';
import 'ready_to_serve_character_widget.dart';

/// Clean 2D Arcade Player Profile Picture Picker.
/// In profile, Champions and Avatar Studio have been removed as requested.
class AvatarPickerDialog extends StatefulWidget {
  final bool showChampions;

  const AvatarPickerDialog({
    super.key,
    this.showChampions = false,
  });

  static Future<void> show(BuildContext context, {bool showChampions = false}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AvatarPickerDialog(showChampions: showChampions),
    );
  }

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  late String _selectedAvatarId;
  String _previewUrl = '';

  @override
  void initState() {
    super.initState();
    _selectedAvatarId = GameStateManager.instance.playerAvatarId;
    if (_selectedAvatarId.startsWith('http://') ||
        _selectedAvatarId.startsWith('https://') ||
        _selectedAvatarId.contains(':\\') ||
        _selectedAvatarId.contains(':/') ||
        _selectedAvatarId.startsWith('file://') ||
        _selectedAvatarId.startsWith('/') ||
        _selectedAvatarId.startsWith('blob:') ||
        _selectedAvatarId.toLowerCase().endsWith('.jpg') ||
        _selectedAvatarId.toLowerCase().endsWith('.jpeg') ||
        _selectedAvatarId.toLowerCase().endsWith('.png') ||
        _selectedAvatarId.toLowerCase().endsWith('.webp') ||
        _selectedAvatarId.contains('image_picker') ||
        _selectedAvatarId.contains('file_picker')) {
      _previewUrl = _selectedAvatarId;
    }
  }

  void _applyAvatar(String id) {
    setState(() {
      _selectedAvatarId = id;
    });
    GameStateManager.instance.updatePlayerAvatar(id);
    AudioService.instance.playPaddleHit();
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        final path = image.path;
        setState(() {
          _previewUrl = path;
        });
        _applyAvatar(path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.neonLime,
              content: Text(
                'Gallery picture selected for ${GameStateManager.instance.playerName}!',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text(
              'Could not load gallery photo: $e',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickFromFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (files.isNotEmpty && mounted) {
        final path = files.first.path;
        if (path != null && path.isNotEmpty) {
          setState(() {
            _previewUrl = path;
          });
          _applyAvatar(path);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.neonLime,
                content: Text(
                  'File picture selected for ${GameStateManager.instance.playerName}!',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text(
              'Could not load selected file: $e',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isShortHeight = screenSize.height < 520;
    final dialogWidth = math.min(screenSize.width * 0.94, 520.0);
    final dialogHeight = math.min(screenSize.height * 0.90, 680.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: dialogHeight,
          ),
          child: Material(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0E1525),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  _buildHeader(context, isShortHeight),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),

                  // ── Content Body ─────────────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: isShortHeight ? 10 : 16,
                      ),
                      child: widget.showChampions
                          ? _buildChampionsBody()
                          : _buildProfilePhotoBody(),
                    ),
                  ),

                  const Divider(color: AppTheme.surfaceBorder, height: 1),
                  // ── Footer ───────────────────────────────────────────────
                  _buildFooter(context, isShortHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isShortHeight) {
    final coins = GameStateManager.instance.coins;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isShortHeight ? 8 : 14,
      ),
      child: Row(
        children: [
          PlayerAvatarWidget(
            avatarId: _selectedAvatarId,
            size: isShortHeight ? 32 : 40,
            showBadge: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PLAYER PROFILE PICTURE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (widget.showChampions)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.trophyAmber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.trophyAmber.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              '$coins COINS',
                              style: const TextStyle(
                                color: AppTheme.trophyAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Unlock & equip champions',
                          style: TextStyle(
                            color: AppTheme.neonLime,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Custom photo & official league badges',
                    style: TextStyle(
                      color: AppTheme.neonLime,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CLEAN PROFILE PHOTO BODY (NO CHAMPIONS, NO AVATAR STUDIO)
  // ---------------------------------------------------------------------------
  Widget _buildProfilePhotoBody() {
    final playerName = GameStateManager.instance.playerName;
    final presetAvatars = PlayerAvatar.presetAvatars;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Profile Picture',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose a photo from your gallery or browse your local files for $playerName.',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 14),

        // Live Preview Box
        Center(
          child: Column(
            children: [
              PlayerAvatarWidget(
                avatarId: _previewUrl.isNotEmpty ? _previewUrl : _selectedAvatarId,
                size: 76,
                showBadge: true,
                showBorder: true,
                isSelected: true,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Text(
                  'Profile Picture: $playerName',
                  style: const TextStyle(color: AppTheme.neonLime, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Choose From Gallery and Browse Files 2D Buttons
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            if (isNarrow) {
              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Game2DButton(
                      key: const ValueKey('picker_gallery_btn'),
                      onPressed: _pickFromGallery,
                      text: 'CHOOSE FROM GALLERY',
                      icon: Icons.photo_library_rounded,
                      variant: GameButtonVariant.cyan,
                      size: GameButtonSize.small,
                      isFullWidth: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Game2DButton(
                      key: const ValueKey('picker_files_btn'),
                      onPressed: _pickFromFile,
                      text: 'BROWSE FILES',
                      icon: Icons.folder_open_rounded,
                      variant: GameButtonVariant.primary,
                      size: GameButtonSize.small,
                      isFullWidth: true,
                    ),
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(
                    child: Game2DButton(
                      key: const ValueKey('picker_gallery_btn'),
                      onPressed: _pickFromGallery,
                      text: 'CHOOSE FROM GALLERY',
                      icon: Icons.photo_library_rounded,
                      variant: GameButtonVariant.cyan,
                      size: GameButtonSize.small,
                      isFullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Game2DButton(
                      key: const ValueKey('picker_files_btn'),
                      onPressed: _pickFromFile,
                      text: 'BROWSE FILES',
                      icon: Icons.folder_open_rounded,
                      variant: GameButtonVariant.primary,
                      size: GameButtonSize.small,
                      isFullWidth: true,
                    ),
                  ),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white70),
            label: const Text(
              'REVERT TO DEFAULT AVATAR',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              _applyAvatar('alex_classic');
              setState(() {
                _previewUrl = 'alex_classic';
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.surfaceBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        const SizedBox(height: 22),
        const Text(
          'League Badges & Profile Avatars',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Official Smash League icon badges for your player card',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: presetAvatars.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) {
            final av = presetAvatars[index];
            final isSelected = _selectedAvatarId == av.id;

            return InkWell(
              onTap: () => _applyAvatar(av.id),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.neonLime.withValues(alpha: 0.15) : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppTheme.neonLime : AppTheme.surfaceBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    PlayerAvatarWidget(
                      avatar: av,
                      size: 40,
                      showBadge: true,
                      isSelected: isSelected,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  av.name,
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.neonLime : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle_rounded, color: AppTheme.neonLime, size: 12),
                              ],
                            ],
                          ),
                          Text(
                            av.title,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CHAMPIONS BODY (AVAILABLE WHEN showChampions: true)
  // ---------------------------------------------------------------------------
  Widget _buildChampionsBody() {
    final state = GameStateManager.instance;
    final champions = CharacterRoster.allCharacters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Court Champions (Buy & Sell)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.trophyAmber.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.trophyAmber.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${state.coins}',
                    style: const TextStyle(
                      color: AppTheme.trophyAmber,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Purchase or resell champions using match coins. Equipped champion enters match court.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 12),

        // Featured Active Champion Showcase matching Dashboard & Pre-Match style
        Center(
          child: DashboardCharacterCardFeature(
            character: CharacterRoster.getById(_selectedAvatarId),
            height: 155,
            showBadge: true,
            showSwapIcon: true,
            onBadgeTap: () {
              final all = CharacterRoster.allCharacters;
              final current = CharacterRoster.getById(_selectedAvatarId);
              final idx = all.indexWhere((c) => c.id == current.id);
              final next = all[(idx + 1) % all.length];
              if (state.isCharacterUnlocked(next.id) || next.isDefaultUnlocked) {
                _applyAvatar(next.id);
              }
              AudioService.instance.playButtonTap();
            },
            showSpotlight: true,
            showCharacterSwitcher: true,
            showActionControls: true,
            onGenderChanged: (newGender) {
              final targetChar = CharacterRoster.getByType(AnimatedCharacterDisplay.typeFromGender(newGender));
              if (state.isCharacterUnlocked(targetChar.id) || targetChar.isDefaultUnlocked) {
                _applyAvatar(targetChar.id);
              }
            },
          ),
        ),
        const SizedBox(height: 14),

        // Champion Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: champions.length,
          separatorBuilder: (_, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final char = champions[index];
            final isUnlocked = state.isCharacterUnlocked(char.id);
            final isEquipped = _selectedAvatarId == char.id;

            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isEquipped
                    ? AppTheme.neonLime.withValues(alpha: 0.12)
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isEquipped
                      ? AppTheme.neonLime
                      : (isUnlocked ? AppTheme.surfaceBorder : Colors.white12),
                  width: isEquipped ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      if (isUnlocked) {
                        _applyAvatar(char.id);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: char.gradientColors),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isEquipped ? AppTheme.neonLime : char.borderColor,
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ReadyToServeCharacterWidget(
                              character: char,
                              action: 'idle',
                              size: 44,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      char.name,
                                      style: TextStyle(
                                        color: isEquipped ? AppTheme.neonLime : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isUnlocked
                                          ? (isEquipped
                                              ? AppTheme.neonLime.withValues(alpha: 0.25)
                                              : Colors.cyan.withValues(alpha: 0.2))
                                          : Colors.amber.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: isUnlocked
                                            ? (isEquipped ? AppTheme.neonLime : Colors.cyanAccent)
                                            : AppTheme.trophyAmber,
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      isUnlocked
                                          ? (isEquipped ? 'EQUIPPED' : 'OWNED')
                                          : 'LOCKED',
                                      style: TextStyle(
                                        color: isUnlocked
                                            ? (isEquipped ? AppTheme.neonLime : Colors.cyanAccent)
                                            : AppTheme.trophyAmber,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${char.title} • ${char.badge}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                char.description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),
                  const SizedBox(height: 8),

                  // Actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isUnlocked) ...[
                        Text(
                          'Price: 🪙${char.price}',
                          style: const TextStyle(
                            color: AppTheme.trophyAmber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.trophyAmber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.shopping_cart_rounded, size: 14),
                            label: Text(
                              'BUY (🪙${char.price})',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                            onPressed: () {
                              if (state.coins < char.price) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFFDC2626),
                                    content: Text(
                                      '⚠️ Insufficient coins! Need 🪙${char.price} (You have 🪙${state.coins}). Win matches to earn more!',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }
                              final success = state.purchaseCharacter(char.id);
                              if (success) {
                                _applyAvatar(char.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.neonLime,
                                    content: Text(
                                      '🎉 Unlocked and equipped ${char.name}!',
                                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ] else ...[
                        if (char.isPurchasable)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              height: 32,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFF87171),
                                  side: const BorderSide(color: Color(0xFFF87171)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.monetization_on_outlined, size: 14),
                                label: Text(
                                  'SELL (+🪙${char.sellRefund})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                                onPressed: () {
                                  _showSellConfirmationDialog(char);
                                },
                              ),
                            ),
                          ),
                        if (isEquipped)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.neonLime.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppTheme.neonLime, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'CURRENTLY EQUIPPED',
                                  style: TextStyle(
                                    color: AppTheme.neonLime,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 32,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.neonLime,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 14),
                              label: const Text(
                                'EQUIP',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                              onPressed: () {
                                _applyAvatar(char.id);
                              },
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSellConfirmationDialog(CharacterInfo char) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.monetization_on_rounded, color: AppTheme.trophyAmber, size: 24),
            const SizedBox(width: 8),
            Text(
              'Sell ${char.name}?',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to sell ${char.name}?',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.trophyAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.trophyAmber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REFUND VALUE',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '+${char.sellRefund} Coins',
                          style: const TextStyle(color: AppTheme.trophyAmber, fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can purchase this character again anytime from the Champions roster.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              final state = GameStateManager.instance;
              final ok = state.sellCharacter(char.id);
              if (ok) {
                _applyAvatar(state.playerAvatarId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.trophyAmber,
                      content: Text(
                        '🪙 Sold ${char.name} for 🪙${char.sellRefund} coins!',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('CONFIRM SALE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isShortHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isShortHeight ? 8 : 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Game2DButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              text: 'DONE',
              icon: Icons.check_rounded,
              variant: GameButtonVariant.cyan,
              size: isShortHeight ? GameButtonSize.small : GameButtonSize.medium,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}
