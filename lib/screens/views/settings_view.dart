import 'package:flutter/material.dart';
import '../../models/game_settings.dart';
import '../../services/game_state_manager.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'player_stats_modal.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameStateManager.instance;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final settings = state.settings;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildAccountCard(context, state),
                                  const SizedBox(height: 16),
                                  _buildAudioCard(context, settings, state),
                                  const SizedBox(height: 16),
                                  _buildControlsCard(context, settings, state),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildCourtThemeCard(context, settings, state),
                                  const SizedBox(height: 16),
                                  _buildHelpAndAboutCard(context, state),
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
                            _buildAudioCard(context, settings, state),
                            const SizedBox(height: 16),
                            _buildControlsCard(context, settings, state),
                            const SizedBox(height: 16),
                            _buildCourtThemeCard(context, settings, state),
                            const SizedBox(height: 16),
                            _buildHelpAndAboutCard(context, state),
                          ],
                        ),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Customize audio, controls, theme, and gameplay options',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioCard(BuildContext context, GameSettings settings, GameStateManager state) {
    return _buildCardWrapper(
      icon: Icons.volume_up_rounded,
      title: 'Audio & Sound Effects',
      accentColor: AppTheme.electricCyan,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Sound Effects (SFX)', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text('Paddle hits, ball bounces, crowd cheers', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            value: settings.sfxEnabled,
            activeThumbColor: AppTheme.neonLime,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              state.updateSettings(settings.copyWith(sfxEnabled: val));
            },
          ),
          SwitchListTile(
            title: const Text('Music & Ambience', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text('Background sports court soundtrack', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            value: settings.musicEnabled,
            activeThumbColor: AppTheme.neonLime,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              state.updateSettings(settings.copyWith(musicEnabled: val));
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Master Volume', style: TextStyle(color: Colors.white, fontSize: 13)),
              const Spacer(),
              Text('${(settings.soundVolume * 100).round()}%', style: const TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold)),
            ],
          ),
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
        ],
      ),
    );
  }

  Widget _buildControlsCard(BuildContext context, GameSettings settings, GameStateManager state) {
    return _buildCardWrapper(
      icon: Icons.gamepad_rounded,
      title: 'Controls & Movement',
      accentColor: AppTheme.neonLime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Joystick Side', style: TextStyle(color: Colors.white, fontSize: 14)),
                    Text('Preferred hand on touchscreen', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Left')),
                  ButtonSegment(value: false, label: Text('Right')),
                ],
                selected: {settings.joystickOnLeft},
                onSelectionChanged: (selection) {
                  state.updateSettings(settings.copyWith(joystickOnLeft: selection.first));
                },
                style: ButtonStyle(
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Stick Sensitivity', style: TextStyle(color: Colors.white, fontSize: 13)),
              const Spacer(),
              Text('${(settings.joystickSensitivity * 100).round()}%', style: const TextStyle(color: AppTheme.electricCyan, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: settings.joystickSensitivity,
            min: 0.5,
            max: 1.5,
            activeColor: AppTheme.electricCyan,
            inactiveColor: AppTheme.surfaceLight,
            onChanged: (val) {
              state.updateSettings(settings.copyWith(joystickSensitivity: val));
            },
          ),
          const Divider(color: AppTheme.surfaceBorder, height: 24),
          // Keyboard cheat sheet
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keyboard Controls (Desktop & Web):', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(height: 6),
                Text('• WASD or Arrow Keys: Run in 4 directions', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                Text('• Spacebar: Strike / Smash the ball', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtThemeCard(BuildContext context, GameSettings settings, GameStateManager state) {
    final themes = [
      {'name': 'Classic Green', 'color': const Color(0xFF2E7D32)},
      {'name': 'Electric Blue', 'color': const Color(0xFF1565C0)},
      {'name': 'Sunset Clay', 'color': const Color(0xFFD84315)},
      {'name': 'Neon Night', 'color': const Color(0xFF4A148C)},
    ];

    return _buildCardWrapper(
      icon: Icons.palette_rounded,
      title: 'Court Theme & Arena',
      accentColor: AppTheme.trophyAmber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select your court visual style',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: themes.map((t) {
              final name = t['name'] as String;
              final color = t['color'] as Color;
              final isSelected = settings.courtTheme == name;

              return InkWell(
                onTap: () {
                  state.updateSettings(settings.copyWith(courtTheme: name));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.3) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : AppTheme.surfaceBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textMuted,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpAndAboutCard(BuildContext context, GameStateManager state) {
    return _buildCardWrapper(
      icon: Icons.help_outline_rounded,
      title: 'Guides & Game Data',
      accentColor: Colors.white,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book_rounded, color: AppTheme.neonLime),
            title: const Text('How to Play Pickleball', style: TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: const Text('Rules, Kitchen zone, serve & smash tips', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 16),
            contentPadding: EdgeInsets.zero,
            onTap: () => _showHowToPlayDialog(context),
          ),
          const Divider(color: AppTheme.surfaceBorder, height: 16),
          ListTile(
            leading: const Icon(Icons.restart_alt_rounded, color: AppTheme.fireOrange),
            title: const Text('Reset Progress', style: TextStyle(color: AppTheme.fireOrange, fontSize: 14)),
            subtitle: const Text('Clear career stats, coins, and levels', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            contentPadding: EdgeInsets.zero,
            onTap: () => _showResetDialog(context, state),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Pickleball Smash v1.0.0 • Built with Flutter & Flame',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({
    required IconData icon,
    required String title,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
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
                  'Hit the ball past the opponent to score a point. First player to reach 11 points wins the match!',
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

  void _showResetDialog(BuildContext context, GameStateManager state) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.fireOrange),
          ),
          title: const Text('Reset All Progress?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'This will reset your level, coins, tournament progress, and challenges back to initial default values. This action cannot be undone.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                state.resetAllData();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Game progress reset to default.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.fireOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('RESET ALL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountCard(BuildContext context, GameStateManager state) {
    final isGuest = state.isGuest;

    return _buildCardWrapper(
      icon: isGuest ? Icons.account_circle_outlined : Icons.verified_user_rounded,
      title: 'Player Account',
      accentColor: isGuest ? AppTheme.trophyAmber : AppTheme.neonLime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isGuest
                      ? AppTheme.trophyAmber.withValues(alpha: 0.15)
                      : AppTheme.neonLime.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isGuest ? AppTheme.trophyAmber : AppTheme.neonLime,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isGuest ? Icons.person_outline_rounded : Icons.check_circle_outline_rounded,
                  color: isGuest ? AppTheme.trophyAmber : AppTheme.neonLime,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 16),
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

