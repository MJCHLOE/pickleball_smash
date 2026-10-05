import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_smash/game/components/player.dart';
import 'package:pickleball_smash/models/character_roster.dart';
import 'package:pickleball_smash/models/player_avatar.dart';
import 'package:pickleball_smash/services/game_state_manager.dart';
import 'package:pickleball_smash/widgets/animated_character_display.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Nard (Male 4) & Ashley (Female 4) Character Tests', () {
    test('CharacterRoster defines Nard and Ashley correctly', () {
      final nard = CharacterRoster.nard;
      expect(nard.id, 'male4_nard');
      expect(nard.name, 'Nard');
      expect(nard.type, CharacterType.male4);
      expect(nard.spriteFolder, 'male4_sprite');
      expect(nard.isMale, isTrue);
      expect(nard.isDefaultUnlocked, isTrue);
      expect(nard.iconPath, contains('male4_icon.png'));
      expect(nard.readyToServePath, contains('male4_p1sideidle.png'));
      expect(nard.charSelectIdlePath, contains('male4_charselectidle.png'));
      expect(nard.frontRunPath, contains('male4_frontrun.png'));
      expect(nard.frontSlashPath, contains('male4_frontslash.png'));

      final ashley = CharacterRoster.ashley;
      expect(ashley.id, 'female4_ashley');
      expect(ashley.name, 'Ashley');
      expect(ashley.type, CharacterType.female4);
      expect(ashley.spriteFolder, 'female4_sprite');
      expect(ashley.isMale, isFalse);
      expect(ashley.isDefaultUnlocked, isTrue);
      expect(ashley.iconPath, contains('female4_icon.png'));
      expect(ashley.readyToServePath, contains('female4_p1sideidle.png'));
      expect(ashley.charSelectIdlePath, contains('female4_charselectidle.png'));
      expect(ashley.frontRunPath, contains('female4_frontrun.png'));
      expect(ashley.frontSlashPath, contains('female4_frontslash.png'));
    });

    test('CharacterRoster lookup by ID and Type resolves Nard and Ashley', () {
      expect(CharacterRoster.getById('male4_nard').name, 'Nard');
      expect(CharacterRoster.getById('nard').name, 'Nard');
      expect(CharacterRoster.getById('female4_ashley').name, 'Ashley');
      expect(CharacterRoster.getById('ashley').name, 'Ashley');

      expect(CharacterRoster.getByType(CharacterType.male4).name, 'Nard');
      expect(CharacterRoster.getByType(CharacterType.female4).name, 'Ashley');

      expect(CharacterRoster.allCharacters.contains(CharacterRoster.nard), isTrue);
      expect(CharacterRoster.allCharacters.contains(CharacterRoster.ashley), isTrue);
    });

    test('PlayerAvatar catalog includes Nard and Ashley presets', () {
      final nardAvatar = PlayerAvatar.getById('male4_nard');
      expect(nardAvatar.name, 'Nard');
      expect(nardAvatar.assetPath, contains('male4_icon.png'));

      final ashleyAvatar = PlayerAvatar.getById('female4_ashley');
      expect(ashleyAvatar.name, 'Ashley');
      expect(ashleyAvatar.assetPath, contains('female4_icon.png'));
    });

    test('AnimatedCharacterDisplay gender mapping resolves male4 and female4', () {
      expect(
        AnimatedCharacterDisplay.genderFromType(CharacterType.male4),
        CharacterGender.male4,
      );
      expect(
        AnimatedCharacterDisplay.typeFromGender(CharacterGender.male4),
        CharacterType.male4,
      );

      expect(
        AnimatedCharacterDisplay.genderFromType(CharacterType.female4),
        CharacterGender.female4,
      );
      expect(
        AnimatedCharacterDisplay.typeFromGender(CharacterGender.female4),
        CharacterType.female4,
      );
    });

    test('GameStateManager unlocks Nard and Ashley by default', () {
      final state = GameStateManager.instance;
      expect(state.unlockedCharacterIds.contains('male4_nard'), isTrue);
      expect(state.unlockedCharacterIds.contains('female4_ashley'), isTrue);
      expect(state.isCharacterUnlocked('male4_nard'), isTrue);
      expect(state.isCharacterUnlocked('female4_ashley'), isTrue);
    });

    test('PlayerComponent instantiates with Nard and Ashley character types', () {
      final pNard = PlayerComponent(
        isPlayerOne: true,
        characterType: CharacterType.male4,
      );
      expect(pNard.characterType, CharacterType.male4);
      expect(pNard.isFemale, isFalse);

      final pAshley = PlayerComponent(
        isPlayerOne: false,
        characterType: CharacterType.female4,
      );
      expect(pAshley.characterType, CharacterType.female4);
      expect(pAshley.isFemale, isTrue);
    });
  });
}
