import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/flame.dart';
import 'screens/splash_loading_screen.dart';
import 'services/audio_service.dart';
import 'services/firebase_multiplayer_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AudioService (global AudioContext configuration & lifecycle observer)
  AudioService.instance.initialize();

  // Configure Firebase Online Multiplayer with user's Realtime Database
  FirebaseMultiplayerService.instance.configureProject('https://pickl-6d440-default-rtdb.firebaseio.com/');

  // Make full screen safely without crashing on web or unsupported platforms
  try {
    if (!kIsWeb) {
      await Flame.device.fullScreen();
    }
  } catch (e) {
    debugPrint('Fullscreen initialization skipped: $e');
  }

  // Lock portrait orientation initially for dashboard & menus
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Orientation lock skipped: $e');
  }

  runApp(const PickleballApp());
}

class PickleballApp extends StatelessWidget {
  final Widget? initialScreen;

  const PickleballApp({super.key, this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PICKL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      ),
      home: initialScreen ?? const SplashLoadingScreen(),
    );
  }
}
