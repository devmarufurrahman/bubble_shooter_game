import 'dart:math' show Point;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bubble_shooter_game/game/components/bubble_color.dart';
import 'package:bubble_shooter_game/game/components/bubble_component.dart';
import 'package:bubble_shooter_game/game/components/bullet_bubble.dart';
import 'package:bubble_shooter_game/game/components/grid_manager.dart';
import 'package:bubble_shooter_game/game/logic/match_checker.dart';

void main() {
  group('Hexagonal Match-3 (BFS Flood-Fill) Tests', () {
    late GridManager grid;

    setUp(() {
      grid = GridManager(radius: 25.0, topOffset: 60.0, maxRows: 14);
    });

    test('3 adjacent identical bubbles form a match cluster', () {
      // Setup 3 red bubbles: (0, 0), (0, 1), (1, 0)
      // Note: (1, 0) is adjacent to (0, 0) and (0, 1) in Odd-r layout
      grid.setBubbleAt(
        0,
        0,
        BubbleComponent(row: 0, col: 0, bubbleType: BubbleType.red, radius: 25.0),
      );
      grid.setBubbleAt(
        0,
        1,
        BubbleComponent(row: 0, col: 1, bubbleType: BubbleType.red, radius: 25.0),
      );
      grid.setBubbleAt(
        1,
        0,
        BubbleComponent(row: 1, col: 0, bubbleType: BubbleType.red, radius: 25.0),
      );

      final matches = MatchChecker.findMatches(0, 0, BubbleType.red, grid);

      expect(matches.length, equals(3));
      expect(matches.contains(const Point(0, 0)), isTrue);
      expect(matches.contains(const Point(0, 1)), isTrue);
      expect(matches.contains(const Point(1, 0)), isTrue);
    });

    test('Cluster of only 2 bubbles does not meet match-3 threshold', () {
      grid.setBubbleAt(
        0,
        0,
        BubbleComponent(row: 0, col: 0, bubbleType: BubbleType.blue, radius: 25.0),
      );
      grid.setBubbleAt(
        0,
        1,
        BubbleComponent(row: 0, col: 1, bubbleType: BubbleType.blue, radius: 25.0),
      );
      grid.setBubbleAt(
        1,
        0,
        BubbleComponent(row: 1, col: 0, bubbleType: BubbleType.green, radius: 25.0), // Different
      );

      final matches = MatchChecker.findMatches(0, 0, BubbleType.blue, grid);
      expect(matches.length, equals(2));
    });

    test('Traverse chains of 4 or 5 connected matching bubbles', () {
      // Chain: (0, 0) - (0, 1) - (0, 2) - (1, 1)
      grid.setBubbleAt(
        0,
        0,
        BubbleComponent(row: 0, col: 0, bubbleType: BubbleType.yellow, radius: 25.0),
      );
      grid.setBubbleAt(
        0,
        1,
        BubbleComponent(row: 0, col: 1, bubbleType: BubbleType.yellow, radius: 25.0),
      );
      grid.setBubbleAt(
        0,
        2,
        BubbleComponent(row: 0, col: 2, bubbleType: BubbleType.yellow, radius: 25.0),
      );
      grid.setBubbleAt(
        1,
        1,
        BubbleComponent(row: 1, col: 1, bubbleType: BubbleType.yellow, radius: 25.0),
      );

      final matches = MatchChecker.findMatches(1, 1, BubbleType.yellow, grid);
      expect(matches.length, equals(4));
    });
  });

  group('Floating / Disconnected Bubble Drop Tests', () {
    late GridManager grid;

    setUp(() {
      grid = GridManager(radius: 25.0, topOffset: 60.0, maxRows: 14);
    });

    test('Bubbles connected to Row 0 are anchored', () {
      // Row 0 anchor
      grid.setBubbleAt(
        0,
        2,
        BubbleComponent(row: 0, col: 2, bubbleType: BubbleType.red, radius: 25.0),
      );
      // Row 1 attached to (0, 2)
      grid.setBubbleAt(
        1,
        1,
        BubbleComponent(row: 1, col: 1, bubbleType: BubbleType.blue, radius: 25.0),
      );
      // Row 2 attached to (1, 1)
      grid.setBubbleAt(
        2,
        2,
        BubbleComponent(row: 2, col: 2, bubbleType: BubbleType.green, radius: 25.0),
      );

      final floating = MatchChecker.findFloatingBubbles(grid);
      expect(floating, isEmpty);
    });

    test('Bubbles isolated from Row 0 are detected as floating', () {
      // Only place bubbles at Row 2 (nothing in Row 0 or Row 1)
      grid.setBubbleAt(
        2,
        2,
        BubbleComponent(row: 2, col: 2, bubbleType: BubbleType.purple, radius: 25.0),
      );
      grid.setBubbleAt(
        2,
        3,
        BubbleComponent(row: 2, col: 3, bubbleType: BubbleType.purple, radius: 25.0),
      );

      final floating = MatchChecker.findFloatingBubbles(grid);
      expect(floating.length, equals(2));
      expect(floating.contains(const Point(2, 2)), isTrue);
      expect(floating.contains(const Point(2, 3)), isTrue);
    });

    test('Popping a bridge bubble causes disconnected lower branch to float', () {
      // Row 0
      grid.setBubbleAt(
        0,
        2,
        BubbleComponent(row: 0, col: 2, bubbleType: BubbleType.red, radius: 25.0),
      );
      // Row 1 (Bridge)
      grid.setBubbleAt(
        1,
        1,
        BubbleComponent(row: 1, col: 1, bubbleType: BubbleType.red, radius: 25.0),
      );
      // Row 2 (Leaf)
      grid.setBubbleAt(
        2,
        2,
        BubbleComponent(row: 2, col: 2, bubbleType: BubbleType.yellow, radius: 25.0),
      );

      // Verify initially all anchored
      expect(MatchChecker.findFloatingBubbles(grid), isEmpty);

      // Now pop/remove the bridge at (1, 1)
      grid.removeBubbleAt(1, 1);

      // Row 2 bubble is now disconnected!
      final floating = MatchChecker.findFloatingBubbles(grid);
      expect(floating.length, equals(1));
      expect(floating.first, equals(const Point(2, 2)));
    });

    test('dropFloatingBubbles detaches orphans and triggers dropAsFloating directly', () {
      // Place isolated bubble
      final bubble = BubbleComponent(row: 3, col: 1, bubbleType: BubbleType.blue, radius: 25.0);
      grid.setBubbleAt(3, 1, bubble);

      final dropped = MatchChecker.dropFloatingBubbles(grid);

      expect(dropped.length, equals(1));
      expect(identical(dropped.first, bubble), isTrue); // Exact same component instance, no ghost duplicates
      expect(grid.isCellOccupied(3, 1), isFalse); // Detached from grid data
      expect(bubble.isDropping, isTrue); // Animated drop started
      expect(grid.hasFallingBubbles, isTrue);
      expect(grid.hasAnyBubblesOnGrid, isFalse);
    });
  });

  group('Grid Snapping Engine Tests', () {
    late GridManager grid;

    setUp(() {
      grid = GridManager(radius: 25.0, topOffset: 60.0, maxRows: 14);
    });

    test('Ceiling hit with no bubble snaps to closest cell in Row 0', () {
      // Impact at x = 72, y = 35 (closest to col 1 which is at x = 75)
      final snap = grid.findBestSnapCell(Vector2(72, 35), null);
      expect(snap.row, equals(0));
      expect(snap.col, equals(1));
    });

    test('Bubble collision snaps to closest empty neighbor', () {
      // Place existing bubble at (0, 2)
      final existing = BubbleComponent(
        row: 0,
        col: 2,
        bubbleType: BubbleType.green,
        radius: 25.0,
      );
      grid.setBubbleAt(0, 2, existing);

      // Bullet hit from bottom-left
      // Existing at (0, 2) is at (125, 60)
      // Bullet position at (110, 85)
      final snap = grid.findBestSnapCell(Vector2(110, 85), existing);

      // Should snap to an empty neighbor of (0, 2)
      final neighbors = grid.getNeighbors(0, 2);
      expect(neighbors.contains(snap), isTrue);
      expect(grid.isCellOccupied(snap.row, snap.col), isFalse);
    });

    test('snapBulletToGrid inserts bubble and removes bullet', () {
      final bullet = BulletBubble(
        bubbleType: BubbleType.red,
        radius: 25.0,
        aimAngle: 0.0,
        gameWidth: 400.0,
        ceilingY: 35.0,
        position: Vector2(25, 35), // At col 0 of row 0
      );

      final inserted = grid.snapBulletToGrid(bullet: bullet, hitBubble: null);

      expect(inserted.row, equals(0));
      expect(inserted.col, equals(0));
      expect(inserted.bubbleType, equals(BubbleType.red));
      expect(grid.isCellOccupied(0, 0), isTrue);
      expect(bullet.parent, isNull); // Removed from parent
    });
  });

  group('Floating Orphan Drop & Ghost Bubble Prevention Tests', () {
    late GridManager grid;

    setUp(() {
      grid = GridManager(radius: 25.0, topOffset: 60.0, maxRows: 14);
    });

    test('dropAsFloating activates gravity physics and disables collision hitbox', () async {
      final bubble = BubbleComponent(
        row: 2,
        col: 2,
        bubbleType: BubbleType.purple,
        radius: 25.0,
      );
      grid.setBubbleAt(2, 2, bubble);
      await bubble.onLoad();

      expect(bubble.isDropping, isFalse);
      expect(bubble.hitbox, isNotNull);

      bubble.dropAsFloating();

      expect(bubble.isDropping, isTrue);
      expect(bubble.hitbox!.collisionType, equals(CollisionType.inactive));

      final double initialY = bubble.position.y;
      bubble.update(0.1); // Gravity acceleration
      expect(bubble.position.y, greaterThan(initialY));
    });

    test('allBubblesCleared is false while falling bubbles are active (prevents premature win)', () {
      final bubble = BubbleComponent(
        row: 3,
        col: 1,
        bubbleType: BubbleType.yellow,
        radius: 25.0,
      );
      grid.setBubbleAt(3, 1, bubble);

      // Detach and start falling
      final dropped = grid.dropFloatingBubbles();
      expect(dropped.length, equals(1));
      expect(identical(dropped.first, bubble), isTrue);

      // Grid matrix is empty, but falling bubbles are still in transit!
      expect(grid.hasAnyBubblesOnGrid, isFalse);
      expect(grid.hasFallingBubbles, isTrue);
      expect(grid.allBubblesCleared, isFalse); // Win dialog must NOT trigger yet

      // Simulate falling until bubble exits past bottom (y > 750)
      for (int i = 0; i < 20; i++) {
        bubble.update(0.1);
      }

      // Now falling bubble has despawned and removed itself
      expect(grid.hasFallingBubbles, isFalse);
      expect(grid.allBubblesCleared, isTrue); // Now win dialog can safely trigger
    });

    test('grid.clear() purges active falling bubbles immediately on level restart', () {
      final bubble = BubbleComponent(
        row: 4,
        col: 2,
        bubbleType: BubbleType.green,
        radius: 25.0,
      );
      grid.setBubbleAt(4, 2, bubble);

      grid.dropFloatingBubbles();
      expect(grid.hasFallingBubbles, isTrue);

      grid.clear();
      expect(grid.hasFallingBubbles, isFalse);
      expect(grid.hasAnyBubblesOnGrid, isFalse);
      expect(grid.allBubblesCleared, isTrue);
    });
  });
}
