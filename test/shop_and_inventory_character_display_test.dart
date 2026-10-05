import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_smash/models/character_roster.dart';
import 'package:pickleball_smash/widgets/animated_character_display.dart';
import 'package:pickleball_smash/widgets/dashboard_character_card_feature.dart';
import 'package:pickleball_smash/widgets/inventory_modal.dart';
import 'package:pickleball_smash/widgets/shop_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shop and Inventory Character Feature Tests (All Characters)', () {
    test('All 8 characters have valid roster configurations and gender mappings', () {
      final characters = CharacterRoster.allCharacters;
      expect(characters.length, equals(8));

      final expectedIds = [
        'alex_classic',
        'maya_speed',
        'male2_blaze',
        'male3_thunder',
        'female2_frost',
        'female3',
        'male4_nard',
        'female4_ashley',
      ];

      for (final id in expectedIds) {
        final char = CharacterRoster.getById(id);
        expect(char.id, equals(id));
        expect(char.name.isNotEmpty, isTrue);
        expect(char.badge.isNotEmpty, isTrue);

        final gender = AnimatedCharacterDisplay.genderFromType(char.type);
        expect(gender, isNotNull);

        final mappedType = AnimatedCharacterDisplay.typeFromGender(gender);
        expect(mappedType, equals(char.type));
      }
    });

    testWidgets('DashboardCharacterCardFeature renders top badge, spotlight, and animated display for Alex Smash', (tester) async {
      final char = CharacterRoster.alex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardCharacterCardFeature(
              character: char,
              showBadge: true,
              showSpotlight: true,
              showCharacterSwitcher: true,
              showActionControls: true,
            ),
          ),
        ),
      );

      // Verify top badge has name, title, and badge icon
      expect(find.text(char.badge), findsOneWidget);
      expect(find.text('${char.name.toUpperCase()} • ${char.title.toUpperCase()}'), findsOneWidget);

      // Verify AnimatedCharacterDisplay is rendered
      expect(find.byType(AnimatedCharacterDisplay), findsOneWidget);
    });

    testWidgets('DashboardCharacterCardFeature renders for all 6 characters', (tester) async {
      for (final char in CharacterRoster.allCharacters) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DashboardCharacterCardFeature(
                character: char,
                showBadge: true,
                showSpotlight: true,
                showCharacterSwitcher: true,
                showActionControls: true,
              ),
            ),
          ),
        );

        expect(find.text(char.badge), findsOneWidget);
        expect(find.text('${char.name.toUpperCase()} • ${char.title.toUpperCase()}'), findsOneWidget);
        expect(find.byType(AnimatedCharacterDisplay), findsOneWidget);
      }
    });

    testWidgets('ShopModal renders featured character showcase and all 6 character cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShopModal(initialTabIndex: 0),
          ),
        ),
      );

      await tester.pump();

      // Top title and featured banner
      expect(find.text('SMASH PRO SHOP'), findsOneWidget);
      expect(find.text('FEATURED FIGHTER'), findsOneWidget);
      expect(find.byType(DashboardCharacterCardFeature), findsOneWidget);

      // All 6 character item keys exist in the roster list and can be scrolled into view
      for (final char in CharacterRoster.allCharacters) {
        final itemFinder = find.byKey(ValueKey('shop_char_${char.id}'));
        await tester.scrollUntilVisible(
          itemFinder,
          150.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(itemFinder, findsOneWidget);
      }
    });

    testWidgets('InventoryModal renders locker character showcase and all 6 roster cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InventoryModal(initialTabIndex: 0),
          ),
        ),
      );

      await tester.pump();

      // Locker spotlight and character feature
      expect(find.text('LOCKER & INVENTORY'), findsOneWidget);
      expect(find.byType(DashboardCharacterCardFeature), findsOneWidget);

      // All 6 character cards in inventory can be scrolled into view
      for (final char in CharacterRoster.allCharacters) {
        final itemFinder = find.byKey(ValueKey('inv_char_${char.id}'));
        await tester.scrollUntilVisible(
          itemFinder,
          150.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(itemFinder, findsOneWidget);
      }
    });
  });
}
