import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/database_service.dart';
import 'services/game_state_manager.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Make full screen for immersive gaming experience
  await Flame.device.fullScreen();

  // Initialize Database Service
  await DatabaseService.instance.initialize();

  // Check for existing session in SQLite
  Widget initialScreen = const LoginScreen();
  try {
    final session = await DatabaseService.instance.getActiveSession();
    if (session != null) {
      final userId = session['userId'] as int;
      final username = session['username'] as String;
      await GameStateManager.instance.loginWithUser(userId, username);
      initialScreen = const DashboardScreen();
    } else {
      GameStateManager.instance.loginAsGuest();
    }
  } catch (_) {
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
