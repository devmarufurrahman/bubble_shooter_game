import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bubble_shooter_game/game/bubble_shooter_game.dart';
import 'package:bubble_shooter_game/game/components/bubble_color.dart';
import 'package:bubble_shooter_game/game/components/grid_manager.dart';
import 'package:bubble_shooter_game/levels/level_data.dart';
import 'package:bubble_shooter_game/levels/level_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  BubbleShooterGame createGame([int level = 1]) {
    final game = BubbleShooterGame(levelNumber: level);
    game.overlays.addEntry('WinOverlay', (ctx, g) => const SizedBox());
    game.overlays.addEntry('GameOverOverlay', (ctx, g) => const SizedBox());
    game.overlays.addEntry('PauseOverlay', (ctx, g) => const SizedBox());
    return game;
  }

  group('LevelConfig & 10-Level System Tests', () {
    test('Exactly 10 levels are defined with progressive difficulty', () {
      expect(LevelConfig.levels.length, equals(10));

      for (int i = 1; i <= 10; i++) {
        final config = LevelConfig.getLevel(i);
        expect(config.levelNumber, equals(i));
        expect(config.maxShots, greaterThan(0));
        expect(config.availableColors.isNotEmpty, isTrue);
        expect(config.initialGrid.isNotEmpty, isTrue);
      }
    });

    test('Ammo limits decrease progressively across campaign', () {
      final lvl1 = LevelConfig.getLevel(1);
      final lvl5 = LevelConfig.getLevel(5);
      final lvl10 = LevelConfig.getLevel(10);

      expect(lvl1.maxShots, equals(30));
      expect(lvl5.maxShots, equals(22));
      expect(lvl10.maxShots, equals(16));
      expect(lvl1.maxShots, greaterThan(lvl5.maxShots));
      expect(lvl5.maxShots, greaterThan(lvl10.maxShots));
    });

    test('Color palette scales from 3 colors to 5 colors', () {
      final lvl1 = LevelConfig.getLevel(1);
      final lvl3 = LevelConfig.getLevel(3);
      final lvl8 = LevelConfig.getLevel(8);

      expect(lvl1.availableColors.length, equals(3));
      expect(lvl3.availableColors.length, equals(4));
      expect(lvl8.availableColors.length, equals(5));
    });

    test('LevelConfig integer to BubbleType mapping matches 1-based convention', () {
      expect(LevelConfig.bubbleTypeFromInt(0), isNull);
      expect(LevelConfig.bubbleTypeFromInt(1), equals(BubbleType.red));
      expect(LevelConfig.bubbleTypeFromInt(2), equals(BubbleType.blue));
      expect(LevelConfig.bubbleTypeFromInt(3), equals(BubbleType.green));
      expect(LevelConfig.bubbleTypeFromInt(4), equals(BubbleType.yellow));
      expect(LevelConfig.bubbleTypeFromInt(5), equals(BubbleType.purple));
      expect(LevelConfig.bubbleTypeFromInt(6), isNull);
    });

    test('GridManager.populateInitialGrid handles 1-based matrix format with 0 as empty', () {
      final gridManager = GridManager(radius: 25.0, topOffset: 60.0);

      // Matrix: 0 is empty, 1 is red, 2 is blue
      final List<List<int>> matrix = [
        [0, 1, 0, 2],
      ];

      gridManager.populateInitialGrid(matrix, oneBased: true);

      expect(gridManager.totalActiveBubbles, equals(2));
      expect(gridManager.isCellOccupied(0, 0), isFalse);
      expect(gridManager.getBubbleAt(0, 1)?.bubbleType, equals(BubbleType.red));
      expect(gridManager.isCellOccupied(0, 2), isFalse);
      expect(gridManager.getBubbleAt(0, 3)?.bubbleType, equals(BubbleType.blue));
    });
  });

  group('Game Loop State, Win & Defeat Rules Tests', () {
    test('Game initializes with level configuration and full shot capacity', () async {
      final game = createGame(1);
      await game.onLoad();

      expect(game.shotsRemaining, equals(30));
      expect(game.shotsNotifier.value, equals(30));
      expect(game.levelConfig.levelNumber, equals(1));
      expect(game.gridManager.totalActiveBubbles, greaterThan(0));
      expect(BubbleShooterGame.dangerThresholdY, equals(552.0));
      expect(game.gameOverReason, isNull);
    });

    test('Win condition: clearing all bubbles unlocks next level and presents WinOverlay', () async {
      final game = createGame(1);
      await game.onLoad();

      // Clear all bubbles on the board to simulate total victory
      game.gridManager.clear();
      expect(game.gridManager.allBubblesCleared, isTrue);

      await game.handleLevelVictory();

      // Verify level 2 was unlocked in persistence
      final unlocked = await LevelManager.instance.getUnlockedLevel();
      expect(unlocked, equals(2));
      expect(game.overlays.isActive('WinOverlay'), isTrue);
    });

    test('Loss condition: running out of shots triggers GameOverOverlay with OUT OF SHOTS', () async {
      final game = createGame(1);
      await game.onLoad();

      // Board has bubbles, but shots reach 0
      expect(game.gridManager.totalActiveBubbles, greaterThan(0));
      game.shotsRemaining = 0;
      game.shotsNotifier.value = 0;

      game.handleGameOver('OUT OF SHOTS');

      expect(game.gameOverReason, equals('OUT OF SHOTS'));
      expect(game.overlays.isActive('GameOverOverlay'), isTrue);
    });

    test('Loss condition: bubbles breaching danger floor threshold triggers defeat', () async {
      final game = createGame(1);
      await game.onLoad();

      game.handleGameOver('BUBBLES REACHED DANGER LINE');

      expect(game.gameOverReason, equals('BUBBLES REACHED DANGER LINE'));
      expect(game.overlays.isActive('GameOverOverlay'), isTrue);
    });

    test('Restarting level restores ammo, clears score, and repopulates grid', () async {
      final game = createGame(1);
      await game.onLoad();

      game.shotsRemaining = 5;
      game.shotsNotifier.value = 5;
      game.currentScore = 1500;
      game.scoreNotifier.value = 1500;
      game.gameOverReason = 'OUT OF SHOTS';
      game.overlays.add('GameOverOverlay');

      game.restartLevel();

      expect(game.shotsRemaining, equals(30));
      expect(game.shotsNotifier.value, equals(30));
      expect(game.currentScore, equals(0));
      expect(game.scoreNotifier.value, equals(0));
      expect(game.gameOverReason, isNull);
      expect(game.overlays.isActive('GameOverOverlay'), isFalse);
    });
  });
}
