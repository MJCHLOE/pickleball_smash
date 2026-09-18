import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/database_service.dart';
import 'services/game_state_manager.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Make full screen safely without crashing on web or unsupported platforms
  try {
    if (!kIsWeb) {
      await Flame.device.fullScreen();
    }
  } catch (e) {
    debugPrint('Fullscreen initialization skipped: $e');
  }

  // Pre-initialize Database Service safely with timeout
  try {
    await DatabaseService.instance.initialize().timeout(
      const Duration(milliseconds: 1000),
      onTimeout: () => debugPrint('DatabaseService init timeout - continuing with fallback store'),
    );
  } catch (e) {
    debugPrint('DatabaseService init error: $e');
  }

  // Check for existing session in SQLite
  Widget initialScreen = const LoginScreen();
  try {
    final session = await DatabaseService.instance.getActiveSession().timeout(
      const Duration(milliseconds: 500),
      onTimeout: () => null,
    );
    if (session != null) {
      final userId = session['userId'] as int;
      final username = session['username'] as String;
      await GameStateManager.instance.loginWithUser(userId, username).timeout(
        const Duration(milliseconds: 1000),
        onTimeout: () => GameStateManager.instance.loginAsGuest(),
      );
      initialScreen = const DashboardScreen();
    } else {
      GameStateManager.instance.loginAsGuest();
    }
  } catch (e) {
    debugPrint('Session check error: $e');
                    GameStateManager.instance.loginAsGuest();
  }

  runApp(PickleballApp(initialScreen: initialScreen));
}

class PickleballApp extends StatelessWidget {
  final Widget? initialScreen;

  const PickleballApp({super.key, this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pickleball Smash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: initialScreen ?? const DashboardScreen(),
    );
  }
}
