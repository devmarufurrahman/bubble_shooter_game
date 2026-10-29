import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bubble_shooter_game/levels/level_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LevelManager Tests', () {
    test('Default unlocked level should be 1', () async {
      final levelManager = LevelManager.instance;
      final int unlocked = await levelManager.getUnlockedLevel();
      expect(unlocked, equals(1));
    });

    test('Unlocking next level increases level correctly', () async {
      final levelManager = LevelManager.instance;
      await levelManager.unlockNextLevel(1);
      final int unlocked = await levelManager.getUnlockedLevel();
      expect(unlocked, equals(2));
    });

    test('Saving high score persists and updates correctly', () async {
      final levelManager = LevelManager.instance;
      expect(await levelManager.getHighScore(1), equals(0));

      await levelManager.saveScore(1, 1500);
      expect(await levelManager.getHighScore(1), equals(1500));

      // Lower score should not overwrite
      await levelManager.saveScore(1, 1200);
      expect(await levelManager.getHighScore(1), equals(1500));

      // Higher score should overwrite
      await levelManager.saveScore(1, 3000);
      expect(await levelManager.getHighScore(1), equals(3000));
    });

    test('Resetting progress clears unlocks and high scores', () async {
      final levelManager = LevelManager.instance;
      await levelManager.unlockNextLevel(1);
      await levelManager.saveScore(1, 2000);

      await levelManager.resetProgress();
      expect(await levelManager.getUnlockedLevel(), equals(1));
      expect(await levelManager.getHighScore(1), equals(0));
    });
  });
}
