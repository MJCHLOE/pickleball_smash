import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/character_roster.dart';
import '../models/court_catalog.dart';
import '../models/game_settings.dart';
import '../services/audio_service.dart';
import '../services/game_state_manager.dart';
import '../theme/app_theme.dart';
import 'game_2d_button.dart';
import 'game_2d_text.dart';

class HudControlsAdjusterModal extends StatefulWidget {
  final ValueChanged<GameSettings>? onSettingsChanged;
  final VoidCallback? onResume;

  const HudControlsAdjusterModal({
    super.key,
    this.onSettingsChanged,
    this.onResume,
  });

  static Future<void> show(
    BuildContext context, {
    ValueChanged<GameSettings>? onSettingsChanged,
    VoidCallback? onResume,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => HudControlsAdjusterModal(
        onSettingsChanged: onSettingsChanged,
        onResume: onResume,
      ),
    );
  }

  @override
  State<HudControlsAdjusterModal> createState() => _HudControlsAdjusterModalState();
}

class _HudControlsAdjusterModalState extends State<HudControlsAdjusterModal> with SingleTickerProviderStateMixin {
  late GameSettings _settings;
  late TabController _tabController;
  String _selectedElement = 'smash'; // 'joystick', 'smash', 'leftSpin', 'rightSpin', 'dash'

  @override
  void initState() {
    super.initState();
    _settings = GameStateManager.instance.settings;
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applySettings(GameSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    GameStateManager.instance.updateSettings(newSettings);
    widget.onSettingsChanged?.call(newSettings);
  }

  double _getElementX(String element) {
    switch (element) {
      case 'joystick':
        return _settings.joystickPosX;
      case 'smash':
        return _settings.smashPosX;
      case 'leftSpin':
        return _settings.leftSpinPosX;
      case 'rightSpin':
        return _settings.rightSpinPosX;
      case 'dash':
        return _settings.dashPosX;
      default:
        return 0.5;
    }
  }

  double _getElementY(String element) {
    switch (element) {
      case 'joystick':
        return _settings.joystickPosY;
      case 'smash':
        return _settings.smashPosY;
      case 'leftSpin':
        return _settings.leftSpinPosY;
      case 'rightSpin':
        return _settings.rightSpinPosY;
      case 'dash':
        return _settings.dashPosY;
      default:
        return 0.5;
    }
  }

  String _elementName(String element) {
    switch (element) {
      case 'joystick':
        return 'Movement Joystick';
      case 'smash':
        return 'Smash / Strike';
      case 'leftSpin':
        return 'Cyclone Curve (K)';
      case 'rightSpin':
        return 'Vortex Hook (L)';
      case 'dash':
        return 'Flash Dash (Shift)';
      default:
        return 'Controller';
    }
  }

  void _updateElementPos(String element, double newX, double newY) {
    final clampedX = newX.clamp(0.04, 0.96);
    final clampedY = newY.clamp(0.08, 0.94);
    GameSettings updated;
    switch (element) {
      case 'joystick':
        updated = _settings.copyWith(
          joystickPosX: clampedX,
          joystickPosY: clampedY,
          controlsPreset: 'Custom',
          freePositioning: true,
        );
        break;
      case 'smash':
        updated = _settings.copyWith(
          smashPosX: clampedX,
          smashPosY: clampedY,
          controlsPreset: 'Custom',
          freePositioning: true,
        );
        break;
      case 'leftSpin':
        updated = _settings.copyWith(
          leftSpinPosX: clampedX,
          leftSpinPosY: clampedY,
          controlsPreset: 'Custom',
          freePositioning: true,
        );
        break;
      case 'rightSpin':
        updated = _settings.copyWith(
          rightSpinPosX: clampedX,
          rightSpinPosY: clampedY,
          controlsPreset: 'Custom',
          freePositioning: true,
        );
        break;
      case 'dash':
        updated = _settings.copyWith(
          dashPosX: clampedX,
          dashPosY: clampedY,
          controlsPreset: 'Custom',
          freePositioning: true,
        );
        break;
      default:
        return;
    }
    _applySettings(updated);
  }

  void _applyPreset(String presetName) {
    AudioService.instance.playButtonTap();
    GameSettings presetSettings;
    switch (presetName) {
      case 'Mobile Legends (Default)':
        presetSettings = _settings.copyWith(
          controlsPreset: 'Mobile Legends (Default)',
          freePositioning: true,
          joystickPosX: GameSettings.mlbbJoystickX,
          joystickPosY: GameSettings.mlbbJoystickY,
          smashPosX: GameSettings.mlbbSmashX,
          smashPosY: GameSettings.mlbbSmashY,
          leftSpinPosX: GameSettings.mlbbLeftSpinX,
          leftSpinPosY: GameSettings.mlbbLeftSpinY,
          rightSpinPosX: GameSettings.mlbbRightSpinX,
          rightSpinPosY: GameSettings.mlbbRightSpinY,
          dashPosX: GameSettings.mlbbDashX,
          dashPosY: GameSettings.mlbbDashY,
          joystickExpand: 1.0,
          skillButtonScale: 1.0,
          smashScale: 1.0,
          leftSpinScale: 1.0,
          rightSpinScale: 1.0,
          dashScale: 1.0,
          buttonSize: 'Normal',
          joystickOnLeft: true,
          showJoystick: true,
          showSkillButtons: true,
        );
        break;
      case 'Compact':
        presetSettings = _settings.copyWith(
          controlsPreset: 'Compact',
          freePositioning: true,
          joystickPosX: 0.14,
          joystickPosY: 0.82,
          smashPosX: 0.88,
          smashPosY: 0.82,
          leftSpinPosX: 0.76,
          leftSpinPosY: 0.84,
          rightSpinPosX: 0.79,
          rightSpinPosY: 0.72,
          dashPosX: 0.88,
          dashPosY: 0.68,
          joystickExpand: 0.85,
          skillButtonScale: 0.85,
          smashScale: 0.85,
          leftSpinScale: 0.85,
          rightSpinScale: 0.85,
          dashScale: 0.85,
          skillSpacing: 75.0,
          joystickMarginX: 24.0,
          joystickMarginY: 24.0,
          skillMarginX: 24.0,
          skillMarginY: 24.0,
          buttonSize: 'Normal',
        );
        break;
      case 'Pro Wide':
        presetSettings = _settings.copyWith(
          controlsPreset: 'Pro Wide',
          freePositioning: true,
          joystickPosX: 0.18,
          joystickPosY: 0.76,
          smashPosX: 0.86,
          smashPosY: 0.78,
          leftSpinPosX: 0.70,
          leftSpinPosY: 0.80,
          rightSpinPosX: 0.74,
          rightSpinPosY: 0.64,
          dashPosX: 0.86,
          dashPosY: 0.58,
          joystickExpand: 1.25,
          skillButtonScale: 1.25,
          smashScale: 1.25,
          leftSpinScale: 1.15,
          rightSpinScale: 1.15,
          dashScale: 1.15,
          skillSpacing: 110.0,
          joystickMarginX: 44.0,
          joystickMarginY: 44.0,
          skillMarginX: 44.0,
          skillMarginY: 44.0,
          buttonSize: 'Large',
        );
        break;
      case 'Left-Handed':
        presetSettings = _settings.copyWith(
          controlsPreset: 'Left-Handed',
          joystickOnLeft: false,
        );
        break;
      case 'Default Arcade':
      default:
        presetSettings = _settings.copyWith(
          controlsPreset: 'Default Arcade',
          freePositioning: false,
          joystickPosX: GameSettings.arcadeJoystickX,
          joystickPosY: GameSettings.arcadeJoystickY,
          smashPosX: GameSettings.arcadeSmashX,
          smashPosY: GameSettings.arcadeSmashY,
          leftSpinPosX: GameSettings.arcadeLeftSpinX,
          leftSpinPosY: GameSettings.arcadeLeftSpinY,
          rightSpinPosX: GameSettings.arcadeRightSpinX,
          rightSpinPosY: GameSettings.arcadeRightSpinY,
          dashPosX: GameSettings.arcadeDashX,
          dashPosY: GameSettings.arcadeDashY,
          joystickExpand: 1.0,
          skillButtonScale: 1.0,
          smashScale: 1.0,
          leftSpinScale: 1.0,
          rightSpinScale: 1.0,
          dashScale: 1.0,
          skillSpacing: 90.0,
          joystickMarginX: 36.0,
          joystickMarginY: 36.0,
          skillMarginX: 36.0,
          skillMarginY: 36.0,
          buttonSize: 'Normal',
          joystickOnLeft: true,
          showJoystick: true,
          showSkillButtons: true,
        );
        break;
    }
    _applySettings(presetSettings);
  }

  Color _resolveColor(String colorName) {
    switch (colorName) {
      case 'Electric Cyan':
        return const Color(0xFF00E5FF);
      case 'Hot Pink':
        return const Color(0xFFFF2A85);
      case 'Trophy Gold':
        return const Color(0xFFFFD700);
      case 'Pure White':
        return Colors.white;
      case 'Arcade Orange':
        return const Color(0xFFFF6D00);
      case 'Neon Lime':
      default:
        return const Color(0xFFCCFF00);
    }
  }

  void _openFullscreenEditor(BuildContext context) {
    AudioService.instance.playButtonTap();
    FullscreenHudEditorModal.show(
      context,
      initialSettings: _settings,
      onSave: (savedSettings) {
        _applySettings(savedSettings);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isShortHeight = screenSize.height < 540;
    final dialogWidth = math.min(screenSize.width * 0.95, 720.0);
    final dialogHeight = math.min(screenSize.height * 0.98, 640.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppTheme.neonLime.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. Header
            _buildHeader(isShortHeight),
            const Divider(color: AppTheme.surfaceBorder, height: 1),

            // 2. Interactive Screen Preview with Free Drag & Drop
            _buildInteractivePreview(isShortHeight),
            const Divider(color: AppTheme.surfaceBorder, height: 1),

            // 3. Category Tabs
            _buildCategoryTabs(isShortHeight),

            // 4. Tab Body Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPresetsTab(isShortHeight),
                  _buildFreePositionTab(isShortHeight),
                  _buildJoystickTab(isShortHeight),
                  _buildSkillsTab(isShortHeight),
                  _buildScoringTab(isShortHeight),
                ],
              ),
            ),

            const Divider(color: AppTheme.surfaceBorder, height: 1),

            // 5. Footer Buttons
            _buildFooter(isShortHeight),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(bool isShortHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isShortHeight ? 6 : 8,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.neonLime.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.tune_rounded, color: AppTheme.neonLime, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Game2DText(
                  'HUD & CONTROLS ADJUSTER',
                  fontSize: 14,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'MLBB Arcade & Free Positioning',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Fullscreen Court Editor Button
          Game2DButton(
            text: MediaQuery.sizeOf(context).width < 420 ? 'COURT' : 'FULLSCREEN',
            icon: Icons.fullscreen_rounded,
            size: GameButtonSize.small,
            variant: GameButtonVariant.cyan,
            onPressed: () => _openFullscreenEditor(context),
          ),
          const SizedBox(width: 6),
          // Reset MLBB Default Button
          if (MediaQuery.sizeOf(context).width < 450)
            IconButton(
              icon: const Icon(Icons.sports_esports_rounded, color: AppTheme.neonLime, size: 20),
              tooltip: 'MLBB DEFAULT',
              onPressed: () => _applyPreset('Mobile Legends (Default)'),
            )
          else
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                foregroundColor: AppTheme.neonLime,
              ),
              icon: const Icon(Icons.sports_esports_rounded, size: 16),
              label: const Text('MLBB DEFAULT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () => _applyPreset('Mobile Legends (Default)'),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              AudioService.instance.playButtonTap();
              Navigator.of(context).pop();
              widget.onResume?.call();
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE MINI-SCREEN PREVIEW WITH FREE DRAG & DROP
  // ---------------------------------------------------------------------------
  Widget _buildInteractivePreview(bool isShortHeight) {
    final previewHeight = isShortHeight ? 95.0 : 120.0;
    final baseColor = _resolveColor(_settings.joystickColor);
    final opacity = _settings.transparentCapacity.clamp(0.20, 1.0);
    final isLeftHanded = !_settings.joystickOnLeft;
    final courtInfo = CourtCatalog.getById(GameStateManager.instance.equippedCourtId);

    return Container(
      height: previewHeight,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A101D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pWidth = constraints.maxWidth;
            final pHeight = constraints.maxHeight;

            void handleDrag(String element, DragUpdateDetails details) {
              final currentX = _getElementX(element);
              final currentY = _getElementY(element);
              final dx = (isLeftHanded ? -details.delta.dx : details.delta.dx) / pWidth;
              final dy = details.delta.dy / pHeight;
              _updateElementPos(element, currentX + dx, currentY + dy);
            }

            return Stack(
              children: [
                // Pickleball Court Background
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/background/hud_court_background.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _FullCourtPainter(courtInfo: courtInfo, isMini: true),
                    ),
                  ),
                ),

                // Player & Opponent Character Sprites on Court
                _buildCourtCharacters(Size(pWidth, pHeight), isMini: true),

                // Top Status Bar: Live mode & Quick Actions
                Positioned(
                  top: 4,
                  left: 6,
                  right: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'LIVE HUD PREVIEW • ${_settings.scoringMode == 'rally' ? '⚡ RALLY SCORING' : '🏓 SIDE-OUT SCORING'}',
                          style: const TextStyle(color: AppTheme.neonLime, fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQuickChip('MLBB', () => _applyPreset('Mobile Legends (Default)'), AppTheme.neonLime),
                          const SizedBox(width: 4),
                          _buildQuickChip('ARCADE', () => _applyPreset('Default Arcade'), AppTheme.electricCyan),
                          const SizedBox(width: 4),
                          _buildQuickChip('FLIP', () => _applySettings(_settings.copyWith(joystickOnLeft: !_settings.joystickOnLeft)), const Color(0xFFFF2A85)),
                          const SizedBox(width: 4),
                          _buildQuickChip('FULLSCREEN COURT', () => _openFullscreenEditor(context), AppTheme.goldCoin, icon: Icons.fullscreen_rounded),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selected Element Live Drag Hint Badge
                Positioned(
                  bottom: 4,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Drag Any Control • Selected: ${_elementName(_selectedElement)} (${(_getElementX(_selectedElement) * 100).round()}%, ${(_getElementY(_selectedElement) * 100).round()}%)',
                      style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // 1. DRAGGABLE JOYSTICK
                if (_settings.showJoystick)
                  _buildDraggableElement(
                    element: 'joystick',
                    pWidth: pWidth,
                    pHeight: pHeight,
                    isLeftHanded: isLeftHanded,
                    size: 38.0 * _settings.joystickExpand,
                    onDrag: (details) => handleDrag('joystick', details),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedElement == 'joystick' ? AppTheme.neonLime : baseColor,
                            width: _selectedElement == 'joystick' ? 2.5 : 1.5,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 14.0 * _settings.joystickExpand,
                            height: 14.0 * _settings.joystickExpand,
                            decoration: BoxDecoration(
                              color: baseColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 2. DRAGGABLE SMASH (BASIC ATTACK - UNIFIED ARCADE BUTTON)
                if (_settings.showSkillButtons)
                  _buildDraggableElement(
                    element: 'smash',
                    pWidth: pWidth,
                    pHeight: pHeight,
                    isLeftHanded: isLeftHanded,
                    size: 34.0 * _settings.smashScale,
                    onDrag: (details) => handleDrag('smash', details),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0F19),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedElement == 'smash' ? AppTheme.neonLime : Colors.white,
                            width: _selectedElement == 'smash' ? 2.5 : 1.5,
                          ),
                          boxShadow: _selectedElement == 'smash'
                              ? [BoxShadow(color: AppTheme.neonLime.withValues(alpha: 0.6), blurRadius: 6)]
                              : null,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [Color(0xFFFF3366), Color(0xFFB71C1C)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/items/paddle_wooden.png',
                                  width: 13.0 * _settings.smashScale,
                                  height: 13.0 * _settings.smashScale,
                                  filterQuality: FilterQuality.none,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.sports_tennis_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'SMASH',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 5.5,
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
                  ),

                // 3. DRAGGABLE LEFT SPIN (CYCLONE CURVE K)
                if (_settings.showSkillButtons)
                  _buildDraggableElement(
                    element: 'leftSpin',
                    pWidth: pWidth,
                    pHeight: pHeight,
                    isLeftHanded: isLeftHanded,
                    size: 24.0 * _settings.leftSpinScale,
                    onDrag: (details) => handleDrag('leftSpin', details),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedElement == 'leftSpin' ? AppTheme.neonLime : Colors.white,
                            width: _selectedElement == 'leftSpin' ? 2.5 : 1.2,
                          ),
                          boxShadow: _selectedElement == 'leftSpin'
                              ? [BoxShadow(color: AppTheme.neonLime.withValues(alpha: 0.6), blurRadius: 6)]
                              : null,
                        ),
                        child: const Center(
                          child: Text('K', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),

                // 4. DRAGGABLE RIGHT SPIN (VORTEX HOOK L)
                if (_settings.showSkillButtons)
                  _buildDraggableElement(
                    element: 'rightSpin',
                    pWidth: pWidth,
                    pHeight: pHeight,
                    isLeftHanded: isLeftHanded,
                    size: 24.0 * _settings.rightSpinScale,
                    onDrag: (details) => handleDrag('rightSpin', details),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedElement == 'rightSpin' ? AppTheme.neonLime : Colors.white,
                            width: _selectedElement == 'rightSpin' ? 2.5 : 1.2,
                          ),
                          boxShadow: _selectedElement == 'rightSpin'
                              ? [BoxShadow(color: AppTheme.neonLime.withValues(alpha: 0.6), blurRadius: 6)]
                              : null,
                        ),
                        child: const Center(
                          child: Text('L', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),

                // 5. DRAGGABLE FLASH DASH (SHIFT)
                if (_settings.showSkillButtons)
                  _buildDraggableElement(
                    element: 'dash',
                    pWidth: pWidth,
                    pHeight: pHeight,
                    isLeftHanded: isLeftHanded,
                    size: 24.0 * _settings.dashScale,
                    onDrag: (details) => handleDrag('dash', details),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedElement == 'dash' ? AppTheme.neonLime : Colors.white,
                            width: _selectedElement == 'dash' ? 2.5 : 1.2,
                          ),
                          boxShadow: _selectedElement == 'dash'
                              ? [BoxShadow(color: AppTheme.neonLime.withValues(alpha: 0.6), blurRadius: 6)]
                              : null,
                        ),
                        child: const Center(
                          child: Text('💨', style: TextStyle(fontSize: 10)),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap, Color color, {IconData? icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 2),
            ],
            Text(label, style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourtCharacters(Size screenSize, {bool isMini = false}) {
    return _CourtCharactersOverlay(screenSize: screenSize, isMini: isMini);
  }

  Widget _buildDraggableElement({
    required String element,
    required double pWidth,
    required double pHeight,
    required bool isLeftHanded,
    required double size,
    required ValueChanged<DragUpdateDetails> onDrag,
    required Widget child,
  }) {
    final normX = _getElementX(element);
    final normY = _getElementY(element);
    final effX = isLeftHanded ? (1.0 - normX) : normX;
    final left = (effX * pWidth - size / 2).clamp(2.0, pWidth - size - 2.0);
    final top = (normY * pHeight - size / 2).clamp(16.0, pHeight - size - 2.0);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          AudioService.instance.playButtonTap();
          setState(() => _selectedElement = element);
        },
        onPanStart: (_) {
          setState(() => _selectedElement = element);
        },
        onPanUpdate: onDrag,
        child: SizedBox(
          width: size,
          height: size,
          child: child,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORY TABS
  // ---------------------------------------------------------------------------
  Widget _buildCategoryTabs(bool isShortHeight) {
    return Container(
      color: const Color(0xFF0B1322),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.neonLime,
        indicatorWeight: 3,
        labelColor: AppTheme.neonLime,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        onTap: (_) => AudioService.instance.playButtonTap(),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_customize_rounded, size: 16), text: 'Presets'),
          Tab(icon: Icon(Icons.open_with_rounded, size: 16), text: 'Positioning'),
          Tab(icon: Icon(Icons.gamepad_rounded, size: 16), text: 'Joystick'),
          Tab(icon: Icon(Icons.auto_awesome_rounded, size: 16), text: 'Skills'),
          Tab(icon: Icon(Icons.scoreboard_rounded, size: 16), text: 'Scoring Rules'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. PRESETS TAB
  // ---------------------------------------------------------------------------
  Widget _buildPresetsTab(bool isShortHeight) {
    final presets = [
      {
        'id': 'Mobile Legends (Default)',
        'icon': Icons.sports_esports_rounded,
        'color': AppTheme.neonLime,
        'title': 'Mobile Legends (Default)',
        'desc': 'Curved radial skill fan around Basic Attack + bottom-left movement wheel. (MLBB Signature Layout)',
      },
      {
        'id': 'Default Arcade',
        'icon': Icons.grid_view_rounded,
        'color': AppTheme.electricCyan,
        'title': 'Default Arcade Layout',
        'desc': 'Balanced 1.0x scale, standard 36px margins, 2x2 skill cluster on right side.',
      },
      {
        'id': 'Compact',
        'icon': Icons.phone_android_rounded,
        'color': AppTheme.goldCoin,
        'title': 'Compact Mode',
        'desc': 'Tighter 0.85x scale and narrow margins. Perfect for smaller phones.',
      },
      {
        'id': 'Pro Wide',
        'icon': Icons.open_in_full_rounded,
        'color': const Color(0xFFFF2A85),
        'title': 'Pro Gamer / Wide',
        'desc': 'Enlarged 1.25x buttons and spaced-out cluster for rapid finger inputs.',
      },
      {
        'id': 'Left-Handed',
        'icon': Icons.swap_horiz_rounded,
        'color': const Color(0xFF38BDF8),
        'title': 'Left-Handed Flipped',
        'desc': 'Flipped: Joystick on the Right, Action and Skill buttons on the Left.',
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        for (final p in presets) ...[
          _buildPresetCard(
            id: p['id'] as String,
            title: p['title'] as String,
            desc: p['desc'] as String,
            icon: p['icon'] as IconData,
            accentColor: p['color'] as Color,
            isSelected: _settings.controlsPreset == p['id'],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildPresetCard({
    required String id,
    required String title,
    required String desc,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _applyPreset(id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.15) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : AppTheme.surfaceBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (id == 'Mobile Legends (Default)') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.neonLime.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.neonLime, width: 0.8),
                          ),
                          child: const Text('DEFAULT', style: TextStyle(color: AppTheme.neonLime, fontSize: 8.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: accentColor, size: 20)
            else
              const Icon(Icons.circle_outlined, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. FREE POSITIONING TAB
  // ---------------------------------------------------------------------------
  Widget _buildFreePositionTab(bool isShortHeight) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // Fullscreen Drag Launch Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.neonLime.withValues(alpha: 0.2),
                AppTheme.electricCyan.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.neonLime.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fullscreen_rounded, color: AppTheme.neonLime, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fullscreen 1:1 Drag Editor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Drag controller elements directly on the full court at 100% scale', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Game2DButton(
                text: 'OPEN EDITOR',
                size: GameButtonSize.small,
                variant: GameButtonVariant.primary,
                onPressed: () => _openFullscreenEditor(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        const Text('Select Control to Position', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Control selector chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildElementSelectorChip('joystick', '🕹️ Movement Joystick'),
            _buildElementSelectorChip('smash', '💥 Smash / Attack'),
            _buildElementSelectorChip('leftSpin', '🌪️ Cyclone (K)'),
            _buildElementSelectorChip('rightSpin', '⚡ Vortex (L)'),
            _buildElementSelectorChip('dash', '💨 Flash Dash'),
          ],
        ),

        const SizedBox(height: 12),

        // Sliders for selected element
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adjusting: ${_elementName(_selectedElement)}',
                style: const TextStyle(color: AppTheme.neonLime, fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // X Position
              _buildSliderTile(
                title: 'Horizontal Position (X)',
                valueText: '${(_getElementX(_selectedElement) * 100).round()}%',
                value: _getElementX(_selectedElement),
                min: 0.05,
                max: 0.95,
                onChanged: (val) => _updateElementPos(_selectedElement, val, _getElementY(_selectedElement)),
              ),

              // Y Position
              _buildSliderTile(
                title: 'Vertical Position (Y)',
                valueText: '${(_getElementY(_selectedElement) * 100).round()}%',
                value: _getElementY(_selectedElement),
                min: 0.08,
                max: 0.92,
                onChanged: (val) => _updateElementPos(_selectedElement, _getElementX(_selectedElement), val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildElementSelectorChip(String id, String label) {
    final isSel = _selectedElement == id;
    return InkWell(
      onTap: () {
        AudioService.instance.playButtonTap();
        setState(() => _selectedElement = id);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppTheme.neonLime.withValues(alpha: 0.25) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSel ? AppTheme.neonLime : AppTheme.surfaceBorder,
            width: isSel ? 1.8 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. JOYSTICK TAB
  // ---------------------------------------------------------------------------
  Widget _buildJoystickTab(bool isShortHeight) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // Show Joystick Switch
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Show On-Screen Joystick', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Display the virtual movement stick on screen', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
                ],
              ),
            ),
            Switch(
              value: _settings.showJoystick,
              activeThumbColor: AppTheme.neonLime,
              onChanged: (val) {
                AudioService.instance.playButtonTap();
                _applySettings(_settings.copyWith(showJoystick: val));
              },
            ),
          ],
        ),

        // Joystick Size / Scale
        _buildSliderTile(
          title: 'Joystick Size / Scale',
          valueText: '${(_settings.joystickExpand * 100).round()}%',
          value: _settings.joystickExpand,
          min: 0.70,
          max: 1.60,
          onChanged: (val) => _applySettings(_settings.copyWith(joystickExpand: val)),
        ),

        // Joystick Horizontal Position (X)
        _buildSliderTile(
          title: 'Horizontal Position (X)',
          valueText: '${(_settings.joystickPosX * 100).round()}%',
          value: _settings.joystickPosX,
          min: 0.05,
          max: 0.95,
          onChanged: (val) => _updateElementPos('joystick', val, _settings.joystickPosY),
        ),

        // Joystick Vertical Position (Y)
        _buildSliderTile(
          title: 'Vertical Position (Y)',
          valueText: '${(_settings.joystickPosY * 100).round()}%',
          value: _settings.joystickPosY,
          min: 0.08,
          max: 0.92,
          onChanged: (val) => _updateElementPos('joystick', _settings.joystickPosX, val),
        ),

        // Joystick Color Theme
        const SizedBox(height: 6),
        const Text('Joystick Accent Color', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
            'Arcade Orange',
          ].map((colorName) {
            final color = _resolveColor(colorName);
            final isSel = _settings.joystickColor == colorName;
            return InkWell(
              onTap: () {
                AudioService.instance.playButtonTap();
                _applySettings(_settings.copyWith(joystickColor: colorName));
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSel ? color.withValues(alpha: 0.25) : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSel ? color : AppTheme.surfaceBorder, width: isSel ? 2 : 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(colorName, style: TextStyle(color: isSel ? Colors.white : AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
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
  // 4. SKILLS TAB
  // ---------------------------------------------------------------------------
  Widget _buildSkillsTab(bool isShortHeight) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // Show Skills Switch
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Show On-Screen Skills & Smash', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Display the action buttons (Smash, Cyclone Curve, Vortex Hook, Flash Dash)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5)),
                ],
              ),
            ),
            Switch(
              value: _settings.showSkillButtons,
              activeThumbColor: AppTheme.neonLime,
              onChanged: (val) {
                AudioService.instance.playButtonTap();
                _applySettings(_settings.copyWith(showSkillButtons: val));
              },
            ),
          ],
        ),

        // Separate Controller Sizing Section
        const SizedBox(height: 6),
        const Text('Individual Controller Sizing', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),

        // Smash Button Scale
        _buildSliderTile(
          title: '💥 Smash Button Size',
          valueText: '${(_settings.smashScale * 100).round()}%',
          value: _settings.smashScale,
          min: 0.65,
          max: 1.50,
          onChanged: (val) => _applySettings(_settings.copyWith(smashScale: val)),
        ),

        // Cyclone Curve (K) Scale
        _buildSliderTile(
          title: '🌪️ Cyclone Curve (K) Size',
          valueText: '${(_settings.leftSpinScale * 100).round()}%',
          value: _settings.leftSpinScale,
          min: 0.65,
          max: 1.50,
          onChanged: (val) => _applySettings(_settings.copyWith(leftSpinScale: val)),
        ),

        // Vortex Hook (L) Scale
        _buildSliderTile(
          title: '⚡ Vortex Hook (L) Size',
          valueText: '${(_settings.rightSpinScale * 100).round()}%',
          value: _settings.rightSpinScale,
          min: 0.65,
          max: 1.50,
          onChanged: (val) => _applySettings(_settings.copyWith(rightSpinScale: val)),
        ),

        // Flash Dash (Shift) Scale
        _buildSliderTile(
          title: '💨 Flash Dash Size',
          valueText: '${(_settings.dashScale * 100).round()}%',
          value: _settings.dashScale,
          min: 0.65,
          max: 1.50,
          onChanged: (val) => _applySettings(_settings.copyWith(dashScale: val)),
        ),

        // Master Skill Button Scale (scales all skills)
        _buildSliderTile(
          title: 'Master Action Buttons Scale',
          valueText: '${(_settings.skillButtonScale * 100).round()}%',
          value: _settings.skillButtonScale,
          min: 0.70,
          max: 1.50,
          onChanged: (val) => _applySettings(_settings.copyWith(
            skillButtonScale: val,
            smashScale: val,
            leftSpinScale: val,
            rightSpinScale: val,
            dashScale: val,
          )),
        ),

        // Skill Cluster Spacing
        _buildSliderTile(
          title: 'Skill Cluster Spacing',
          valueText: '${_settings.skillSpacing.round()} px',
          value: _settings.skillSpacing,
          min: 60.0,
          max: 130.0,
          onChanged: (val) => _applySettings(_settings.copyWith(skillSpacing: val)),
        ),

        // HUD Opacity / Transparency
        _buildSliderTile(
          title: 'Controls Opacity / Transparency',
          valueText: '${(_settings.transparentCapacity * 100).round()}%',
          value: _settings.transparentCapacity,
          min: 0.20,
          max: 1.0,
          onChanged: (val) => _applySettings(_settings.copyWith(transparentCapacity: val)),
        ),

        // Handedness Toggle
        const SizedBox(height: 6),
        const Text('Handedness Layout', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  AudioService.instance.playButtonTap();
                  _applySettings(_settings.copyWith(joystickOnLeft: true));
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _settings.joystickOnLeft ? AppTheme.neonLime.withValues(alpha: 0.2) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _settings.joystickOnLeft ? AppTheme.neonLime : AppTheme.surfaceBorder),
                  ),
                  child: Center(
                    child: Text('Right-Handed (Default)', style: TextStyle(color: _settings.joystickOnLeft ? AppTheme.neonLime : Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () {
                  AudioService.instance.playButtonTap();
                  _applySettings(_settings.copyWith(joystickOnLeft: false));
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: !_settings.joystickOnLeft ? AppTheme.electricCyan.withValues(alpha: 0.2) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: !_settings.joystickOnLeft ? AppTheme.electricCyan : AppTheme.surfaceBorder),
                  ),
                  child: Center(
                    child: Text('Left-Handed', style: TextStyle(color: !_settings.joystickOnLeft ? AppTheme.electricCyan : Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. SCORING RULES TAB
  // ---------------------------------------------------------------------------
  Widget _buildScoringTab(bool isShortHeight) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Option 1: Rally Scoring (Default)
        _buildScoringCard(
          id: 'rally',
          title: '⚡ Rally Scoring (Major League Rules)',
          subtitle: 'Point awarded on EVERY rally won • Fast & responsive arcade pace',
          desc: 'Whenever you or the opponent fails to strike on 1 bounce, double bounces, or hits out, the opposing side scores +1 point immediately.',
          badgeColor: AppTheme.neonLime,
          isSelected: _settings.scoringMode == 'rally',
        ),

        const SizedBox(height: 10),

        // Option 2: Traditional Side-Out Scoring
        _buildScoringCard(
          id: 'sideOut',
          title: '🏓 Traditional Side-Out (Official USA Pickleball)',
          subtitle: 'Only the serving team scores points • Receivers get Side-Out',
          desc: 'When the receiver wins a rally, no point is awarded; instead, serve turnover occurs to give the receiver a chance to serve and score.',
          badgeColor: AppTheme.electricCyan,
          isSelected: _settings.scoringMode == 'sideOut',
        ),

        const SizedBox(height: 12),

        // Rule Explanation Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.neonLime.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.rule_rounded, color: AppTheme.neonLime, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pickleball Double Bounce Rule:\n'
                  'The ball must be struck after exactly 1 floor bounce. If the ball bounces a second time on your court, you commit a fault and the enemy receives the rally win/score!',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoringCard({
    required String id,
    required String title,
    required String subtitle,
    required String desc,
    required Color badgeColor,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        AudioService.instance.playButtonTap();
        _applySettings(_settings.copyWith(scoringMode: id));
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? badgeColor.withValues(alpha: 0.14) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? badgeColor : AppTheme.surfaceBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: badgeColor, size: 20)
                else
                  const Icon(Icons.circle_outlined, color: AppTheme.textMuted, size: 20),
              ],
            ),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10.5)),
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.3)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SLIDER TILE HELPER
  // ---------------------------------------------------------------------------
  Widget _buildSliderTile({
    required String title,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(valueText, style: const TextStyle(color: AppTheme.neonLime, fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              activeTrackColor: AppTheme.neonLime,
              inactiveTrackColor: AppTheme.surfaceLight,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER ACTIONS
  // ---------------------------------------------------------------------------
  Widget _buildFooter(bool isShortHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isShortHeight ? 6 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Presets auto-saved to cloud & storage',
              style: TextStyle(color: AppTheme.textMuted, fontSize: isShortHeight ? 9.5 : 11, fontStyle: FontStyle.italic),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Game2DButton(
            text: 'SAVE & APPLY',
            icon: Icons.check_rounded,
            size: isShortHeight ? GameButtonSize.small : GameButtonSize.medium,
            variant: GameButtonVariant.primary,
            onPressed: () {
              AudioService.instance.playButtonTap();
              Navigator.of(context).pop();
              widget.onResume?.call();
            },
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FULLSCREEN 1:1 DRAG & DROP HUD CONTROLLER EDITOR
// -----------------------------------------------------------------------------
class FullscreenHudEditorModal extends StatefulWidget {
  final GameSettings initialSettings;
  final ValueChanged<GameSettings> onSave;

  const FullscreenHudEditorModal({
    super.key,
    required this.initialSettings,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required GameSettings initialSettings,
    required ValueChanged<GameSettings> onSave,
  }) {
    return showDialog(
      context: context,
      useSafeArea: false,
      barrierDismissible: false,
      builder: (context) => FullscreenHudEditorModal(
        initialSettings: initialSettings,
        onSave: onSave,
      ),
    );
  }

  @override
  State<FullscreenHudEditorModal> createState() => _FullscreenHudEditorModalState();
}

class _FullscreenHudEditorModalState extends State<FullscreenHudEditorModal> {
  late GameSettings _settings;
  String _selectedElement = 'joystick';
  bool _showGuides = false;
  bool _showHudTopBar = true;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  double _getX(String element) {
    switch (element) {
      case 'joystick':
        return _settings.joystickPosX;
      case 'smash':
        return _settings.smashPosX;
      case 'leftSpin':
        return _settings.leftSpinPosX;
      case 'rightSpin':
        return _settings.rightSpinPosX;
      case 'dash':
        return _settings.dashPosX;
      default:
        return 0.5;
    }
  }

  double _getY(String element) {
    switch (element) {
      case 'joystick':
        return _settings.joystickPosY;
      case 'smash':
        return _settings.smashPosY;
      case 'leftSpin':
        return _settings.leftSpinPosY;
      case 'rightSpin':
        return _settings.rightSpinPosY;
      case 'dash':
        return _settings.dashPosY;
      default:
        return 0.5;
    }
  }

  String _name(String element) {
    switch (element) {
      case 'joystick':
        return 'Movement Joystick';
      case 'smash':
        return 'Smash / Basic Attack';
      case 'leftSpin':
        return 'Cyclone Curve (K)';
      case 'rightSpin':
        return 'Vortex Hook (L)';
      case 'dash':
        return 'Flash Dash (Shift)';
      default:
        return 'Controller';
    }
  }

  void _updatePos(String element, double newX, double newY) {
    final clampedX = newX.clamp(0.04, 0.96);
    final clampedY = newY.clamp(0.06, 0.94);
    setState(() {
      switch (element) {
        case 'joystick':
          _settings = _settings.copyWith(joystickPosX: clampedX, joystickPosY: clampedY, controlsPreset: 'Custom', freePositioning: true);
          break;
        case 'smash':
          _settings = _settings.copyWith(smashPosX: clampedX, smashPosY: clampedY, controlsPreset: 'Custom', freePositioning: true);
          break;
        case 'leftSpin':
          _settings = _settings.copyWith(leftSpinPosX: clampedX, leftSpinPosY: clampedY, controlsPreset: 'Custom', freePositioning: true);
          break;
        case 'rightSpin':
          _settings = _settings.copyWith(rightSpinPosX: clampedX, rightSpinPosY: clampedY, controlsPreset: 'Custom', freePositioning: true);
          break;
        case 'dash':
          _settings = _settings.copyWith(dashPosX: clampedX, dashPosY: clampedY, controlsPreset: 'Custom', freePositioning: true);
          break;
      }
    });
  }

  void _nudgeSelected(double dx, double dy) {
    AudioService.instance.playButtonTap();
    final curX = _getX(_selectedElement);
    final curY = _getY(_selectedElement);
    _updatePos(_selectedElement, curX + dx, curY + dy);
  }

  void _resetSelectedElement() {
    AudioService.instance.playButtonTap();
    double defX = 0.5;
    double defY = 0.5;
    switch (_selectedElement) {
      case 'joystick':
        defX = GameSettings.mlbbJoystickX;
        defY = GameSettings.mlbbJoystickY;
        break;
      case 'smash':
        defX = GameSettings.mlbbSmashX;
        defY = GameSettings.mlbbSmashY;
        break;
      case 'leftSpin':
        defX = GameSettings.mlbbLeftSpinX;
        defY = GameSettings.mlbbLeftSpinY;
        break;
      case 'rightSpin':
        defX = GameSettings.mlbbRightSpinX;
        defY = GameSettings.mlbbRightSpinY;
        break;
      case 'dash':
        defX = GameSettings.mlbbDashX;
        defY = GameSettings.mlbbDashY;
        break;
    }
    _updatePos(_selectedElement, defX, defY);
  }

  void _resetMlbb() {
    AudioService.instance.playButtonTap();
    setState(() {
      _settings = _settings.copyWith(
        controlsPreset: 'Mobile Legends (Default)',
        freePositioning: true,
        joystickPosX: GameSettings.mlbbJoystickX,
        joystickPosY: GameSettings.mlbbJoystickY,
        smashPosX: GameSettings.mlbbSmashX,
        smashPosY: GameSettings.mlbbSmashY,
        leftSpinPosX: GameSettings.mlbbLeftSpinX,
        leftSpinPosY: GameSettings.mlbbLeftSpinY,
        rightSpinPosX: GameSettings.mlbbRightSpinX,
        rightSpinPosY: GameSettings.mlbbRightSpinY,
        dashPosX: GameSettings.mlbbDashX,
        dashPosY: GameSettings.mlbbDashY,
        joystickExpand: 1.0,
        skillButtonScale: 1.0,
        smashScale: 1.0,
        leftSpinScale: 1.0,
        rightSpinScale: 1.0,
        dashScale: 1.0,
        joystickOnLeft: true,
      );
    });
  }

  void _applyPresetInEditor(String presetName) {
    AudioService.instance.playButtonTap();
    setState(() {
      switch (presetName) {
        case 'Mobile Legends (Default)':
          _resetMlbb();
          break;
        case 'Default Arcade':
          _settings = _settings.copyWith(
            controlsPreset: 'Default Arcade',
            freePositioning: true,
            joystickPosX: GameSettings.arcadeJoystickX,
            joystickPosY: GameSettings.arcadeJoystickY,
            smashPosX: GameSettings.arcadeSmashX,
            smashPosY: GameSettings.arcadeSmashY,
            leftSpinPosX: GameSettings.arcadeLeftSpinX,
            leftSpinPosY: GameSettings.arcadeLeftSpinY,
            rightSpinPosX: GameSettings.arcadeRightSpinX,
            rightSpinPosY: GameSettings.arcadeRightSpinY,
            dashPosX: GameSettings.arcadeDashX,
            dashPosY: GameSettings.arcadeDashY,
            joystickExpand: 1.0,
            skillButtonScale: 1.0,
            smashScale: 1.0,
            leftSpinScale: 1.0,
            rightSpinScale: 1.0,
            dashScale: 1.0,
            joystickOnLeft: true,
          );
          break;
        case 'Compact Mode':
          _settings = _settings.copyWith(
            controlsPreset: 'Compact Mode',
            freePositioning: true,
            joystickPosX: 0.12,
            joystickPosY: 0.82,
            smashPosX: 0.90,
            smashPosY: 0.82,
            leftSpinPosX: 0.78,
            leftSpinPosY: 0.84,
            rightSpinPosX: 0.82,
            rightSpinPosY: 0.72,
            dashPosX: 0.90,
            dashPosY: 0.68,
            joystickExpand: 0.85,
            skillButtonScale: 0.85,
            smashScale: 0.85,
            leftSpinScale: 0.85,
            rightSpinScale: 0.85,
            dashScale: 0.85,
            joystickOnLeft: true,
          );
          break;
        case 'Pro Gamer / Wide':
          _settings = _settings.copyWith(
            controlsPreset: 'Pro Gamer / Wide',
            freePositioning: true,
            joystickPosX: 0.18,
            joystickPosY: 0.76,
            smashPosX: 0.84,
            smashPosY: 0.78,
            leftSpinPosX: 0.68,
            leftSpinPosY: 0.80,
            rightSpinPosX: 0.72,
            rightSpinPosY: 0.64,
            dashPosX: 0.84,
            dashPosY: 0.60,
            joystickExpand: 1.2,
            skillButtonScale: 1.15,
            smashScale: 1.2,
            leftSpinScale: 1.1,
            rightSpinScale: 1.1,
            dashScale: 1.1,
            joystickOnLeft: true,
          );
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isLeftHanded = !_settings.joystickOnLeft;
    final opacity = _settings.transparentCapacity.clamp(0.20, 1.0);
    final courtInfo = CourtCatalog.getById(GameStateManager.instance.equippedCourtId);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Full Pickleball Background Court Layout Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/background/hud_court_background.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _FullCourtPainter(
                    courtInfo: courtInfo,
                    isMini: false,
                    showGrid: _showGuides,
                  ),
                ),
              ),
            ),
            if (_showGuides)
              CustomPaint(
                size: Size.infinite,
                painter: _FullCourtPainter(
                  courtInfo: courtInfo,
                  isMini: false,
                  showGrid: true,
                ),
              ),

            // 2. Player (Front View) & Opponent Sprites on Court
            _CourtCharactersOverlay(
              screenSize: screenSize,
              isMini: false,
            ),

            // 3. Realistic Match Top Bar (Scores, Mode, Avatars)
            if (_showHudTopBar)
              _buildInGameTopBar(screenSize, courtInfo),

            // 4. Draggable Movement Joystick
            if (_settings.showJoystick)
              _buildDraggableWidget(
                element: 'joystick',
                screenSize: screenSize,
                isLeftHanded: isLeftHanded,
                size: 136.0 * _settings.joystickExpand,
                child: _buildJoystickGraphic(opacity),
              ),

            // 5. Draggable Basic Smash Attack (Unified 2D Arcade Paddle Button)
            if (_settings.showSkillButtons)
              _buildDraggableWidget(
                element: 'smash',
                screenSize: screenSize,
                isLeftHanded: isLeftHanded,
                size: 84.0 * _settings.smashScale,
                child: _buildSmashGraphic(opacity),
              ),

            // 6. Draggable Cyclone Curve (Skill 1 - K)
            if (_settings.showSkillButtons)
              _buildDraggableWidget(
                element: 'leftSpin',
                screenSize: screenSize,
                isLeftHanded: isLeftHanded,
                size: 58.0 * _settings.leftSpinScale,
                child: _buildSkillGraphic(
                  opacity: opacity,
                  gradient: const [Color(0xFF10B981), Color(0xFF047857)],
                  borderGlow: const Color(0xFF34D399),
                  icon: '🌪️',
                  keyBadge: 'K',
                  label: 'CYCLONE',
                  element: 'leftSpin',
                ),
              ),

            // 7. Draggable Vortex Hook (Skill 2 - L)
            if (_settings.showSkillButtons)
              _buildDraggableWidget(
                element: 'rightSpin',
                screenSize: screenSize,
                isLeftHanded: isLeftHanded,
                size: 58.0 * _settings.rightSpinScale,
                child: _buildSkillGraphic(
                  opacity: opacity,
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
                  borderGlow: const Color(0xFFA78BFA),
                  icon: '⚡',
                  keyBadge: 'L',
                  label: 'VORTEX',
                  element: 'rightSpin',
                ),
              ),

            // 8. Draggable Flash Dash (Skill 3 / Spell - Shift)
            if (_settings.showSkillButtons)
              _buildDraggableWidget(
                element: 'dash',
                screenSize: screenSize,
                isLeftHanded: isLeftHanded,
                size: 58.0 * _settings.dashScale,
                child: _buildSkillGraphic(
                  opacity: opacity,
                  gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
                  borderGlow: const Color(0xFF38BDF8),
                  icon: '💨',
                  keyBadge: 'SHIFT',
                  label: 'DASH',
                  element: 'dash',
                ),
              ),

            // 9. Top Controls Toolbar (FREE DRAG HUD EDITOR, MLBB DEFAULT, FLIP, GUIDES, SAVE & APPLY)
            _buildTopToolbar(context),

            // 10. Bottom Floating Inspector Bar (Selection, Nudge D-pad, Size & Opacity Sliders, Presets)
            _buildBottomInspectorBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopToolbar(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.4)),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.neonLime.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.touch_app_rounded, color: AppTheme.neonLime, size: 16),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('FREE DRAG HUD EDITOR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('Drag buttons anywhere on court • Layout preview', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // MLBB Default Reset
            Game2DButton(
              text: 'MLBB DEFAULT',
              icon: Icons.sports_esports_rounded,
              size: GameButtonSize.small,
              variant: GameButtonVariant.cyan,
              onPressed: _resetMlbb,
            ),
            const SizedBox(width: 6),
            // Flip Left / Right
            Game2DButton(
              text: 'FLIP',
              icon: Icons.swap_horiz_rounded,
              size: GameButtonSize.small,
              variant: GameButtonVariant.dark,
              onPressed: () {
                AudioService.instance.playButtonTap();
                setState(() {
                  _settings = _settings.copyWith(joystickOnLeft: !_settings.joystickOnLeft);
                });
              },
            ),
            const SizedBox(width: 6),
            // Save & Apply
            Game2DButton(
              text: 'SAVE & APPLY',
              icon: Icons.check_rounded,
              size: GameButtonSize.small,
              variant: GameButtonVariant.primary,
              onPressed: () {
                AudioService.instance.playButtonTap();
                widget.onSave(_settings);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                AudioService.instance.playButtonTap();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInGameTopBar(Size screenSize, CourtInfo courtInfo) {
    final state = GameStateManager.instance;
    final playerChar = CharacterRoster.getById(state.playerAvatarId);
    final isCompact = screenSize.width < 540;

    return Positioned(
      top: 56,
      left: 12,
      right: 12,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Player info (Left)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.neonLime.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.neonLime, width: 1.2),
                    ),
                    child: Center(
                      child: Text(playerChar.badge, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        playerChar.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9.5),
                      ),
                      const Text(
                        'YOU (HOME)',
                        style: TextStyle(color: AppTheme.neonLime, fontSize: 8, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppTheme.neonLime,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text('0', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),

              // Match Status / Rules Banner (Center)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: courtInfo.accentColor.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: courtInfo.accentColor, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          _settings.scoringMode == 'rally' ? '⚡ RALLY SCORING (11 PTS)' : '🏓 SIDE-OUT (11 PTS)',
                          style: TextStyle(color: courtInfo.accentColor, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(height: 2),
                    Text(
                      courtInfo.name,
                      style: const TextStyle(color: Colors.white60, fontSize: 7.5),
                    ),
                  ],
                ],
              ),

              // Opponent info (Right)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3366),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text('0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CPU CHALLENGER',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9.5),
                      ),
                      Text(
                        'AWAY',
                        style: TextStyle(color: Color(0xFFFF3366), fontSize: 8, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3366).withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF3366), width: 1.2),
                    ),
                    child: const Center(
                      child: Text('🤖', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableWidget({
    required String element,
    required Size screenSize,
    required bool isLeftHanded,
    required double size,
    required Widget child,
  }) {
    final normX = _getX(element);
    final normY = _getY(element);
    final effX = isLeftHanded ? (1.0 - normX) : normX;
    final isSelected = _selectedElement == element;
    final label = _name(element);

    final left = (effX * screenSize.width - size / 2).clamp(4.0, screenSize.width - size - 4.0);
    final top = (normY * screenSize.height - size / 2).clamp(48.0, screenSize.height - size - 64.0);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AudioService.instance.playButtonTap();
          setState(() => _selectedElement = element);
        },
        onPanStart: (_) {
          setState(() => _selectedElement = element);
        },
        onPanUpdate: (details) {
          final curX = _getX(element);
          final curY = _getY(element);
          final dx = (isLeftHanded ? -details.delta.dx : details.delta.dx) / screenSize.width;
          final dy = details.delta.dy / screenSize.height;
          _updatePos(element, curX + dx, curY + dy);
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Selected Glowing Border
            if (isSelected) ...[
              Container(
                width: size + 14,
                height: size + 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neonLime, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonLime.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Floating live coordinates chip
              Positioned(
                top: -24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.neonLime, width: 1),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drag_indicator_rounded, color: AppTheme.neonLime, size: 10),
                      const SizedBox(width: 3),
                      Text(
                        '$label (${(normX * 100).round()}%, ${(normY * 100).round()}%)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // The Graphic Controller
            SizedBox(
              width: size,
              height: size,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoystickGraphic(double opacity) {
    final isSelected = _selectedElement == 'joystick';
    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.neonLime : const Color(0xFF38BDF8).withValues(alpha: 0.8),
            width: isSelected ? 3.0 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppTheme.neonLime.withValues(alpha: 0.3) : const Color(0xFF38BDF8).withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(top: 6, child: Icon(Icons.arrow_drop_up_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18)),
            Positioned(bottom: 6, child: Icon(Icons.arrow_drop_down_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18)),
            Positioned(left: 6, child: Icon(Icons.arrow_left_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18)),
            Positioned(right: 6, child: Icon(Icons.arrow_right_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18)),
            Container(
              width: 52.0 * _settings.joystickExpand,
              height: 52.0 * _settings.joystickExpand,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [Color(0xFF67E8F9), Color(0xFF0284C7)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
              ),
              child: const Center(
                child: Icon(Icons.gamepad_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmashGraphic(double opacity) {
    final isSelected = _selectedElement == 'smash';
    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B0F19), // Dark arcade casing
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.neonLime : const Color(0xFFFFD700),
            width: isSelected ? 3.5 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.neonLime.withValues(alpha: 0.6)
                  : const Color(0xFFFF2D55).withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFFFF3366), Color(0xFFB71C1C)],
              radius: 0.85,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/items/paddle_wooden.png',
                  width: 34.0 * _settings.smashScale,
                  height: 34.0 * _settings.smashScale,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.sports_tennis_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 1),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SMASH',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkillGraphic({
    required double opacity,
    required List<Color> gradient,
    required Color borderGlow,
    required String icon,
    required String keyBadge,
    required String label,
    required String element,
  }) {
    final isSelected = _selectedElement == element;
    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: gradient),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.neonLime : borderGlow,
            width: isSelected ? 3.0 : 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: borderGlow.withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 17)),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white30, width: 0.5),
                ),
                child: Text(
                  keyBadge,
                  style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInspectorBar(BuildContext context) {
    final currentScale = _selectedElement == 'joystick'
        ? _settings.joystickExpand
        : (_selectedElement == 'smash'
            ? _settings.smashScale
            : (_selectedElement == 'leftSpin'
                ? _settings.leftSpinScale
                : (_selectedElement == 'rightSpin'
                    ? _settings.rightSpinScale
                    : (_selectedElement == 'dash'
                        ? _settings.dashScale
                        : _settings.skillButtonScale))));
    final currentOpacity = _settings.transparentCapacity;

    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 10)],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Element Selector Chips
              _buildInspectorChip('joystick', '🕹️ Joystick'),
              const SizedBox(width: 4),
              _buildInspectorChip('smash', '💥 Smash'),
              const SizedBox(width: 4),
              _buildInspectorChip('leftSpin', '🌪️ Cyclone'),
              const SizedBox(width: 4),
              _buildInspectorChip('rightSpin', '⚡ Vortex'),
              const SizedBox(width: 4),
              _buildInspectorChip('dash', '💨 Dash'),
              const SizedBox(width: 10),

              // Divider
              Container(width: 1, height: 26, color: Colors.white24),
              const SizedBox(width: 10),

              // 2. 4-Way Nudge D-Pad for Pixel Precision
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNudgeButton(Icons.arrow_left_rounded, () => _nudgeSelected(-0.01, 0)),
                  _buildNudgeButton(Icons.arrow_drop_up_rounded, () => _nudgeSelected(0, -0.01)),
                  _buildNudgeButton(Icons.arrow_drop_down_rounded, () => _nudgeSelected(0, 0.01)),
                  _buildNudgeButton(Icons.arrow_right_rounded, () => _nudgeSelected(0.01, 0)),
                  const SizedBox(width: 3),
                  InkWell(
                    onTap: _resetSelectedElement,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restart_alt_rounded, size: 12, color: Colors.white70),
                          SizedBox(width: 2),
                          Text('RESET', style: TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Guides grid toggle
                  InkWell(
                    onTap: () {
                      AudioService.instance.playButtonTap();
                      setState(() => _showGuides = !_showGuides);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showGuides ? AppTheme.neonLime.withValues(alpha: 0.25) : Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _showGuides ? AppTheme.neonLime : Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grid_4x4_rounded, size: 12, color: _showGuides ? AppTheme.neonLime : Colors.white70),
                          const SizedBox(width: 2),
                          Text(
                            _showGuides ? 'GUIDES: ON' : 'GUIDES',
                            style: TextStyle(
                              color: _showGuides ? AppTheme.neonLime : Colors.white70,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // HUD score bar toggle
                  InkWell(
                    onTap: () {
                      AudioService.instance.playButtonTap();
                      setState(() => _showHudTopBar = !_showHudTopBar);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showHudTopBar ? AppTheme.electricCyan.withValues(alpha: 0.25) : Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _showHudTopBar ? AppTheme.electricCyan : Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.splitscreen_rounded, size: 12, color: _showHudTopBar ? AppTheme.electricCyan : Colors.white70),
                          const SizedBox(width: 2),
                          Text(
                            _showHudTopBar ? 'HUD: ON' : 'HUD',
                            style: TextStyle(
                              color: _showHudTopBar ? AppTheme.electricCyan : Colors.white70,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),

              // Divider
              Container(width: 1, height: 26, color: Colors.white24),
              const SizedBox(width: 10),

              // 3. Size Slider
              Text('Size: ${(currentScale * 100).round()}%', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
              SizedBox(
                width: 85,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    activeTrackColor: AppTheme.neonLime,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: currentScale,
                    min: 0.65,
                    max: 1.5,
                    onChanged: (val) {
                      setState(() {
                        if (_selectedElement == 'joystick') {
                          _settings = _settings.copyWith(joystickExpand: val);
                        } else if (_selectedElement == 'smash') {
                          _settings = _settings.copyWith(smashScale: val);
                        } else if (_selectedElement == 'leftSpin') {
                          _settings = _settings.copyWith(leftSpinScale: val);
                        } else if (_selectedElement == 'rightSpin') {
                          _settings = _settings.copyWith(rightSpinScale: val);
                        } else if (_selectedElement == 'dash') {
                          _settings = _settings.copyWith(dashScale: val);
                        } else {
                          _settings = _settings.copyWith(skillButtonScale: val);
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 4. Opacity Slider
              Text('Opacity: ${(currentOpacity * 100).round()}%', style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
              SizedBox(
                width: 75,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    activeTrackColor: AppTheme.electricCyan,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: currentOpacity,
                    min: 0.2,
                    max: 1.0,
                    onChanged: (val) {
                      setState(() {
                        _settings = _settings.copyWith(transparentCapacity: val);
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Divider
              Container(width: 1, height: 26, color: Colors.white24),
              const SizedBox(width: 8),

              // 5. Quick Presets Row
              _buildPresetChip('MLBB', 'Mobile Legends (Default)', AppTheme.neonLime),
              const SizedBox(width: 4),
              _buildPresetChip('ARCADE', 'Default Arcade', AppTheme.electricCyan),
              const SizedBox(width: 4),
              _buildPresetChip('COMPACT', 'Compact Mode', const Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              _buildPresetChip('PRO WIDE', 'Pro Gamer / Wide', const Color(0xFFA855F7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectorChip(String element, String label) {
    final isSelected = _selectedElement == element;
    return InkWell(
      onTap: () {
        AudioService.instance.playButtonTap();
        setState(() => _selectedElement = element);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonLime.withValues(alpha: 0.25) : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.neonLime : Colors.white24,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.neonLime : Colors.white70,
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNudgeButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(3),
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildPresetChip(String shortLabel, String presetName, Color color) {
    return InkWell(
      onTap: () => _applyPresetInEditor(presetName),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.7)),
        ),
        child: Text(
          shortLabel,
          style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Standalone Widget rendering court players in front-view stance
class _CourtCharactersOverlay extends StatelessWidget {
  final Size screenSize;
  final bool isMini;

  const _CourtCharactersOverlay({
    required this.screenSize,
    this.isMini = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = GameStateManager.instance;
    final playerChar = CharacterRoster.getById(state.playerAvatarId);
    final isLandscape = screenSize.width > screenSize.height;

    final courtWidth = isMini
        ? screenSize.width * 0.68
        : (isLandscape ? math.min(screenSize.width * 0.48, screenSize.height * 0.95) : screenSize.width * 0.82);
    final courtHeight = isMini
        ? screenSize.height * 0.82
        : (isLandscape ? screenSize.height * 0.86 : screenSize.height * 0.78);
    final courtCenter = Offset(screenSize.width / 2, screenSize.height / 2);
    final courtRect = Rect.fromCenter(center: courtCenter, width: courtWidth, height: courtHeight);

    final charHeight = isMini ? 34.0 : (isLandscape ? 70.0 : 60.0);
    final playerY = courtRect.bottom - (courtRect.height * 0.16) - charHeight / 2;
    final opponentY = courtRect.top + (courtRect.height * 0.16) - charHeight / 2;

    return Stack(
      children: [
        // Opponent on top side of court
        Positioned(
          left: courtCenter.dx - charHeight / 2,
          top: opponentY,
          child: IgnorePointer(
            child: _buildSpriteItem(
              char: CharacterRoster.maya,
              height: charHeight,
              isOpponent: true,
              isMini: isMini,
            ),
          ),
        ),

        // Player on bottom side of court (Front view stance)
        Positioned(
          left: courtCenter.dx - charHeight / 2,
          top: playerY,
          child: IgnorePointer(
            child: _buildSpriteItem(
              char: playerChar,
              height: charHeight,
              isOpponent: false,
              isMini: isMini,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpriteItem({
    required CharacterInfo char,
    required double height,
    required bool isOpponent,
    bool isMini = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOpponent && !isMini)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24, width: 0.8),
            ),
            child: const Text(
              '🤖 CPU CHALLENGER',
              style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 1,
              child: Container(
                width: height * 0.75,
                height: isMini ? 5 : 10,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(
              width: height,
              height: height,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.5,
                  child: Image.asset(
                    char.charSelectIdlePath,
                    width: height * 2,
                    height: height,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (_, _, _) => Icon(
                      isOpponent ? Icons.smart_toy_rounded : Icons.person_rounded,
                      color: isOpponent ? Colors.white54 : AppTheme.neonLime,
                      size: height * 0.7,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!isOpponent && !isMini)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.8), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(char.badge, style: const TextStyle(fontSize: 9)),
                const SizedBox(width: 3),
                Text(
                  '${char.name.toUpperCase()} (YOU)',
                  style: const TextStyle(color: AppTheme.neonLime, fontSize: 8.5, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Full Authentic Pickleball Court Painter
class _FullCourtPainter extends CustomPainter {
  final CourtInfo courtInfo;
  final bool isMini;
  final bool showGrid;

  const _FullCourtPainter({
    required this.courtInfo,
    this.isMini = false,
    this.showGrid = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isLandscape = size.width > size.height;

    // 1. Apron Floor Background Gradient
    final floorRect = Offset.zero & size;
    final floorPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: isMini ? 0.85 : 1.1,
        colors: [
          courtInfo.apronColor,
          courtInfo.apronOuterColor,
        ],
      ).createShader(floorRect);
    canvas.drawRect(floorRect, floorPaint);

    // 2. Court Dimensions & Geometry
    final courtWidth = isMini
        ? size.width * 0.68
        : (isLandscape ? math.min(size.width * 0.48, size.height * 0.95) : size.width * 0.82);
    final courtHeight = isMini
        ? size.height * 0.82
        : (isLandscape ? size.height * 0.86 : size.height * 0.78);
    final courtCenter = Offset(size.width / 2, size.height / 2);
    final courtRect = Rect.fromCenter(center: courtCenter, width: courtWidth, height: courtHeight);

    // Drop Shadow under Court
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isMini ? 4 : 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(courtRect.inflate(isMini ? 3 : 6), Radius.circular(isMini ? 4 : 8)),
      shadowPaint,
    );

    // 3. Main Court Surface (Service Area)
    final surfacePaint = Paint()..color = courtInfo.courtColor;
    canvas.drawRect(courtRect, surfacePaint);

    // 4. Kitchen / Non-Volley Zone (Center third of court)
    final kitchenHeight = courtRect.height * 0.18;
    final kitchenRect = Rect.fromCenter(
      center: courtCenter,
      width: courtRect.width,
      height: kitchenHeight * 2,
    );
    final kitchenPaint = Paint()..color = courtInfo.kitchenColor;
    canvas.drawRect(kitchenRect, kitchenPaint);

    // Subtle texture / acrylic floor lines on court surface
    final texturePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    final step = isMini ? 12.0 : 20.0;
    for (double y = courtRect.top; y <= courtRect.bottom; y += step) {
      canvas.drawLine(Offset(courtRect.left, y), Offset(courtRect.right, y), texturePaint);
    }

    // 5. White / Line Paint
    final lineWidth = isMini ? 1.5 : 2.5;
    final linePaint = Paint()
      ..color = courtInfo.lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..isAntiAlias = true;

    // Outer Boundary (Baselines & Sidelines)
    canvas.drawRect(courtRect, linePaint);

    // Kitchen Lines (Non-Volley Zone Boundaries)
    canvas.drawLine(
      Offset(courtRect.left, courtCenter.dy - kitchenHeight),
      Offset(courtRect.right, courtCenter.dy - kitchenHeight),
      linePaint,
    );
    canvas.drawLine(
      Offset(courtRect.left, courtCenter.dy + kitchenHeight),
      Offset(courtRect.right, courtCenter.dy + kitchenHeight),
      linePaint,
    );

    // Center Service Lines (from Baselines to Kitchen Lines)
    canvas.drawLine(
      Offset(courtCenter.dx, courtRect.top),
      Offset(courtCenter.dx, courtCenter.dy - kitchenHeight),
      linePaint,
    );
    canvas.drawLine(
      Offset(courtCenter.dx, courtCenter.dy + kitchenHeight),
      Offset(courtCenter.dx, courtRect.bottom),
      linePaint,
    );

    // Centerline hash marks on baselines
    final hashLength = isMini ? 4.0 : 8.0;
    canvas.drawLine(
      Offset(courtCenter.dx, courtRect.top),
      Offset(courtCenter.dx, courtRect.top + hashLength),
      linePaint,
    );
    canvas.drawLine(
      Offset(courtCenter.dx, courtRect.bottom - hashLength),
      Offset(courtCenter.dx, courtRect.bottom),
      linePaint,
    );

    // 6. Realistic 2D Pickleball Net
    final netY = courtCenter.dy;
    final postExtension = isMini ? 8.0 : 16.0;
    final netLeft = courtRect.left - postExtension;
    final netRight = courtRect.right + postExtension;

    // Net drop shadow
    final netShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..strokeWidth = isMini ? 4.0 : 7.0;
    canvas.drawLine(
      Offset(netLeft, netY + (isMini ? 2 : 4)),
      Offset(netRight, netY + (isMini ? 2 : 4)),
      netShadowPaint,
    );

    // Net mesh
    final meshPaint = Paint()
      ..color = courtInfo.netMeshColor.withValues(alpha: 0.7)
      ..strokeWidth = isMini ? 1.0 : 2.0;
    canvas.drawLine(Offset(courtRect.left, netY), Offset(courtRect.right, netY), meshPaint);

    // Net tape (crisp white/yellow header)
    final tapePaint = Paint()
      ..color = courtInfo.netTapeColor
      ..strokeWidth = isMini ? 2.5 : 4.0;
    canvas.drawLine(Offset(courtRect.left, netY - 1), Offset(courtRect.right, netY - 1), tapePaint);

    // Net posts (left & right)
    final postRadius = isMini ? 3.0 : 5.0;
    final postPaint = Paint()..color = const Color(0xFF374151);
    final postCapPaint = Paint()..color = courtInfo.accentColor;
    canvas.drawCircle(Offset(netLeft, netY), postRadius, postPaint);
    canvas.drawCircle(Offset(netLeft, netY), postRadius * 0.5, postCapPaint);
    canvas.drawCircle(Offset(netRight, netY), postRadius, postPaint);
    canvas.drawCircle(Offset(netRight, netY), postRadius * 0.5, postCapPaint);

    // 7. Optional Alignment Grid / Guides
    if (showGrid) {
      final gridPaint = Paint()
        ..color = AppTheme.neonLime.withValues(alpha: 0.22)
        ..strokeWidth = 1.0;
      final crosshairPaint = Paint()
        ..color = AppTheme.electricCyan.withValues(alpha: 0.45)
        ..strokeWidth = 1.2;

      for (double xRatio in [0.25, 0.33, 0.5, 0.67, 0.75]) {
        final x = size.width * xRatio;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), xRatio == 0.5 ? crosshairPaint : gridPaint);
      }
      for (double yRatio in [0.25, 0.33, 0.5, 0.67, 0.75]) {
        final y = size.height * yRatio;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), yRatio == 0.5 ? crosshairPaint : gridPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FullCourtPainter oldDelegate) {
    return oldDelegate.courtInfo.id != courtInfo.id ||
        oldDelegate.isMini != isMini ||
        oldDelegate.showGrid != showGrid;
  }
}
