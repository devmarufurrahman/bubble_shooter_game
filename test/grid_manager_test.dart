import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bubble_shooter_game/game/components/bubble_color.dart';
import 'package:bubble_shooter_game/game/components/bubble_component.dart';
import 'package:bubble_shooter_game/game/components/grid_manager.dart';

void main() {
  group('Odd-r Hexagonal Grid Math Tests', () {
    const double radius = 25.0;
    const double topOffset = 60.0;
    late GridManager gridManager;

    setUp(() {
      gridManager = GridManager(
        radius: radius,
        topOffset: topOffset,
        maxRows: 14,
        evenColumns: 8,
        oddColumns: 7,
      );
    });

    test('Even row (row 0) column coordinates match 8-column layout', () {
      // Even row: X = col * (2 * radius) + radius
      // For col 0: 0 * 50 + 25 = 25
      final Vector2 pos0 = gridManager.getCanvasPosition(0, 0);
      expect(pos0.x, equals(25.0));
      expect(pos0.y, equals(topOffset));

      // For col 7: 7 * 50 + 25 = 375
      final Vector2 pos7 = gridManager.getCanvasPosition(0, 7);
      expect(pos7.x, equals(375.0));
      expect(pos7.y, equals(topOffset));
    });

    test('Odd row (row 1) column coordinates match 7-column layout with offset', () {
      // Odd row: X = col * (2 * radius) + (2 * radius)
      // For col 0: 0 * 50 + 50 = 50
      final Vector2 pos0 = gridManager.getCanvasPosition(1, 0);
      expect(pos0.x, equals(50.0));
      expect(pos0.y, closeTo(topOffset + (radius * math.sqrt(3)), 0.0001));

      // For col 6: 6 * 50 + 50 = 350
      final Vector2 pos6 = gridManager.getCanvasPosition(1, 6);
      expect(pos6.x, equals(350.0));
      expect(pos6.y, closeTo(topOffset + (radius * math.sqrt(3)), 0.0001));
    });

    test('Ceiling Y is properly anchored to top of row 0', () {
      expect(gridManager.ceilingY, equals(topOffset - radius));
    });

    test('Set, query, and remove bubbles from grid', () {
      expect(gridManager.isCellOccupied(0, 0), isFalse);
      expect(gridManager.getBubbleAt(0, 0), isNull);

      final bubble = BubbleComponent(
        row: 0,
        col: 0,
        bubbleType: BubbleType.red,
        radius: radius,
      );
      gridManager.setBubbleAt(0, 0, bubble);

      expect(gridManager.isCellOccupied(0, 0), isTrue);
      expect(gridManager.getBubbleAt(0, 0), equals(bubble));
      expect(bubble.position.x, equals(25.0));
      expect(bubble.position.y, equals(topOffset));

      gridManager.removeBubbleAt(0, 0);
      expect(gridManager.isCellOccupied(0, 0), isFalse);
      expect(gridManager.getBubbleAt(0, 0), isNull);
    });

    test('Populate initial grid from matrix data', () {
      final List<List<int>> data = [
        [0, 1, 2, 3, 4, 0, 1, 2], // 8 bubbles
        [1, 2, 3, 4, 0, 1, 2],    // 7 bubbles
      ];

      gridManager.populateInitialGrid(data);

      expect(gridManager.totalActiveBubbles, equals(15));
      expect(gridManager.getBubbleAt(0, 0)?.bubbleType, equals(BubbleType.red));
      expect(gridManager.getBubbleAt(0, 4)?.bubbleType, equals(BubbleType.purple));
      expect(gridManager.getBubbleAt(1, 0)?.bubbleType, equals(BubbleType.blue));
    });

    test('Hexagonal neighbor connectivity in Odd-r layout', () {
      // Row 1 (odd), Col 1: has 6 valid neighbors inside bounds
      final neighborsOdd = gridManager.getNeighbors(1, 1);
      expect(neighborsOdd.length, equals(6));

      // Neighbors of odd row (1, 1) should include (0, 1), (0, 2), (1, 0), (1, 2), (2, 1), (2, 2)
      expect(neighborsOdd.contains(const GridCoord(0, 1)), isTrue);
      expect(neighborsOdd.contains(const GridCoord(0, 2)), isTrue);
      expect(neighborsOdd.contains(const GridCoord(1, 0)), isTrue);
      expect(neighborsOdd.contains(const GridCoord(1, 2)), isTrue);
      expect(neighborsOdd.contains(const GridCoord(2, 1)), isTrue);
      expect(neighborsOdd.contains(const GridCoord(2, 2)), isTrue);
    });

    test('BubbleType palette produces distinct non-null shader tints', () {
      for (final type in BubbleType.values) {
        expect(type.baseColor, isNotNull);
        expect(type.lightTint, isNotNull);
        expect(type.shadowTint, isNotNull);
        expect(type.glowColor, isNotNull);
      }
    });
  });
}

