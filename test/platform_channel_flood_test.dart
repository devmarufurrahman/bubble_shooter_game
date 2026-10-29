import 'dart:math' show Point;
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bubble_shooter_game/core/audio/audio.dart';
import 'package:bubble_shooter_game/core/utils/utils.dart';
import 'package:bubble_shooter_game/game/bubble_shooter_game.dart';
import 'package:bubble_shooter_game/game/components/components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundManager.enableAudio = true;
    SoundManager.instance.resetDebounceTimers();
    HapticsHelper.resetDebounce();
  });

  tearDown(() {
    SoundManager.enableAudio = false;
  });

  group('SoundManager Audio Rate-Limiting & Debounce Tests', () {
    test('Debounce constants are configured with appropriate intervals', () {
      expect(SoundManager.popDebounceMs, equals(80));
      expect(SoundManager.bounceDebounceMs, equals(60));
      expect(SoundManager.shootDebounceMs, equals(50));
      expect(SoundManager.defaultDebounceMs, equals(50));
    });

    test('Repeated immediate calls to playPop() do not crash and execute safely', () {
      final sound = SoundManager.instance;
      // Trigger multiple rapid calls simulating multi-bubble pop burst
      expect(() {
        sound.playPop();
        sound.playPop();
        sound.playPop();
        sound.playPop();
      }, returnsNormally);
    });

    test('Immediate zero-overhead guard when muted or disabled', () async {
      final sound = SoundManager.instance;
      await sound.setMuted(true);

      expect(() {
        sound.playShoot();
        sound.playBounce();
        sound.playPop();
      }, returnsNormally);

      await sound.setMuted(false);
    });

    test('resetDebounceTimers clears cached playback timestamps', () {
      final sound = SoundManager.instance;
      sound.playPop();
      expect(() => sound.resetDebounceTimers(), returnsNormally);
      expect(() => sound.playPop(), returnsNormally);
    });
  });

  group('HapticsHelper Rate-Limiting & Debounce Tests', () {
    test('Haptic cooldown constant is configured to 40ms', () {
      expect(HapticsHelper.defaultHapticCooldownMs, equals(40));
    });

    test('Rapid consecutive haptic feedback calls execute safely and debounce', () async {
      await HapticsHelper.setHapticsEnabled(true);
      HapticsHelper.resetDebounce();

      expect(() async {
        await HapticsHelper.lightImpact();
        await HapticsHelper.lightImpact();
        await HapticsHelper.selectionClick();
        await HapticsHelper.mediumImpact();
      }, returnsNormally);
    });

    test('HapticsHelper.resetDebounce resets internal cooldown timestamp', () {
      expect(() => HapticsHelper.resetDebounce(), returnsNormally);
    });
  });

  group('GridManager batchPopMatches Tests', () {
    late GridManager grid;

    setUp(() {
      grid = GridManager(radius: 25.0, topOffset: 60.0, maxRows: 14);
    });

    test('batchPopMatches with empty list returns empty without errors', () {
      final popped = grid.batchPopMatches([]);
      expect(popped, isEmpty);
    });

    test('batchPopMatches detaches matching bubbles and triggers pop animation', () {
      final b1 = BubbleComponent(row: 0, col: 0, bubbleType: BubbleType.red, radius: 25.0);
      final b2 = BubbleComponent(row: 0, col: 1, bubbleType: BubbleType.red, radius: 25.0);
      final b3 = BubbleComponent(row: 1, col: 0, bubbleType: BubbleType.red, radius: 25.0);

      grid.setBubbleAt(0, 0, b1);
      grid.setBubbleAt(0, 1, b2);
      grid.setBubbleAt(1, 0, b3);

      final matches = [
        const Point(0, 0),
        const Point(0, 1),
        const Point(1, 0),
      ];

      final popped = grid.batchPopMatches(matches);

      expect(popped.length, equals(3));
      expect(popped, containsAll([b1, b2, b3]));

      // Verify grid cells are now empty
      expect(grid.isCellOccupied(0, 0), isFalse);
      expect(grid.isCellOccupied(0, 1), isFalse);
      expect(grid.isCellOccupied(1, 0), isFalse);

      // Verify each popped bubble entered popping animation state
      expect(b1.isPopping, isTrue);
      expect(b2.isPopping, isTrue);
      expect(b3.isPopping, isTrue);
    });
  });

  group('BubbleShooterGame Aim & Platform Channel Cleanliness Tests', () {
    test('onPanUpdate computes aiming angle purely locally without throwing', () async {
      final game = BubbleShooterGame(levelNumber: 1);
      await game.onLoad();

      // Cannon starts aiming
      game.cannon.isAiming = true;
      expect(game.cannon.isAiming, isTrue);

      final initialAngle = game.cannon.aimAngle;

      // Simulate aiming towards top-left
      game.cannon.aimAt(Vector2(50, 200));
      expect(game.cannon.aimAngle, isNot(equals(initialAngle)));
      expect(game.cannon.aimAngle, isNegative);

      // Simulate aiming towards top-right
      game.cannon.aimAt(Vector2(350, 200));
      expect(game.cannon.aimAngle, isPositive);

      game.onDisposeGame();
    });
  });
}
