import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/player_avatar.dart';
import '../services/audio_service.dart';
import '../services/game_state_manager.dart';
import '../theme/app_theme.dart';
import 'game_2d_button.dart';
import 'player_avatar.dart';

class AvatarPickerDialog extends StatefulWidget {
  const AvatarPickerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AvatarPickerDialog(),
    );
  }

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  int _activeTab = 0; // 0: Champions, 1: My Photo URL, 2: Avatar Studio
  late String _selectedAvatarId;

  // Custom photo tab controller
  final TextEditingController _urlController = TextEditingController();
  String _previewUrl = '';

  // Avatar Studio state
  final TextEditingController _initialsController = TextEditingController(text: 'SM');
  int _selectedColorIndex = 0;
  int _selectedIconIndex = 0;

  final List<IconData> _studioIcons = const [
    Icons.sports_tennis_rounded,
    Icons.bolt_rounded,
    Icons.star_rounded,
    Icons.local_fire_department_rounded,
    Icons.military_tech_rounded,
    Icons.rocket_launch_rounded,
    Icons.shield_rounded,
    Icons.auto_awesome_rounded,
  ];

  final List<List<Color>> _studioColors = const [
    [Color(0xFF2563EB), Color(0xFF1D4ED8)], // Electric Blue
    [Color(0xFF16A34A), Color(0xFF15803D)], // Neon Green
    [Color(0xFFDC2626), Color(0xFF991B1B)], // Fire Red
    [Color(0xFF7C3AED), Color(0xFF5B21B6)], // Cyber Purple
    [Color(0xFFD97706), Color(0xFFB45309)], // Gold Champion
    [Color(0xFF0D9488), Color(0xFF0F766E)], // Cyan Teal
    [Color(0xFFDB2777), Color(0xFF9D174D)], // Neon Pink
    [Color(0xFF090D16), Color(0xFF1E293B)], // Stealth Noir
  ];

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
      _activeTab = 1;
      _urlController.text = _selectedAvatarId;
      _previewUrl = _selectedAvatarId;
    } else if (_selectedAvatarId.startsWith('custom:')) {
      _activeTab = 2;
      final parts = _selectedAvatarId.split(':');
      if (parts.length > 1) _initialsController.text = parts[1];
      if (parts.length > 2) _selectedIconIndex = int.tryParse(parts[2]) ?? 0;
      if (parts.length > 3) _selectedColorIndex = int.tryParse(parts[3]) ?? 0;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _initialsController.dispose();
    super.dispose();
  }

  void _applyAvatar(String id) {
    setState(() {
      _selectedAvatarId = id;
    });
    GameStateManager.instance.updatePlayerAvatar(id);
    AudioService.instance.playPaddleHit();
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
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.surfaceBorder, width: 2),
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
                  // Header
                  _buildHeader(context, isShortHeight),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),

                  // Tabs
                  _buildTabs(),
                  const Divider(color: AppTheme.surfaceBorder, height: 1),

                  // Content Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: isShortHeight ? 10 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_activeTab == 0)
                            _buildPresetChampionsTab()
                          else if (_activeTab == 1)
                            _buildCustomPhotoTab()
                          else if (_activeTab == 2)
                            _buildStudioTab(),
                        ],
                      ),
                    ),
                  ),

                  const Divider(color: AppTheme.surfaceBorder, height: 1),
                  // Footer
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
                Text(
                  'Saved automatically to your database profile',
                  style: TextStyle(
                    color: AppTheme.neonLime.withValues(alpha: 0.9),
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

  Widget _buildTabs() {
    final tabs = [
      {'id': 0, 'label': 'CHAMPIONS', 'icon': Icons.stars_rounded},
      {'id': 1, 'label': 'PHOTO / GALLERY', 'icon': Icons.photo_library_rounded},
      {'id': 2, 'label': 'AVATAR STUDIO', 'icon': Icons.palette_rounded},
    ];

    return Container(
      color: AppTheme.surfaceLight.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: tabs.map((tab) {
          final idx = tab['id'] as int;
          final label = tab['label'] as String;
          final icon = tab['icon'] as IconData;
          final isSelected = _activeTab == idx;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _activeTab = idx;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.neonLime : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected ? Colors.black : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: PRESET CHAMPIONS
  // ---------------------------------------------------------------------------
  Widget _buildPresetChampionsTab() {
    final avatars = PlayerAvatar.presetAvatars;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pick Your Champion Avatar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose an official Smash League player profile picture',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: avatars.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) {
            final av = avatars[index];
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
                      size: 44,
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
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check_circle_rounded, color: AppTheme.neonLime, size: 14),
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
        _urlController.text = path;
        setState(() {
          _previewUrl = path;
        });
        _applyAvatar(path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.neonLime,
              content: Text(
                'Gallery picture selected and saved for ${GameStateManager.instance.playerName}!',
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
          _urlController.text = path;
          setState(() {
            _previewUrl = path;
          });
          _applyAvatar(path);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppTheme.neonLime,
                content: Text(
                  'File picture selected and saved for ${GameStateManager.instance.playerName}!',
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

  // ---------------------------------------------------------------------------
  // TAB 2: MY PHOTO / IMAGE URL / LOCAL FILE
  // ---------------------------------------------------------------------------
  Widget _buildCustomPhotoTab() {
    final playerName = GameStateManager.instance.playerName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Your Own Custom Profile Picture',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose a photo from your gallery, browse local files, or enter an image URL. Saved automatically to database for $playerName.',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 16),

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
                  'Profile Picture for: $playerName',
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
        const SizedBox(height: 16),

        // Divider with OR ENTER IMAGE URL
        Row(
          children: [
            const Expanded(child: Divider(color: AppTheme.surfaceBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'OR PASTE WEB URL / PATH',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppTheme.surfaceBorder)),
          ],
        ),
        const SizedBox(height: 14),

        // Input Field
        TextField(
          controller: _urlController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Image Web URL or File Path',
            hintText: 'https://example.com/my-photo.jpg or C:/images/me.png',
            labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
            prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.electricCyan, size: 20),
            filled: true,
            fillColor: AppTheme.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.neonLime, width: 2),
            ),
          ),
          onChanged: (val) {
            setState(() {
              _previewUrl = val.trim();
            });
          },
        ),
        const SizedBox(height: 12),

        // Example shortcuts
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildSampleChip('Pro Paddle', 'https://images.unsplash.com/photo-1599474924187-334a4ae5bd3c?w=150'),
            _buildSampleChip('Champion Gold', 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=150'),
            _buildSampleChip('Cyber Gamer', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
          ],
        ),
        const SizedBox(height: 16),

        // Save Button
        SizedBox(
          width: double.infinity,
          child: Game2DButton(
            key: const ValueKey('save_custom_photo_btn'),
            onPressed: () {
              final val = _urlController.text.trim();
              if (val.isNotEmpty) {
                _applyAvatar(val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.neonLime,
                    content: Text(
                      'Custom profile picture saved to database for $playerName!',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
            },
            text: 'SAVE THIS PROFILE PICTURE',
            icon: Icons.check_circle_rounded,
            variant: GameButtonVariant.primary,
            size: GameButtonSize.medium,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSampleChip(String label, String sampleUrl) {
    return ActionChip(
      avatar: const Icon(Icons.auto_awesome, size: 14, color: AppTheme.electricCyan),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      backgroundColor: AppTheme.surfaceLight,
      side: const BorderSide(color: AppTheme.surfaceBorder),
      onPressed: () {
        _urlController.text = sampleUrl;
        setState(() {
          _previewUrl = sampleUrl;
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: AVATAR STUDIO (CUSTOM INITIALS & PALETTE)
  // ---------------------------------------------------------------------------
  Widget _buildStudioTab() {
    final initials = _initialsController.text.trim().isEmpty ? 'SM' : _initialsController.text.trim().toUpperCase();
    final customPayload = 'custom:$initials:$_selectedIconIndex:$_selectedColorIndex';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Design Your Unique Avatar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Customize your badge initials, theme gradient, and signature icon',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 16),

        // Preview Box
        Center(
          child: Column(
            children: [
              PlayerAvatarWidget(
                avatarId: customPayload,
                size: 72,
                showBadge: true,
                isSelected: true,
              ),
              const SizedBox(height: 8),
              Text(
                'LIVE PREVIEW: $initials',
                style: const TextStyle(color: AppTheme.neonLime, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 1. Initials field
        TextField(
          controller: _initialsController,
          maxLength: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Player Initials (1-3 letters)',
            counterText: '',
            labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.neonLime, size: 20),
            filled: true,
            fillColor: AppTheme.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),

        // 2. Color Palette selector
        const Text('Color Gradient Theme', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_studioColors.length, (idx) {
            final isSel = _selectedColorIndex == idx;
            final colors = _studioColors[idx];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedColorIndex = idx;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel ? Colors.white : Colors.transparent,
                    width: isSel ? 2.5 : 1,
                  ),
                ),
                child: isSel ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 14),

        // 3. Signature Icon selector
        const Text('Signature Icon', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_studioIcons.length, (idx) {
            final isSel = _selectedIconIndex == idx;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedIconIndex = idx;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSel ? AppTheme.neonLime : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _studioIcons[idx],
                  color: isSel ? Colors.black : Colors.white,
                  size: 20,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Save studio avatar
        SizedBox(
          width: double.infinity,
          child: Game2DButton(
            onPressed: () {
              _applyAvatar(customPayload);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.neonLime,
                  content: Text(
                    'Created custom avatar for "$initials" & saved to database!',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            text: 'SAVE CUSTOM AVATAR',
            icon: Icons.palette_rounded,
            variant: GameButtonVariant.primary,
            size: GameButtonSize.medium,
            isFullWidth: true,
          ),
        ),
      ],
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

