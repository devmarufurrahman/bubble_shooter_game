import 'dart:math' as math;
import 'package:flame/components.dart';

/// Point representation for integer grid coordinates.
class GridCoord {
  final int row;
  final int col;
  const GridCoord(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridCoord &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'GridCoord(row: $row, col: $col)';

  math.Point<int> toPoint() => math.Point(row, col);
}

/// Pure, decoupled mathematical utility class for Odd-r staggered hexagonal grid layout,
/// coordinate conversions, distance calculations, and snap resolution.
class HexMath {
  const HexMath._();

  static const double sqrt3 = 1.7320508075688772;

  /// Returns true if [row] is an even row index (0, 2, 4...).
  static bool isRowEven(int row) => (row % 2) == 0;

  /// Returns column budget for [row]: [evenCols] for even rows, [oddCols] for odd rows.
  static int getColumnsForRow(int row, {int evenCols = 8, int oddCols = 7}) {
    return isRowEven(row) ? evenCols : oddCols;
  }

  /// Calculates absolute (x, y) canvas center coordinate for a cell at ([row], [col]).
  static Vector2 getCanvasPosition({
    required int row,
    required int col,
    required double radius,
    required double topOffset,
  }) {
    final double diameter = 2 * radius;
    final double x = isRowEven(row)
        ? (col * diameter) + radius
        : (col * diameter) + diameter;
    final double y = topOffset + (row * (radius * sqrt3));
    return Vector2(x, y);
  }

  /// Calculates Euclidean distance between two 2D positions.
  static double distance(Vector2 a, Vector2 b) {
    final double dx = a.x - b.x;
    final double dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Retrieves all 6 hex neighbor coordinates in Odd-r horizontal offset grid as [GridCoord]s.
  static List<GridCoord> getNeighbors({
    required int row,
    required int col,
    int maxRows = 14,
    int evenCols = 8,
    int oddCols = 7,
  }) {
    final List<GridCoord> offsets = isRowEven(row)
        ? const [
            GridCoord(-1, -1), // Top-Left
            GridCoord(-1, 0),  // Top-Right
            GridCoord(0, -1),  // West
            GridCoord(0, 1),   // East
            GridCoord(1, -1),  // Bottom-Left
            GridCoord(1, 0),   // Bottom-Right
          ]
        : const [
            GridCoord(-1, 0),  // Top-Left
            GridCoord(-1, 1),  // Top-Right
            GridCoord(0, -1),  // West
            GridCoord(0, 1),   // East
            GridCoord(1, 0),   // Bottom-Left
            GridCoord(1, 1),   // Bottom-Right
          ];

    final List<GridCoord> valid = [];
    for (final offset in offsets) {
      final int nr = row + offset.row;
      final int nc = col + offset.col;
      if (isValidCell(nr, nc, maxRows: maxRows, evenCols: evenCols, oddCols: oddCols)) {
        valid.add(GridCoord(nr, nc));
      }
    }
    return valid;
  }

  /// Retrieves all 6 hex neighbor coordinates as [math.Point<int>]s.
  static List<math.Point<int>> getNeighborPoints({
    required int row,
    required int col,
    int maxRows = 14,
    int evenCols = 8,
    int oddCols = 7,
  }) {
    return getNeighbors(
      row: row,
      col: col,
      maxRows: maxRows,
      evenCols: evenCols,
      oddCols: oddCols,
    ).map((c) => math.Point(c.row, c.col)).toList();
  }

  /// Validates whether ([row], [col]) lies strictly within grid bounds.
  static bool isValidCell(
    int row,
    int col, {
    int maxRows = 14,
    int evenCols = 8,
    int oddCols = 7,
  }) {
    if (row < 0 || row >= maxRows) return false;
    final int cols = getColumnsForRow(row, evenCols: evenCols, oddCols: oddCols);
    return col >= 0 && col < cols;
  }

  /// Calculates optimal empty snap cell for a bullet projectile at [impactPosition].
  static GridCoord findBestSnapCell({
    required Vector2 impactPosition,
    required double radius,
    required double topOffset,
    required bool Function(int r, int c) isOccupied,
    GridCoord? hitCell,
    int maxRows = 14,
    int evenCols = 8,
    int oddCols = 7,
  }) {
    // 1. Ceiling hit with no bubble collision
    if (hitCell == null) {
      final int row0Cols = getColumnsForRow(0, evenCols: evenCols, oddCols: oddCols);
      int bestCol = 0;
      double minDistance = double.infinity;

      for (int c = 0; c < row0Cols; c++) {
        if (!isOccupied(0, c)) {
          final Vector2 cellPos = getCanvasPosition(
            row: 0,
            col: c,
            radius: radius,
            topOffset: topOffset,
          );
          final double dist = distance(cellPos, impactPosition);
          if (dist < minDistance) {
            minDistance = dist;
            bestCol = c;
          }
        }
      }
      return GridCoord(0, bestCol);
    }

    // 2. Bubble collision: check all empty neighbors around hitCell
    final List<GridCoord> neighbors = getNeighbors(
      row: hitCell.row,
      col: hitCell.col,
      maxRows: maxRows,
      evenCols: evenCols,
      oddCols: oddCols,
    );

    final List<GridCoord> emptyNeighbors =
        neighbors.where((n) => !isOccupied(n.row, n.col)).toList();

    if (emptyNeighbors.isNotEmpty) {
      GridCoord best = emptyNeighbors.first;
      double minDistance = double.infinity;

      for (final n in emptyNeighbors) {
        final Vector2 cellPos = getCanvasPosition(
          row: n.row,
          col: n.col,
          radius: radius,
          topOffset: topOffset,
        );
        final double dist = distance(cellPos, impactPosition);
        if (dist < minDistance) {
          minDistance = dist;
          best = n;
        }
      }
      return best;
    }

    // 3. Fallback: find any nearest unoccupied cell
    GridCoord fallback = const GridCoord(0, 0);
    double minDistance = double.infinity;

    for (int r = 0; r < maxRows; r++) {
      final int cols = getColumnsForRow(r, evenCols: evenCols, oddCols: oddCols);
      for (int c = 0; c < cols; c++) {
        if (!isOccupied(r, c)) {
          final Vector2 cellPos = getCanvasPosition(
            row: r,
            col: c,
            radius: radius,
            topOffset: topOffset,
          );
          final double dist = distance(cellPos, impactPosition);
          if (dist < minDistance) {
            minDistance = dist;
            fallback = GridCoord(r, c);
          }
        }
      }
    }

    return fallback;
  }
}
