import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/game_settings.dart';
import '../../models/player_avatar.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_picker_dialog.dart';
import '../../widgets/game_2d_button.dart';
import '../../widgets/player_avatar.dart';

class InGameSettingsModal extends StatefulWidget {
  final ValueChanged<GameSettings>? onSettingsChanged;
  final VoidCallback onResume;

  const InGameSettingsModal({
    super.key,
    this.onSettingsChanged,
    required this.onResume,
  });

  static Future<void> show(
    BuildContext context, {
    ValueChanged<GameSettings>? onSettingsChanged,
    required VoidCallback onResume,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => InGameSettingsModal(
        onSettingsChanged: onSettingsChanged,
        onResume: onResume,
      ),
    );
  }

  @override
  State<InGameSettingsModal> createState() => _InGameSettingsModalState();
}

class _InGameSettingsModalState extends State<InGameSettingsModal> {
  String _activeTab = 'graphics'; // 'graphics', 'audio', 'controls', 'avatar'

  void _update(GameSettings newSettings) {
    GameStateManager.instance.updateSettings(newSettings);
    widget.onSettingsChanged?.call(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateManager.instance;
    final screenSize = MediaQuery.sizeOf(context);
    final isShortHeight = screenSize.height < 520;
    final dialogWidth = math.min(screenSize.width * 0.95, 520.0);
    final dialogHeight = math.min(screenSize.height * 0.92, 680.0);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final settings = state.settings;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: isShortHeight ? 6 : 14,
          ),
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
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      _buildHeader(context, state, isShortHeight),
                      const Divider(color: AppTheme.surfaceBorder, height: 1),

                      // Navigation Tabs
                      _buildTabs(isShortHeight),
                      const Divider(color: AppTheme.surfaceBorder, height: 1),

                      // Tab Body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: isShortHeight ? 10 : 14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_activeTab == 'graphics')
                                _buildGraphicsSettings(settings)
                              else if (_activeTab == 'audio')
                                _buildAudioSettings(settings)
                              else if (_activeTab == 'controls')
                                _buildControllerSettings(settings)
                              else if (_activeTab == 'avatar')
                                _buildAvatarSettings(state),
                            ],
                          ),
                        ),
                      ),

                      const Divider(color: AppTheme.surfaceBorder, height: 1),
                      // Footer Actions
                      _buildFooter(context, isShortHeight),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, GameStateManager state, bool isShortHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isShortHeight ? 8 : 12,
      ),
      child: Row(
        children: [
          // Player Avatar in In-Game Header
          PlayerAvatarWidget(
            avatarId: state.playerAvatarId,
            size: isShortHeight ? 32 : 38,
            showBadge: true,
            onTap: () => AvatarPickerDialog.show(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'IN-GAME SETTINGS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.neonLime.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppTheme.neonLime,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${state.playerName} • Instant Match Adjustments',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TABS
  // ---------------------------------------------------------------------------
  Widget _buildTabs(bool isShortHeight) {
    final tabs = [
      {'id': 'graphics', 'label': 'GRAPHICS', 'icon': Icons.auto_awesome_rounded},
      {'id': 'audio', 'label': 'AUDIO', 'icon': Icons.volume_up_rounded},
      {'id': 'controls', 'label': 'CONTROLS', 'icon': Icons.gamepad_rounded},
      {'id': 'avatar', 'label': 'AVATAR', 'icon': Icons.account_circle_rounded},
    ];

    return Container(
      color: AppTheme.surfaceLight.withValues(alpha: 0.4),
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isShortHeight ? 4 : 6,
      ),
      child: Row(
        children: tabs.map((tab) {
          final id = tab['id'] as String;
          final label = tab['label'] as String;
          final icon = tab['icon'] as IconData;
          final isSelected = _activeTab == id;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _activeTab = id;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: isShortHeight ? 6 : 8),
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
                          size: 13,
                          color: isSelected ? Colors.black : Colors.white70,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
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
  // GRAPHICS SETTINGS
  // ---------------------------------------------------------------------------
  Widget _buildGraphicsSettings(GameSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quality Presets
        const Text('Quality Preset', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Low', 'Medium', 'High', 'Ultra'].map((p) {
              final isSel = settings.graphicsQuality == p;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(p, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? Colors.black : Colors.white)),
                  selected: isSel,
                  selectedColor: AppTheme.electricCyan,
                  backgroundColor: AppTheme.surfaceLight,
                  onSelected: (_) {
                    if (p == 'Low') {
                      _update(settings.copyWith(graphicsQuality: p, targetFps: 30, particlesEnabled: false, shadowsEnabled: false, screenShakeEnabled: false));
                    } else if (p == 'Medium') {
                      _update(settings.copyWith(graphicsQuality: p, targetFps: 60, particlesEnabled: true, shadowsEnabled: false, screenShakeEnabled: true));
                    } else if (p == 'High') {
                      _update(settings.copyWith(graphicsQuality: p, targetFps: 60, particlesEnabled: true, shadowsEnabled: true, screenShakeEnabled: true));
                    } else {
                      _update(settings.copyWith(graphicsQuality: p, targetFps: 120, particlesEnabled: true, shadowsEnabled: true, screenShakeEnabled: true));
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Target Framerate
        const Text('Target Framerate', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30 FPS')),
                ButtonSegment(value: 60, label: Text('60 FPS')),
                ButtonSegment(value: 120, label: Text('120 FPS')),
              ],
              selected: {settings.targetFps},
              onSelectionChanged: (val) {
                _update(settings.copyWith(targetFps: val.first));
              },
              style: _compactSegmentedStyle(),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Toggles
        SwitchListTile(
          title: const Text('Live FPS Counter', style: TextStyle(color: Colors.white, fontSize: 13)),
          subtitle: const Text('Real-time frame rate in HUD', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          value: settings.showFps,
          activeThumbColor: AppTheme.neonLime,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            _update(settings.copyWith(showFps: val));
          },
        ),
        SwitchListTile(
          title: const Text('Particle Effects', style: TextStyle(color: Colors.white, fontSize: 13)),
          subtitle: const Text('Sparks on smash and ball trails', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          value: settings.particlesEnabled,
          activeThumbColor: AppTheme.neonLime,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            _update(settings.copyWith(particlesEnabled: val));
          },
        ),
        SwitchListTile(
          title: const Text('Screen Shake', style: TextStyle(color: Colors.white, fontSize: 13)),
          subtitle: const Text('Camera kick on power smash hits', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          value: settings.screenShakeEnabled,
          activeThumbColor: AppTheme.neonLime,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) {
            _update(settings.copyWith(screenShakeEnabled: val));
          },
        ),
        const SizedBox(height: 12),

        // Court Theme
        const Text('Court Theme Style', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            {'name': 'Classic Green', 'color': const Color(0xFF2E7D32)},
            {'name': 'Electric Blue', 'color': const Color(0xFF0288D1)},
            {'name': 'Sunset Clay', 'color': const Color(0xFFD84315)},
            {'name': 'Neon Night', 'color': const Color(0xFF6A1B9A)},
          ].map((theme) {
            final name = theme['name'] as String;
            final color = theme['color'] as Color;
            final isSel = settings.courtTheme == name;

            return InkWell(
              onTap: () {
                _update(settings.copyWith(courtTheme: name));
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSel ? color.withValues(alpha: 0.35) : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSel ? color : AppTheme.surfaceBorder, width: isSel ? 2 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(name, style: TextStyle(color: isSel ? Colors.white : AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // AUDIO SETTINGS
  // ---------------------------------------------------------------------------
  Widget _buildAudioSettings(GameSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Master Volume
        Row(
          children: [
            Icon(settings.masterVolume <= 0.01 ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: AppTheme.neonLime, size: 18),
            const SizedBox(width: 8),
            const Expanded(child: Text('Master Volume', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('${(settings.masterVolume * 100).round()}%', style: const TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        Slider(
          value: settings.masterVolume,
          min: 0.0,
          max: 1.0,
          activeColor: AppTheme.neonLime,
          inactiveColor: AppTheme.surfaceLight,
          onChanged: (val) {
            _update(settings.copyWith(masterVolume: val));
          },
        ),
        const Divider(color: AppTheme.surfaceBorder, height: 16),

        // SFX
        Row(
          children: [
            const Expanded(child: Text('Sound Effects (SFX)', style: TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Switch(
              value: settings.sfxEnabled,
              activeThumbColor: AppTheme.neonLime,
              onChanged: (val) => _update(settings.copyWith(sfxEnabled: val)),
            ),
          ],
        ),
        if (settings.sfxEnabled)
          Slider(
            value: settings.soundVolume,
            min: 0.0,
            max: 1.0,
            activeColor: AppTheme.neonLime,
            inactiveColor: AppTheme.surfaceLight,
            onChanged: (val) => _update(settings.copyWith(soundVolume: val)),
          ),

        // Music
        Row(
          children: [
            const Expanded(child: Text('Music & Soundtrack', style: TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Switch(
              value: settings.musicEnabled,
              activeThumbColor: AppTheme.electricCyan,
              onChanged: (val) => _update(settings.copyWith(musicEnabled: val)),
            ),
          ],
        ),
        if (settings.musicEnabled)
          Slider(
            value: settings.musicVolume,
            min: 0.0,
            max: 1.0,
            activeColor: AppTheme.electricCyan,
            inactiveColor: AppTheme.surfaceLight,
            onChanged: (val) => _update(settings.copyWith(musicVolume: val)),
          ),

        // Crowd
        Row(
          children: [
            const Expanded(child: Text('Stadium Crowd & Cheers', style: TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Switch(
              value: settings.crowdEnabled,
              activeThumbColor: AppTheme.trophyAmber,
              onChanged: (val) => _update(settings.copyWith(crowdEnabled: val)),
            ),
          ],
        ),
        if (settings.crowdEnabled)
          Slider(
            value: settings.crowdVolume,
            min: 0.0,
            max: 1.0,
            activeColor: AppTheme.trophyAmber,
            inactiveColor: AppTheme.surfaceLight,
            onChanged: (val) => _update(settings.copyWith(crowdVolume: val)),
          ),

        // Haptics
        SwitchListTile(
          title: const Text('Haptic Vibration Feedback', style: TextStyle(color: Colors.white, fontSize: 13)),
          subtitle: const Text('Tactile pulses on hits and smashes', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          value: settings.hapticsEnabled,
          activeThumbColor: AppTheme.neonLime,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => _update(settings.copyWith(hapticsEnabled: val)),
        ),
        const SizedBox(height: 10),

        // Test Audio Button
        Center(
          child: Game2DButton(
            onPressed: () async {
              await AudioService.instance.playTestAudio();
            },
            text: 'TEST AUDIO & HAPTICS',
            icon: Icons.graphic_eq_rounded,
            variant: GameButtonVariant.primary,
            size: GameButtonSize.small,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CONTROLLER SETTINGS
  // ---------------------------------------------------------------------------
  Widget _buildControllerSettings(GameSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handedness
        const Text('Joystick Placement', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Left-Handed')),
                ButtonSegment(value: false, label: Text('Right-Handed')),
              ],
              selected: {settings.joystickOnLeft},
              onSelectionChanged: (val) => _update(settings.copyWith(joystickOnLeft: val.first)),
              style: _compactSegmentedStyle(),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Strike Button Size
        const Text('Strike Button Size', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Normal', label: Text('Normal')),
                ButtonSegment(value: 'Large', label: Text('Large')),
                ButtonSegment(value: 'Extra Large', label: Text('XL')),
              ],
              selected: {settings.buttonSize},
              onSelectionChanged: (val) => _update(settings.copyWith(buttonSize: val.first)),
              style: _compactSegmentedStyle(),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Sensitivity
        Row(
          children: [
            const Expanded(child: Text('Stick Sensitivity', style: TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('${(settings.joystickSensitivity * 100).round()}%', style: const TextStyle(color: AppTheme.trophyAmber, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        Slider(
          value: settings.joystickSensitivity,
          min: 0.5,
          max: 2.0,
          activeColor: AppTheme.trophyAmber,
          inactiveColor: AppTheme.surfaceLight,
          onChanged: (val) => _update(settings.copyWith(joystickSensitivity: val)),
        ),

        // Opacity
        Row(
          children: [
            const Expanded(child: Text('In-Game Controller Opacity', style: TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('${(settings.controllerOpacity * 100).round()}%', style: const TextStyle(color: AppTheme.electricCyan, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        Slider(
          value: settings.controllerOpacity,
          min: 0.2,
          max: 1.0,
          activeColor: AppTheme.electricCyan,
          inactiveColor: AppTheme.surfaceLight,
          onChanged: (val) => _update(settings.copyWith(controllerOpacity: val)),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // AVATAR SETTINGS
  // ---------------------------------------------------------------------------
  Widget _buildAvatarSettings(GameStateManager state) {
    final currentAvatar = PlayerAvatar.getById(state.playerAvatarId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Player Profile Picture',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Update your in-match profile picture and save directly to database',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 14),

        // Active Player Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Row(
            children: [
              PlayerAvatarWidget(
                avatarId: state.playerAvatarId,
                size: 50,
                showBadge: true,
                showBorder: true,
                isSelected: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.playerName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentAvatar.name,
                      style: const TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w600, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      currentAvatar.title,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Quick Pick Presets
        const Text('Quick Select Avatar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlayerAvatar.presetAvatars.take(6).map((av) {
            final isSel = state.playerAvatarId == av.id;
            return InkWell(
              onTap: () {
                state.updatePlayerAvatar(av.id);
                AudioService.instance.playPaddleHit();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSel ? AppTheme.neonLime : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: PlayerAvatarWidget(
                  avatar: av,
                  size: 40,
                  showBadge: true,
                  isSelected: isSel,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Custom Photo / Full Picker button
        SizedBox(
          width: double.infinity,
          child: Game2DButton(
            onPressed: () {
              AvatarPickerDialog.show(context);
            },
            text: 'ADD OWN PHOTO / CUSTOM STUDIO',
            icon: Icons.add_a_photo_rounded,
            variant: GameButtonVariant.primary,
            size: GameButtonSize.small,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER
  // ---------------------------------------------------------------------------
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
                widget.onResume();
              },
              text: 'RESUME MATCH',
              icon: Icons.play_arrow_rounded,
              variant: GameButtonVariant.primary,
              size: isShortHeight ? GameButtonSize.small : GameButtonSize.medium,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _compactSegmentedStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTheme.neonLime;
        }
        return AppTheme.surfaceLight;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.black;
        }
        return Colors.white;
      }),
      textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
