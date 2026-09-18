import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_smash/main.dart';
import 'package:pickleball_smash/models/game_settings.dart';
import 'package:pickleball_smash/models/player_avatar.dart';
import 'package:pickleball_smash/screens/auth/login_screen.dart';
import 'package:pickleball_smash/screens/auth/register_screen.dart';
import 'package:pickleball_smash/screens/dashboard_screen.dart';
import 'package:pickleball_smash/screens/game_play_screen.dart';
import 'package:pickleball_smash/screens/views/in_game_settings_modal.dart';
import 'package:pickleball_smash/screens/views/settings_view.dart';
import 'package:pickleball_smash/services/database_service.dart';
import 'package:pickleball_smash/services/game_state_manager.dart';
import 'package:pickleball_smash/theme/app_theme.dart';
import 'package:pickleball_smash/widgets/animated_character_display.dart';
import 'package:pickleball_smash/widgets/avatar_picker_dialog.dart';
import 'package:pickleball_smash/widgets/game_2d_text.dart';
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
        for (int i = 0; i < 50; i++) {
          if (!GameStateManager.instance.isGuest) break;
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });

      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

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
      expect(find.text('Pickleball Smash'), findsOneWidget);
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
      expect(historyBtn, findsOneWidget);

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

      expect(find.text('Official Pickleball Smash Rankings. Sorted by Trophies and Match Victories.'), findsOneWidget);
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
        joystickSensitivity: 1.4,
        joystickDeadzone: 0.15,
        buttonSize: 'Large',
        controllerOpacity: 0.7,
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
      expect(reconstructed.joystickSensitivity, 1.4);
      expect(reconstructed.buttonSize, 'Large');
      expect(reconstructed.graphicsQuality, 'Ultra');
      expect(reconstructed.targetFps, 120);
      expect(reconstructed.screenShakeEnabled, false);
      expect(reconstructed.showFps, true);
      expect(reconstructed.courtTheme, 'Electric Blue');
      expect(reconstructed.courtBrightness, 1.2);

      final copy = original.copyWith(
        graphicsQuality: 'Low',
        masterVolume: 0.2,
        controlScheme: 'drag',
      );
      expect(copy.graphicsQuality, 'Low');
      expect(copy.masterVolume, 0.2);
      expect(copy.controlScheme, 'drag');
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

      // Tap Right-Handed to test live settings update
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
      final leaderboard = await db.getAllPlayersLeaderboard();
      expect(leaderboard.isNotEmpty, true);
      final me = leaderboard.firstWhere((p) => p['user_id'] == userId);
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
      state.updatePlayerAvatar('C:/photos/alpha_gallery_pic.png');
      expect(state.playerAvatarId, 'C:/photos/alpha_gallery_pic.png');

      // 4. Login as Player Beta, set different custom gallery/file photo, and save
      await state.loginWithUser(userBetaId, userBetaName);
      state.updatePlayerAvatar('/storage/emulated/0/DCIM/beta_camera.jpg');
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
      final leaderboard = await db.getAllPlayersLeaderboard(limit: 500);
      final alphaInBoard = leaderboard.firstWhere((p) => p['user_id'] == userAlphaId);
      final betaInBoard = leaderboard.firstWhere((p) => p['user_id'] == userBetaId);
      expect(alphaInBoard['avatar_id'], 'C:/photos/alpha_gallery_pic.png');
      expect(betaInBoard['avatar_id'], '/storage/emulated/0/DCIM/beta_camera.jpg');

      state.loginAsGuest();
    });

    testWidgets('AvatarPickerDialog allows picking champions, saving custom photo URLs, and creating studio avatars', (WidgetTester tester) async {
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
      expect(find.text('CHAMPIONS'), findsOneWidget);
      expect(find.text('PHOTO / GALLERY'), findsOneWidget);
      expect(find.text('AVATAR STUDIO'), findsOneWidget);

      // Tap Maya Swift champion
      expect(find.text('Maya Swift'), findsOneWidget);
      await tester.tap(find.text('Maya Swift'));
      await tester.pumpAndSettle();
      expect(state.playerAvatarId, 'maya_speed');

      // Switch to PHOTO / GALLERY tab
      await tester.tap(find.text('PHOTO / GALLERY'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Add Your Own Custom Profile Picture'), findsOneWidget);
      expect(find.byKey(const ValueKey('picker_gallery_btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('picker_files_btn')), findsOneWidget);
      expect(find.text('CHOOSE FROM GALLERY'), findsOneWidget);
      expect(find.text('BROWSE FILES'), findsOneWidget);
      expect(find.text('SAVE THIS PROFILE PICTURE'), findsOneWidget);

      // Enter custom photo URL or file path
      final urlField = find.byType(TextField).first;
      await tester.enterText(urlField, 'https://mysite.com/my_pickleball_pic.jpg');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('save_custom_photo_btn')));
      await tester.tap(find.byKey(const ValueKey('save_custom_photo_btn')));
      await tester.pumpAndSettle();
      expect(state.playerAvatarId, 'https://mysite.com/my_pickleball_pic.jpg');

      // Switch to AVATAR STUDIO tab
      await tester.tap(find.text('AVATAR STUDIO'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Design Your Unique Avatar'), findsOneWidget);
      expect(find.text('SAVE CUSTOM AVATAR'), findsOneWidget);

      // Enter initials
      final initialsField = find.byType(TextField).first;
      await tester.enterText(initialsField, 'ACE');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('SAVE CUSTOM AVATAR'));
      await tester.tap(find.text('SAVE CUSTOM AVATAR'));
      await tester.pumpAndSettle();
      expect(state.playerAvatarId.startsWith('custom:ACE:'), true);
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
      expect(find.text('Pickleball Smash'), findsOneWidget);
    });
  });
}
