import 'dart:collection';
import 'dart:math' show Point;
import '../../data/models/bubble_type.dart';
import 'hex_math.dart';

/// Pure algorithmic engine handling Match-3 BFS flood-fill,
/// ceiling anchor reachability, and orphan bubble drop detection.
class MatchEngine {
  MatchEngine._();

  /// Executes BFS flood-fill to find all contiguous matching bubbles of [targetType]
  /// starting from cell coordinate ([startRow], [startCol]).
  static List<Point<int>> findMatches({
    required int startRow,
    required int startCol,
    required BubbleType targetType,
    required BubbleType? Function(int r, int c) getBubbleTypeAt,
    int maxRows = 14,
    int evenCols = 8,
    int oddCols = 7,
  }) {
    final List<Point<int>> matches = [];
    final Set<Point<int>> visited = {};
    final Queue<Point<int>> queue = Queue<Point<int>>();

    final Point<int> start = Point(startRow, startCol);
    queue.add(start);
    visited.add(start);

    while (queue.isNotEmpty) {
      final Point<int> current = queue.removeFirst();
      final BubbleType? currentType = getBubbleTypeAt(current.x, current.y);

      if (currentType == targetType) {
        matches.add(current);

        final List<Point<int>> neighbors = HexMath.getNeighborPoints(
          row: current.x,
          col: current.y,
          maxRows: maxRows,
          evenCols: evenCols,
          oddCols: oddCols,
        );

        for (final Point<int> neighbor in neighbors) {
          if (!visited.contains(neighbor)) {
            visited.add(neighbor);
            final BubbleType? nType = getBubbleTypeAt(neighbor.x, neighbor.y);
            if (nType == targetType) {
              queue.add(neighbor);
            }
          }
        }
      }
    }

    return matches;
  }

  /// Traverses the grid starting from Row 0 to discover all occupied bubbles
  /// that are structurally connected to the ceiling anchor.
  static Set<Point<int>> findConnectedToCeiling({
    required bool Function(int r, int c) isOccupied,
    int maxRows = 14,
    int evenCols = 8,
    int oddCols = 7,
  }) {
    final Set<Point<int>> anchored = {};
    final Queue<Point<int>> queue = Queue<Point<int>>();

    // Seed BFS with all occupied bubbles in Row 0 (ceiling)
    final int topCols = HexMath.getColumnsForRow(0, evenCols: evenCols, oddCols: oddCols);
    for (int col = 0; col < topCols; col++) {
      if (isOccupied(0, col)) {
        final Point<int> root = Point(0, col);
        queue.add(root);
        anchored.add(root);
      }
    }

    // Traverse all structural neighbors
    while (queue.isNotEmpty) {
      final Point<int> current = queue.removeFirst();
      final List<Point<int>> neighbors = HexMath.getNeighborPoints(
        row: current.x,
        col: current.y,
        maxRows: maxRows,
        evenCols: evenCols,
        oddCols: oddCols,
      );

      for (final Point<int> neighbor in neighbors) {
        if (!anchored.contains(neighbor) && isOccupied(neighbor.x, neighbor.y)) {
          anchored.add(neighbor);
          queue.add(neighbor);
        }
      }
    }

    return anchored;
  }

  /// Identifies all occupied bubbles that are disconnected from the ceiling anchor.
  static List<Point<int>> findFloatingBubbles({
    required bool Function(int r, int c) isOccupied,
    int maxRows = 14,
    int evenCols = 8,
    int oddCols = 7,
  }) {
    final Set<Point<int>> anchored = findConnectedToCeiling(
      isOccupied: isOccupied,
      maxRows: maxRows,
      evenCols: evenCols,
      oddCols: oddCols,
    );

    final List<Point<int>> floating = [];

    for (int r = 0; r < maxRows; r++) {
      final int cols = HexMath.getColumnsForRow(r, evenCols: evenCols, oddCols: oddCols);
      for (int c = 0; c < cols; c++) {
        final Point<int> cell = Point(r, c);
        if (isOccupied(r, c) && !anchored.contains(cell)) {
          floating.add(cell);
        }
      }
    }

    return floating;
  }
}
