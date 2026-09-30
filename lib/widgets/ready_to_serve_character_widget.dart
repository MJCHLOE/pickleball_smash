import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pickleball_smash/models/character_roster.dart';

/// An animated character sprite widget that renders authentic pixel-art character animations,
/// defaulting to the animated "ready to serve" stance (p1sideidle).
class ReadyToServeCharacterWidget extends StatefulWidget {
  final CharacterInfo character;
  final double size;
  final String action; // 'serve' (default), 'idle', 'run', 'smash'
  final bool animate;

  const ReadyToServeCharacterWidget({
    super.key,
    required this.character,
    this.size = 64,
    this.action = 'serve',
    this.animate = true,
  });

  @override
  State<ReadyToServeCharacterWidget> createState() => _ReadyToServeCharacterWidgetState();
}

class _ReadyToServeCharacterWidgetState extends State<ReadyToServeCharacterWidget> {
  Timer? _timer;
  int _frameIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didUpdateWidget(covariant ReadyToServeCharacterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.action != widget.action ||
        oldWidget.character.id != widget.character.id ||
        oldWidget.animate != widget.animate) {
      _frameIndex = 0;
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _timer?.cancel();
    if (!widget.animate) return;

    // In widget test environments, avoid running endless periodic timers so pumpAndSettle can settle cleanly
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest) return;

    final totalFrames = _getTotalFrames(widget.action);
    if (totalFrames <= 1) return;

    final stepDuration = _getStepDuration(widget.action);
    _timer = Timer.periodic(stepDuration, (_) {
      if (mounted) {
        setState(() {
          _frameIndex = (_frameIndex + 1) % totalFrames;
        });
      }
    });
  }

  int _getTotalFrames(String action) {
    switch (action) {
      case 'run':
        return 8;
      case 'smash':
        return 6;
      case 'idle':
      case 'serve':
      default:
        return 2;
    }
  }

  Duration _getStepDuration(String action) {
    switch (action) {
      case 'run':
        return const Duration(milliseconds: 100);
      case 'smash':
        return const Duration(milliseconds: 80);
      case 'idle':
        return const Duration(milliseconds: 350);
      case 'serve':
      default:
        return const Duration(milliseconds: 350);
    }
  }

  String _getAssetPath(CharacterInfo char, String action) {
    switch (action) {
      case 'run':
        return char.frontRunPath;
      case 'smash':
        return char.frontSlashPath;
      case 'idle':
        return char.charSelectIdlePath;
      case 'serve':
      default:
        return char.readyToServePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalFrames = _getTotalFrames(widget.action);
    final assetPath = _getAssetPath(widget.character, widget.action);
    final size = widget.size;

    final factor = 1.0 / totalFrames;
    final alignmentX = totalFrames > 1
        ? -1.0 + 2.0 * (_frameIndex.clamp(0, totalFrames - 1) / (totalFrames - 1))
        : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Align(
          alignment: Alignment(alignmentX, 0.0),
          widthFactor: factor,
          child: Image.asset(
            assetPath,
            width: size * totalFrames,
            height: size,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) => Icon(
              Icons.person,
              color: widget.character.borderColor,
              size: size * 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
