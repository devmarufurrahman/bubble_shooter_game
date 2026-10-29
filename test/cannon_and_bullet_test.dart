import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bubble_shooter_game/game/components/bubble_color.dart';
import 'package:bubble_shooter_game/game/components/bullet_bubble.dart';
import 'package:bubble_shooter_game/game/components/cannon_component.dart';
import 'package:bubble_shooter_game/game/components/grid_manager.dart';

void main() {
  group('CannonComponent Tests', () {
    const double gameWidth = 400.0;
    const double gameHeight = 700.0;
    const double ceilingY = 35.0;
    const double bubbleRadius = 25.0;

    late CannonComponent cannon;

    setUp(() {
      cannon = CannonComponent(
        gameWidth: gameWidth,
        gameHeight: gameHeight,
        ceilingY: ceilingY,
        bubbleRadius: bubbleRadius,
        position: Vector2(200, 630),
      );
      cannon.onLoad();
    });

    test('Aiming straight up calculates angle ~ 0.0 radians', () {
      // Touch directly above cannon (x: 200, y: 300)
      cannon.aimAt(Vector2(200, 300));
      expect(cannon.aimAngle, closeTo(0.0, 0.001));
    });

    test('Aiming up-right gives positive angle', () {
      cannon.aimAt(Vector2(300, 530));
      expect(cannon.aimAngle, greaterThan(0.0));
      expect(cannon.aimAngle, lessThanOrEqualTo(CannonComponent.maxAimAngle));
    });

    test('Aiming up-left gives negative angle', () {
      cannon.aimAt(Vector2(100, 530));
      expect(cannon.aimAngle, lessThan(0.0));
      expect(cannon.aimAngle, greaterThanOrEqualTo(-CannonComponent.maxAimAngle));
    });

    test('Rotation is strictly clamped to +/- 70 degrees', () {
      // Extreme right
      cannon.aimAt(Vector2(1000, 630));
      expect(cannon.aimAngle, closeTo(CannonComponent.maxAimAngle, 0.0001));

      // Extreme left
      cannon.aimAt(Vector2(-1000, 630));
      expect(cannon.aimAngle, closeTo(-CannonComponent.maxAimAngle, 0.0001));

      // Downward drag (should not shoot backwards)
      cannon.aimAt(Vector2(300, 900));
      expect(cannon.aimAngle, lessThanOrEqualTo(CannonComponent.maxAimAngle));
      expect(cannon.aimAngle, greaterThanOrEqualTo(-CannonComponent.maxAimAngle));
    });

    test('Nozzle position computes correct tip coordinate', () {
      cannon.aimAngle = 0.0; // Straight up
      final tip = cannon.nozzlePosition;
      expect(tip.x, closeTo(200.0, 0.001));
      expect(tip.y, closeTo(630.0 - CannonComponent.barrelLength, 0.001));
    });

    test('Queue cycling promotes next bubble and picks new valid color', () {
      final gridManager = GridManager(radius: bubbleRadius, topOffset: 60.0);
      gridManager.populateInitialGrid([
        [0, 1], // only red and blue on grid
      ]);

      final initialNext = cannon.nextBubbleType;
      cannon.cycleNextBubble(gridManager);

      // current should now be the old next
      expect(cannon.currentBubbleType, equals(initialNext));
      // new next should be one of the grid colors (red or blue)
      expect(
        cannon.nextBubbleType == BubbleType.red ||
            cannon.nextBubbleType == BubbleType.blue,
        isTrue,
      );
    });
  });

  group('BulletBubble Physics & Bounce Tests', () {
    const double gameWidth = 400.0;
    const double ceilingY = 35.0;
    const double radius = 25.0;
    const double speed = 750.0;

    test('Velocity calculation follows aim angle', () {
      // Straight up: sin(0) = 0, -cos(0) = -1 -> (0, -750)
      final bulletUp = BulletBubble(
        bubbleType: BubbleType.green,
        radius: radius,
        aimAngle: 0.0,
        gameWidth: gameWidth,
        ceilingY: ceilingY,
        speed: speed,
      );
      expect(bulletUp.velocity.x, closeTo(0.0, 0.001));
      expect(bulletUp.velocity.y, closeTo(-750.0, 0.001));

      // 45 degrees right: sin(pi/4) > 0, -cos(pi/4) < 0
      final bulletRight = BulletBubble(
        bubbleType: BubbleType.red,
        radius: radius,
        aimAngle: math.pi / 4,
        gameWidth: gameWidth,
        ceilingY: ceilingY,
        speed: speed,
      );
      expect(bulletRight.velocity.x, greaterThan(0.0));
      expect(bulletRight.velocity.y, lessThan(0.0));
    });

    test('Left wall bounce reflects velocity.x to positive', () {
      final bullet = BulletBubble(
        bubbleType: BubbleType.blue,
        radius: radius,
        aimAngle: -math.pi / 4, // moving left-up
        gameWidth: gameWidth,
        ceilingY: ceilingY,
        position: Vector2(30, 400),
      );

      expect(bullet.velocity.x, lessThan(0.0));

      // Step physics into wall
      bullet.update(0.1); // moves left by ~53px, hits wall (30 - 53 < 25)

      expect(bullet.position.x, equals(radius));
      expect(bullet.velocity.x, greaterThan(0.0)); // Reflected right
      expect(bullet.isMoving, isTrue);
    });

    test('Right wall bounce reflects velocity.x to negative', () {
      final bullet = BulletBubble(
        bubbleType: BubbleType.yellow,
        radius: radius,
        aimAngle: math.pi / 4, // moving right-up
        gameWidth: gameWidth,
        ceilingY: ceilingY,
        position: Vector2(370, 400),
      );

      expect(bullet.velocity.x, greaterThan(0.0));

      // Step physics into right wall
      bullet.update(0.1);

      expect(bullet.position.x, equals(gameWidth - radius));
      expect(bullet.velocity.x, lessThan(0.0)); // Reflected left
      expect(bullet.isMoving, isTrue);
    });

    test('Ceiling impact halts velocity and triggers onStopped callback', () {
      bool stoppedCalled = false;

      final bullet = BulletBubble(
        bubbleType: BubbleType.purple,
        radius: radius,
        aimAngle: 0.0, // straight up
        gameWidth: gameWidth,
        ceilingY: ceilingY,
        position: Vector2(200, 70),
        onStopped: () => stoppedCalled = true,
      );

      expect(bullet.isMoving, isTrue);
      expect(bullet.hasStopped, isFalse);

      // Step physics into ceiling (70 - 750 * 0.1 = -5 < ceilingY)
      bullet.update(0.1);

      expect(bullet.position.y, equals(ceilingY + radius));
      expect(bullet.velocity, equals(Vector2.zero()));
      expect(bullet.isMoving, isFalse);
      expect(bullet.hasStopped, isTrue);
      expect(stoppedCalled, isTrue);
    });
  });
}

