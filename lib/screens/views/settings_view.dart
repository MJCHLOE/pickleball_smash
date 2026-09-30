import 'package:flutter/material.dart';
import '../../models/game_settings.dart';
import '../../services/audio_service.dart';
import '../../services/game_state_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_picker_dialog.dart';
import '../../widgets/game_2d_button.dart';
import '../../widgets/hud_controls_adjuster_modal.dart';
import '../../widgets/player_avatar.dart';
import '../auth/login_screen.dart';
import 'player_stats_modal.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _selectedCategory = 'all'; // 'all', 'graphics', 'audio', 'controls', 'account'

  @override
  Widget build(BuildContext context) {
    final state = GameStateManager.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final settings = state.settings;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 850;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 16),
                      _buildCategoryFilter(),
                      const SizedBox(height: 20),

                      if (_selectedCategory == 'all') ...[
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildAccountCard(context, state),
                                    const SizedBox(height: 16),
                                    _buildGraphicsCard(context, settings, state),
                                    const SizedBox(height: 16),
                                    _buildHelpAndAboutCard(context, state),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right column
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildAudioCard(context, settings, state),
                                    const SizedBox(height: 16),
                                    _buildControlsCard(context, settings, state),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildAccountCard(context, state),
                              const SizedBox(height: 16),
                              _buildGraphicsCard(context, settings, state),
                              const SizedBox(height: 16),
                              _buildAudioCard(context, settings, state),
                              const SizedBox(height: 16),
                              _buildControlsCard(context, settings, state),
                              const SizedBox(height: 16),
                              _buildHelpAndAboutCard(context, state),
                            ],
                          ),
                      ] else if (_selectedCategory == 'graphics') ...[
                        _buildGraphicsCard(context, settings, state),
                      ] else if (_selectedCategory == 'audio') ...[
                        _buildAudioCard(context, settings, state),
                      ] else if (_selectedCategory == 'controls') ...[
                        _buildControlsCard(context, settings, state),
                      ] else if (_selectedCategory == 'account') ...[
                        _buildAccountCard(context, state),
                        const SizedBox(height: 16),
                        _buildHelpAndAboutCard(context, state),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: const Icon(Icons.tune_rounded, color: AppTheme.neonLime, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Game Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Adjust graphics quality, audio volume, and custom controls',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORY FILTER CHIPS
  // ---------------------------------------------------------------------------
  Widget _buildCategoryFilter() {
    final categories = [
      {'id': 'all', 'label': 'All Settings', 'icon': Icons.dashboard_customize_rounded},
      {'id': 'graphics', 'label': 'Graphics', 'icon': Icons.auto_awesome_rounded},
      {'id': 'audio', 'label': 'Audio', 'icon': Icons.volume_up_rounded},
      {'id': 'controls', 'label': 'Controls', 'icon': Icons.gamepad_rounded},
      {'id': 'account', 'label': 'Account', 'icon': Icons.manage_accounts_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final id = cat['id'] as String;
          final label = cat['label'] as String;
          final icon = cat['icon'] as IconData;
          final isSelected = _selectedCategory == id;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black : AppTheme.textMuted,
              ),
              label: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.neonLime,
              backgroundColor: AppTheme.surfaceLight,
              side: BorderSide(
                color: isSelected ? AppTheme.neonLime : AppTheme.surfaceBorder,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = id;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GRAPHICS ADJUSTER CARD
  // ---------------------------------------------------------------------------
  Widget _buildGraphicsCard(BuildContext context, GameSettings settings, GameStateManager state) {
    return _buildCardWrapper(
      icon: Icons.auto_awesome_rounded,
      title: 'Graphics & Visual Adjuster',
      subtitle: 'Fine-tune render fidelity, court themes, and visual effects',
      accentColor: AppTheme.electricCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Graphics Quality Preset
          const Text(
            'Quality Preset',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Low', 'Medium', 'High', 'Ultra'].map((preset) {
                final isSelected = settings.graphicsQuality == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      _applyQualityPreset(preset, settings, state);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.electricCyan : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.electricCyan : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Text(
                        preset,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Target Framerate
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Target Framerate', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Performance mode & battery optimization', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 30, label: Text('30 FPS')),
                    ButtonSegment(value: 60, label: Text('60 FPS')),
                    ButtonSegment(value: 120, label: Text('120 FPS')),
                  ],
                  selected: {settings.targetFps},
                  onSelectionChanged: (selection) {
                    state.updateSettings(settings.copyWith(targetFps: selection.first));
                  },
                  style: _segmentedButtonStyle(),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.surfaceBorder, height: 24),

          // 3. Visual FX Toggles
          SwitchListTile(
            title: const Text('Particle & Hit Effects', style: TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: const Text('Sparks on smash and ball trail speed effects', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            value: settings.particlesEnabled,
            activeThumbColor: AppTheme.neonLime,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              state.updateSettings(settings.copyWith(particlesEnabled: val));
            },
          ),
          SwitchListTile(
            title: const Text('Dynamic Shadows', style: TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: const Text('Ball and player drop shadows on court floor', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            value: settings.shadowsEnabled,
            activeThumbColor: AppTheme.neonLime,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              state.updateSettings(settings.copyWith(shadowsEnabled: val));
            },
          ),
          SwitchListTile(
            title: const Text('Screen Shake on Smash', style: TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: const Text('Subtle camera kick for satisfying smash impacts', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            value: settings.screenShakeEnabled,
            activeThumbColor: AppTheme.neonLime,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              state.updateSettings(settings.copyWith(screenShakeEnabled: val));
            },
          ),
          SwitchListTile(
            title: const Text('Show Live FPS Counter', style: TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: const Text('Displays real-time frame rate in gameplay HUD', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            value: settings.showFps,
            activeThumbColor: AppTheme.neonLime,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              state.updateSettings(settings.copyWith(showFps: val));
            },
          ),
          const Divider(color: AppTheme.surfaceBorder, height: 24),

          // 4. Court Theme & Live Preview
          const Text(
            'Court Theme & Arena Style',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildCourtThemeSelector(settings, state),
          const SizedBox(height: 14),

          // Court Brightness slider
          Row(
            children: [
              const Text('Arena Lighting', style: TextStyle(color: Colors.white, fontSize: 13)),
              const Spacer(),
              Text(
                '${(settings.courtBrightness * 100).round()}%',
                style: const TextStyle(color: AppTheme.electricCyan, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          Slider(
            value: settings.courtBrightness,
            min: 0.6,
            max: 1.4,
            activeColor: AppTheme.electricCyan,
            inactiveColor: AppTheme.surfaceLight,
            onChanged: (val) {
              state.updateSettings(settings.copyWith(courtBrightness: val));
            },
          ),
          const SizedBox(height: 8),

          // Live Court Miniature Preview
          _buildCourtLivePreview(settings),
        ],
      ),
    );
  }

  void _applyQualityPreset(String preset, GameSettings settings, GameStateManager state) {
    switch (preset) {
      case 'Low':
        state.updateSettings(settings.copyWith(
          graphicsQuality: 'Low',
          targetFps: 30,
          particlesEnabled: false,
          shadowsEnabled: false,
          screenShakeEnabled: false,
        ));
        break;
      case 'Medium':
        state.updateSettings(settings.copyWith(
          graphicsQuality: 'Medium',
          targetFps: 60,
          particlesEnabled: true,
          shadowsEnabled: false,
          screenShakeEnabled: true,
        ));
        break;
      case 'High':
        state.updateSettings(settings.copyWith(
          graphicsQuality: 'High',
          targetFps: 60,
          particlesEnabled: true,
          shadowsEnabled: true,
          screenShakeEnabled: true,
        ));
        break;
      case 'Ultra':
        state.updateSettings(settings.copyWith(
          graphicsQuality: 'Ultra',
          targetFps: 120,
          particlesEnabled: true,
          shadowsEnabled: true,
          screenShakeEnabled: true,
        ));
        break;
    }
  }

  Widget _buildCourtThemeSelector(GameSettings settings, GameStateManager state) {
    final themes = [
      {'name': 'Classic Green', 'color': const Color(0xFF2E7D32)},
      {'name': 'Electric Blue', 'color': const Color(0xFF0288D1)},
      {'name': 'Sunset Clay', 'color': const Color(0xFFD84315)},
      {'name': 'Neon Night', 'color': const Color(0xFF6A1B9A)},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: themes.map((t) {
        final name = t['name'] as String;
        final color = t['color'] as Color;
        final isSelected = settings.courtTheme == name;

        return InkWell(
          onTap: () {
            state.updateSettings(settings.copyWith(courtTheme: name));
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.35) : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : AppTheme.surfaceBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourtLivePreview(GameSettings settings) {
    Color courtColor;
    switch (settings.courtTheme) {
      case 'Electric Blue':
        courtColor = const Color(0xFF0F3854);
        break;
      case 'Sunset Clay':
        courtColor = const Color(0xFF5E2718);
        break;
      case 'Neon Night':
        courtColor = const Color(0xFF33144A);
        break;
      default:
        courtColor = const Color(0xFF1B4D2E);
        break;
    }

    final double brightness = settings.courtBrightness;

    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color.lerp(courtColor, Colors.white, (brightness - 1.0) * 0.3) ?? courtColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Court white lines
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white54, width: 1.5),
            ),
          ),
          // Center net
          Container(
            height: 2,
            width: double.infinity,
            color: Colors.white,
          ),
          // Preview badge
          Positioned(
            bottom: 6,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'PREVIEW: ${settings.courtTheme.toUpperCase()} • ${settings.targetFps} FPS',
                style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Ball dot
          Positioned(
            top: 24,
            left: 80,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF76FF03),
                shape: BoxShape.circle,
                boxShadow: settings.shadowsEnabled
                    ? [
                        const BoxShadow(
                          color: Colors.black45,
                          offset: Offset(2, 3),
                          blurRadius: 3,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AUDIO ADJUSTER CARD
  // ---------------------------------------------------------------------------
  Widget _buildAudioCard(BuildContext context, GameSettings settings, GameStateManager state) {
    return _buildCardWrapper(
      icon: Icons.volume_up_rounded,
      title: 'Audio & Sound Effects',
      subtitle: 'Master volume, sound effects, ambience, and tactile haptics',
      accentColor: AppTheme.neonLime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Master Volume
          Row(
            children: [
              Icon(
                settings.masterVolume <= 0.01 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: AppTheme.neonLime,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Master Volume', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
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
              state.updateSettings(settings.copyWith(masterVolume: val));
            },
          ),
          const Divider(color: AppTheme.surfaceBorder, height: 20),

          // 2. Sound Effects (SFX) Volume & Toggle
          Row(
            children: [
              const Expanded(
                child: Text('Sound Effects (SFX)', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              Switch(
                value: settings.sfxEnabled,
                activeThumbColor: AppTheme.neonLime,
                onChanged: (val) {
                  state.updateSettings(settings.copyWith(sfxEnabled: val));
                },
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
              onChanged: (val) {
                state.updateSettings(settings.copyWith(soundVolume: val));
              },
            ),

          // 3. Music & Ambience Volume & Toggle
          Row(
            children: [
              const Expanded(
                child: Text('Music & Soundtrack', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              Switch(
                value: settings.musicEnabled,
                activeThumbColor: AppTheme.electricCyan,
                onChanged: (val) {
                  state.updateSettings(settings.copyWith(musicEnabled: val));
                },
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
              onChanged: (val) {
                state.updateSettings(settings.copyWith(musicVolume: val));
              },
            ),

          // 4. Stadium Crowd & Cheers
          Row(
            children: [
              const Expanded(
                child: Text('Stadium Crowd & Cheers', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              Switch(
                value: settings.crowdEnabled,
                activeThumbColor: AppTheme.trophyAmber,
                onChanged: (val) {
                  state.updateSettings(settings.copyWith(crowdEnabled: val));
                },
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
              onChanged: (val) {
                state.updateSettings(settings.copyWith(crowdVolume: val));
              },
            ),

          // 5. Haptic Feedback Vibration
          SwitchListTile(
            title: const Text('Haptic Vibration Feedback', style: TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: const Text('Tactile controller pulses on ball strikes and smashes', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            value: settings.hapticsEnabled,
            activeThumbColor: AppTheme.neonLime,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              state.updateSettings(settings.copyWith(hapticsEnabled: val));
            },
          ),
          const SizedBox(height: 12),

          // Interactive Test Audio Button
          Center(
            child: Game2DButton(
              onPressed: () async {
                await AudioService.instance.playTestAudio();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.volume_up, color: AppTheme.neonLime, size: 18),
                          SizedBox(width: 8),
                          Text('Audio & Haptic Test triggered!'),
                        ],
                      ),
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppTheme.surfaceLight,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              text: 'TEST AUDIO & HAPTICS',
              icon: Icons.graphic_eq_rounded,
              variant: GameButtonVariant.primary,
              size: GameButtonSize.medium,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTROLLER ADJUSTER CARD
  // ---------------------------------------------------------------------------
  Widget _buildControlsCard(BuildContext context, GameSettings settings, GameStateManager state) {
    return _buildCardWrapper(
      icon: Icons.gamepad_rounded,
      title: 'Controls & Movement',
      subtitle: 'Joystick placement, stick sensitivity, button sizing, and opacity',
      accentColor: AppTheme.trophyAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // On-Screen HUD Adjuster Quick Launch
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonLime.withValues(alpha: 0.18),
                  AppTheme.electricCyan.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.5)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.neonLime.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.gamepad_rounded, color: AppTheme.neonLime, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('On-Screen HUD Adjuster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                Text('Live preview, presets & custom controls', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Game2DButton(
                        text: 'CUSTOMIZE HUD & SKILLS',
                        size: GameButtonSize.small,
                        variant: GameButtonVariant.primary,
                        isFullWidth: true,
                        onPressed: () {
                          HudControlsAdjusterModal.show(context);
                        },
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.neonLime.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.gamepad_rounded, color: AppTheme.neonLime, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('On-Screen HUD & Skills Adjuster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Live screen preview, custom layout presets, button sizes & spacing', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Game2DButton(
                      text: 'CUSTOMIZE HUD',
                      size: GameButtonSize.small,
                      variant: GameButtonVariant.primary,
                      onPressed: () {
                        HudControlsAdjusterModal.show(context);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 1. Control Scheme
          const Text('Control Scheme', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                {'id': 'joystick', 'label': 'Virtual Joystick', 'icon': Icons.radio_button_checked_rounded},
                {'id': 'dpad', 'label': 'Arcade D-Pad', 'icon': Icons.control_camera_rounded},
                {'id': 'drag', 'label': 'Touch & Drag', 'icon': Icons.touch_app_rounded},
              ].map((scheme) {
                final id = scheme['id'] as String;
                final label = scheme['label'] as String;
                final icon = scheme['icon'] as IconData;
                final isSelected = settings.controlScheme == id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      state.updateSettings(settings.copyWith(controlScheme: id));
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.trophyAmber : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.trophyAmber : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Joystick Side (Handedness)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Joystick Side', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Preferred thumb placement', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Left-Handed')),
                    ButtonSegment(value: false, label: Text('Right-Handed')),
                  ],
                  selected: {settings.joystickOnLeft},
                  onSelectionChanged: (selection) {
                    state.updateSettings(settings.copyWith(joystickOnLeft: selection.first));
                  },
                  style: _segmentedButtonStyle(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Strike Button Size
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Strike Button Size', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Radius of smash button', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Normal', label: Text('Normal')),
                    ButtonSegment(value: 'Large', label: Text('Large')),
                    ButtonSegment(value: 'Extra Large', label: Text('XL')),
                  ],
                  selected: {settings.buttonSize},
                  onSelectionChanged: (selection) {
                    state.updateSettings(settings.copyWith(buttonSize: selection.first));
                  },
                  style: _segmentedButtonStyle(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4. Joystick Expand
          Row(
            children: [
              const Expanded(
                child: Text('Joystick Expand (Size)', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              Text('${(settings.joystickExpand * 100).round()}%', style: const TextStyle(color: AppTheme.trophyAmber, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          Slider(
            value: settings.joystickExpand,
            min: 0.7,
            max: 1.6,
            divisions: 9,
            activeColor: AppTheme.trophyAmber,
            inactiveColor: AppTheme.surfaceLight,
            onChanged: (val) {
              state.updateSettings(settings.copyWith(joystickExpand: val));
            },
          ),

          // 5. Transparent Capacity
          Row(
            children: [
              const Expanded(
                child: Text('Transparent Capacity', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              Text('${(settings.transparentCapacity * 100).round()}%', style: const TextStyle(color: AppTheme.electricCyan, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          Slider(
            value: settings.transparentCapacity,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            activeColor: AppTheme.electricCyan,
            inactiveColor: AppTheme.surfaceLight,
            onChanged: (val) {
              state.updateSettings(settings.copyWith(transparentCapacity: val));
            },
          ),
          const SizedBox(height: 6),

          // 6. Joystick Color Choices
          const Text('Joystick Color', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Neon Lime',
              'Electric Cyan',
              'Hot Pink',
              'Trophy Gold',
              'Pure White',
            ].map((colorName) {
              final isSelected = settings.joystickColor == colorName;
              final colorVal = _getColorValue(colorName);
              return InkWell(
                onTap: () => state.updateSettings(settings.copyWith(joystickColor: colorName)),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colorVal.withValues(alpha: 0.25) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? colorVal : AppTheme.surfaceBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorVal,
                          shape: BoxShape.circle,
                          boxShadow: isSelected ? [BoxShadow(color: colorVal.withValues(alpha: 0.6), blurRadius: 4)] : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        colorName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textMuted,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Auto-Serve Switch
          SwitchListTile(
            title: const Text('Auto-Serve Assistant', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Automatically serves when ready so play never stalls or freezes', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            value: settings.autoServe,
            activeThumbColor: AppTheme.electricCyan,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => state.updateSettings(settings.copyWith(autoServe: val)),
          ),
          const SizedBox(height: 14),

          // AI Bot Difficulty
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI Bot Difficulty', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Adjust bot reaction speed, dash frequency, and spin technique counters', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<AIDifficulty>(
                  segments: const [
                    ButtonSegment(value: AIDifficulty.easy, label: Text('Easy')),
                    ButtonSegment(value: AIDifficulty.normal, label: Text('Normal')),
                    ButtonSegment(value: AIDifficulty.hard, label: Text('Hard')),
                    ButtonSegment(value: AIDifficulty.extreme, label: Text('Extreme')),
                  ],
                  selected: {settings.aiDifficulty},
                  onSelectionChanged: (selection) {
                    state.updateSettings(settings.copyWith(aiDifficulty: selection.first));
                  },
                  style: _segmentedButtonStyle(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Interactive Controller Preview Box
          _buildControllerLivePreview(settings),

          const Divider(color: AppTheme.surfaceBorder, height: 24),
          // Keyboard & Desktop Cheat Sheet
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.keyboard_rounded, color: AppTheme.neonLime, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Keyboard & Desktop Controls:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text('• WASD or Arrow Keys: Run across court', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                Text('• Spacebar / Left Click: Smash & Strike ball', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControllerLivePreview(GameSettings settings) {
    final opacity = settings.transparentCapacity;
    final expand = settings.joystickExpand;
    final colorChoice = settings.joystickColor;
    final isLeft = settings.joystickOnLeft;

    double buttonRadius = 24.0;
    if (settings.buttonSize == 'Large') buttonRadius = 28.0;
    if (settings.buttonSize == 'Extra Large') buttonRadius = 32.0;

    return Container(
      height: 90,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isLeft) ...[
            _buildMiniJoystick(opacity, expand, colorChoice),
            _buildMiniStrikeButton(opacity, buttonRadius),
          ] else ...[
            _buildMiniStrikeButton(opacity, buttonRadius),
            _buildMiniJoystick(opacity, expand, colorChoice),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniJoystick(double opacity, double expand, String colorChoice) {
    final colorVal = _getColorValue(colorChoice);
    final size = (56.0 * expand.clamp(0.7, 1.4)).clamp(38.0, 75.0);
    final knobSize = (24.0 * expand.clamp(0.7, 1.4)).clamp(16.0, 32.0);
    return Opacity(
      opacity: opacity.clamp(0.1, 1.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorVal.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: colorVal, width: 1.5),
        ),
        child: Center(
          child: Container(
            width: knobSize,
            height: knobSize,
            decoration: BoxDecoration(
              color: colorVal,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorValue(String colorName) {
    switch (colorName) {
      case 'Electric Cyan':
        return const Color(0xFF00E5FF);
      case 'Hot Pink':
        return const Color(0xFFFF1744);
      case 'Trophy Gold':
        return const Color(0xFFFFD700);
      case 'Pure White':
        return const Color(0xFFFFFFFF);
      case 'Neon Lime':
      default:
        return const Color(0xFFCCFF00);
    }
  }

  Widget _buildMiniStrikeButton(double opacity, double radius) {
    final bevelH = (radius * 0.18).clamp(3.0, 6.0);
    final paddleSize = radius * 1.25;

    return Opacity(
      opacity: opacity.clamp(0.2, 1.0),
      child: SizedBox(
        width: radius * 2 + 6,
        height: radius * 2 + bevelH + 6,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Dark Arcade Casing Base
            Positioned(
              top: bevelH / 2,
              child: Container(
                width: radius * 2 + 4,
                height: radius * 2 + bevelH + 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F19),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            // 2. 3D Bottom Bevel
            Positioned(
              top: bevelH,
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: const BoxDecoration(
                  color: Color(0xFFB71C1C),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // 3. Top Button Face
            Positioned(
              top: 0,
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF2D55),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black45, width: 1.2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Paddle sprite
                    Image.asset(
                      'assets/images/logo/pixel_paddle.png',
                      width: paddleSize,
                      height: paddleSize,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.sports_tennis_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    // Action label
                    Positioned(
                      bottom: 2,
                      child: Text(
                        'SMASH',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w900,
                          fontSize: (radius * 0.22).clamp(7.0, 10.0),
                          letterSpacing: 0.5,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PLAYER ACCOUNT CARD
  // ---------------------------------------------------------------------------
  Widget _buildAccountCard(BuildContext context, GameStateManager state) {
    final isGuest = state.isGuest;

    return _buildCardWrapper(
      icon: isGuest ? Icons.account_circle_outlined : Icons.verified_user_rounded,
      title: 'Player Account',
      subtitle: isGuest ? 'Guest session' : 'Synchronized profile',
      accentColor: isGuest ? AppTheme.trophyAmber : AppTheme.neonLime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PlayerAvatarWidget(
                avatarId: state.playerAvatarId,
                size: 50,
                showBadge: true,
                showBorder: true,
                onTap: () => AvatarPickerDialog.show(context),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGuest ? 'Guest Player' : state.currentUsername,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGuest
                          ? 'Local session only (not saved to database)'
                          : 'Synced to local SQLite database',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Change Profile Picture button
          Game2DButton(
            key: const ValueKey('settings_change_avatar_btn'),
            onPressed: () => AvatarPickerDialog.show(context),
            text: 'CHANGE PROFILE PICTURE',
            icon: Icons.add_a_photo_rounded,
            variant: GameButtonVariant.cyan,
            size: GameButtonSize.small,
            isFullWidth: true,
          ),
          const SizedBox(height: 10),
          // View Stats & Records button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => PlayerStatsModal.show(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.neonLime,
                side: const BorderSide(color: AppTheme.neonLime),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.analytics_rounded, size: 18),
              label: const Text(
                'VIEW RECORDS & LEADERBOARD',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (isGuest)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const ValueKey('settings_register_login_btn'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonLime,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text(
                  'SAVE PROGRESS (SIGN IN / REGISTER)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('settings_logout_btn'),
                onPressed: () => _showLogoutDialog(context, state),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.fireOrange,
                  side: const BorderSide(color: AppTheme.fireOrange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  'SWITCH ACCOUNT / LOG OUT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELP & ABOUT CARD
  // ---------------------------------------------------------------------------
  Widget _buildHelpAndAboutCard(BuildContext context, GameStateManager state) {
    return _buildCardWrapper(
      icon: Icons.help_outline_rounded,
      title: 'Guides & Rules',
      subtitle: 'Pickleball rules and game information',
      accentColor: Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book_rounded, color: AppTheme.neonLime),
            title: const Text('How to Play Pickleball', style: TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: const Text('Rules, Kitchen zone, serve & smash tips', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 14),
            contentPadding: EdgeInsets.zero,
            onTap: () => _showHowToPlayDialog(context),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'PICKL v1.0.0 • Built with Flutter & Flame',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER STYLING & DIALOGS
  // ---------------------------------------------------------------------------
  Widget _buildCardWrapper({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color accentColor,
    required Widget child,
  }) {
    return Material(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  ButtonStyle _segmentedButtonStyle() {
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
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showHowToPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.surfaceBorder),
          ),
          title: const Row(
            children: [
              Icon(Icons.sports_tennis, color: AppTheme.neonLime),
              SizedBox(width: 10),
              Text('How to Play', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1. Serving & Positioning',
                  style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'The ball serves into play automatically. Move your player horizontally and vertically across your half of the court to intercept the ball.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                SizedBox(height: 12),
                Text(
                  '2. Striking & Smashes',
                  style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap the Red Strike button (or Spacebar on keyboard) as the ball approaches your paddle to execute a powerful smash. Angle your player to aim left or right!',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                SizedBox(height: 12),
                Text(
                  '3. Scoring',
                  style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Hit the ball past the opponent to score a point. First player to reach the target score wins the match!',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('GOT IT', style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }


  void _showLogoutDialog(BuildContext context, GameStateManager state) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.surfaceBorder),
          ),
          title: const Text('Log Out?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'Your progress has been saved to the database. You can log back in at any time.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await state.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.fireOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('LOG OUT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
