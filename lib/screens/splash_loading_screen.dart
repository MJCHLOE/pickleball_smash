import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/game_2d_text.dart';
import '../widgets/smooth_lights_background.dart';
import '../services/database_service.dart';
import '../services/game_state_manager.dart';
import 'auth/login_screen.dart';
import 'dashboard_screen.dart';

/// Arcade-styled Retro Splash & Loading Screen.
///
/// Features animated glowing floating elements, retro CRT scanline effects,
/// dynamic arcade status loading text, chunky progress bar, and smooth
/// asynchronous background session initialization.
class SplashLoadingScreen extends StatefulWidget {
  final Widget? targetScreen;
  final Duration minimumDuration;

  const SplashLoadingScreen({
    super.key,
    this.targetScreen,
    this.minimumDuration = const Duration(milliseconds: 2200),
  });

  @override
  State<SplashLoadingScreen> createState() => _SplashLoadingScreenState();
}

class _SplashLoadingScreenState extends State<SplashLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnim;

  Widget? _destinationScreen;
  bool _initCompleted = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: widget.minimumDuration,
    );

    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAndNavigate();
      }
    });

    _performBackgroundInit();
  }

  Future<void> _performBackgroundInit() async {
    if (widget.targetScreen != null) {
      _destinationScreen = widget.targetScreen;
      _initCompleted = true;
      _checkAndNavigate();
      return;
    }

    try {
      // 1. Initialize SQLite Database
      await DatabaseService.instance.initialize().timeout(
        const Duration(milliseconds: 1200),
        onTimeout: () => debugPrint('Database init timeout in splash'),
      );

      // 2. Check for active session
      final session = await DatabaseService.instance.getActiveSession().timeout(
        const Duration(milliseconds: 800),
        onTimeout: () => null,
      );

      if (session != null) {
        final userId = session['userId'] as int;
        final username = session['username'] as String;
        await GameStateManager.instance.loginWithUser(userId, username).timeout(
          const Duration(milliseconds: 1200),
          onTimeout: () => GameStateManager.instance.loginAsGuest(),
        );
        _destinationScreen = const DashboardScreen();
      } else {
        GameStateManager.instance.loginAsGuest();
        _destinationScreen = const LoginScreen();
      }
    } catch (e) {
      debugPrint('Splash init error: $e');
      GameStateManager.instance.loginAsGuest();
      _destinationScreen = const LoginScreen();
    } finally {
      _initCompleted = true;
      _checkAndNavigate();
    }
  }

  void _checkAndNavigate() {
    if (!mounted) return;
    if (_progressController.isCompleted && _initCompleted) {
      final destination = _destinationScreen ?? const LoginScreen();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: destination,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  String _getStatusText(double progress) {
    if (progress < 0.25) {
      return 'INITIALIZING COURT SYSTEM...';
    } else if (progress < 0.50) {
      return 'SYNCHRONIZING PADDLES & BALLS...';
    } else if (progress < 0.75) {
      return 'CALIBRATING PHYSICS ENGINE...';
    } else if (progress < 0.95) {
      return 'CHECKING PLAYER PROFILE...';
    } else {
      return 'SYSTEM READY! INSERT COIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060913),
      body: SmoothLightsAlphabetBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, _) {
              final progress = _progressAnim.value;
              final percentInt = (progress * 100).toInt().clamp(0, 100);

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Retro Arcade Logo Section
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.electricCyan.withValues(alpha: 0.8),
                              width: 3.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.electricCyan.withValues(alpha: 0.5),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: AppTheme.neonLime.withValues(alpha: 0.35),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo/app_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(
                                  Icons.sports_tennis,
                                  size: 48,
                                  color: AppTheme.neonLime,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title with 2D arcade styling
                        Game2DText.hero(
                          'PICKL SMASH',
                          fontSize: 36,
                          strokeColor: const Color(0xFF030712),
                          strokeWidth: 5.0,
                          gradient: AppTheme.playButtonGradient,
                        ),

                        const SizedBox(height: 6),

                        const Game2DText(
                          'ARCADE PICKLEBALL BATTLE',
                          fontSize: 13,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w900,
                          textColor: AppTheme.electricCyan,
                          strokeColor: Colors.black,
                          strokeWidth: 2.5,
                        ),

                        const SizedBox(height: 48),

                        // Arcade Progress Container
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1424).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.surfaceBorder,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top progress details: Status text + percentage
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getStatusText(progress),
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                        fontFamily: 'monospace',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$percentInt%',
                                    style: const TextStyle(
                                      color: AppTheme.neonLime,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Segmented / chunky Arcade Progress Bar
                              Container(
                                height: 16,
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF050811),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.electricCyan.withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final fillWidth = constraints.maxWidth * progress;
                                      return Stack(
                                        children: [
                                          // Glowing gradient bar
                                          Container(
                                            width: fillWidth,
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF00E5FF),
                                                  Color(0xFF76FF03),
                                                  Color(0xFFCCFF00),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Scanline grid lines
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: _ProgressBarScanlinePainter(),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Blinking "INSERT COIN" / Arcade Marquee
                        _BlinkingInsertCoin(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProgressBarScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1.0;
    for (double x = 4.0; x < size.width; x += 6.0) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BlinkingInsertCoin extends StatefulWidget {
  @override
  State<_BlinkingInsertCoin> createState() => _BlinkingInsertCoinState();
}

class _BlinkingInsertCoinState extends State<_BlinkingInsertCoin>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blinkCtrl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.electricCyan.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videogame_asset_outlined,
              size: 14,
              color: AppTheme.neonLime,
            ),
            SizedBox(width: 6),
            Text(
              'INSERT COIN • 1 PLAYER',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
