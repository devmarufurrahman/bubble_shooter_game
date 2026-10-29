import 'dart:math';
import 'package:flame/components.dart';
import '../../data/models/bubble_type.dart';
import '../components/bubble_component.dart';
import '../components/grid_manager.dart';
import 'hex_math.dart';
import 'match_engine.dart';

/// Puzzle resolution facade providing Hex math, BFS Match-3 flood-fill,
/// and floating orphan bubble detection.
class MatchChecker {
  const MatchChecker._();

  /// Calculates valid hexagonal neighbor coordinates in an Odd-r horizontal layout.
  static List<Point<int>> getHexNeighbors({
    required int row,
    required int col,
    required int maxRows,
    required int evenColumns,
    required int oddColumns,
  }) =>
      HexMath.getNeighborPoints(
        row: row,
        col: col,
        maxRows: maxRows,
        evenCols: evenColumns,
        oddCols: oddColumns,
      );

  /// Traverses contiguous clusters of matching [targetColor] starting from
  /// cell ([startRow], [startCol]) via Breadth-First Search (BFS).
  static List<Point<int>> findMatches(
    int startRow,
    int startCol,
    BubbleType targetColor,
    GridManager grid,
  ) =>
      MatchEngine.findMatches(
        startRow: startRow,
        startCol: startCol,
        targetType: targetColor,
        getBubbleTypeAt: (r, c) => grid.getBubbleAt(r, c)?.bubbleType,
        maxRows: grid.maxRows,
        evenCols: grid.evenColumns,
        oddCols: grid.oddColumns,
      );

  /// Discovers all bubbles that remain structurally anchored to Row 0.
  static Set<Point<int>> findAnchoredBubbles(GridManager grid) =>
      MatchEngine.findConnectedToCeiling(
        isOccupied: (r, c) => grid.isCellOccupied(r, c),
        maxRows: grid.maxRows,
        evenCols: grid.evenColumns,
        oddCols: grid.oddColumns,
      );

  /// Identifies all floating orphan bubbles that have become disconnected from the ceiling.
  static List<Point<int>> findFloatingBubbles(GridManager grid) =>
      MatchEngine.findFloatingBubbles(
        isOccupied: (r, c) => grid.isCellOccupied(r, c),
        maxRows: grid.maxRows,
        evenCols: grid.evenColumns,
        oddCols: grid.oddColumns,
      );

  /// Detaches all floating disconnected bubbles from [grid] and initiates
  /// their falling animation directly on the same [BubbleComponent] instances.
  static List<BubbleComponent> dropFloatingBubbles(
    GridManager grid, [
    Component? world,
  ]) =>
      grid.dropFloatingBubbles();
}
