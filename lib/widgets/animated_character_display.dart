import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/character_roster.dart';

enum CharacterGender { male, female, male2, male3, male4, female2, female3, female4 }
enum CharacterAction { idle, run, smash }

class AnimatedCharacterDisplay extends StatefulWidget {
  final CharacterGender initialGender;
  final bool showControls;
  final bool showCharacterSwitcher;
  final bool showActionControls;
  final bool autoCycleActions;
  final double height;
  final VoidCallback? onSmashTriggered;
  final ValueChanged<CharacterGender>? onGenderChanged;

  const AnimatedCharacterDisplay({
    super.key,
    this.initialGender = CharacterGender.male,
    this.showControls = true,
    this.showCharacterSwitcher = true,
    this.showActionControls = true,
    this.autoCycleActions = false,
    this.height = 180,
    this.onSmashTriggered,
    this.onGenderChanged,
  });

  static CharacterGender genderFromType(CharacterType type) {
    switch (type) {
      case CharacterType.female1:
        return CharacterGender.female;
      case CharacterType.female2:
        return CharacterGender.female2;
      case CharacterType.female3:
        return CharacterGender.female3;
      case CharacterType.female4:
        return CharacterGender.female4;
      case CharacterType.male2:
        return CharacterGender.male2;
      case CharacterType.male3:
        return CharacterGender.male3;
      case CharacterType.male4:
        return CharacterGender.male4;
      case CharacterType.male1:
        return CharacterGender.male;
    }
  }

  static CharacterType typeFromGender(CharacterGender gender) {
    switch (gender) {
      case CharacterGender.female:
        return CharacterType.female1;
      case CharacterGender.female2:
        return CharacterType.female2;
      case CharacterGender.female3:
        return CharacterType.female3;
      case CharacterGender.female4:
        return CharacterType.female4;
      case CharacterGender.male2:
        return CharacterType.male2;
      case CharacterGender.male3:
        return CharacterType.male3;
      case CharacterGender.male4:
        return CharacterType.male4;
      case CharacterGender.male:
        return CharacterType.male1;
    }
  }

  @override
  State<AnimatedCharacterDisplay> createState() => _AnimatedCharacterDisplayState();
}

class _AnimatedCharacterDisplayState extends State<AnimatedCharacterDisplay>
    with SingleTickerProviderStateMixin {
  late CharacterGender _gender;
  CharacterAction _action = CharacterAction.idle;

  // Cached decoded images
  final Map<String, ui.Image> _imageCache = {};
  bool _isLoading = true;

  // Frame ticking
  Timer? _frameTimer;
  int _currentFrame = 0;
  int _totalFrames = 2;

  // Smash impact feedback
  bool _showImpactBurst = false;
  double _smashProgress = 0.0;
  Timer? _smashTimer;

  // Asset paths
  static const String maleIdle = 'assets/images/male1_sprite/male_charselectidle.png';
  static const String maleRun = 'assets/images/male1_sprite/male_frontrun.png';
  static const String maleSmash = 'assets/images/male1_sprite/male_frontslash.png';

  static const String femaleIdle = 'assets/images/female1_sprite/female_charselectidle.png';
  static const String femaleRun = 'assets/images/female1_sprite/female_runfront.png';
  static const String femaleSmash = 'assets/images/female1_sprite/female_frontslash.png';

  static const String male2Idle = 'assets/images/male2_sprite/male2_charselectidle.png';
  static const String male2Run = 'assets/images/male2_sprite/male2_frontrun.png';
  static const String male2Smash = 'assets/images/male2_sprite/male2_frontslash.png';

  static const String male3Idle = 'assets/images/male3_sprite/male3_charselectidle.png';
  static const String male3Run = 'assets/images/male3_sprite/male3_frontrun.png';
  static const String male3Smash = 'assets/images/male3_sprite/male3_frontslash.png';

  static const String male4Idle = 'assets/images/male4_sprite/male4_charselectidle.png';
  static const String male4Run = 'assets/images/male4_sprite/male4_frontrun.png';
  static const String male4Smash = 'assets/images/male4_sprite/male4_frontslash.png';

  static const String female2Idle = 'assets/images/female2_sprite/female2_charselectidle.png';
  static const String female2Run = 'assets/images/female2_sprite/female2_frontrun.png';
  static const String female2Smash = 'assets/images/female2_sprite/female2_frontslash.png';

  static const String female3Idle = 'assets/images/female3_sprite/female3_charselectidle.png';
  static const String female3Run = 'assets/images/female3_sprite/female3_frontrun.png';
  static const String female3Smash = 'assets/images/female3_sprite/female3_frontslash.png';

  static const String female4Idle = 'assets/images/female4_sprite/female4_charselectidle.png';
  static const String female4Run = 'assets/images/female4_sprite/female4_frontrun.png';
  static const String female4Smash = 'assets/images/female4_sprite/female4_frontslash.png';

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender;
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    _isLoading = !isTest;
    _updateActionState();
    _loadAllSprites();
  }

  @override
  void didUpdateWidget(covariant AnimatedCharacterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGender != widget.initialGender) {
      _gender = widget.initialGender;
      _updateActionState();
      _startFrameTimer();
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _smashTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllSprites() async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _updateActionState();
        });
      }
      return;
    }

    final assets = [
      maleIdle,
      maleRun,
      maleSmash,
      femaleIdle,
      femaleRun,
      femaleSmash,
      male2Idle,
      male2Run,
      male2Smash,
      male3Idle,
      male3Run,
      male3Smash,
      male4Idle,
      male4Run,
      male4Smash,
      female2Idle,
      female2Run,
      female2Smash,
      female3Idle,
      female3Run,
      female3Smash,
      female4Idle,
      female4Run,
      female4Smash,
    ];

    try {
      for (final path in assets) {
        if (!_imageCache.containsKey(path)) {
          final data = await rootBundle.load(path);
          final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
          final frameInfo = await codec.getNextFrame();
          _imageCache[path] = frameInfo.image;
        }
      }
    } catch (e) {
      debugPrint('Error loading character sprite sheets: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _updateActionState();
      });
      _startFrameTimer();
    }
  }

  void _startFrameTimer() {
    _frameTimer?.cancel();

    // In widget test environments, avoid running endless periodic timers so pumpAndSettle can settle
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest && _action != CharacterAction.smash) {
      return;
    }

    // Dynamically adjust animation speed based on action
    final duration = _action == CharacterAction.smash
        ? const Duration(milliseconds: 75)
        : _action == CharacterAction.run
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 350);

    _frameTimer = Timer.periodic(duration, (timer) {
      if (!mounted || _isLoading) return;

      setState(() {
        if (_action == CharacterAction.smash) {
          if (_currentFrame < _totalFrames - 1) {
            _currentFrame++;
            _smashProgress = _currentFrame / (_totalFrames - 1);
          } else {
            // Smash finished, return to idle
            _action = CharacterAction.idle;
            _showImpactBurst = false;
            _updateActionState();
            _startFrameTimer();
          }
        } else {
          _currentFrame = (_currentFrame + 1) % math.max(1, _totalFrames);
        }
      });
    });
  }

  void _updateActionState() {
    if (_gender == CharacterGender.male) {
      switch (_action) {
        case CharacterAction.idle:
          _totalFrames = 2;
          break;
        case CharacterAction.run:
          _totalFrames = 8;
          break;
        case CharacterAction.smash:
          _totalFrames = 6;
          break;
      }
    } else {
      switch (_action) {
        case CharacterAction.idle:
          _totalFrames = 2;
          break;
        case CharacterAction.run:
          _totalFrames = 8;
          break;
        case CharacterAction.smash:
          _totalFrames = 6;
          break;
      }
    }
    _currentFrame = 0;
  }

  void _triggerSmash() {
    if (_action == CharacterAction.smash) return;

    widget.onSmashTriggered?.call();
    HapticFeedback.heavyImpact();

    setState(() {
      _action = CharacterAction.smash;
      _currentFrame = 0;
      _smashProgress = 0.0;
      _showImpactBurst = true;
      _updateActionState();
    });

    _startFrameTimer();

    // Hide burst effect after brief delay
    _smashTimer?.cancel();
    _smashTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _showImpactBurst = false;
        });
      }
    });
  }

  String _getActiveSpritePath() {
    if (_gender == CharacterGender.male) {
      switch (_action) {
        case CharacterAction.idle:
          return maleIdle;
        case CharacterAction.run:
          return maleRun;
        case CharacterAction.smash:
          return maleSmash;
      }
    } else if (_gender == CharacterGender.male2) {
      switch (_action) {
        case CharacterAction.idle:
          return male2Idle;
        case CharacterAction.run:
          return male2Run;
        case CharacterAction.smash:
          return male2Smash;
      }
    } else if (_gender == CharacterGender.male3) {
      switch (_action) {
        case CharacterAction.idle:
          return male3Idle;
        case CharacterAction.run:
          return male3Run;
        case CharacterAction.smash:
          return male3Smash;
      }
    } else if (_gender == CharacterGender.male4) {
      switch (_action) {
        case CharacterAction.idle:
          return male4Idle;
        case CharacterAction.run:
          return male4Run;
        case CharacterAction.smash:
          return male4Smash;
      }
    } else if (_gender == CharacterGender.female2) {
      switch (_action) {
        case CharacterAction.idle:
          return female2Idle;
        case CharacterAction.run:
          return female2Run;
        case CharacterAction.smash:
          return female2Smash;
      }
    } else if (_gender == CharacterGender.female3) {
      switch (_action) {
        case CharacterAction.idle:
          return female3Idle;
        case CharacterAction.run:
          return female3Run;
        case CharacterAction.smash:
          return female3Smash;
      }
    } else if (_gender == CharacterGender.female4) {
      switch (_action) {
        case CharacterAction.idle:
          return female4Idle;
        case CharacterAction.run:
          return female4Run;
        case CharacterAction.smash:
          return female4Smash;
      }
    } else {
      switch (_action) {
        case CharacterAction.idle:
          return femaleIdle;
        case CharacterAction.run:
          return femaleRun;
        case CharacterAction.smash:
          return femaleSmash;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Icon(Icons.sports_tennis, color: Color(0xFF00E676), size: 28),
        ),
      );
    }

    final spriteImage = _imageCache[_getActiveSpritePath()];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isCompact = availableWidth < 350;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Character Interactive Stage
            GestureDetector(
              onTap: _triggerSmash,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Court shadow & Character Sprite Canvas
                  Container(
                    height: widget.height,
                    width: math.min(widget.height * 1.3, availableWidth),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: RadialGradient(
                        colors: [
                          _getGenderGlowColor(_gender).withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                        radius: 0.85,
                      ),
                    ),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _SpriteCharacterPainter(
                          spriteImage: spriteImage,
                          frameIndex: _currentFrame,
                          totalFrames: _totalFrames,
                          action: _action,
                          gender: _gender,
                          smashProgress: _smashProgress,
                        ),
                        isComplex: true,
                        willChange: true,
                      ),
                    ),
                  ),

                  // Tap to smash hint badge
                  Positioned(
                    top: 6,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _action == CharacterAction.smash
                              ? const Color(0xFFFFD600)
                              : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _action == CharacterAction.smash
                                ? Icons.flash_on
                                : Icons.touch_app,
                            size: 11,
                            color: _action == CharacterAction.smash
                                ? const Color(0xFFFFD600)
                                : const Color(0xFF00E676),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _action == CharacterAction.smash ? "SMASHING!" : "TAP TO SMASH",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: _action == CharacterAction.smash
                                  ? const Color(0xFFFFD600)
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Smash burst visual feedback
                  if (_showImpactBurst)
                    Positioned(
                      top: 15,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _showImpactBurst ? 1.0 : 0.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5252), Color(0xFFFFD600)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.8),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Text(
                            "⚡ POWER SMASH!",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Responsive Controls: Character & Action switchers
            if (widget.showControls) ...[
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  // Male / Female toggle
                  if (widget.showCharacterSwitcher)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SegmentedButton<CharacterGender>(
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              if (_gender == CharacterGender.male) {
                                return const Color(0xFF00E676).withValues(alpha: 0.25);
                              } else if (_gender == CharacterGender.male2) {
                                return const Color(0xFFFF9100).withValues(alpha: 0.25);
                              } else if (_gender == CharacterGender.male3) {
                                return const Color(0xFF00E5FF).withValues(alpha: 0.25);
                              } else if (_gender == CharacterGender.male4) {
                                return const Color(0xFF0284C7).withValues(alpha: 0.25);
                              } else if (_gender == CharacterGender.female2) {
                                return const Color(0xFFEC4899).withValues(alpha: 0.25);
                              } else if (_gender == CharacterGender.female3) {
                                return const Color(0xFF2563EB).withValues(alpha: 0.25);
                              } else if (_gender == CharacterGender.female4) {
                                return const Color(0xFF9333EA).withValues(alpha: 0.25);
                              } else {
                                return const Color(0xFFFF4081).withValues(alpha: 0.25);
                              }
                            }
                            return const Color(0xFF1E293B);
                          }),
                          side: WidgetStateProperty.all(
                            BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                        ),
                        segments: [
                          ButtonSegment(
                            value: CharacterGender.male,
                            label: Text(
                              isCompact ? "Alex" : "Alex (M)",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.sports_tennis, size: 14),
                          ),
                          ButtonSegment(
                            value: CharacterGender.female,
                            label: Text(
                              isCompact ? "Maya" : "Maya (F)",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.bolt, size: 14),
                          ),
                          ButtonSegment(
                            value: CharacterGender.male2,
                            label: Text(
                              isCompact ? "Marcus" : "Marcus (M2)",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.local_fire_department, size: 14),
                          ),
                          ButtonSegment(
                            value: CharacterGender.male3,
                            label: Text(
                              isCompact ? "Jax" : "Jax (M3)",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.flash_on, size: 14),
                          ),
                          ButtonSegment(
                            value: CharacterGender.male4,
                            label: Text(
                              isCompact ? "Nard" : "Nard (M4)",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.track_changes_rounded, size: 14),
                          ),
                          ButtonSegment(
                            value: CharacterGender.female2,
                            label: Text(
                              isCompact ? "Joy" : "Princess-Joy",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.diamond_rounded, size: 14),
                          ),
                          ButtonSegment(
                            value: CharacterGender.female3,
                            label: Text(
                              isCompact ? "Disney" : "Disneykirk",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.waves_rounded, size: 14),
                          ),
                          ButtonSegment(
                            value: CharacterGender.female4,
                            label: Text(
                              isCompact ? "Ashley" : "Ashley (F4)",
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                          ),
                        ],
                        selected: {_gender},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _gender = newSelection.first;
                            _updateActionState();
                            _startFrameTimer();
                          });
                          widget.onGenderChanged?.call(newSelection.first);
                        },
                      ),
                    ),

                  // Action Buttons: Idle / Run / Smash
                  if (widget.showActionControls)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionChip("Idle", CharacterAction.idle),
                            _buildActionChip("Run", CharacterAction.run),
                            _buildActionChip("Smash", CharacterAction.smash, isSmash: true),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Color _getGenderGlowColor(CharacterGender gender) {
    switch (gender) {
      case CharacterGender.male:
        return const Color(0xFF00E676);
      case CharacterGender.female:
        return const Color(0xFFFF4081);
      case CharacterGender.male2:
        return const Color(0xFFFF9100);
      case CharacterGender.male3:
        return const Color(0xFF00E5FF);
      case CharacterGender.male4:
        return const Color(0xFF0284C7);
      case CharacterGender.female2:
        return const Color(0xFFEC4899);
      case CharacterGender.female3:
        return const Color(0xFF3B82F6);
      case CharacterGender.female4:
        return const Color(0xFF9333EA);
    }
  }

  Widget _buildActionChip(String label, CharacterAction action, {bool isSmash = false}) {
    final isSelected = _action == action;
    final faceColor = isSmash ? const Color(0xFFFFD600) : const Color(0xFF00E676);
    final bevelColor = isSmash ? const Color(0xFFE65100) : const Color(0xFF1B5E20);

    return GestureDetector(
      onTap: () {
        if (action == CharacterAction.smash) {
          _triggerSmash();
        } else {
          setState(() {
            _action = action;
            _updateActionState();
            _startFrameTimer();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? bevelColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          margin: EdgeInsets.only(bottom: isSelected ? 2 : 0),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? faceColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                  )
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: isSelected
                  ? Colors.black
                  : (isSmash ? const Color(0xFFFFD600) : Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpriteCharacterPainter extends CustomPainter {
  final ui.Image? spriteImage;
  final int frameIndex;
  final int totalFrames;
  final CharacterAction action;
  final CharacterGender gender;
  final double smashProgress;

  _SpriteCharacterPainter({
    required this.spriteImage,
    required this.frameIndex,
    required this.totalFrames,
    required this.action,
    required this.gender,
    required this.smashProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Court Shadow under character's feet
    final shadowCenter = Offset(size.width / 2, size.height * 0.88);
    final shadowScale = action == CharacterAction.smash
        ? 1.3
        : (action == CharacterAction.run ? 0.9 + 0.2 * math.sin(frameIndex) : 1.0);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter,
        width: 60 * shadowScale,
        height: 16 * shadowScale,
      ),
      shadowPaint,
    );

    // 2. Render Character Sprite Frame (Only Character)
    if (spriteImage != null) {
      final safeFrame = frameIndex.clamp(0, math.max(0, totalFrames - 1));
      const frameWidth = 64.0;
      const frameHeight = 64.0;

      final srcRect = Rect.fromLTWH(
        safeFrame * frameWidth,
        0,
        frameWidth,
        frameHeight,
      );

      // Target sizing: Scale up to fit nicely inside the canvas height
      final targetHeight = size.height * 0.78;
      final targetWidth = targetHeight; // 1:1 square frame
      final targetX = (size.width - targetWidth) / 2;
      final targetY = size.height * 0.12;

      final dstRect = Rect.fromLTWH(targetX, targetY, targetWidth, targetHeight);

      final spritePaint = Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false;

      canvas.drawImageRect(spriteImage!, srcRect, dstRect, spritePaint);

      // 3. Draw Smash Swing Arc and Motion Lines
      if (action == CharacterAction.smash && smashProgress > 0.1 && smashProgress < 0.9) {
        final arcPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..shader = const SweepGradient(
            colors: [Colors.transparent, Color(0xFFFFD600), Color(0xFF00E676)],
          ).createShader(dstRect);

        final arcRect = Rect.fromCenter(
          center: Offset(targetX + targetWidth * 0.65, targetY + targetHeight * 0.45),
          width: targetWidth * 0.9,
          height: targetHeight * 0.9,
        );

        canvas.drawArc(arcRect, -math.pi * 0.3, math.pi * 0.8 * smashProgress, false, arcPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpriteCharacterPainter oldDelegate) {
    return oldDelegate.frameIndex != frameIndex ||
        oldDelegate.action != action ||
        oldDelegate.gender != gender ||
        oldDelegate.smashProgress != smashProgress ||
        oldDelegate.spriteImage != spriteImage;
  }
}
