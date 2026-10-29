import 'dart:math';
import 'package:flame/components.dart';
import '../components/bubble_color.dart';
import '../components/falling_bubble_component.dart';
import '../components/grid_manager.dart';

/// Core puzzle resolution engine providing Odd-r hexagonal topology,
/// Breadth-First Search (BFS) Match-3 flood-fill, and floating orphan detection.
class MatchChecker {
  const MatchChecker._();

  /// Calculates valid hexagonal neighbor coordinates in an Odd-r horizontal layout.
  ///
  /// - Even Row r: [(r-1, c-1), (r-1, c), (r, c-1), (r, c+1), (r+1, c-1), (r+1, c)]
  /// - Odd Row r:  [(r-1, c), (r-1, c+1), (r, c-1), (r, c+1), (r+1, c), (r+1, c+1)]
  static List<Point<int>> getHexNeighbors({
    required int row,
    required int col,
    required int maxRows,
    required int evenColumns,
    required int oddColumns,
  }) {
    final List<Point<int>> candidates = [];
    final bool isEven = (row % 2 == 0);

    if (isEven) {
      candidates.add(Point(row - 1, col - 1)); // Top-Left
      candidates.add(Point(row - 1, col));     // Top-Right
      candidates.add(Point(row, col - 1));     // Left
      candidates.add(Point(row, col + 1));     // Right
      candidates.add(Point(row + 1, col - 1)); // Bottom-Left
      candidates.add(Point(row + 1, col));     // Bottom-Right
    } else {
      candidates.add(Point(row - 1, col));     // Top-Left
      candidates.add(Point(row - 1, col + 1)); // Top-Right
      candidates.add(Point(row, col - 1));     // Left
      candidates.add(Point(row, col + 1));     // Right
      candidates.add(Point(row + 1, col));     // Bottom-Left
      candidates.add(Point(row + 1, col + 1)); // Bottom-Right
    }

    // Filter to valid board boundaries
    return candidates.where((p) {
      if (p.x < 0 || p.x >= maxRows) return false;
      final int maxCols = (p.x % 2 == 0) ? evenColumns : oddColumns;
      return p.y >= 0 && p.y < maxCols;
    }).toList();
  }

  /// Traverses contiguous clusters of matching [targetColor] starting from
  /// cell ([startRow], [startCol]) via Breadth-First Search (BFS).
  static List<Point<int>> findMatches(
    int startRow,
    int startCol,
    BubbleType targetColor,
    GridManager grid,
  ) {
    final List<Point<int>> matches = [];
    final Set<Point<int>> visited = {};
    final List<Point<int>> queue = [];

    final Point<int> startPoint = Point<int>(startRow, startCol);
    final startBubble = grid.getBubbleAt(startRow, startCol);

    if (startBubble == null || startBubble.bubbleType != targetColor) {
      return matches;
    }

    visited.add(startPoint);
    queue.add(startPoint);

    while (queue.isNotEmpty) {
      final Point<int> current = queue.removeAt(0);
      final bubble = grid.getBubbleAt(current.x, current.y);

      if (bubble == null || bubble.bubbleType != targetColor) {
        continue;
      }

      matches.add(current);

      final List<Point<int>> neighbors = getHexNeighbors(
        row: current.x,
        col: current.y,
        maxRows: grid.maxRows,
        evenColumns: grid.evenColumns,
        oddColumns: grid.oddColumns,
      );

      for (final Point<int> n in neighbors) {
        if (!visited.contains(n)) {
          visited.add(n);
          final neighborBubble = grid.getBubbleAt(n.x, n.y);
          if (neighborBubble != null && neighborBubble.bubbleType == targetColor) {
            queue.add(n);
          }
        }
      }
    }

    return matches;
  }

  /// Identifies all floating / disconnected bubbles not anchored to Row 0 (the ceiling).
  static List<Point<int>> findFloatingBubbles(GridManager grid) {
    final Set<Point<int>> anchored = {};
    final List<Point<int>> queue = [];

    // 1. Gather all bubbles directly touching the ceiling (Row 0)
    final int row0Cols = grid.getColumnsForRow(0);
    for (int col = 0; col < row0Cols; col++) {
      if (grid.isCellOccupied(0, col)) {
        final Point<int> pt = Point(0, col);
        anchored.add(pt);
        queue.add(pt);
      }
    }

    // 2. BFS flood-fill from Row 0 to mark all connected chains
    while (queue.isNotEmpty) {
      final Point<int> current = queue.removeAt(0);

      final List<Point<int>> neighbors = getHexNeighbors(
        row: current.x,
        col: current.y,
        maxRows: grid.maxRows,
        evenColumns: grid.evenColumns,
        oddColumns: grid.oddColumns,
      );

      for (final Point<int> n in neighbors) {
        if (!anchored.contains(n) && grid.isCellOccupied(n.x, n.y)) {
          anchored.add(n);
          queue.add(n);
        }
      }
    }

    // 3. Any occupied bubble not in the anchored set is disconnected
    final List<Point<int>> floating = [];
    for (int r = 1; r < grid.maxRows; r++) {
      final int cols = grid.getColumnsForRow(r);
      for (int c = 0; c < cols; c++) {
        if (grid.isCellOccupied(r, c) && !anchored.contains(Point(r, c))) {
          floating.add(Point(r, c));
        }
      }
    }

    return floating;
  }

  /// Detaches all disconnected bubbles from [grid], adds physics-driven
  /// [FallingBubbleComponent]s to [world], and returns the spawned falling components.
  static List<FallingBubbleComponent> dropFloatingBubbles(
    GridManager grid,
    Component world,
  ) {
    final List<Point<int>> floatingCoords = findFloatingBubbles(grid);
    final List<FallingBubbleComponent> falling = [];

    for (final Point<int> pt in floatingCoords) {
      final detached = grid.detachBubbleAt(pt.x, pt.y);
      if (detached != null) {
        detached.removeFromParent();

        final fallingBubble = FallingBubbleComponent(
          bubbleType: detached.bubbleType,
          radius: detached.radius,
          startPosition: detached.position,
        );

        world.add(fallingBubble);
        falling.add(fallingBubble);
      }
    }

    return falling;
  }
}

