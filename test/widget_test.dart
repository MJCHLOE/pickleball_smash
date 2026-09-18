import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_smash/main.dart';
import 'package:pickleball_smash/models/game_settings.dart';
import 'package:pickleball_smash/screens/auth/login_screen.dart';
import 'package:pickleball_smash/screens/auth/register_screen.dart';
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

  group('SQLite DatabaseService Tests', () {
    final dbService = DatabaseService.instance;

    test('Register and Login flow with SQLite', () async {
      final uniqueUser = 'TestUser_${DateTime.now().millisecondsSinceEpoch}';
      final pass = 'pass1234';

      // 1. Register
      final regResult = await dbService.registerUser(username: uniqueUser, password: pass);
      expect(regResult['userId'], isA<int>());
      expect(regResult['username'], uniqueUser);

      // 2. Duplicate registration should throw
      expect(
        () => dbService.registerUser(username: uniqueUser, password: 'any'),
        throwsA(isA<Exception>()),
      );

      // 3. Login with wrong password should throw
      expect(
        () => dbService.loginUser(username: uniqueUser, password: 'wrongpassword'),
        throwsA(isA<Exception>()),
      );

      // 4. Login with correct password
      final loginResult = await dbService.loginUser(username: uniqueUser, password: pass);
      expect(loginResult['userId'], regResult['userId']);
      expect(loginResult['username'], uniqueUser);

      // 5. Active session should be set
      final session = await dbService.getActiveSession();
      expect(session, isNotNull);
      expect(session!['username'], uniqueUser);

      // 6. Clear session
      await dbService.clearActiveSession();
      final clearedSession = await dbService.getActiveSession();
      expect(clearedSession, isNull);
    });

    test('Save and Load player data with SQLite', () async {
      final uniqueUser = 'Saver_${DateTime.now().millisecondsSinceEpoch}';
      final reg = await dbService.registerUser(username: uniqueUser, password: 'password');
      final userId = reg['userId'] as int;

      final state = GameStateManager.instance;
      state.resetAllData();

      await dbService.savePlayerData(
        userId: userId,
        playerLevel: 5,
        playerXp: 350,
        xpToNextLevel: 1200,
        coins: 2500,
        trophies: 600,
        matchesPlayed: 10,
        matchesWon: 8,
        totalSmashes: 45,
        bestStreak: 4,
        currentStreak: 2,
        tournaments: state.tournaments,
        challenges: state.challenges,
        settings: const GameSettings(courtTheme: 'Neon Night'),
      );

      final loaded = await dbService.loadPlayerData(userId);
      expect(loaded, isNotNull);
      expect(loaded!['playerLevel'], 5);
      expect(loaded['coins'], 2500);
      expect(loaded['trophies'], 600);
      expect((loaded['settings'] as GameSettings).courtTheme, 'Neon Night');
    });
  });

  group('GameStateManager Tests', () {
    late GameStateManager state;

    setUp(() {
      state = GameStateManager.instance;
      state.loginAsGuest();
    });

    test('Initial state values are correct', () {
      expect(state.playerLevel, 1);
      expect(state.coins, 500);
      expect(state.tournaments.length, 3);
      expect(state.challenges.isNotEmpty, true);
      expect(state.isGuest, true);
    });

    test('Claiming a completed challenge adds coins and XP', () {
      final challenge = state.challenges.firstWhere((c) => c.isCompleted, orElse: () {
        state.challenges.first.currentProgress = state.challenges.first.goal;
        return state.challenges.first;
      });

      final initialCoins = state.coins;
      final initialXp = state.playerXp;

      final claimed = state.claimChallenge(challenge.id);
      expect(claimed, true);
      expect(state.coins, initialCoins + challenge.rewardCoins);
      expect(state.playerXp, initialXp + challenge.rewardXp);
      expect(challenge.isClaimed, true);

      final claimAgain = state.claimChallenge(challenge.id);
      expect(claimAgain, false);
    });

    test('Recording match result updates career stats and challenges', () {
      final initialMatches = state.matchesPlayed;
      final initialWins = state.matchesWon;
      final initialSmashes = state.totalSmashes;

      state.recordMatchResult(won: true, smashesHit: 5);

      expect(state.matchesPlayed, initialMatches + 1);
      expect(state.matchesWon, initialWins + 1);
      expect(state.totalSmashes, initialSmashes + 5);
      expect(state.currentStreak, 1);
    });

    test('Tournament advancement updates bracket correctly', () {
      final rookie = state.tournaments.firstWhere((t) => t.id == 'rookie_open');
      final currentIdx = rookie.currentMatchIndex;

      state.advanceTournamentMatch('rookie_open', true);

      final updatedRookie = state.tournaments.firstWhere((t) => t.id == 'rookie_open');
      expect(updatedRookie.currentMatchIndex, currentIdx + 1);
    });

    test('Match history records in guest mode and migrates to SQLite upon user registration', () async {
      state.loginAsGuest();
      state.recordMatchResult(
        won: true,
        smashesHit: 8,
        matchType: 'quick',
        opponentName: 'Test Opponent',
        playerScore: 11,
        opponentScore: 7,
      );

      final guestHistory = await state.getMatchHistory();
      expect(guestHistory.length, 1);
      expect(guestHistory.first['opponent_name'], 'Test Opponent');
      expect(guestHistory.first['player_score'], 11);

      final reg = await DatabaseService.instance.registerUser(
        username: 'HistoryPlayer_${DateTime.now().millisecondsSinceEpoch}',
        password: 'password123',
      );
      final userId = reg['userId'] as int;
      final username = reg['username'] as String;

      await state.loginWithUser(userId, username, preserveCurrentDataIfNew: true);

      expect(state.isGuest, false);
      expect(state.currentUsername, username);

      final dbHistory = await state.getMatchHistory();
      expect(dbHistory.length, 1);
      expect(dbHistory.first['opponent_name'], 'Test Opponent');
      expect(dbHistory.first['player_score'], 11);
      expect(dbHistory.first['won'], 1);
    });
  });

  group('Auth Screens Widget Tests', () {
    testWidgets('LoginScreen renders fields and Play as Guest button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('login_username_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('login_password_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('login_submit_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('play_as_guest_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_to_register_btn')), findsOneWidget);
    });

    testWidgets('Tapping Play as Guest navigates to DashboardScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('play_as_guest_btn')));
      await tester.pumpAndSettle();

      // Should now be on DashboardScreen
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(GameStateManager.instance.isGuest, true);
    });

    testWidgets('RegisterScreen renders fields and validates matching passwords', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('register_username_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('register_password_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('register_confirm_password_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('register_submit_btn')), findsOneWidget);

      // Enter mismatched passwords
      await tester.enterText(find.byKey(const ValueKey('register_username_field')), 'Player1');
      await tester.enterText(find.byKey(const ValueKey('register_password_field')), 'pass1');
      await tester.enterText(find.byKey(const ValueKey('register_confirm_password_field')), 'pass2');

      await tester.tap(find.byKey(const ValueKey('register_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('RegisterScreen creates account and navigates to DashboardScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      GameStateManager.instance.loginAsGuest();

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pumpAndSettle();

      final testUser = 'NewPlayer_${DateTime.now().millisecondsSinceEpoch}';
      await tester.enterText(find.byKey(const ValueKey('register_username_field')), testUser);
      await tester.enterText(find.byKey(const ValueKey('register_password_field')), 'secret123');
      await tester.enterText(find.byKey(const ValueKey('register_confirm_password_field')), 'secret123');

      await tester.ensureVisible(find.byKey(const ValueKey('register_submit_btn')));

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('register_submit_btn')));
        for (int i = 0; i < 50; i++) {
          if (!GameStateManager.instance.isGuest) break;
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should now be on DashboardScreen with new username
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(GameStateManager.instance.isGuest, false);
      expect(GameStateManager.instance.currentUsername, testUser);
    });

    testWidgets('RegisterScreen allows playing as guest', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pumpAndSettle();

      final guestBtn = find.text('Skip for now, play as Guest');
      expect(guestBtn, findsOneWidget);

      await tester.tap(guestBtn);
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(GameStateManager.instance.isGuest, true);
    });
  });

  group('Responsive Dashboard Widget Tests', () {
    testWidgets('Renders BottomNavigationBar on compact screen (< 700px)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const PickleballApp(initialScreen: DashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_dest_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_dest_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_dest_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_dest_3')), findsOneWidget);

      expect(find.text('Guest Player'), findsAtLeast(1));
      expect(find.byIcon(Icons.monetization_on_rounded), findsOneWidget);
    });

    testWidgets('Renders NavigationRail on wide screen (>= 700px)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const PickleballApp(initialScreen: DashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);

      expect(find.byKey(const ValueKey('rail_item_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('rail_item_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('rail_item_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('rail_item_3')), findsOneWidget);

      expect(find.text('QUICK MATCH'), findsOneWidget);
    });

    testWidgets('Can switch tabs to Tournaments, Challenges, and Settings', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const PickleballApp(initialScreen: DashboardScreen()));
      await tester.pumpAndSettle();

      // Tap on Tournaments tab
      await tester.tap(find.byKey(const ValueKey('rail_item_1')));
      await tester.pumpAndSettle();

      expect(find.text('Championship Tournaments'), findsOneWidget);
      expect(find.text('Knockout Bracket'), findsOneWidget);

      // Tap on Challenges tab
      await tester.tap(find.byKey(const ValueKey('rail_item_2')));
      await tester.pumpAndSettle();

      expect(find.text('Smash Challenges'), findsOneWidget);
      expect(find.text('Daily Quests'), findsOneWidget);
      expect(find.text('Career Milestones'), findsOneWidget);

      // Tap on Settings tab
      await tester.tap(find.byKey(const ValueKey('rail_item_3')));
      await tester.pumpAndSettle();

      expect(find.text('Game Settings'), findsOneWidget);
      expect(find.text('Player Account'), findsOneWidget);
      expect(find.text('Audio & Sound Effects'), findsOneWidget);
      expect(find.text('Controls & Movement'), findsOneWidget);
    });

    testWidgets('Claiming completed challenge in ChallengesView updates currency', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = GameStateManager.instance;
      state.loginAsGuest();
      final initialCoins = state.coins;

      await tester.pumpWidget(const PickleballApp(initialScreen: DashboardScreen()));
      await tester.pumpAndSettle();

      // Navigate to Challenges
      await tester.tap(find.byKey(const ValueKey('rail_item_2')));
      await tester.pumpAndSettle();

      // Switch to Career Milestones
      await tester.tap(find.text('Career Milestones'));
      await tester.pumpAndSettle();

      final claimButton = find.text('CLAIM');
      expect(claimButton, findsOneWidget);

      await tester.tap(claimButton);
      await tester.pumpAndSettle();

      expect(find.text('Claimed'), findsWidgets);
      expect(state.coins, greaterThan(initialCoins));
    });

    testWidgets('Tapping Match History in HomeView opens modal bottom sheet', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = GameStateManager.instance;
      state.loginAsGuest();

      await tester.pumpWidget(const PickleballApp(initialScreen: DashboardScreen()));
      await tester.pumpAndSettle();

      final historyBtn = find.text('Match History');
      expect(historyBtn, findsOneWidget);

      await tester.tap(historyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Playing as Guest. Create an account to permanently sync matches to SQLite.'), findsOneWidget);
    });
  });
}
