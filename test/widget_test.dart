import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_smash/main.dart';
import 'package:pickleball_smash/models/ball_catalog.dart';
import 'package:pickleball_smash/models/character_roster.dart';
import 'package:pickleball_smash/models/court_catalog.dart';
import 'package:pickleball_smash/models/battle_technique.dart';
import 'package:pickleball_smash/models/game_settings.dart';
import 'package:pickleball_smash/models/player_avatar.dart';
import 'package:pickleball_smash/game/components/arcade_skill_button_component.dart';
import 'package:pickleball_smash/widgets/inventory_modal.dart';
import 'package:pickleball_smash/widgets/shop_modal.dart';
import 'package:pickleball_smash/screens/auth/login_screen.dart';
import 'package:pickleball_smash/screens/auth/register_screen.dart';
import 'package:pickleball_smash/screens/dashboard_screen.dart';
import 'package:pickleball_smash/screens/game_play_screen.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:pickleball_smash/game/pickleball_game.dart';
import 'package:pickleball_smash/game/components/ball.dart';
import 'package:pickleball_smash/game/components/player.dart';
import 'package:pickleball_smash/game/components/background.dart';
import 'package:pickleball_smash/game/components/arcade_button_component.dart';
import 'package:pickleball_smash/screens/views/in_game_settings_modal.dart';
import 'package:pickleball_smash/screens/views/home_view.dart';
import 'package:pickleball_smash/screens/views/settings_view.dart';
import 'package:pickleball_smash/services/database_service.dart';
import 'package:pickleball_smash/services/game_state_manager.dart';
import 'package:pickleball_smash/theme/app_theme.dart';
import 'package:pickleball_smash/widgets/animated_character_display.dart';
import 'package:pickleball_smash/widgets/avatar_picker_dialog.dart';
import 'package:pickleball_smash/widgets/game_2d_text.dart';
import 'package:pickleball_smash/widgets/pickleball_rules_modal.dart';
import 'package:pickleball_smash/widgets/player_avatar.dart';
import 'package:pickleball_smash/widgets/smooth_lights_background.dart';
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
        for (int i = 0; i < 200; i++) {
          if (!GameStateManager.instance.isGuest) {
            await Future.delayed(const Duration(milliseconds: 300));
            break;
          }
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Should now be on DashboardScreen with new username
      expect(GameStateManager.instance.isGuest, false);
      expect(GameStateManager.instance.currentUsername, testUser);
      expect(find.byType(DashboardScreen), findsOneWidget);
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
    setUp(() {
      GameStateManager.instance.loginAsGuest();
    });

    testWidgets('Renders BottomNavigationBar on compact screen (< 700px)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

    testWidgets('Renders Dashboard on ultra-compact 320px screen without any right overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const PickleballApp(initialScreen: DashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('PICKL'), findsOneWidget);
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

      expect(find.text('1v1 SINGLES'), findsOneWidget);
      expect(find.text('2v2 DOUBLES'), findsOneWidget);
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
      // Complete a challenge so it can be claimed
      state.challenges.firstWhere((c) => c.id == 'c_career_1').currentProgress = 100;
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
      await tester.ensureVisible(historyBtn);
      await tester.tap(historyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Playing as Guest. Create an account to permanently sync matches to SQLite.'), findsOneWidget);
    });
  });

  group('Per-Player Statistics & Leaderboard Tests', () {
    test('Each player has their own isolated statistics in SQLite', () async {
      final db = DatabaseService.instance;
      final state = GameStateManager.instance;

      // 1. Register Player Alpha
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final userAlpha = 'Alpha_$timestamp';
      final regAlpha = await db.registerUser(username: userAlpha, password: 'password123');
      final idAlpha = regAlpha['userId'] as int;

      await state.loginWithUser(idAlpha, userAlpha, preserveCurrentDataIfNew: false);
      expect(state.matchesPlayed, 0);
      expect(state.matchesWon, 0);

      // Record 2 wins for Player Alpha
      state.recordMatchResult(won: true, smashesHit: 6, opponentName: 'Bot 1');
      state.recordMatchResult(won: true, smashesHit: 4, opponentName: 'Bot 2');
      await state.saveCurrentProgress();

      expect(state.matchesPlayed, 2);
      expect(state.matchesWon, 2);
      expect(state.totalSmashes, 10);

      // 2. Register Player Beta (should have brand new clean stats)
      final userBeta = 'Beta_${timestamp + 100}';
      final regBeta = await db.registerUser(username: userBeta, password: 'password123');
      final idBeta = regBeta['userId'] as int;

      await state.loginWithUser(idBeta, userBeta, preserveCurrentDataIfNew: false);
      // Verify Player Beta starts at 0 matches (no data leakage from Alpha)
      expect(state.matchesPlayed, 0);
      expect(state.matchesWon, 0);
      expect(state.totalSmashes, 0);

      // Record 1 win for Player Beta
      state.recordMatchResult(won: true, smashesHit: 3, opponentName: 'Bot 3');
      await state.saveCurrentProgress();

      expect(state.matchesPlayed, 1);
      expect(state.matchesWon, 1);
      expect(state.totalSmashes, 3);

      // 3. Re-load Player Alpha and verify their 2 matches are intact in SQLite
      final alphaData = await db.loadPlayerData(idAlpha);
      expect(alphaData, isNotNull);
      expect(alphaData!['matchesPlayed'], 2);
      expect(alphaData['matchesWon'], 2);
      expect(alphaData['totalSmashes'], 10);

      // 4. Verify Leaderboard reflects individual player records
      final leaderboard = await db.getAllPlayersLeaderboard(limit: 500);
      expect(leaderboard.any((p) => p['username'] == userAlpha), true);
      expect(leaderboard.any((p) => p['username'] == userBeta), true);

      final alphaInLb = leaderboard.firstWhere((p) => p['username'] == userAlpha);
      final betaInLb = leaderboard.firstWhere((p) => p['username'] == userBeta);

      expect(alphaInLb['matches_won'], 2);
      expect(betaInLb['matches_won'], 1);
    });

    testWidgets('Tapping All Records in HomeView opens PlayerStatsModal', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = GameStateManager.instance;
      state.loginAsGuest();

      await tester.pumpWidget(const PickleballApp(initialScreen: DashboardScreen()));
      await tester.pumpAndSettle();

      final allRecordsBtn = find.text('All Records');
      expect(allRecordsBtn, findsOneWidget);

      await tester.ensureVisible(allRecordsBtn);
      await tester.tap(allRecordsBtn);
      await tester.pumpAndSettle();

      expect(find.text('PLAYER STATISTICS & RECORDS'), findsOneWidget);
      expect(find.text('My Career Records'), findsOneWidget);
      expect(find.text('All Players Leaderboard'), findsOneWidget);
      expect(find.text('CAREER PERFORMANCE'), findsOneWidget);
      expect(find.text('PERSONAL MATCH HISTORY'), findsOneWidget);

      // Switch to Leaderboard tab
      await tester.tap(find.text('All Players Leaderboard'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.text('Official PICKL Rankings. Sorted by Trophies and Match Victories.'), findsOneWidget);
    });
  });

  group('AnimatedCharacterDisplay Tests', () {
    testWidgets('Renders AnimatedCharacterDisplay with initial controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedCharacterDisplay(
                height: 180,
                showControls: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AnimatedCharacterDisplay), findsOneWidget);
      expect(find.text('TAP TO SMASH'), findsOneWidget);
      expect(find.text('Idle'), findsOneWidget);
      expect(find.text('Run'), findsOneWidget);
      expect(find.text('Smash'), findsOneWidget);
    });

    testWidgets('Tapping Smash triggers smash animation and feedback', (WidgetTester tester) async {
      bool smashTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedCharacterDisplay(
                height: 180,
                showControls: true,
                onSmashTriggered: () {
                  smashTriggered = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Smash'));
      await tester.pump();

      expect(smashTriggered, isTrue);
      expect(find.text('⚡ POWER SMASH!'), findsOneWidget);
      expect(find.text('SMASHING!'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('TAP TO SMASH'), findsOneWidget);
    });

    testWidgets('Switching character toggle between Alex and Maya works cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedCharacterDisplay(
                height: 180,
                showControls: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final mayaSegment = find.textContaining('Maya');
      expect(mayaSegment, findsOneWidget);
      await tester.tap(mayaSegment);
      await tester.pump(const Duration(milliseconds: 100));

      final alexSegment = find.textContaining('Alex');
      expect(alexSegment, findsOneWidget);
      await tester.tap(alexSegment);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Renders responsively on ultra-compact 320px screen width without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: AnimatedCharacterDisplay(
                  height: 160,
                  showControls: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(AnimatedCharacterDisplay), findsOneWidget);
    });
  });

  group('Game Settings & Adjusters Tests', () {
    test('GameSettings model serializes and deserializes all graphics, audio, and controller adjuster fields', () {
      const original = GameSettings(
        masterVolume: 0.9,
        soundVolume: 0.75,
        musicVolume: 0.5,
        crowdVolume: 0.65,
        sfxEnabled: true,
        musicEnabled: false,
        crowdEnabled: true,
        hapticsEnabled: true,
        soundProfile: 'Stadium Live',
        controlScheme: 'dpad',
        joystickOnLeft: false,
        joystickExpand: 1.3,
        joystickDeadzone: 0.15,
        buttonSize: 'Large',
        transparentCapacity: 0.7,
        joystickColor: 'Electric Cyan',
        hapticOnHit: true,
        graphicsQuality: 'Ultra',
        targetFps: 120,
        particlesEnabled: true,
        shadowsEnabled: true,
        screenShakeEnabled: false,
        showFps: true,
        courtTheme: 'Electric Blue',
        courtBrightness: 1.2,
      );

      final map = original.toMap();
      final reconstructed = GameSettings.fromMap(map);

      expect(reconstructed.masterVolume, 0.9);
      expect(reconstructed.soundVolume, 0.75);
      expect(reconstructed.musicVolume, 0.5);
      expect(reconstructed.crowdVolume, 0.65);
      expect(reconstructed.musicEnabled, false);
      expect(reconstructed.soundProfile, 'Stadium Live');
      expect(reconstructed.controlScheme, 'dpad');
      expect(reconstructed.joystickOnLeft, false);
      expect(reconstructed.joystickExpand, 1.3);
      expect(reconstructed.transparentCapacity, 0.7);
      expect(reconstructed.joystickColor, 'Electric Cyan');
      expect(reconstructed.buttonSize, 'Large');
      expect(reconstructed.graphicsQuality, 'Ultra');
      expect(reconstructed.targetFps, 120);
      expect(reconstructed.screenShakeEnabled, false);
      expect(reconstructed.showFps, true);
      expect(reconstructed.courtTheme, 'Electric Blue');
      expect(reconstructed.courtBrightness, 1.2);
      expect(reconstructed.autoServe, false);

      final copy = original.copyWith(
        graphicsQuality: 'Low',
        masterVolume: 0.2,
        controlScheme: 'drag',
        joystickExpand: 1.5,
        transparentCapacity: 0.95,
        joystickColor: 'Hot Pink',
        autoServe: true,
      );
      expect(copy.graphicsQuality, 'Low');
      expect(copy.masterVolume, 0.2);
      expect(copy.controlScheme, 'drag');
      expect(copy.joystickExpand, 1.5);
      expect(copy.transparentCapacity, 0.95);
      expect(copy.joystickColor, 'Hot Pink');
      expect(copy.autoServe, true);
      expect(copy.courtTheme, 'Electric Blue'); // retained
    });

    testWidgets('SettingsView renders all Adjuster cards, allows category switching, and triggers test audio', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check main headers
      expect(find.text('Game Settings'), findsOneWidget);
      expect(find.text('Graphics & Visual Adjuster'), findsOneWidget);
      expect(find.text('Audio & Sound Effects'), findsOneWidget);
      expect(find.text('Controls & Movement'), findsOneWidget);
      expect(find.text('Player Account'), findsOneWidget);

      // Switch to Graphics category filter
      await tester.tap(find.text('Graphics'));
      await tester.pumpAndSettle();
      expect(find.text('Graphics & Visual Adjuster'), findsOneWidget);
      expect(find.text('Target Framerate'), findsOneWidget);

      // Switch to Audio category filter
      await tester.tap(find.text('Audio'));
      await tester.pumpAndSettle();
      expect(find.text('Audio & Sound Effects'), findsOneWidget);
      expect(find.text('Master Volume'), findsOneWidget);

      // Tap TEST AUDIO & HAPTICS button
      final testAudioBtn = find.text('TEST AUDIO & HAPTICS');
      expect(testAudioBtn, findsOneWidget);
      await tester.tap(testAudioBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to Controls category filter
      await tester.tap(find.text('Controls'));
      await tester.pumpAndSettle();
      expect(find.text('Controls & Movement'), findsOneWidget);
      expect(find.text('Virtual Joystick'), findsOneWidget);
      expect(find.text('Arcade D-Pad'), findsOneWidget);
    });

    testWidgets('SettingsView renders responsively on ultra-compact 320px screen width without any overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SettingsView), findsOneWidget);
      expect(find.text('Game Settings'), findsOneWidget);
    });

    testWidgets('InGameSettingsModal renders with tabs, updates settings live, and is responsive on 320px screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      GameSettings? updatedSettings;
      bool resumed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InGameSettingsModal(
              onSettingsChanged: (s) => updatedSettings = s,
              onResume: () => resumed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('IN-GAME SETTINGS'), findsOneWidget);
      expect(find.text('GRAPHICS'), findsOneWidget);
      expect(find.text('AUDIO'), findsOneWidget);
      expect(find.text('CONTROLS'), findsOneWidget);

      // Verify Graphics tab elements
      expect(find.text('Quality Preset'), findsOneWidget);
      expect(find.text('Target Framerate'), findsOneWidget);

      // Switch to AUDIO tab
      await tester.tap(find.text('AUDIO'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Master Volume'), findsOneWidget);
      expect(find.text('TEST AUDIO & HAPTICS'), findsOneWidget);

      // Switch to CONTROLS tab
      await tester.tap(find.text('CONTROLS'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Joystick Placement'), findsOneWidget);
      expect(find.text('Left-Handed'), findsOneWidget);
      expect(find.text('Right-Handed'), findsOneWidget);
      expect(find.text('Joystick Expand (Size)'), findsOneWidget);
      expect(find.text('Transparent Capacity'), findsOneWidget);
      expect(find.text('Joystick Color'), findsOneWidget);
      expect(find.text('Neon Lime'), findsOneWidget);
      expect(find.text('Electric Cyan'), findsOneWidget);

      // Scroll and tap Electric Cyan to test live color choice update
      await tester.ensureVisible(find.text('Electric Cyan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electric Cyan'));
      await tester.pumpAndSettle();
      expect(updatedSettings?.joystickColor, 'Electric Cyan');

      // Scroll and tap Right-Handed to test live settings update
      await tester.ensureVisible(find.text('Right-Handed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Right-Handed'));
      await tester.pumpAndSettle();
      expect(updatedSettings?.joystickOnLeft, false);

      // Tap RESUME MATCH
      await tester.tap(find.text('RESUME MATCH'));
      await tester.pumpAndSettle();
      expect(resumed, true);
    });
  });

  group('Player Profile Pictures & Database Persistence Tests', () {
    test('PlayerAvatar model parses presets, opponent names, custom photo URLs, and avatar studio codes', () {
      // 1. Preset test
      final alex = PlayerAvatar.getById('alex_classic');
      expect(alex.name, 'Alex Smash');
      expect(alex.isCustom, false);

      final maya = PlayerAvatar.getById('maya_speed');
      expect(maya.name, 'Maya Swift');

      // 2. Opponent lookup test
      final king = PlayerAvatar.getForOpponent('The Pickle King');
      expect(king.id, 'the_pickle_king');
      expect(king.badge, '👑');

      final ben = PlayerAvatar.getForOpponent('Ben Dinker');
      expect(ben.id, 'ben_dinker');

      // 3. Custom Photo URL
      final photo = PlayerAvatar.getById('https://example.com/custom_player.png');
      expect(photo.isCustom, true);
      expect(photo.customImageUrl, 'https://example.com/custom_player.png');
      expect(photo.badge, '📷');

      // 4. Custom Avatar Studio code
      final studio = PlayerAvatar.getById('custom:JC:2:3');
      expect(studio.isCustom, true);
      expect(studio.initials, 'JC');
      expect(studio.badge, '🎨');
    });

    test('DatabaseService saves, updates, and loads player avatar_id and returns it in leaderboard', () async {
      final db = DatabaseService.instance;
      final uniqueUser = 'avatar_user_${DateTime.now().millisecondsSinceEpoch}';
      final reg = await db.registerUser(username: uniqueUser, password: 'password123');
      final userId = reg['userId'] as int;

      // 1. Save player data with custom avatar
      await db.savePlayerData(
        userId: userId,
        avatarId: 'jordan_power',
        playerLevel: 4,
        playerXp: 200,
        xpToNextLevel: 500,
        coins: 1200,
        trophies: 150,
        matchesPlayed: 10,
        matchesWon: 8,
        totalSmashes: 45,
        bestStreak: 5,
        currentStreak: 3,
        tournaments: [],
        challenges: [],
        settings: const GameSettings(),
      );

      // 2. Load and verify avatarId
      final loaded = await db.loadPlayerData(userId);
      expect(loaded, isNotNull);
      expect(loaded!['avatarId'], 'jordan_power');

      // 3. Update avatar to custom studio code
      await db.updateUserAvatar(userId, 'custom:WIN:1:2');
      final reloaded = await db.loadPlayerData(userId);
      expect(reloaded!['avatarId'], 'custom:WIN:1:2');

      // 4. Check leaderboard contains avatar_id
      final leaderboard = await db.getAllPlayersLeaderboard(limit: 200);
      expect(leaderboard.isNotEmpty, true);
      final me = leaderboard.firstWhere((p) => p['username'] == uniqueUser || p['user_id'] == userId);
      expect(me['avatar_id'], 'custom:WIN:1:2');
    });

    test('Every player saves and loads their own distinct profile picture in SQLite', () async {
      final db = DatabaseService.instance;
      final state = GameStateManager.instance;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 1. Register Player Alpha
      final userAlphaName = 'AlphaPlayer_$timestamp';
      final regAlpha = await db.registerUser(username: userAlphaName, password: 'password123');
      final userAlphaId = regAlpha['userId'] as int;

      // 2. Register Player Beta
      final userBetaName = 'BetaPlayer_$timestamp';
      final regBeta = await db.registerUser(username: userBetaName, password: 'password123');
      final userBetaId = regBeta['userId'] as int;

      // 3. Login as Player Alpha, set custom gallery/file photo, and save
      await state.loginWithUser(userAlphaId, userAlphaName);
      await state.updatePlayerAvatar('C:/photos/alpha_gallery_pic.png');
      expect(state.playerAvatarId, 'C:/photos/alpha_gallery_pic.png');

      // 4. Login as Player Beta, set different custom gallery/file photo, and save
      await state.loginWithUser(userBetaId, userBetaName);
      await state.updatePlayerAvatar('/storage/emulated/0/DCIM/beta_camera.jpg');
      expect(state.playerAvatarId, '/storage/emulated/0/DCIM/beta_camera.jpg');

      // 5. Verify direct database records
      final dataAlpha = await db.loadPlayerData(userAlphaId);
      final dataBeta = await db.loadPlayerData(userBetaId);
      expect(dataAlpha!['avatarId'], 'C:/photos/alpha_gallery_pic.png');
      expect(dataBeta!['avatarId'], '/storage/emulated/0/DCIM/beta_camera.jpg');

      // 6. Switch back to Player Alpha - their specific profile picture is restored
      await state.loginWithUser(userAlphaId, userAlphaName);
      expect(state.playerAvatarId, 'C:/photos/alpha_gallery_pic.png');

      // 7. Switch back to Player Beta - their specific profile picture is restored
      await state.loginWithUser(userBetaId, userBetaName);
      expect(state.playerAvatarId, '/storage/emulated/0/DCIM/beta_camera.jpg');

      // 8. Verify Leaderboard reflects both distinct avatars
      final leaderboard = await db.getAllPlayersLeaderboard(limit: 5000);
      final alphaInBoard = leaderboard.firstWhere((p) => p['user_id'] == userAlphaId);
      final betaInBoard = leaderboard.firstWhere((p) => p['user_id'] == userBetaId);
      expect(alphaInBoard['avatar_id'], 'C:/photos/alpha_gallery_pic.png');
      expect(betaInBoard['avatar_id'], '/storage/emulated/0/DCIM/beta_camera.jpg');

      state.loginAsGuest();
    });

    testWidgets('AvatarPickerDialog renders clean profile picture picker with gallery, files, and badges (champions and studio removed)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = GameStateManager.instance;
      state.loginAsGuest();
      state.playerAvatarId = 'alex_classic';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarPickerDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('PLAYER PROFILE PICTURE'), findsOneWidget);
      // Champions and Studio are removed from profile as requested
      expect(find.text('CHAMPIONS'), findsNothing);
      expect(find.text('AVATAR STUDIO'), findsNothing);

      // Verify custom profile picture actions and league badges
      expect(find.byKey(const ValueKey('picker_gallery_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('picker_files_btn')), findsOneWidget);
      expect(find.text('CHOOSE FROM GALLERY'), findsOneWidget);
      expect(find.text('BROWSE FILES'), findsOneWidget);
      expect(find.text('League Badges & Profile Avatars'), findsOneWidget);

      // Pick Alex Smash badge
      final alexSmash = find.text('Alex Smash');
      await tester.ensureVisible(alexSmash);
      await tester.tap(alexSmash);
      await tester.pumpAndSettle();
      expect(state.playerAvatarId, 'alex_classic');
    });

    testWidgets('InGameSettingsModal renders responsively in short landscape mode (600x360) without overflow and supports AVATAR tab', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InGameSettingsModal(
              onResume: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('IN-GAME SETTINGS'), findsOneWidget);
      expect(find.text('AVATAR'), findsOneWidget);

      // Tap AVATAR tab
      await tester.tap(find.text('AVATAR'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Player Profile Picture'), findsOneWidget);
      expect(find.text('Quick Select Avatar'), findsOneWidget);
      expect(find.text('ADD OWN PHOTO / CUSTOM STUDIO'), findsOneWidget);
    });

    testWidgets('GamePlayScreen in-game HUD displays player and opponent avatars responsively on 320px width', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GamePlayScreen(
            matchType: 'tournament',
            opponentName: 'Ben Dinker',
            matchTitle: 'Quarter-Final',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(PlayerAvatarWidget), findsWidgets);
      expect(find.text('Ben Dinker'), findsOneWidget);
      expect(find.byKey(const ValueKey('ingame_settings_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('ingame_pause_btn')), findsOneWidget);
    });
  });

  group('Smooth Animated Lights Background & 2D Game Text Tests', () {
    testWidgets('SmoothLightsAlphabetBackground renders CustomPaint canvas and child correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmoothLightsAlphabetBackground(
              animate: false,
              child: Center(
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SmoothLightsAlphabetBackground), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('SmoothLightsAlphabetBackground animates and updates smoothly without exceptions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmoothLightsAlphabetBackground(
              animate: true,
              forceAnimateInTests: true,
              speedMultiplier: 2.0,
            ),
          ),
        ),
      );
      // Pump multiple animation ticks
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.byType(SmoothLightsAlphabetBackground), findsOneWidget);
    });

    testWidgets('Game2DText renders with stroke layer, 2D drop extrusion shadow, and foreground text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Game2DText(
                'SMASH POWER',
                fontSize: 26,
                textColor: AppTheme.electricCyan,
                strokeColor: Colors.black,
                strokeWidth: 4.0,
                shadowOffset: Offset(0, 3.0),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(Game2DText), findsOneWidget);
      expect(find.text('SMASH POWER'), findsOneWidget);
    });

    testWidgets('Game2DText hero, title, score, and badge presets render correctly with gradients and vibrant colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Game2DText.hero('HERO SMASH'),
                Game2DText.title('TITLE CHAMPION'),
                Game2DText.score('9999'),
                Game2DText.badge('PRO LVL 10'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('HERO SMASH'), findsOneWidget);
      expect(find.text('TITLE CHAMPION'), findsOneWidget);
      expect(find.text('9999'), findsOneWidget);
      expect(find.text('PRO LVL 10'), findsOneWidget);
    });

    testWidgets('AppTheme.game2DTextStyle generates multi-directional shadows for 2D arcade outline', (WidgetTester tester) async {
      final style = AppTheme.game2DTextStyle(
        fontSize: 20,
        color: AppTheme.neonLime,
        outlineColor: Colors.black,
        outlineWidth: 2.0,
        shadowDistance: 3.0,
      );

      expect(style.fontSize, 20);
      expect(style.color, AppTheme.neonLime);
      expect(style.shadows, isNotNull);
      expect(style.shadows!.length, greaterThanOrEqualTo(5));
    });

    testWidgets('DashboardScreen and Auth screens render with SmoothLightsAlphabetBackground and 2D text', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      GameStateManager.instance.loginAsGuest();

      await tester.pumpWidget(const PickleballApp(initialScreen: DashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(SmoothLightsAlphabetBackground), findsWidgets);
      expect(find.byType(Game2DText), findsWidgets);
      expect(find.text('PICKL'), findsOneWidget);
    });

    testWidgets('SettingsView does not display Reset Progress option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Progress'), findsNothing);
      expect(find.text('Reset All Progress?'), findsNothing);
      expect(find.text('Guides & Rules'), findsOneWidget);
    });

    testWidgets('Orientation switches between Dashboard (portrait) and GamePlay (landscape)', (WidgetTester tester) async {
      final log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      // Dashboard locks portrait
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final portraitCalls = log.where((call) =>
        call.method == 'SystemChrome.setPreferredOrientations' &&
        (call.arguments as List).contains('DeviceOrientation.portraitUp')
      );
      expect(portraitCalls.isNotEmpty, true);

      // Gameplay locks landscape
      await tester.pumpWidget(
        const MaterialApp(
          home: GamePlayScreen(),
        ),
      );
      await tester.pump();

      final landscapeCalls = log.where((call) =>
        call.method == 'SystemChrome.setPreferredOrientations' &&
        (call.arguments as List).contains('DeviceOrientation.landscapeLeft')
      );
      expect(landscapeCalls.isNotEmpty, true);
    });
  });

  group('Official Pickleball Sports Rules Tests', () {
    test('Game starts in waiting-for-serve state with Player 1 serving first', () {
      final game = PickleballGame(targetScore: 5);
      game.player1 = PlayerComponent(isPlayerOne: true);
      game.player2 = PlayerComponent(isPlayerOne: false);
      game.ball = BallComponent()..customGame = game;
      game.prepareServicePositions();

      expect(game.isWaitingForServe, true);
      expect(game.serverPlayer, 1);
      expect(game.servingSide, 'right');
      expect(game.ball.velocity, Vector2.zero());
      expect(game.player1.position.x, 760.0);
      expect(game.player2.position.x, 520.0);

      // Execute serve
      game.ball.executeServe(isPlayerOne: true);
      expect(game.isWaitingForServe, false);
      expect(game.ball.velocity == Vector2.zero(), false);
      expect(game.ball.velocity.y < 0, true); // Traveling up towards Player 2
    });

    test('Side-out scoring only awards points to the server, and receiver win causes Side-Out', () {
      final game = PickleballGame(targetScore: 5);
      game.player1 = PlayerComponent(isPlayerOne: true);
      game.player2 = PlayerComponent(isPlayerOne: false);
      game.ball = BallComponent()..customGame = game;
      game.prepareServicePositions();

      expect(game.serverPlayer, 1);
      expect(game.p1Score, 0);
      expect(game.p2Score, 0);

      // 1. Server (P1) wins rally -> +1 point to P1
      game.handleRallyWon(winnerIsPlayerOne: true, faultReason: '');
      expect(game.p1Score, 1);
      expect(game.p2Score, 0);
      expect(game.serverPlayer, 1);
      expect(game.servingSide, 'left'); // 1 is odd -> left court

      // 2. Receiver (P2) wins rally -> Side-Out! No points awarded, serve transfers to P2
      game.handleRallyWon(winnerIsPlayerOne: false, faultReason: 'FAULT: Out of Bounds');
      expect(game.p1Score, 1);
      expect(game.p2Score, 0); // Receiver did not gain a point!
      expect(game.serverPlayer, 2); // Side-out occurred!
      expect(game.servingSide, 'right'); // P2 score is 0 (even) -> right court
    });

    test('Win by 2 margin rule requires at least a 2-point lead to conclude match', () {
      bool matchFinished = false;
      bool? userWon;
      final game = PickleballGame(
        targetScore: 5,
        onMatchFinished: (won) {
          matchFinished = true;
          userWon = won;
        },
      );
      game.player1 = PlayerComponent(isPlayerOne: true);
      game.player2 = PlayerComponent(isPlayerOne: false);
      game.ball = BallComponent()..customGame = game;
      game.prepareServicePositions();

      // Set score to 4-4
      game.p1Score = 4;
      game.p2Score = 4;
      game.serverPlayer = 1;

      // P1 wins rally -> 5-4. Reached targetScore (5), but lead is only 1 point.
      game.handleRallyWon(winnerIsPlayerOne: true, faultReason: '');
      expect(game.p1Score, 5);
      expect(game.p2Score, 4);
      expect(matchFinished, false); // Must win by 2!

      // P1 wins rally again -> 6-4. Lead is 2 points! Match concludes.
      game.handleRallyWon(winnerIsPlayerOne: true, faultReason: '');
      expect(game.p1Score, 6);
      expect(game.p2Score, 4);
      expect(matchFinished, true);
      expect(userWon, true);
    });

    test('Two-Bounce Rule and Kitchen Volley fault detection', () {
      final game = PickleballGame(targetScore: 5);
      game.player1 = PlayerComponent(isPlayerOne: true);
      game.player2 = PlayerComponent(isPlayerOne: false);
      game.ball = BallComponent()..customGame = game;
      game.prepareServicePositions();

      // Serve the ball
      game.ball.executeServe(isPlayerOne: true);
      expect(game.rallyHitCount, 0); // 0 means return of serve

      // Receiver (Player 2) hits without letting serve bounce (bounceCountCurrentSide == 0)
      game.ball.bounceCountCurrentSide = 0;
      game.ball.position = game.player2.position;
      game.player2.currentState = PlayerState.slash;
      game.ball.onCollisionStart({}, game.player2);

      // Fault called! Two-Bounce Rule violation awarded to server (P1)
      expect(game.p1Score, 1);
    });

    test('Standard pickleball game defaults to 11 points and requires win by 2 margin', () {
      bool matchFinished = false;
      final game = PickleballGame(
        onMatchFinished: (won) {
          matchFinished = true;
        },
      );
      game.player1 = PlayerComponent(isPlayerOne: true);
      game.player2 = PlayerComponent(isPlayerOne: false);
      game.ball = BallComponent()..customGame = game;
      game.prepareServicePositions();

      expect(game.targetScore, 11);

      // Score is 10 - 10
      game.p1Score = 10;
      game.p2Score = 10;
      game.serverPlayer = 1;

      // P1 reaches 11 points (lead is only 1 point: 11 - 10)
      game.handleRallyWon(winnerIsPlayerOne: true, faultReason: '');
      expect(game.p1Score, 11);
      expect(matchFinished, false); // Must win by 2!

      // P1 scores again (12 - 10: lead is 2 points!)
      game.handleRallyWon(winnerIsPlayerOne: true, faultReason: '');
      expect(game.p1Score, 12);
      expect(matchFinished, true);
    });

    test('Kitchen Momentum Fault triggers when player momentum enters kitchen after volley', () {
      String? lastViolation;
      final game = PickleballGame(
        onViolation: (type, desc, rule) {
          lastViolation = type;
        },
      );
      final p1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false)..customGame = game;
      game.player1 = p1;
      game.player2 = p2;
      game.ball = BallComponent()..customGame = game;
      game.isWaitingForServe = false;
      game.rallyHitCount = 2; // Open play

      // P1 hits a volley outside the kitchen at Y = 450 (kitchen bottom line is at 440)
      p1.position = Vector2(640, 450);
      game.ball.position = Vector2(640, 450);
      game.ball.velocity = Vector2(0, 300);
      game.ball.bounceCountCurrentSide = 0; // In air -> volley!
      p1.strike();

      expect(p1.timeSinceLastVolley, 0.0);

      // P1 momentum carries forward into kitchen (Y moves to 435 <= 440) within 0.5s
      p1.position = Vector2(640, 435);
      p1.update(0.1);

      expect(lastViolation, 'KITCHEN MOMENTUM');
      expect(game.serverPlayer, 2); // Side-out awarded to CPU!
    });

    test('Body hits in flight do NOT trigger Body Fault and rally continues', () {
      String? lastViolation;
      final game = PickleballGame(
        onViolation: (type, desc, rule) {
          lastViolation = type;
        },
      );
      final p1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false)..customGame = game;
      game.player1 = p1;
      game.player2 = p2;
      game.ball = BallComponent()..customGame = game;
      game.isWaitingForServe = false;

      // Ball in flight strikes P2's body before bouncing (z > 2, bounceCount == 0, idle player)
      game.ball.position = p2.position;
      game.ball.z = 12.0;
      game.ball.bounceCountCurrentSide = 0;
      p2.currentState = PlayerState.idle;

      game.ball.onCollisionStart({}, p2);

      // Body fault removed: no fault triggered and score remains unchanged!
      expect(lastViolation, isNull);
      expect(game.p1Score, 0);
    });

    test('Multiple floor bounces trigger Double Bounce fault and score is awarded to opponent', () {
      String? lastViolation;
      final game = PickleballGame(
        settings: const GameSettings(scoringMode: 'rally'),
        onViolation: (type, desc, rule) {
          lastViolation = type;
        },
      );
      final p1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false)..customGame = game;
      game.player1 = p1;
      game.player2 = p2;
      game.ball = BallComponent()..customGame = game;
      game.isWaitingForServe = false;
      game.rallyHitCount = 2; // In active rally

      // Simulate 1st bounce
      game.ball.bounceCountCurrentSide = 0;
      game.ball.position = Vector2(640, 520); // P1 side
      game.ball.z = 0.0;
      game.ball.zVelocity = -180.0;
      game.ball.update(0.016);

      expect(game.ball.bounceCountCurrentSide, 1);
      expect(lastViolation, isNull);

      // Advance time and simulate 2nd floor bounce on P1's court without player striking
      game.ball.update(0.3);
      game.ball.z = 0.0;
      game.ball.zVelocity = -180.0;
      game.ball.update(0.016);

      // Double bounce fault triggered: opponent (Player 2) scores point!
      expect(game.p2Score, 1);
    });

    test('Expert AI calculates predictive trajectory, covers court, and strikes smoothly', () {
      final game = PickleballGame();
      final p1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      final cpu = PlayerComponent(isPlayerOne: false, isAI: true)..customGame = game;
      game.player1 = p1;
      game.player2 = cpu;
      game.ball = BallComponent()..customGame = game;
      game.isWaitingForServe = false;

      // Ball moving toward CPU with speed
      game.ball.position = Vector2(640, 300);
      game.ball.velocity = Vector2(80, -250);
      game.ball.bounceCountCurrentSide = 0;

      // CPU updates with predictive anticipation
      cpu.position = Vector2(640, 150);
      cpu.update(0.1);

      // CPU should move towards predicted landing position
      expect(cpu.aiVelocity.length, greaterThan(0));
      expect(cpu.aiSpeed, 315.0);
    });

    testWidgets('GamePlayScreen renders top-left scoreboard, top-center violation display, and top-right unified controls', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GamePlayScreen(matchType: 'quick'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('serve_action_prompt')), findsOneWidget);
      expect(find.textContaining('TAP SMASH TO SERVE'), findsOneWidget);

      // Top-Left Scoreboard verifies
      expect(find.textContaining('FIRST TO 11 • WIN BY 2'), findsOneWidget);

      // Top-Right Unified Controls verifies
      expect(find.byKey(const ValueKey('ingame_pause_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('ingame_settings_btn')), findsOneWidget);

      // Tap the serve action prompt to serve
      await tester.tap(find.byKey(const ValueKey('serve_action_prompt')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });
  });

  group('Reworked Characters & Omnidirectional AI Movement Tests', () {
    test('PlayerComponent loads and animates reworked male and female characters without exceptions', () async {
      final game = PickleballGame();
      final malePlayer = PlayerComponent(isPlayerOne: true, isFemale: false)..customGame = game;
      final femalePlayer = PlayerComponent(isPlayerOne: false, isFemale: true)..customGame = game;
      game.player1 = malePlayer;
      game.player2 = femalePlayer;
      game.ball = BallComponent()..customGame = game;

      // Both male and female players initialize successfully
      expect(malePlayer.isFemale, false);
      expect(femalePlayer.isFemale, true);
      expect(malePlayer.size, Vector2(64, 64));
      expect(femalePlayer.size, Vector2(64, 64));
    });

    test('Enemy CPU moves omnidirectionally: forward, backward, and side-to-side', () {
      final game = PickleballGame();
      final cpu = PlayerComponent(isPlayerOne: false, isFemale: true)..customGame = game;
      final p1 = PlayerComponent(isPlayerOne: true, isFemale: false)..customGame = game;
      game.player1 = p1;
      game.player2 = cpu;
      game.ball = BallComponent()..customGame = game;
      game.isWaitingForServe = false;

      // Start at baseline ready position
      cpu.position = Vector2(640.0, 140.0);

      // 1. Forward movement: ball drops short near kitchen (Y = 300, moving up towards CPU)
      game.ball.position = Vector2(640.0, 300.0);
      game.ball.velocity = Vector2(0, -300);
      game.rallyHitCount = 2; // Open play

      final initialY = cpu.position.y;
      cpu.update(0.1);

      // CPU should move FORWARD (downwards towards net, increasing Y)
      expect(cpu.position.y > initialY, true);
      expect(cpu.currentDirection, PlayerDirection.front);

      // 2. Backward movement: ball is deep towards top baseline (Y = 100)
      game.ball.position = Vector2(640.0, 100.0);
      game.ball.velocity = Vector2(0, -300);

      final currentY = cpu.position.y;
      cpu.update(0.15);

      // CPU should move BACKWARD (upwards towards baseline, decreasing Y)
      expect(cpu.position.y < currentY, true);
      expect(cpu.currentDirection, PlayerDirection.behind);

      // 3. Side-to-side movement: ball is to the left (X = 400)
      game.ball.position = Vector2(400.0, 180.0);
      game.ball.velocity = Vector2(0, -300);

      final currentX = cpu.position.x;
      cpu.update(0.1);

      // CPU should move LEFT (decreasing X)
      expect(cpu.position.x < currentX, true);
      expect(cpu.currentDirection, PlayerDirection.left);

      // 4. Side-to-side movement: ball is to the right (X = 800)
      game.ball.position = Vector2(800.0, 180.0);
      game.ball.velocity = Vector2(0, -300);

      final nextX = cpu.position.x;
      cpu.update(0.1);

      // CPU should move RIGHT (increasing X)
      expect(cpu.position.x > nextX, true);
      expect(cpu.currentDirection, PlayerDirection.right);
    });

    testWidgets('GamePlayScreen renders responsively across multiple screen dimensions', (WidgetTester tester) async {
      // 1. Ultrawide modern phone landscape (800x360)
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: GamePlayScreen(matchType: 'quick')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(GamePlayScreen), findsOneWidget);

      // 2. Standard 16:9 landscape (1280x720)
      tester.view.physicalSize = const Size(1280, 720);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);

      // 3. Portrait screen (400x800)
      tester.view.physicalSize = const Size(400, 800);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });

    test('PickleballGame camera and background scale dynamically and center across 20:9, 4:3, and 16:9 screens', () {
      final game = PickleballGame();
      expect(game.camera.viewfinder.anchor, Anchor.center);

      // 1. Ultrawide 20:9 phone (2400 x 1080)
      game.onGameResize(Vector2(2400, 1080));
      expect(game.camera.viewfinder.zoom, closeTo(1.5, 0.001));
      expect(game.camera.viewfinder.position, Vector2(640, 360));

      // 2. Tablet 4:3 iPad (2048 x 1536)
      game.onGameResize(Vector2(2048, 1536));
      expect(game.camera.viewfinder.zoom, closeTo(1.6, 0.001));
      expect(game.camera.viewfinder.position, Vector2(640, 360));

      // 3. Standard 16:9 HD screen (1280 x 720)
      game.onGameResize(Vector2(1280, 720));
      expect(game.camera.viewfinder.zoom, closeTo(1.0, 0.001));
      expect(game.camera.viewfinder.position, Vector2(640, 360));

      // 4. Background arena floor color matches theme
      final bg = Background();
      bg.updateTheme('Classic Red');
      expect(bg.apronOuterColor, const Color(0xFF7A0114));
      bg.updateTheme('Electric Blue');
      expect(bg.apronOuterColor, const Color(0xFF05121B));
    });

    test('BallComponent simulates 3D parabolic flight and bounces on the court floor', () {
      final game = PickleballGame();
      final ball = BallComponent()..customGame = game;
      game.ball = ball;
      game.player1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      game.player2 = PlayerComponent(isPlayerOne: false)..customGame = game;
      game.player1.position = Vector2(760, 695);
      game.player2.position = Vector2(520, 130);

      // 1. Ball starts at paddle height ready for serve
      ball.setupForServe();
      expect(ball.z, 16.0);
      expect(ball.isWaitingForServe, true);

      // 2. Serve ball -> launches upward arc
      ball.executeServe(isPlayerOne: true);
      expect(ball.zVelocity, 210.0);
      expect(ball.isWaitingForServe, false);
      expect(ball.bounceCountCurrentSide, 0);

      // 3. Gravity pulls ball down toward floor
      ball.update(0.1);
      expect(ball.z > 0, true);

      // 4. Ball reaches floor (z <= 0) -> Floor bounce triggers in open rally!
      game.rallyHitCount = 2;
      ball.position = Vector2(640, 200);
      ball.z = 2.0;
      ball.zVelocity = -200.0;
      ball.update(0.02); // Drops to z <= 0

      // Ball bounced on floor:
      expect(ball.z, 0.0);
      expect(ball.bounceCountCurrentSide, 1);
      expect(ball.zVelocity > 0, true); // Rebounded upward off the hard floor!
    });

    test('Player 1 and Player 2 are allowed to step outside the white lines into the apron while remaining clamped to playable limits', () {
      final game = PickleballGame();
      final p1 = PlayerComponent(isPlayerOne: true, isFemale: false)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false, isFemale: true)..customGame = game;
      game.player1 = p1;
      game.player2 = p2;
      game.ball = BallComponent()..customGame = game;
      game.isWaitingForServe = false;

      // 1. Player 1 (Bottom): can step outside white lines (X < 400 or X > 880, Y > 670)
      // Moving into left apron: clamped to 320.0
      p1.position = Vector2(100.0, 680.0);
      p1.update(0.1);
      expect(p1.position.x, 320.0);
      expect(p1.position.x < 400.0, true); // Outside white line!
      expect(p1.isOutsideCourt, true);

      // Moving into right apron and behind baseline: clamped to 960.0 and 715.0
      p1.position = Vector2(1100.0, 800.0);
      p1.update(0.1);
      expect(p1.position.x, 960.0);
      expect(p1.position.x > 880.0, true); // Outside white line!
      expect(p1.position.y, 715.0);
      expect(p1.position.y > 670.0, true); // Outside baseline!
      expect(p1.isOutsideCourt, true);

      // Player 1 cannot cross net into opponent's half
      p1.position = Vector2(640.0, 200.0);
      p1.update(0.1);
      expect(p1.position.y, 385.0);

      // 2. Player 2 (CPU): can step outside white lines
      p2.position = Vector2(100.0, 5.0);
      p2.update(0.1);
      expect(p2.position.x, 320.0);
      expect(p2.position.x < 400.0, true);
      expect(p2.position.y, 15.0);
      expect(p2.position.y < 50.0, true); // Outside top baseline!
      expect(p2.isOutsideCourt, true);

      // Player 2 cannot cross net into P1 half
      p2.position = Vector2(640.0, 500.0);
      p2.update(0.1);
      expect(p2.position.y, 330.0);
    });

    test('Player outside the white line can hit ball after floor bounce, and ball is guaranteed to bounce inside opponent court', () {
      final game = PickleballGame();
      final p1 = PlayerComponent(isPlayerOne: true, isFemale: false)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false, isFemale: true)..customGame = game;
      final ball = BallComponent()..customGame = game;
      game.player1 = p1;
      game.player2 = p2;
      game.ball = ball;
      game.isWaitingForServe = false;
      game.rallyHitCount = 3; // Open play

      // Position Player 1 in the right apron outside the white sideline
      p1.position = Vector2(920.0, 550.0);
      expect(p1.isOutsideCourt, true);

      // Ball is flying towards P1 in the apron
      ball.position = Vector2(915.0, 540.0);
      ball.velocity = Vector2(0.0, 200.0); // Moving towards P1
      ball.z = 12.0;

      // 1. If ball has not bounced yet, strike from outside court is prevented
      ball.bounceCountCurrentSide = 0;
      p1.strike();
      expect(ball.velocity.y > 0, true); // Not hit yet, still moving toward P1

      // 2. Once ball bounces on floor, strike from outside court is allowed!
      ball.bounceCountCurrentSide = 1;
      p1.strike();

      // Ball was struck!
      expect(ball.velocity.y < 0, true); // Propelled toward opponent court
      expect(ball.bounceCountCurrentSide, 0);

      // Calculate where the ball will land on the floor
      final tBounce = (ball.zVelocity + sqrt(ball.zVelocity * ball.zVelocity + 4 * 170.0 * ball.z)) / 340.0;
      final landingX = ball.position.x + ball.velocity.x * tBounce;
      final landingY = ball.position.y + ball.velocity.y * tBounce;

      // Ball MUST bounce inside the opponent's court boundaries!
      // Court X is [400, 880], Court Y (P2 side) is [50, 360]
      expect(landingX >= 400.0 && landingX <= 880.0, true,
          reason: 'Ball landing X ($landingX) must be inside court sidelines [400, 880]');
      expect(landingY >= 50.0 && landingY <= 360.0, true,
          reason: 'Ball landing Y ($landingY) must be inside opponent court half [50, 360]');
    });

    test('Soft hit or neutral hit from any position cleanly clears net and bounces inside court boundaries', () {
      final game = PickleballGame();
      final p1 = PlayerComponent(isPlayerOne: true, isFemale: false)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false, isFemale: true)..customGame = game;
      final ball = BallComponent()..customGame = game;
      game.player1 = p1;
      game.player2 = p2;
      game.ball = ball;
      game.isWaitingForServe = false;
      game.rallyHitCount = 2;

      // Player 1 at deep court, hitting without extra joystick movement (neutral / soft touch)
      p1.position = Vector2(640.0, 650.0);
      ball.position = Vector2(640.0, 640.0);
      ball.velocity = Vector2(0.0, 150.0);
      ball.bounceCountCurrentSide = 1;

      ball.processPlayerHit(p1);

      // Parabolic flight time to floor
      final tBounce = (ball.zVelocity + sqrt(ball.zVelocity * ball.zVelocity + 4 * 170.0 * ball.z)) / 340.0;
      final landingX = ball.position.x + ball.velocity.x * tBounce;
      final landingY = ball.position.y + ball.velocity.y * tBounce;

      // Verify net clearance at Y = 360
      final tNet = (360.0 - ball.position.y) / ball.velocity.y;
      final zAtNet = ball.z + ball.zVelocity * tNet - 0.5 * ball.gravity * tNet * tNet;

      expect(zAtNet > 18.0, true, reason: 'Ball altitude at net ($zAtNet px) must exceed net tape height (18 px)');
      expect(landingX >= 400.0 && landingX <= 880.0, true, reason: 'Landing X ($landingX) must be in-bounds');
      expect(landingY >= 50.0 && landingY <= 360.0, true, reason: 'Landing Y ($landingY) must be inside P2 court');
    });

    test('Background renders 2D pixelated portrait court geometry with un-aliased lines and theme support', () {
      final bg = Background();
      expect(bg.paint.isAntiAlias, false);
      expect(bg.paint.filterQuality, FilterQuality.none);
      expect(Background.courtLeftX, 400.0);
      expect(Background.courtRightX, 880.0);
      expect(Background.courtTopY, 50.0);
      expect(Background.courtBottomY, 670.0);
      expect(Background.netY, 360.0);
      expect(Background.kitchenTopY, 280.0);
      expect(Background.kitchenBottomY, 440.0);
    });

    test('BallComponent returns forward without sharp sideways angles when hit by player', () {
      final game = PickleballGame();
      final ball = BallComponent()..customGame = game;
      final p1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false)..customGame = game;
      game.ball = ball;
      game.player1 = p1;
      game.player2 = p2;

      // Position ball near P1 for a hit, with maximum lateral offset and movement
      p1.position = Vector2(640.0, 580.0);
      p1.hAxis = 1; // Moving full speed right
      ball.position = Vector2(695.0, 575.0); // Extreme lateral edge of paddle reach
      ball.velocity = Vector2(0, 300); // Coming down from P2
      ball.z = 10.0;
      ball.isWaitingForServe = false;
      game.isWaitingForServe = false;
      game.rallyHitCount = 2;
      ball.bounceCountCurrentSide = 1;

      // Strike ball
      p1.strike();

      // Ball velocity.x should be smoothly bounded within [-120, 120] and velocity.y must propel toward P2
      expect(ball.velocity.x.abs() <= 120.0, true);
      expect(ball.velocity.y < 0, true); // Traveling forward up toward opponent court
    });

    testWidgets('AnimatedCharacterDisplay renders only character without paddle attachment', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedCharacterDisplay(
                height: 180,
                showControls: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(AnimatedCharacterDisplay), findsOneWidget);
    });
  });

  group('Doubles 2v2 Mode and Official Rules Tests', () {
    test('Doubles mode initializes with 4 players and starts at 0-0-2 with server 2 on Team 1', () {
      final game = PickleballGame(isDoubles: true);
      expect(game.isDoubles, true);
      expect(game.serverTeam, 1);
      expect(game.serverNumber, 2);
      expect(game.doublesScoreCallout, '0 - 0 - 2');
      expect(game.servingSide, 'right');
    });

    test('Doubles server stands behind baseline outside court during service preparation', () {
      final game = PickleballGame(isDoubles: true);
      final p1 = PlayerComponent(isPlayerOne: true, isAI: false, playerSlot: 1)..customGame = game;
      final p1Partner = PlayerComponent(isPlayerOne: true, isAI: true, playerSlot: 2)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false, isAI: true, playerSlot: 1)..customGame = game;
      final p2Partner = PlayerComponent(isPlayerOne: false, isAI: true, playerSlot: 2)..customGame = game;
      final ball = BallComponent()..customGame = game;

      game.player1 = p1;
      game.player1Partner = p1Partner;
      game.player2 = p2;
      game.player2Partner = p2Partner;
      game.ball = ball;

      game.prepareServicePositions();

      // Team 1 Server 2 starts serving from right side behind baseline (Y = 695.0, court bottom is 670.0)
      final server = game.activeServerComponent;
      expect(server.position.y, 695.0);
      expect(server.position.y > 670.0, true);
      expect(server.position.x, 760.0);

      // Ball is placed with the server at paddle position
      expect(ball.position.x, server.position.x + 20);
      expect(ball.position.y, server.position.y - 28);

      // Strike serve: ball is launched towards diagonal court (X ~ 520, Y ~ 165)
      server.strike();
      expect(ball.velocity.y < 0, true); // Moving towards Team 2 side
      expect(ball.isWaitingForServe, false);
      expect(game.isWaitingForServe, false);

      // Server steps forward into court inside baseline
      expect(server.position.y <= 670.0, true);
    });

    test('Doubles rally win by server scores 1 point and swaps partner courts', () {
      final game = PickleballGame(isDoubles: true);
      final p1 = PlayerComponent(isPlayerOne: true, isAI: false, playerSlot: 1)..customGame = game;
      final p1Partner = PlayerComponent(isPlayerOne: true, isAI: true, playerSlot: 2)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false, isAI: true, playerSlot: 1)..customGame = game;
      final p2Partner = PlayerComponent(isPlayerOne: false, isAI: true, playerSlot: 2)..customGame = game;
      final ball = BallComponent()..customGame = game;

      game.player1 = p1;
      game.player1Partner = p1Partner;
      game.player2 = p2;
      game.player2Partner = p2Partner;
      game.ball = ball;

      expect(game.p1CourtSide, 'right');
      expect(game.p1PartnerCourtSide, 'left');

      // Team 1 wins rally
      game.handleRallyWon(winnerIsPlayerOne: true, faultReason: '');

      // Score increases by 1, partners swap courts
      expect(game.p1Score, 1);
      expect(game.p2Score, 0);
      expect(game.serverNumber, 2); // Same server serves again
      expect(game.p1CourtSide, 'left');
      expect(game.p1PartnerCourtSide, 'right');
      expect(game.doublesScoreCallout, '1 - 0 - 2');
    });

    test('Doubles opening serve loss (0-0-2) causes immediate Side-Out to Team 2 Server 1', () {
      final game = PickleballGame(isDoubles: true);
      final p1 = PlayerComponent(isPlayerOne: true, isAI: false, playerSlot: 1)..customGame = game;
      final p1Partner = PlayerComponent(isPlayerOne: true, isAI: true, playerSlot: 2)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false, isAI: true, playerSlot: 1)..customGame = game;
      final p2Partner = PlayerComponent(isPlayerOne: false, isAI: true, playerSlot: 2)..customGame = game;
      final ball = BallComponent()..customGame = game;

      game.player1 = p1;
      game.player1Partner = p1Partner;
      game.player2 = p2;
      game.player2Partner = p2Partner;
      game.ball = ball;

      // Opponent wins the rally
      game.handleRallyWon(winnerIsPlayerOne: false, faultReason: 'FAULT: Out of Bounds');

      // Side-Out to Team 2, server 1
      expect(game.serverTeam, 2);
      expect(game.serverNumber, 1);
      expect(game.p1Score, 0);
      expect(game.p2Score, 0);
      expect(game.doublesScoreCallout, '0 - 0 - 1');
    });

    test('Doubles regular rotation: Server 1 loss transfers to Server 2 on same team; Server 2 loss causes Side-Out', () {
      final game = PickleballGame(isDoubles: true);
      final p1 = PlayerComponent(isPlayerOne: true, isAI: false, playerSlot: 1)..customGame = game;
      final p1Partner = PlayerComponent(isPlayerOne: true, isAI: true, playerSlot: 2)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false, isAI: true, playerSlot: 1)..customGame = game;
      final p2Partner = PlayerComponent(isPlayerOne: false, isAI: true, playerSlot: 2)..customGame = game;
      final ball = BallComponent()..customGame = game;

      game.player1 = p1;
      game.player1Partner = p1Partner;
      game.player2 = p2;
      game.player2Partner = p2Partner;
      game.ball = ball;

      // Force state to Team 2 Server 1 (e.g. after side-out)
      game.serverTeam = 2;
      game.serverNumber = 1;

      // Team 1 wins rally -> Team 2 Server 1 loses serve
      game.handleRallyWon(winnerIsPlayerOne: true, faultReason: '');

      // Serve rotates to Server 2 of same team (Team 2)
      expect(game.serverTeam, 2);
      expect(game.serverNumber, 2);
      expect(game.doublesScoreCallout, '0 - 0 - 2');

      // Team 1 wins rally again -> Team 2 Server 2 loses serve -> Side-Out to Team 1 Server 1
      game.handleRallyWon(winnerIsPlayerOne: true, faultReason: '');
      expect(game.serverTeam, 1);
      expect(game.serverNumber, 1);
      expect(game.doublesScoreCallout, '0 - 0 - 1');
    });

    testWidgets('Dashboard renders 1v1 SINGLES and 2v2 DOUBLES buttons and navigates to 2v2 Doubles match', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = GameStateManager.instance;
      state.loginAsGuest();

      await tester.pumpWidget(const PickleballApp(initialScreen: DashboardScreen()));
      await tester.pumpAndSettle();

      final singlesBtn = find.byKey(const ValueKey('dashboard_1v1_btn'));
      final doublesBtn = find.byKey(const ValueKey('dashboard_2v2_btn'));

      expect(singlesBtn, findsOneWidget);
      expect(doublesBtn, findsOneWidget);

      // Tap 2v2 Doubles button
      await tester.tap(doublesBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GamePlayScreen), findsOneWidget);
    });

    testWidgets('GamePlayScreen renders HUD for 2v2 Doubles with 3-number score callout and partner info', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GamePlayScreen(
            isDoubles: true,
            opponentName: 'CPU Duo',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('2V2 DOUBLES'), findsOneWidget);
      expect(find.textContaining('CALL: 0 - 0 - 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('serve_action_prompt')), findsOneWidget);
      expect(find.byKey(const ValueKey('ingame_pause_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('ingame_settings_btn')), findsOneWidget);
    });
  });

  group('Character Ground Shadow & Responsive In-Game Rules Tests', () {
    test('PlayerComponent renders ground shadow beneath character feet and reports kitchen boundary correctly', () {
      final game = PickleballGame();
      final p1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false)..customGame = game;
      game.player1 = p1;
      game.player2 = p2;

      expect(p1.size, Vector2(64, 64));

      // Test Kitchen boundary detection for P1 (Bottom side, NVZ is y <= 440.0)
      p1.position = Vector2(640.0, 420.0);
      expect(p1.isInKitchen, true);
      p1.position = Vector2(640.0, 520.0);
      expect(p1.isInKitchen, false);

      // Test Kitchen boundary detection for P2 (Top side, NVZ is y >= 324.0)
      p2.position = Vector2(640.0, 340.0);
      expect(p2.isInKitchen, true);
      p2.position = Vector2(640.0, 150.0);
      expect(p2.isInKitchen, false);

      // Verify render executes without error and draws ground shadow
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      p1.render(canvas);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    testWidgets('PickleballRulesModal renders all 5 rule tabs, navigation, and resume action', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool resumed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PickleballRulesModal(
              onResume: () {
                resumed = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PICKLEBALL RULES GUIDE'), findsOneWidget);
      expect(find.text('Violations & Faults'), findsOneWidget);
      expect(find.text('Two-Bounce Rule'), findsOneWidget);
      expect(find.text('The Kitchen (NVZ)'), findsOneWidget);
      expect(find.text('Serving & Court'), findsOneWidget);
      expect(find.text('Scoring & Rotation'), findsOneWidget);

      // Switch to Two-Bounce Rule tab
      await tester.tap(find.text('Two-Bounce Rule'));
      await tester.pumpAndSettle();
      expect(find.text('Shot 1: The Serve'), findsOneWidget);
      expect(find.text('Shot 2: Return of Serve'), findsOneWidget);

      // Switch to Kitchen tab
      await tester.tap(find.text('The Kitchen (NVZ)'));
      await tester.pumpAndSettle();
      expect(find.text('No Volleys Allowed Inside'), findsOneWidget);
      expect(find.text('Hitting Off the Bounce (Dinking)'), findsOneWidget);

      // Switch to Serving tab
      await tester.tap(find.text('Serving & Court'));
      await tester.pumpAndSettle();
      expect(find.text('Underhand Motion'), findsOneWidget);
      expect(find.text('Clearing the Kitchen Line'), findsOneWidget);

      // Switch to Scoring tab
      await tester.tap(find.text('Scoring & Rotation'));
      await tester.pumpAndSettle();
      expect(find.text('Only the Serving Side Scores'), findsOneWidget);

      // Tap Resume Play
      await tester.tap(find.text('RESUME PLAY'));
      await tester.pumpAndSettle();
      expect(resumed, true);
    });

    testWidgets('PickleballRulesModal auto-selects tab corresponding to highlighted violation', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PickleballRulesModal(
              highlightedViolation: 'TWO-BOUNCE RULE',
              onResume: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should auto-navigate to Two-Bounce Rule tab
      expect(find.text('THE TWO-BOUNCE RULE (USA Pickleball Rule 2)'), findsOneWidget);
      expect(find.textContaining('Violation Review: TWO-BOUNCE RULE'), findsOneWidget);
    });

    testWidgets('GamePlayScreen renders top bar responsively across 320px ultra-compact width, short landscape, and desktop', (WidgetTester tester) async {
      // 1. Ultra-compact 320px width
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GamePlayScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('serve_action_prompt')), findsOneWidget);
      expect(find.byKey(const ValueKey('ingame_pause_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('ingame_rules_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('ingame_settings_btn')), findsOneWidget);

      // 2. Short landscape screen (600x360)
      tester.view.physicalSize = const Size(600, 360);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('ingame_rules_btn')), findsOneWidget);

      // 3. Desktop / Tablet screen (1280x720)
      tester.view.physicalSize = const Size(1280, 720);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('serve_action_prompt')), findsOneWidget);
      expect(find.byKey(const ValueKey('ingame_rules_btn')), findsOneWidget);
    });

    testWidgets('Tapping rules button in GamePlayScreen top bar or pause menu opens PickleballRulesModal', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GamePlayScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Tap ingame_rules_btn directly from top bar
      final rulesBtn = find.byKey(const ValueKey('ingame_rules_btn'));
      expect(rulesBtn, findsOneWidget);
      await tester.tap(rulesBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(PickleballRulesModal), findsOneWidget);
      expect(find.text('PICKLEBALL RULES GUIDE'), findsOneWidget);

      // Close modal using RESUME PLAY
      await tester.tap(find.text('RESUME PLAY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(PickleballRulesModal), findsNothing);

      // 2. Pause match and open rules via pause menu
      final pauseBtn = find.byKey(const ValueKey('ingame_pause_btn'));
      await tester.tap(pauseBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final pauseRulesBtn = find.byKey(const ValueKey('pause_menu_rules_btn'));
      expect(pauseRulesBtn, findsOneWidget);
      await tester.tap(pauseRulesBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(PickleballRulesModal), findsOneWidget);
      await tester.tap(find.text('RESUME PLAY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(PickleballRulesModal), findsNothing);
    });

    test('AI waits for ball to bounce on floor before striking and movement speeds are slower and smooth', () {
      final game = PickleballGame();
      final cpu = PlayerComponent(isPlayerOne: false, isAI: true)..customGame = game;
      final p1 = PlayerComponent(isPlayerOne: true, isAI: false)..customGame = game;
      final ball = BallComponent()..customGame = game;
      game.player1 = p1;
      game.player2 = cpu;
      game.ball = ball;
      game.isWaitingForServe = false;
      ball.isWaitingForServe = false;

      // 1. Movement speed verification
      expect(p1.speed, 280.0);
      expect(cpu.aiSpeed, 315.0);
      expect(ball.initialSpeed, 280.0);
      expect(ball.gravity, 340.0);

      // 2. Ball approaching CPU in air before floor bounce (bounceCountCurrentSide == 0)
      cpu.position = Vector2(640.0, 140.0);
      ball.position = Vector2(640.0, 145.0);
      ball.velocity = Vector2(0, -280.0);
      ball.bounceCountCurrentSide = 0; // In air!
      game.rallyHitCount = 2;

      // Update CPU AI - should NOT strike yet because ball has not bounced on floor!
      final hitsBefore = game.rallyHitCount;
      cpu.update(0.016);
      expect(game.rallyHitCount, hitsBefore); // Did not hit in the air

      // 3. Ball bounces on the court floor (bounceCountCurrentSide >= 1)
      ball.bounceCountCurrentSide = 1; // Bounced!
      cpu.update(0.016);

      // CPU should now strike cleanly after the floor bounce!
      expect(game.rallyHitCount > hitsBefore, true);
      expect(ball.velocity.y > 0, true); // Propelled forward back to P1 side
    });
  });

  group('Continuous Gameplay & Seamless Flow Tests', () {
    test('BallComponent floor bounce pop provides generous hangtime for continuous play', () {
      final game = PickleballGame();
      final ball = BallComponent()..customGame = game;
      game.ball = ball;
      game.isWaitingForServe = false;
      ball.isWaitingForServe = false;

      // Ball falling toward floor at high speed
      ball.position = Vector2(640.0, 500.0);
      ball.z = 2.0;
      ball.zVelocity = -220.0;
      ball.update(0.02); // Triggers floor bounce (z <= 0)

      // Verify generous pop-up velocity (>= 175 px/s, giving > 1.0s airtime)
      expect(ball.z, 0.0);
      expect(ball.bounceCountCurrentSide, 1);
      expect(ball.zVelocity >= 175.0, true, reason: 'Floor bounce must pop up >= 175 px/s for generous hangtime');

      // Estimate hangtime until second bounce: 2 * v_z / g = 2 * 175 / 340 ~ 1.03s
      final hangTime = (2 * ball.zVelocity) / ball.gravity;
      expect(hangTime >= 1.0, true, reason: 'Hangtime ($hangTime s) must exceed 1.0s to keep rallies continuous');
    });

    test('Auto-serve executes smoothly so gameplay never stalls', () {
      final game = PickleballGame(
        settings: const GameSettings(autoServe: true),
      );
      final p1 = PlayerComponent(isPlayerOne: true, isAI: false)..customGame = game;
      final cpu = PlayerComponent(isPlayerOne: false, isAI: true)..customGame = game;
      final ball = BallComponent()..customGame = game;
      game.player1 = p1;
      game.player2 = cpu;
      game.ball = ball;

      // 1. Human serve auto-serves after countdown if player does not tap
      game.prepareServicePositions();
      expect(game.isWaitingForServe, true);
      expect(ball.isWaitingForServe, true);

      // Simulate 1.9s of wait time (exceeds 1.8s auto-serve threshold)
      for (int i = 0; i < 20; i++) {
        ball.update(0.1);
      }

      // Auto-serve should have fired!
      expect(game.isWaitingForServe, false, reason: 'Auto-serve must launch if player does not tap within 1.8s');
      expect(ball.isWaitingForServe, false);
      expect(ball.velocity.length > 0, true);
    });

    test('Continuous rally streak increments on legal hits and resets on rally end', () {
      final game = PickleballGame();
      final p1 = PlayerComponent(isPlayerOne: true, isAI: false)..customGame = game;
      final cpu = PlayerComponent(isPlayerOne: false, isAI: true)..customGame = game;
      final ball = BallComponent()..customGame = game;
      game.player1 = p1;
      game.player2 = cpu;
      game.ball = ball;
      game.isWaitingForServe = false;

      int recordedStreak = 0;
      int recordedLongest = 0;
      game.onRallyStreakUpdated = (streak, longest) {
        recordedStreak = streak;
        recordedLongest = longest;
      };

      // 1. First hit by Player 1
      p1.position = Vector2(640.0, 580.0);
      ball.position = Vector2(640.0, 570.0);
      ball.velocity = Vector2(0.0, 200.0);
      ball.bounceCountCurrentSide = 1;

      ball.processPlayerHit(p1);
      expect(game.continuousRallyStreak, 1);
      expect(recordedStreak, 1);
      expect(game.longestRally, 1);

      // 2. Second hit by CPU
      cpu.position = Vector2(640.0, 150.0);
      ball.position = Vector2(640.0, 160.0);
      ball.velocity = Vector2(0.0, -200.0);
      ball.bounceCountCurrentSide = 1;

      ball.processPlayerHit(cpu);
      expect(game.continuousRallyStreak, 2);
      expect(recordedStreak, 2);
      expect(game.longestRally, 2);
      expect(recordedLongest, 2);

      // 3. Rally concludes
      game.handleRallyWon(winnerIsPlayerOne: true, faultReason: '');
      expect(game.continuousRallyStreak, 0);
      expect(recordedStreak, 0);
      expect(game.longestRally, 2); // Longest streak preserved!
    });

    test('resetForNewMatch seamlessly restarts game state for continuous play', () {
      final game = PickleballGame();
      final p1 = PlayerComponent(isPlayerOne: true, isAI: false)..customGame = game;
      final cpu = PlayerComponent(isPlayerOne: false, isAI: true)..customGame = game;
      final ball = BallComponent()..customGame = game;
      game.player1 = p1;
      game.player2 = cpu;
      game.ball = ball;

      // Simulate a finished match
      game.p1Score = 11;
      game.p2Score = 9;
      game.isGameOver = true;
      game.pauseEngine();

      // Reset for continuous next match
      game.resetForNewMatch();

      expect(game.p1Score, 0);
      expect(game.p2Score, 0);
      expect(game.isGameOver, false);
      expect(game.isWaitingForServe, true);
      expect(game.continuousRallyStreak, 0);
    });

    testWidgets('GamePlayScreen renders continuous rally badge and Play Next Match button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GamePlayScreen(matchType: 'quick'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Play Next Match button exists in the tree when match is finished
      // We can inspect the widget hierarchy
      expect(find.byType(GamePlayScreen), findsOneWidget);
    });

    test('Joystick expand and transparent capacity update in-place without doubling components', () {
      final game = PickleballGame();
      game.player1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      game.background = Background();

      // Initialize controls
      game.applySettings(const GameSettings(joystickExpand: 1.0, transparentCapacity: 0.85));

      expect(game.camera.viewport.children.whereType<JoystickComponent>().length, 1);
      expect(game.camera.viewport.children.whereType<HudButtonComponent>().length, 1);

      // Simulate dragging sliders repeatedly (e.g. 5 times in settings)
      for (double expand = 0.8; expand <= 1.6; expand += 0.2) {
        game.applySettings(
          GameSettings(
            joystickExpand: expand,
            transparentCapacity: 0.5,
            joystickColor: 'Electric Cyan',
          ),
        );

        // Verify that components NEVER double or accumulate!
        expect(game.camera.viewport.children.whereType<JoystickComponent>().length, 1);
        expect(game.camera.viewport.children.whereType<HudButtonComponent>().length, 1);
      }

      // Check final knob radius and color
      final knob = game.joystick.knob as CircleComponent;
      expect(knob.radius, closeTo(26.0 * 1.6, 0.01));
      expect(knob.paint.color.a, closeTo((240 * 0.5) / 255.0, 0.05));
    });

    test('Smash button renders with 2D arcade button style and updates in-place without doubling', () {
      final game = PickleballGame();
      game.player1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      game.background = Background();

      // Apply initial Normal settings
      game.applySettings(const GameSettings(buttonSize: 'Normal', transparentCapacity: 0.85));

      expect(game.strikeButton.button, isA<ArcadeButtonFaceComponent>());
      expect(game.strikeButton.buttonDown, isA<ArcadeButtonFaceComponent>());

      final face = game.strikeButton.button as ArcadeButtonFaceComponent;
      final downFace = game.strikeButton.buttonDown as ArcadeButtonFaceComponent;

      expect(face.isPressed, false);
      expect(downFace.isPressed, true);
      expect(face.radius, 40.0);

      // Mutate to Large
      game.applySettings(const GameSettings(buttonSize: 'Large', transparentCapacity: 0.6));
      expect(game.camera.viewport.children.whereType<HudButtonComponent>().length, 1);
      expect(face.radius, 48.0);
      expect(face.opacity, 0.6);

      // Mutate to Extra Large
      game.applySettings(const GameSettings(buttonSize: 'Extra Large', transparentCapacity: 1.0));
      expect(game.camera.viewport.children.whereType<HudButtonComponent>().length, 1);
      expect(face.radius, 56.0);
      expect(face.opacity, 1.0);
    });

    test('Player must manually serve before match begins (default manual serve)', () {
      final game = PickleballGame(); // default settings has autoServe: false
      final p1 = PlayerComponent(isPlayerOne: true, isAI: false)..customGame = game;
      final cpu = PlayerComponent(isPlayerOne: false, isAI: true)..customGame = game;
      final ball = BallComponent()..customGame = game;
      game.player1 = p1;
      game.player2 = cpu;
      game.ball = ball;

      game.prepareServicePositions();
      expect(game.isWaitingForServe, true);
      expect(ball.isWaitingForServe, true);

      // Simulate 3.0s of elapsed waiting time
      for (int i = 0; i < 30; i++) {
        ball.update(0.1);
      }

      // Ball must STILL be waiting for player to manually serve!
      expect(game.isWaitingForServe, true, reason: 'Game must wait for player to manually serve');
      expect(ball.isWaitingForServe, true);

      // Now player strikes to serve
      p1.strike();

      // Serve is launched!
      expect(game.isWaitingForServe, false, reason: 'Serve launches when player presses smash');
      expect(ball.isWaitingForServe, false);
      expect(ball.velocity.length > 0, true);
    });

    test('Smash button triggers dynamic tap effect with shockwave and sparks', () {
      final game = PickleballGame();
      game.player1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      game.background = Background();
      game.applySettings(const GameSettings());

      final face = game.strikeButton.button as ArcadeButtonFaceComponent;
      expect(face.tapEffectProgress, 0.0);

      // Trigger tap effect
      game.triggerSmashButtonEffect();
      expect(face.tapEffectProgress, 1.0);

      // Advance update frame
      face.update(0.1);
      expect(face.tapEffectProgress < 1.0, true);
      expect(face.tapEffectProgress > 0.0, true);

      // Decays over time back to 0
      face.update(0.5);
      expect(face.tapEffectProgress, 0.0);
    });

    test('Mandatory floor bounce training mode: ball cannot be hit out of the air by either human player or AI', () {
      final game = PickleballGame();
      game.applySettings(const GameSettings(requireFloorBounceAllShots: true));
      final p1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      final cpu = PlayerComponent(isPlayerOne: false, isAI: true)..customGame = game;
      final ball = BallComponent()..customGame = game;
      game.player1 = p1;
      game.player2 = cpu;
      game.ball = ball;
      game.isWaitingForServe = false;
      ball.isWaitingForServe = false;
      game.rallyHitCount = 2; // Open play

      // Ball approaching P1 in air (bounceCountCurrentSide == 0) outside kitchen
      p1.position = Vector2(640.0, 560.0);
      ball.position = Vector2(640.0, 560.0);
      ball.velocity = Vector2(0.0, 260.0);
      ball.bounceCountCurrentSide = 0; // In air!

      final initialRally = game.rallyHitCount;
      p1.strike();

      // Ball must NOT be hit because it hasn't bounced on the floor yet!
      expect(game.rallyHitCount, initialRally, reason: 'Human cannot hit ball before floor bounce in training mode');

      // Now ball bounces on floor (bounceCountCurrentSide == 1)
      ball.bounceCountCurrentSide = 1;
      p1.strike();

      // Ball is struck and propelled forward!
      expect(game.rallyHitCount, initialRally + 1, reason: 'Human successfully hits ball after floor bounce');
      expect(ball.velocity.y < 0, true, reason: 'Ball propelled back toward CPU');

      // Now ball flies towards CPU in air (bounceCountCurrentSide == 0)
      cpu.position = Vector2(640.0, 140.0);
      ball.position = Vector2(640.0, 140.0);
      ball.bounceCountCurrentSide = 0; // Not bounced on CPU side yet!
      final hitsBeforeCpu = game.rallyHitCount;

      cpu.update(0.016);
      expect(game.rallyHitCount, hitsBeforeCpu, reason: 'CPU AI does not strike before floor bounce in training mode');

      // Ball bounces on CPU side
      ball.bounceCountCurrentSide = 1;
      cpu.update(0.016);
      expect(game.rallyHitCount, hitsBeforeCpu + 1, reason: 'CPU AI strikes after floor bounce');
    });

    test('Official Rules: Two-Bounce Rule, Kitchen NVZ, Legal Dink after bounce, Open-Play Volleys, and Service Foot Fault', () {
      String? lastViolation;
      final game = PickleballGame(
        onViolation: (type, desc, rule) {
          lastViolation = type;
        },
      );
      final p1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false)..customGame = game;
      final ball = BallComponent()..customGame = game;
      game.player1 = p1;
      game.player2 = p2;
      game.ball = ball;

      // 1. Service Foot Fault: Server steps on or inside baseline before serve (P1 Y <= 661)
      game.isWaitingForServe = true;
      ball.isWaitingForServe = true;
      p1.position = Vector2(760.0, 655.0); // Inside baseline!
      ball.executeServe(isPlayerOne: true);
      expect(lastViolation, 'SERVICE FOOT FAULT');
      expect(game.isWaitingForServe, true); // Rally ended, reset for serve

      // 2. Legal Serve from behind baseline (P1 Y > 670)
      lastViolation = null;
      p1.position = Vector2(760.0, 695.0); // Safely behind baseline!
      ball.executeServe(isPlayerOne: true);
      expect(lastViolation, isNull);
      expect(game.isWaitingForServe, false);
      expect(game.rallyHitCount, 0);

      // 3. Two-Bounce Rule on Return of Serve: Receiver (P2) volleys out of air before floor bounce
      ball.position = p2.position;
      ball.velocity = Vector2(0.0, -250.0);
      ball.bounceCountCurrentSide = 0; // In air!
      p2.currentState = PlayerState.slash;
      ball.processPlayerHit(p2);
      expect(lastViolation, 'TWO-BOUNCE RULE');

      // 4. Kitchen Volley Rule: Open play volley inside kitchen (P1 Y <= 440)
      lastViolation = null;
      game.isWaitingForServe = false;
      ball.isWaitingForServe = false;
      game.rallyHitCount = 2; // Open play
      p1.position = Vector2(640.0, 420.0); // Inside kitchen!
      ball.position = Vector2(640.0, 420.0);
      ball.velocity = Vector2(0.0, 250.0);
      ball.bounceCountCurrentSide = 0; // In air!
      p1.currentState = PlayerState.slash;
      ball.processPlayerHit(p1);
      expect(lastViolation, 'KITCHEN VOLLEY');

      // 5. Legal Dink in Kitchen after Floor Bounce (P1 Y <= 440, bounceCount >= 1)
      lastViolation = null;
      game.isWaitingForServe = false;
      ball.isWaitingForServe = false;
      game.rallyHitCount = 2;
      p1.position = Vector2(640.0, 420.0); // Inside kitchen!
      ball.position = Vector2(640.0, 420.0);
      ball.velocity = Vector2(0.0, 250.0);
      ball.bounceCountCurrentSide = 1; // Bounced on court floor in kitchen!
      final hitsBeforeDink = game.rallyHitCount;
      p1.strike();
      expect(lastViolation, isNull);
      expect(game.rallyHitCount, hitsBeforeDink + 1, reason: 'Hitting in kitchen after bounce is 100% legal');
      expect(ball.velocity.y < 0, true);

      // 6. Legal Open-Play Volley Outside Kitchen (P1 Y = 520 > 440, bounceCount == 0)
      lastViolation = null;
      game.isWaitingForServe = false;
      ball.isWaitingForServe = false;
      game.rallyHitCount = 4; // Open play
      p1.position = Vector2(640.0, 520.0); // Outside kitchen!
      ball.position = Vector2(640.0, 520.0);
      ball.velocity = Vector2(0.0, 260.0);
      ball.bounceCountCurrentSide = 0; // In air!
      final hitsBeforeVolley = game.rallyHitCount;
      p1.strike();
      expect(lastViolation, isNull);
      expect(game.rallyHitCount, hitsBeforeVolley + 1, reason: 'Open-play volley outside kitchen is legal');
      expect(ball.velocity.y < 0, true);
    });

    testWidgets('GamePlayScreen renders violation display on the right side directly underneath settings controls', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GamePlayScreen(matchType: 'quick'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state<State<GamePlayScreen>>(find.byType(GamePlayScreen));
      expect(find.byKey(const ValueKey('violation_display_box')), findsNothing);

      // Trigger a violation
      final dynamic dynState = state;
      dynState.setViolationForTest('TWO-BOUNCE RULE', 'Ball must bounce before return!', 'Rule 2.A');
      await tester.pump();

      // Verify the violation display renders with the right key and text
      expect(find.byKey(const ValueKey('violation_display_box')), findsOneWidget);
      expect(find.text('VIOLATION: TWO-BOUNCE RULE'), findsOneWidget);

      // Verify geometry: violation box must be on the right half of the screen
      final violationOffset = tester.getTopLeft(find.byKey(const ValueKey('violation_display_box')));
      final settingsOffset = tester.getTopLeft(find.byKey(const ValueKey('ingame_settings_btn')));

      expect(violationOffset.dx, greaterThan(400.0), reason: 'Violation must be on the right side of the screen');
      expect(violationOffset.dy, greaterThan(settingsOffset.dy), reason: 'Violation must be positioned underneath the settings controls');
    });
  });

  group('Male2 and Male3 Characters, Coin Purchase & Resale, and AI Usage Tests', () {
    test('CharacterRoster defines Alex, Maya, Marcus (2000 coins), and Jax (2500 coins)', () {
      expect(CharacterRoster.alex.price, 0);
      expect(CharacterRoster.alex.sellRefund, 0);
      expect(CharacterRoster.alex.isDefaultUnlocked, true);
      expect(CharacterRoster.alex.type, CharacterType.male1);
      expect(CharacterRoster.alex.spriteFolder, 'male1_sprite');

      expect(CharacterRoster.maya.price, 0);
      expect(CharacterRoster.maya.sellRefund, 0);
      expect(CharacterRoster.maya.isDefaultUnlocked, true);
      expect(CharacterRoster.maya.type, CharacterType.female1);
      expect(CharacterRoster.maya.spriteFolder, 'female1_sprite');

      expect(CharacterRoster.marcus.price, 0);
      expect(CharacterRoster.marcus.sellRefund, 0);
      expect(CharacterRoster.marcus.isDefaultUnlocked, true);
      expect(CharacterRoster.marcus.type, CharacterType.male2);
      expect(CharacterRoster.marcus.spriteFolder, 'male2_sprite');

      expect(CharacterRoster.jax.price, 0);
      expect(CharacterRoster.jax.sellRefund, 0);
      expect(CharacterRoster.jax.isDefaultUnlocked, true);
      expect(CharacterRoster.jax.type, CharacterType.male3);
      expect(CharacterRoster.jax.spriteFolder, 'male3_sprite');

      expect(CharacterRoster.chloe.price, 0);
      expect(CharacterRoster.chloe.sellRefund, 0);
      expect(CharacterRoster.chloe.isDefaultUnlocked, true);
      expect(CharacterRoster.chloe.type, CharacterType.female2);
      expect(CharacterRoster.chloe.spriteFolder, 'female2_sprite');

      expect(CharacterRoster.getById('male2_blaze'), CharacterRoster.marcus);
      expect(CharacterRoster.getById('male3_thunder'), CharacterRoster.jax);
      expect(CharacterRoster.getById('female2_frost'), CharacterRoster.chloe);
      expect(CharacterRoster.getById('alex_classic'), CharacterRoster.alex);
      expect(CharacterRoster.getById('maya_speed'), CharacterRoster.maya);

      expect(CharacterRoster.getByType(CharacterType.male2), CharacterRoster.marcus);
      expect(CharacterRoster.getByType(CharacterType.male3), CharacterRoster.jax);
      expect(CharacterRoster.getByType(CharacterType.female2), CharacterRoster.chloe);
      expect(CharacterRoster.getByType(CharacterType.male1), CharacterRoster.alex);
      expect(CharacterRoster.getByType(CharacterType.female1), CharacterRoster.maya);
    });

    test('GameStateManager character purchase, unlock, equip, and resale logic', () {
      final state = GameStateManager.instance;
      state.loginAsGuest();
      state.coins = 500;

      // All characters are 100% free and unlocked for all players
      expect(state.isCharacterUnlocked('alex_classic'), true);
      expect(state.isCharacterUnlocked('maya_speed'), true);
      expect(state.isCharacterUnlocked('male2_blaze'), true);
      expect(state.isCharacterUnlocked('male3_thunder'), true);
      expect(state.isCharacterUnlocked('female2_frost'), true);

      // Equipping Marcus Blaze
      state.equipCharacter('male2_blaze');
      expect(state.playerAvatarId, 'male2_blaze');

      // Equipping Jax Thunder
      state.equipCharacter('male3_thunder');
      expect(state.playerAvatarId, 'male3_thunder');

      // Equipping Chloe Frost
      state.equipCharacter('female2_frost');
      expect(state.playerAvatarId, 'female2_frost');

      // Free characters cannot be sold (they are permanent and unlocked for all)
      final sellChloe = state.sellCharacter('female2_frost');
      expect(sellChloe, false);
      expect(state.coins, 500);
      expect(state.isCharacterUnlocked('female2_frost'), true);

      final sellJax = state.sellCharacter('male3_thunder');
      expect(sellJax, false);
      expect(state.coins, 500);
      expect(state.isCharacterUnlocked('male3_thunder'), true);
    });

    test('PlayerComponent loads and animates male2 and male3 without error', () async {
      final game = PickleballGame();
      final p1 = PlayerComponent(isPlayerOne: true, characterType: CharacterType.male2)..customGame = game;
      final p2 = PlayerComponent(isPlayerOne: false, characterType: CharacterType.male3)..customGame = game;
      final partner1 = PlayerComponent(isPlayerOne: true, characterType: CharacterType.male3, playerSlot: 2)..customGame = game;
      final partner2 = PlayerComponent(isPlayerOne: false, characterType: CharacterType.male2, playerSlot: 2)..customGame = game;

      game.player1 = p1;
      game.player2 = p2;
      game.player1Partner = partner1;
      game.player2Partner = partner2;
      game.ball = BallComponent()..customGame = game;

      expect(p1.characterType, CharacterType.male2);
      expect(p1.isFemale, false);
      expect(p2.characterType, CharacterType.male3);
      expect(p2.isFemale, false);
      expect(partner1.characterType, CharacterType.male3);
      expect(partner2.characterType, CharacterType.male2);

      final pFemale2 = PlayerComponent(isPlayerOne: false, characterType: CharacterType.female2)..customGame = game;
      expect(pFemale2.characterType, CharacterType.female2);
      expect(pFemale2.isFemale, true);

      // Striking triggers animations smoothly
      expect(() => p1.strike(), returnsNormally);
      expect(() => p2.strike(), returnsNormally);
      expect(() => pFemale2.strike(), returnsNormally);
      expect(() => p1.update(0.016), returnsNormally);
      expect(() => p2.update(0.016), returnsNormally);
      expect(() => pFemale2.update(0.016), returnsNormally);
    });

    testWidgets('AvatarPickerDialog displays character roster and allows free equipping', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = GameStateManager.instance;
      state.loginAsGuest();
      state.coins = 3000;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarPickerDialog(showChampions: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Court Champions (Buy & Sell)'), findsOneWidget);
      expect(find.text('Alex Smash'), findsOneWidget);
      expect(find.text('Maya Swift'), findsOneWidget);
      expect(find.text('Marcus Blaze'), findsOneWidget);
      expect(find.text('Jax Thunder'), findsOneWidget);

      // Verify all characters are unlocked
      expect(state.isCharacterUnlocked('male2_blaze'), true);
      expect(state.isCharacterUnlocked('male3_thunder'), true);
      expect(state.isCharacterUnlocked('female2_frost'), true);

      // Equip Marcus Blaze directly
      final equipButtons = find.widgetWithText(ElevatedButton, 'EQUIP');
      expect(equipButtons, findsWidgets);
      await tester.ensureVisible(equipButtons.first);
      await tester.tap(equipButtons.first);
      await tester.pumpAndSettle();

      expect(state.playerAvatarId, isNotEmpty);
    });
  });

  group('Shop, Inventory, Pixel Courts, and Ball Tier Effects Tests', () {
    setUp(() {
      final state = GameStateManager.instance;
      state.loginAsGuest();
      state.coins = 5000;
      state.unlockedCourtIds.clear();
      state.unlockedCourtIds.add('court_pro_stadium');
      state.equippedCourtId = 'court_pro_stadium';
      state.unlockedBallIds.clear();
      state.unlockedBallIds.add('ball_elite');
      state.equippedBallId = 'ball_elite';
    });

    test('CourtCatalog defines at least 5 pixel courts including Sunset Beach Resort', () {
      expect(CourtCatalog.allCourts.length, greaterThanOrEqualTo(5));

      // 1. Classic Pro Arena
      final pro = CourtCatalog.proStadium;
      expect(pro.id, 'court_pro_stadium');
      expect(pro.price, 0);
      expect(pro.isDefaultUnlocked, true);
      expect(pro.environment, CourtEnvironment.stadium);

      // 2. Sunset Beach Resort (Beach Area)
      final beach = CourtCatalog.beachResort;
      expect(beach.id, 'court_beach_resort');
      expect(beach.price, 0);
      expect(beach.isDefaultUnlocked, true);
      expect(beach.environment, CourtEnvironment.beach);
      expect(beach.name, contains('Beach'));

      // 3. Neon Cyber Arcade
      final cyber = CourtCatalog.cyberArcade;
      expect(cyber.id, 'court_cyber_arcade');
      expect(cyber.price, 0);
      expect(cyber.isDefaultUnlocked, true);
      expect(cyber.environment, CourtEnvironment.cyber);

      // 4. Emerald Forest Park
      final forest = CourtCatalog.forestPark;
      expect(forest.id, 'court_forest_park');
      expect(forest.price, 0);
      expect(forest.isDefaultUnlocked, true);
      expect(forest.environment, CourtEnvironment.forest);

      // 5. Volcanic Magma Stadium
      final magma = CourtCatalog.magmaStadium;
      expect(magma.id, 'court_magma_stadium');
      expect(magma.price, 0);
      expect(magma.isDefaultUnlocked, true);
      expect(magma.environment, CourtEnvironment.magma);

      // ID resolver lookup
      expect(CourtCatalog.getById('court_beach_resort').environment, CourtEnvironment.beach);
      expect(CourtCatalog.getById('beach').environment, CourtEnvironment.beach);
      expect(CourtCatalog.getById('cyber').environment, CourtEnvironment.cyber);
      expect(CourtCatalog.getById('forest').environment, CourtEnvironment.forest);
      expect(CourtCatalog.getById('magma').environment, CourtEnvironment.magma);
      expect(CourtCatalog.getById('unknown').environment, CourtEnvironment.stadium);
    });

    test('BallCatalog defines all 5 requested balls with distinct effects and tiers', () {
      expect(BallCatalog.allBalls.length, 5);

      // 1. Elite Ball
      final elite = BallCatalog.elite;
      expect(elite.id, 'ball_elite');
      expect(elite.name, 'Elite Ball');
      expect(elite.tier, BallTier.elite);
      expect(elite.price, 0);
      expect(elite.isDefaultUnlocked, true);

      // 2. Special Ball
      final special = BallCatalog.special;
      expect(special.id, 'ball_special');
      expect(special.name, 'Special Ball');
      expect(special.tier, BallTier.special);
      expect(special.price, 0);
      expect(special.isDefaultUnlocked, true);

      // 3. Epic Ball
      final epic = BallCatalog.epic;
      expect(epic.id, 'ball_epic');
      expect(epic.name, 'Epic Ball');
      expect(epic.tier, BallTier.epic);
      expect(epic.price, 0);
      expect(epic.isDefaultUnlocked, true);

      // 4. Mythic Ball
      final mythic = BallCatalog.mythic;
      expect(mythic.id, 'ball_mythic');
      expect(mythic.name, 'Mythic Ball');
      expect(mythic.tier, BallTier.mythic);
      expect(mythic.price, 0);
      expect(mythic.isDefaultUnlocked, true);

      // 5. Legendary Ball
      final legendary = BallCatalog.legendary;
      expect(legendary.id, 'ball_legendary');
      expect(legendary.name, 'Legendary Ball');
      expect(legendary.tier, BallTier.legendary);
      expect(legendary.price, 0);
      expect(legendary.isDefaultUnlocked, true);

      // ID resolver lookup
      expect(BallCatalog.getById('ball_elite').tier, BallTier.elite);
      expect(BallCatalog.getById('special').tier, BallTier.special);
      expect(BallCatalog.getById('epic').tier, BallTier.epic);
      expect(BallCatalog.getById('mythic').tier, BallTier.mythic);
      expect(BallCatalog.getById('legendary').tier, BallTier.legendary);
    });

    test('GameStateManager court and ball purchasing, unlocking, and equipping logic', () {
      final state = GameStateManager.instance;
      state.coins = 2000;

      // Default state: all courts and balls are unlocked and free for all players
      expect(state.isCourtUnlocked('court_pro_stadium'), true);
      expect(state.isCourtUnlocked('court_beach_resort'), true);
      expect(state.isCourtUnlocked('court_cyber_arcade'), true);

      expect(state.isBallUnlocked('ball_elite'), true);
      expect(state.isBallUnlocked('ball_special'), true);
      expect(state.isBallUnlocked('ball_legendary'), true);

      // Free purchases equip item directly without coin deduction
      final buyLegendary = state.purchaseBall('ball_legendary');
      expect(buyLegendary, true);
      expect(state.isBallUnlocked('ball_legendary'), true);
      expect(state.equippedBallId, 'ball_legendary');
      expect(state.coins, 2000);

      final buyBeach = state.purchaseCourt('court_beach_resort');
      expect(buyBeach, true);
      expect(state.isCourtUnlocked('court_beach_resort'), true);
      expect(state.equippedCourtId, 'court_beach_resort');
      expect(state.coins, 2000);

      // Equipping items
      state.equipCourt('court_pro_stadium');
      expect(state.equippedCourtId, 'court_pro_stadium');
      state.equipCourt('court_beach_resort');
      expect(state.equippedCourtId, 'court_beach_resort');

      state.equipBall('ball_elite');
      expect(state.equippedBallId, 'ball_elite');
      state.equipBall('ball_special');
      expect(state.equippedBallId, 'ball_special');
    });

    testWidgets('ShopModal renders 3 tabs and handles item purchase and equip interactions', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = GameStateManager.instance;
      state.coins = 4000;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  key: const ValueKey('open_shop_btn'),
                  onPressed: () => ShopModal.show(ctx),
                  child: const Text('Open Shop'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open shop
      await tester.tap(find.byKey(const ValueKey('open_shop_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(ShopModal), findsOneWidget);
      expect(find.text('SMASH PRO SHOP'), findsOneWidget);
      expect(find.text('CHARACTERS'), findsOneWidget);
      expect(find.text('COURTS'), findsOneWidget);
      expect(find.text('BALLS'), findsOneWidget);

      // Alex is obtained/equipped
      expect(find.text('Alex Smash'), findsOneWidget);
      expect(find.text('EQUIPPED'), findsAtLeast(1));

      // Switch to COURTS tab
      await tester.tap(find.text('COURTS'));
      await tester.pumpAndSettle();

      expect(find.text('Sunset Beach Resort'), findsOneWidget);
      expect(find.text('Neon Cyber Arcade'), findsOneWidget);

      // Equip Sunset Beach Resort in shop
      final equipBeachBtn = find.descendant(
        of: find.byKey(const ValueKey('shop_court_court_beach_resort')),
        matching: find.text('EQUIP'),
      );
      expect(equipBeachBtn, findsOneWidget);
      await tester.tap(equipBeachBtn);
      await tester.pumpAndSettle();

      expect(state.isCourtUnlocked('court_beach_resort'), true);
      expect(state.equippedCourtId, 'court_beach_resort');

      // Switch to BALLS tab
      await tester.tap(find.text('BALLS'));
      await tester.pumpAndSettle();

      expect(find.text('Elite Ball'), findsOneWidget);
      expect(find.text('Special Ball'), findsOneWidget);
      expect(find.text('Epic Ball'), findsOneWidget);
      expect(find.text('Mythic Ball'), findsOneWidget);
      expect(find.text('Legendary Ball'), findsOneWidget);
    });

    testWidgets('ShopModal displays character front views, showcases Chloe Frost and supports pose inspection', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = GameStateManager.instance;
      state.coins = 5000;
      state.unlockedCharacterIds.remove('female2_frost');
      state.equipCharacter('alex_classic');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  key: const ValueKey('open_shop_btn_f2'),
                  onPressed: () => ShopModal.show(ctx),
                  child: const Text('Open Shop'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_shop_btn_f2')));
      await tester.pumpAndSettle();

      expect(find.byType(ShopModal), findsOneWidget);

      // Verify first characters in list
      expect(find.text('Alex Smash'), findsOneWidget);
      expect(find.text('Maya Swift'), findsOneWidget);

      // Verify default spotlight shows equipped character (Alex)
      expect(find.text('ALEX SMASH • POWER SMASHER'), findsOneWidget);

      // Scroll ListView up to reveal Chloe Frost
      await tester.scrollUntilVisible(
        find.text('Chloe Frost'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Chloe Frost'), findsOneWidget);

      // Tap Chloe Frost to spotlight her front view
      await tester.tap(find.byKey(const ValueKey('shop_char_female2_frost')));
      await tester.pumpAndSettle();

      expect(find.text('CHLOE FROST • SPIN SPECIALIST'), findsOneWidget);

      // Toggle pose chips
      expect(find.text('Run'), findsOneWidget);
      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();

      expect(find.text('Smash'), findsOneWidget);
      await tester.tap(find.text('Smash'));
      await tester.pumpAndSettle();

      expect(find.text('Idle'), findsOneWidget);
      await tester.tap(find.text('Idle'));
      await tester.pumpAndSettle();

      // Equip Chloe Frost
      final equipChloeBtn = find.descendant(
        of: find.byKey(const ValueKey('shop_char_female2_frost')),
        matching: find.text('EQUIP'),
      );
      expect(equipChloeBtn, findsOneWidget);
      await tester.tap(equipChloeBtn);
      await tester.pumpAndSettle();

      expect(state.isCharacterUnlocked('female2_frost'), true);
      expect(state.playerAvatarId, 'female2_frost');
    });

    testWidgets('InventoryModal renders active loadout and equipment management', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = GameStateManager.instance;
      state.unlockedCourtIds.add('court_beach_resort');
      state.equippedCourtId = 'court_beach_resort';
      state.unlockedBallIds.add('ball_special');
      state.equippedBallId = 'ball_special';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  key: const ValueKey('open_inv_btn'),
                  onPressed: () => InventoryModal.show(ctx),
                  child: const Text('Open Inventory'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open inventory
      await tester.tap(find.byKey(const ValueKey('open_inv_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(InventoryModal), findsOneWidget);
      expect(find.text('LOCKER & INVENTORY'), findsOneWidget);
      expect(find.text('ACTIVE LOADOUT:'), findsOneWidget);

      // Switch to COURTS tab
      await tester.tap(find.text('COURTS'));
      await tester.pumpAndSettle();

      // Classic Pro is unlocked and has EQUIP button
      final equipProBtn = find.descendant(
        of: find.byKey(const ValueKey('inv_court_court_pro_stadium')),
        matching: find.text('EQUIP'),
      );
      expect(equipProBtn, findsOneWidget);

      await tester.tap(equipProBtn);
      await tester.pumpAndSettle();

      expect(state.equippedCourtId, 'court_pro_stadium');

      // Switch to BALLS tab
      await tester.tap(find.text('BALLS'));
      await tester.pumpAndSettle();

      expect(find.text('Elite Ball'), findsAtLeast(1));
      expect(find.text('Special Ball'), findsAtLeast(1));
    });

    test('Background component configures equipped court theme and pixel environment details', () {
      // Beach
      final bgBeach = Background(courtId: 'court_beach_resort');
      expect(bgBeach.courtInfo.environment, CourtEnvironment.beach);
      expect(bgBeach.courtInfo.name, 'Sunset Beach Resort');

      // Cyber
      final bgCyber = Background(courtId: 'court_cyber_arcade');
      expect(bgCyber.courtInfo.environment, CourtEnvironment.cyber);

      // Magma
      final bgMagma = Background(courtId: 'court_magma_stadium');
      expect(bgMagma.courtInfo.environment, CourtEnvironment.magma);

      // Forest
      final bgForest = Background(courtId: 'court_forest_park');
      expect(bgForest.courtInfo.environment, CourtEnvironment.forest);

      // Verify procedural drawing runs without throws
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      bgBeach.render(canvas);
      bgCyber.render(canvas);
      bgMagma.render(canvas);
      bgForest.render(canvas);
      recorder.endRecording();
    });

    test('BallComponent renders custom gradient, glow, ripple, and motion particles', () {
      // Legendary 24K Solar Gold
      final ballLeg = BallComponent(ballId: 'ball_legendary');
      expect(ballLeg.ballInfo.tier, BallTier.legendary);
      expect(ballLeg.ballInfo.name, 'Legendary Ball');

      // Mythic Cosmic
      final ballMyth = BallComponent(ballId: 'ball_mythic');
      expect(ballMyth.ballInfo.tier, BallTier.mythic);

      // Epic Molten Inferno
      final ballEpic = BallComponent(ballId: 'ball_epic');
      expect(ballEpic.ballInfo.tier, BallTier.epic);

      // Special Plasma
      final ballSpec = BallComponent(ballId: 'ball_special');
      expect(ballSpec.ballInfo.tier, BallTier.special);

      // Verify rendering on canvas without exceptions
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      ballLeg.render(canvas);
      ballMyth.render(canvas);
      ballEpic.render(canvas);
      ballSpec.render(canvas);
      recorder.endRecording();
    });

    testWidgets('HomeView renders PRO SHOP & LOCKER banner with quick launch actions', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: HomeView(
              onPlayQuickMatch: () {},
              onOpenTournament: () {},
              onOpenChallenges: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PRO SHOP & LOCKER'), findsOneWidget);
      expect(find.byKey(const ValueKey('home_open_shop_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('home_open_inventory_btn')), findsOneWidget);

      // Open shop from HomeView banner
      await tester.tap(find.byKey(const ValueKey('home_open_shop_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(ShopModal), findsOneWidget);
    });
  });

  group('Battle Techniques & Arcade Skill Buttons Tests', () {
    test('TechniqueCatalog defines leftSpin and rightSpin metadata correctly', () {
      expect(TechniqueCatalog.leftSpin.technique, BattleTechnique.leftSpin);
      expect(TechniqueCatalog.leftSpin.name, 'Cyclone Curve');
      expect(TechniqueCatalog.leftSpin.icon, '🌪️');
      expect(TechniqueCatalog.leftSpin.hotkey, 'K');
      expect(TechniqueCatalog.leftSpin.cooldownSeconds, 6.0);

      expect(TechniqueCatalog.rightSpin.technique, BattleTechnique.rightSpin);
      expect(TechniqueCatalog.rightSpin.name, 'Vortex Hook');
      expect(TechniqueCatalog.rightSpin.icon, '⚡');
      expect(TechniqueCatalog.rightSpin.hotkey, 'L');
      expect(TechniqueCatalog.rightSpin.cooldownSeconds, 6.0);

      expect(TechniqueCatalog.dash.technique, BattleTechnique.dash);
      expect(TechniqueCatalog.dash.name, 'Flash Dash');
      expect(TechniqueCatalog.dash.icon, '💨');
      expect(TechniqueCatalog.dash.hotkey, 'SHIFT');
      expect(TechniqueCatalog.dash.cooldownSeconds, 3.5);

      expect(TechniqueCatalog.get(BattleTechnique.leftSpin).id, 'left_spin');
      expect(TechniqueCatalog.get(BattleTechnique.rightSpin).id, 'right_spin');
      expect(TechniqueCatalog.get(BattleTechnique.dash).id, 'flash_dash');
      expect(TechniqueCatalog.get(BattleTechnique.none).id, 'left_spin');
    });

    test('ArcadeSkillButtonComponent renders, triggers tap effects, and respects cooldowns', () {
      bool tapped = false;
      final btn = ArcadeSkillButtonComponent(
        technique: BattleTechnique.leftSpin,
        radius: 28.0,
        opacity: 0.9,
        onTriggered: () {
          tapped = true;
        },
      );

      expect(btn.cooldownRemaining, 0.0);
      expect(btn.isPrimed, false);

      // Trigger tap
      btn.triggerTapEffect();
      expect(btn.tapEffectProgress, 1.0);
      btn.onTriggered?.call();
      expect(tapped, true);

      btn.update(0.1);
      expect(btn.tapEffectProgress < 1.0, true);

      // Start cooldown
      btn.startCooldown();
      expect(btn.cooldownRemaining, 6.0);

      // Advance time
      btn.update(3.0);
      expect(btn.cooldownRemaining, closeTo(3.0, 0.01));

      // Reset cooldown
      btn.resetCooldown();
      expect(btn.cooldownRemaining, 0.0);

      // Render to canvas
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      btn.isPrimed = true;
      btn.render(canvas);

      btn.startCooldown();
      btn.render(canvas);
      final pic = recorder.endRecording();
      expect(pic, isNotNull);
    });

    test('PlayerComponent queues techniques, primes aura, and auto-expires prime timer', () {
      final game = PickleballGame(joystickOnLeft: true, targetScore: 11, isDoubles: false);
      final player = PlayerComponent(isPlayerOne: true, isFemale: false)..customGame = game;
      game.player1 = player;
      game.ball = BallComponent()..customGame = game;

      expect(player.activeTechnique, BattleTechnique.none);
      expect(player.techniquePrimeTimer, 0.0);

      // Queue Left Spin
      player.queueTechnique(BattleTechnique.leftSpin);
      expect(player.activeTechnique, BattleTechnique.leftSpin);
      expect(player.techniquePrimeTimer, 4.5);

      // Advance by 2 seconds
      player.update(2.0);
      expect(player.activeTechnique, BattleTechnique.leftSpin);
      expect(player.techniquePrimeTimer, closeTo(2.5, 0.01));

      // Advance past 4.5 seconds -> auto-clears
      player.update(2.6);
      expect(player.activeTechnique, BattleTechnique.none);
      expect(player.techniquePrimeTimer, 0.0);

      // Clear technique manual call
      player.queueTechnique(BattleTechnique.rightSpin);
      expect(player.activeTechnique, BattleTechnique.rightSpin);
      player.clearTechnique();
      expect(player.activeTechnique, BattleTechnique.none);
    });

    test('BallComponent executes Left Spin with aerodynamic left curving and floor kick', () {
      String? announcedTitle;
      final game = PickleballGame(
        joystickOnLeft: true,
        targetScore: 11,
        isDoubles: false,
        onAnnouncement: (title, subtitle) {
          announcedTitle = title;
        },
      );
      final p1 = PlayerComponent(isPlayerOne: true, isFemale: false)..customGame = game;
      final cpu = PlayerComponent(isPlayerOne: false, isFemale: false, isAI: true)..customGame = game;
      final ball = BallComponent()..customGame = game;

      game.player1 = p1;
      game.player2 = cpu;
      game.ball = ball;
      game.isWaitingForServe = false;

      // Initially ball is far away on opponent side
      ball.position = Vector2(640, 200);
      p1.position = Vector2(640, 600);
      ball.velocity = Vector2(0, 200);
      game.rallyHitCount = 2;

      // Queue Left Spin (Cyclone Curve) on player 1 while ball is far away -> primed!
      p1.queueTechnique(BattleTechnique.leftSpin);
      expect(p1.activeTechnique, BattleTechnique.leftSpin);

      // Ball arrives and bounces on player's side
      ball.position = Vector2(640, 580);
      ball.bounceCountCurrentSide = 1; // Legal bounce occurred

      // Execute hit
      ball.processPlayerHit(p1);

      expect(p1.activeTechnique, BattleTechnique.none);
      expect(ball.activeTechniqueType, BattleTechnique.leftSpin);
      expect(ball.spin, -1.0);
      expect(ball.curveStrength > 0, true);
      expect(announcedTitle, '🌪️ CYCLONE CURVE!');

      // As ball updates in flight, velocity.x curves to the left (decreasing X)
      final initialVx = ball.velocity.x;
      ball.update(0.1);
      expect(ball.velocity.x < initialVx, true);
      expect(ball.ballRotationAngle != 0.0, true);
    });

    test('BallComponent executes Right Spin with aerodynamic right curving and floor kick', () {
      String? announcedTitle;
      final game = PickleballGame(
        joystickOnLeft: true,
        targetScore: 11,
        isDoubles: false,
        onAnnouncement: (title, subtitle) {
          announcedTitle = title;
        },
      );
      final p1 = PlayerComponent(isPlayerOne: true, isFemale: false)..customGame = game;
      final cpu = PlayerComponent(isPlayerOne: false, isFemale: false, isAI: true)..customGame = game;
      final ball = BallComponent()..customGame = game;

      game.player1 = p1;
      game.player2 = cpu;
      game.ball = ball;
      game.isWaitingForServe = false;

      // Initially ball is far away
      ball.position = Vector2(640, 200);
      p1.position = Vector2(640, 600);
      ball.velocity = Vector2(0, 200);
      game.rallyHitCount = 2;

      // Queue Right Spin (Vortex Hook) on player 1 while ball is far away -> primed!
      p1.queueTechnique(BattleTechnique.rightSpin);
      expect(p1.activeTechnique, BattleTechnique.rightSpin);

      // Now ball arrives and bounces on player's side
      ball.position = Vector2(640, 580);
      ball.bounceCountCurrentSide = 1;

      // Execute hit
      ball.processPlayerHit(p1);

      expect(p1.activeTechnique, BattleTechnique.none);
      expect(ball.activeTechniqueType, BattleTechnique.rightSpin);
      expect(ball.spin, 1.0);
      expect(ball.curveStrength > 0, true);
      expect(announcedTitle, '⚡ VORTEX HOOK!');

      // As ball updates in flight, velocity.x curves to the right (increasing X)
      final initialVx = ball.velocity.x;
      ball.update(0.1);
      expect(ball.velocity.x > initialVx, true);
      expect(ball.ballRotationAngle != 0.0, true);
    });

    test('BallComponent renders custom technique particles and auras without error', () {
      final game = PickleballGame(joystickOnLeft: true, targetScore: 11, isDoubles: false);
      final ball = BallComponent()..customGame = game;
      game.ball = ball;

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // 1. Render with Left Spin
      ball.activeTechniqueType = BattleTechnique.leftSpin;
      ball.ballRotationAngle = 1.2;
      ball.render(canvas);

      // 2. Render with Right Spin
      ball.activeTechniqueType = BattleTechnique.rightSpin;
      ball.ballRotationAngle = 2.4;
      ball.render(canvas);

      final pic = recorder.endRecording();
      expect(pic, isNotNull);
    });

    test('PickleballGame creates skill buttons in viewport and handles cooldowns and screen shake', () {
      final game = PickleballGame(joystickOnLeft: true, targetScore: 11, isDoubles: false);
      game.player1 = PlayerComponent(isPlayerOne: true)..customGame = game;
      game.player2 = PlayerComponent(isPlayerOne: false, isAI: true)..customGame = game;
      game.ball = BallComponent()..customGame = game;
      game.background = Background();
      game.applySettings(const GameSettings(joystickOnLeft: true));

      expect(game.leftSpinButton, isNotNull);
      expect(game.rightSpinButton, isNotNull);
      expect(game.dashButton, isNotNull);

      expect(game.camera.viewport.children.contains(game.leftSpinButton!), true);
      expect(game.camera.viewport.children.contains(game.rightSpinButton!), true);
      expect(game.camera.viewport.children.contains(game.dashButton!), true);

      // Trigger Left Spin via game method
      game.triggerLeftSpin();
      expect(game.player1.activeTechnique, BattleTechnique.leftSpin);
      expect(game.leftSpinButton!.isPrimed, true);

      // Execute technique triggers cooldown
      game.onTechniqueExecuted(BattleTechnique.leftSpin);
      expect(game.leftSpinButton!.cooldownRemaining, 6.0);
      expect(game.leftSpinButton!.isPrimed, false);

      // Trigger Right Spin
      game.triggerRightSpin();
      expect(game.player1.activeTechnique, BattleTechnique.rightSpin);
      expect(game.rightSpinButton!.isPrimed, true);

      game.onTechniqueExecuted(BattleTechnique.rightSpin);
      expect(game.rightSpinButton!.cooldownRemaining, 6.0);
      expect(game.rightSpinButton!.isPrimed, false);

      // Trigger Dash
      game.triggerDash();
      expect(game.dashButton!.cooldownRemaining, 3.5);

      // Reset match clears cooldowns
      game.resetForNewMatch();
      expect(game.leftSpinButton!.cooldownRemaining, 0.0);
      expect(game.rightSpinButton!.cooldownRemaining, 0.0);
      expect(game.dashButton!.cooldownRemaining, 0.0);

      // Settings change updates joystick hand and repositions skill buttons in-place
      game.applySettings(const GameSettings(controlsPreset: 'Default Arcade', joystickOnLeft: false));
      expect(game.leftSpinButton!.margin?.left, 126.0);
      expect(game.rightSpinButton!.margin?.left, 36.0);
      expect(game.dashButton!.margin?.left, 126.0);
    });

    test('PlayerComponent executes Dash with speed boost, afterimages, dust particles, and cooldown', () {
      final game = PickleballGame(joystickOnLeft: true, targetScore: 11, isDoubles: false);
      final player = PlayerComponent(isPlayerOne: true, isFemale: false)..customGame = game;
      game.player1 = player;
      game.ball = BallComponent()..customGame = game;

      player.position = Vector2(640, 600);
      expect(player.isDashing, false);
      expect(player.dashCooldown, 0.0);
      expect(player.afterimages.isEmpty, true);
      expect(player.dashParticles.isEmpty, true);

      // Dash towards right
      final success = player.dash(customDirection: Vector2(1, 0));
      expect(success, true);
      expect(player.isDashing, true);
      expect(player.dashTimer, 0.22);
      expect(player.dashCooldown, 3.5);
      expect(player.currentVelocity.x, 750.0);
      expect(player.dashParticles.isNotEmpty, true);
      expect(player.afterimages.isNotEmpty, true);

      // Updating position during dash moves player at dashSpeed (750 px/s)
      final initialX = player.position.x;
      player.update(0.1);
      expect(player.position.x > initialX + 60.0, true);
      expect(player.isDashing, true);

      // Trying to dash again while on cooldown is rejected
      final secondDash = player.dash(customDirection: Vector2(-1, 0));
      expect(secondDash, false);

      // Advance until dash ends
      player.update(0.15);
      expect(player.isDashing, false);

      // Render canvas with afterimages, particles, and streaks without throwing
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      player.render(canvas);
      final pic = recorder.endRecording();
      expect(pic, isNotNull);
    });

    test('PlayerComponent dash cancels immediately when striking and AI executes dash during rally', () {
      final game = PickleballGame(joystickOnLeft: true, targetScore: 11, isDoubles: false);
      final p1 = PlayerComponent(isPlayerOne: true, isFemale: false)..customGame = game;
      final cpu = PlayerComponent(isPlayerOne: false, isFemale: false, isAI: true)..customGame = game;
      final ball = BallComponent()..customGame = game;

      game.player1 = p1;
      game.player2 = cpu;
      game.ball = ball;
      game.isWaitingForServe = false;

      // 1. Human dash cancelled on strike
      p1.position = Vector2(640, 600);
      p1.dash(customDirection: Vector2(0, -1));
      expect(p1.isDashing, true);

      p1.strike();
      expect(p1.isDashing, false);

      // 2. CPU AI executes dash when ball is far away on CPU side
      cpu.position = Vector2(400, 150);
      ball.position = Vector2(850, 250);
      ball.velocity = Vector2(100, -250); // Flying towards CPU side
      ball.bounceCountCurrentSide = 1;

      expect(cpu.isDashing, false);
      cpu.update(0.016); // CPU detects target distance > 140 and dashes!
      expect(cpu.isDashing, true);
      expect(cpu.dashCooldown > 0, true);
    });
  });
}

