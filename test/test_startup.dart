import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_smash/main.dart';
import 'package:pickleball_smash/screens/auth/login_screen.dart';
import 'package:pickleball_smash/screens/dashboard_screen.dart';
import 'package:pickleball_smash/services/database_service.dart';
import 'package:pickleball_smash/services/game_state_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseService.instance.initialize();
  });

  testWidgets('Test PickleballApp startup with active session', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

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
    } catch (e) {
      print('Session catch: $e');
      GameStateManager.instance.loginAsGuest();
    }

    print('InitialScreen is: ${initialScreen.runtimeType}');
    await tester.pumpWidget(PickleballApp(initialScreen: initialScreen));
    await tester.pumpAndSettle();

    print('Rendered widgets count: ${find.byType(MaterialApp).evaluate().length}');
    print('Scaffold count: ${find.byType(Scaffold).evaluate().length}');
  });
}

