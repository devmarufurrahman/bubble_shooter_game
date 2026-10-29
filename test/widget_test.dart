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

    test('saveLevelProgress atomically persists score, stars, and unlocks next level', () async {
      expect(await LevelManager.getStars(1), equals(0));
      expect(await LevelManager.getHighScore(1), equals(0));
      expect(await LevelManager.getUnlockedLevel(), equals(1));

      // Save initial completion: 1500 points, 2 stars
      await LevelManager.saveLevelProgress(1, 1500, 2);

      expect(await LevelManager.getHighScore(1), equals(1500));
      expect(await LevelManager.getStars(1), equals(2));
      expect(await LevelManager.getUnlockedLevel(), equals(2));

      // Lower score and lower stars should not overwrite
      await LevelManager.saveLevelProgress(1, 1000, 1);
      expect(await LevelManager.getHighScore(1), equals(1500));
      expect(await LevelManager.getStars(1), equals(2));

      // Higher score and higher stars should overwrite
      await LevelManager.saveLevelProgress(1, 2500, 3);
      expect(await LevelManager.getHighScore(1), equals(2500));
      expect(await LevelManager.getStars(1), equals(3));

      // Verify persistent keys directly
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('level_1_score'), equals(2500));
      expect(prefs.getInt('level_1_stars'), equals(3));
      expect(prefs.getInt('unlocked_level'), equals(2));
    });
  });
}
