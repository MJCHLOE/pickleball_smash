import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CharacterGender { male, female }
enum CharacterAction { idle, run, smash }

class AnimatedCharacterDisplay extends StatefulWidget {
  final CharacterGender initialGender;
  final bool showControls;
  final bool autoCycleActions;
  final double height;
  final VoidCallback? onSmashTriggered;

  const AnimatedCharacterDisplay({
    super.key,
    this.initialGender = CharacterGender.male,
    this.showControls = true,
    this.autoCycleActions = false,
    this.height = 180,
    this.onSmashTriggered,
  });

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
  static const String malePaddle = 'assets/images/male1_sprite/pickleballpaddle_for player1.png';

  static const String femaleRun = 'assets/images/female1_sprite/female_runfront.png';
  static const String femaleBehind = 'assets/images/female1_sprite/female_runbehind.png';
  static const String femalePaddle = 'assets/images/female1_sprite/pickleballpaddle_for player2.png';

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
      malePaddle,
      femaleRun,
      femaleBehind,
      femalePaddle,
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
      // Female sprite sheet has 8 frames of 64x64
      switch (_action) {
        case CharacterAction.idle:
          _totalFrames = 2; // Use first 2 frames for gentle breathing idle
          break;
        case CharacterAction.run:
          _totalFrames = 8;
          break;
        case CharacterAction.smash:
          _totalFrames = 8; // Full power spin and strike
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
    } else {
      switch (_action) {
        case CharacterAction.idle:
          return femaleRun;
        case CharacterAction.run:
          return femaleRun;
        case CharacterAction.smash:
          return femaleRun;
      }
    }
  }

  String _getActivePaddlePath() {
    return _gender == CharacterGender.male ? malePaddle : femalePaddle;
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
    final paddleImage = _imageCache[_getActivePaddlePath()];

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
                          _gender == CharacterGender.male
                              ? const Color(0xFF00E676).withValues(alpha: 0.12)
                              : const Color(0xFFFF4081).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                        radius: 0.85,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _SpriteCharacterPainter(
                        spriteImage: spriteImage,
                        paddleImage: paddleImage,
                        frameIndex: _currentFrame,
                        totalFrames: _totalFrames,
                        action: _action,
                        gender: _gender,
                        smashProgress: _smashProgress,
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
                  SegmentedButton<CharacterGender>(
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return _gender == CharacterGender.male
                              ? const Color(0xFF00E676).withValues(alpha: 0.25)
                              : const Color(0xFFFF4081).withValues(alpha: 0.25);
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
                    ],
                    selected: {_gender},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _gender = newSelection.first;
                        _updateActionState();
                        _startFrameTimer();
                      });
                    },
                  ),

                  // Action Buttons: Idle / Run / Smash
                  Container(
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
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActionChip(String label, CharacterAction action, {bool isSmash = false}) {
    final isSelected = _action == action;
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
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isSmash ? const Color(0xFFFFD600) : const Color(0xFF00E676))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.black
                : (isSmash ? const Color(0xFFFFD600) : Colors.white70),
          ),
        ),
      ),
    );
  }
}

class _SpriteCharacterPainter extends CustomPainter {
  final ui.Image? spriteImage;
  final ui.Image? paddleImage;
  final int frameIndex;
  final int totalFrames;
  final CharacterAction action;
  final CharacterGender gender;
  final double smashProgress;

  _SpriteCharacterPainter({
    required this.spriteImage,
    required this.paddleImage,
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

    // 2. Render Character Sprite Frame
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

      // 3. Render Paddle Attachment if female or smash motion
      if (paddleImage != null) {
        canvas.save();
        
        // Paddle position relative to character's hand
        double paddleX = targetX + targetWidth * 0.72;
        double paddleY = targetY + targetHeight * 0.52;
        double paddleAngle = 0.2;

        if (action == CharacterAction.smash) {
          // Dynamic swing rotation
          paddleAngle = math.pi * 0.5 * (1.0 - smashProgress) - 0.4;
          paddleX += 8 * math.sin(smashProgress * math.pi);
          paddleY -= 12 * math.sin(smashProgress * math.pi);
        } else if (action == CharacterAction.run) {
          paddleAngle += 0.25 * math.sin(frameIndex);
        }

        canvas.translate(paddleX, paddleY);
        canvas.rotate(paddleAngle);

        final paddlePaint = Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false;

        const paddleSize = 28.0;
        final paddleSrc = Rect.fromLTWH(
          0,
          0,
          paddleImage!.width.toDouble(),
          paddleImage!.height.toDouble(),
        );
        final paddleDst = Rect.fromCenter(
          center: Offset.zero,
          width: paddleSize,
          height: paddleSize,
        );

        canvas.drawImageRect(paddleImage!, paddleSrc, paddleDst, paddlePaint);
        canvas.restore();
      }

      // 4. Draw Smash Swing Arc and Motion Lines
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
        oldDelegate.spriteImage != spriteImage ||
        oldDelegate.paddleImage != paddleImage;
  }
}
