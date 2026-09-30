import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_smash/models/character_roster.dart';
import 'package:pickleball_smash/models/multiplayer_models.dart';
import 'package:pickleball_smash/services/game_state_manager.dart';
import 'package:pickleball_smash/services/multiplayer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multiplayer Character Sync & Visibility Tests', () {
    test('RoomPlayerSlot deserializes characterId with fallback to playerAvatar', () {
      final slotWithChar = RoomPlayerSlot.fromJson({
        'slotIndex': 0,
        'team': 'A',
        'playerId': '#PB-1001',
        'playerName': 'Alex',
        'playerAvatar': 'alex_classic',
        'characterId': 'female2_frost',
        'isHost': true,
        'isReady': true,
        'isBot': false,
      });

      expect(slotWithChar.characterId, equals('female2_frost'));

      final slotFallback = RoomPlayerSlot.fromJson({
        'slotIndex': 1,
        'team': 'B',
        'playerId': '#PB-2002',
        'playerName': 'Sammy',
        'playerAvatar': 'male3_thunder',
        'isHost': false,
        'isReady': true,
        'isBot': false,
      });

      expect(slotFallback.characterId, equals('male3_thunder'));
    });

    test('CharacterRoster resolves character types correctly for all character IDs', () {
      expect(CharacterRoster.getById('alex_classic').type, equals(CharacterType.male1));
      expect(CharacterRoster.getById('female2_frost').type, equals(CharacterType.female2));
      expect(CharacterRoster.getById('male3_thunder').type, equals(CharacterType.male3));
      expect(CharacterRoster.getById('male2_blaze').type, equals(CharacterType.male2));
      expect(CharacterRoster.getById('maya_speed').type, equals(CharacterType.female1));
    });

    test('MultiplayerService updateMyCharacter updates slot and local equipped avatar', () async {
      final multi = MultiplayerService.instance;
      await multi.createRoom(
        gameMode: '1v1 Singles',
        mode: MultiplayerConnectionMode.lanHotspot,
        enableNetworking: false,
      );

      final room = multi.currentRoom;
      expect(room, isNotNull);

      // Change character to Chloe Frost
      await multi.updateMyCharacter('female2_frost');

      expect(GameStateManager.instance.playerAvatarId, equals('female2_frost'));
      expect(multi.currentRoom!.slots[0].characterId, equals('female2_frost'));
    });
  });
}
