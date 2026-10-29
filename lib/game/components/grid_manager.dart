import 'dart:math' as math;
import 'package:flame/components.dart';
import 'bubble_color.dart';
import 'bubble_component.dart';
import 'bullet_bubble.dart';

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
}

/// Flame Component managing the Odd-r staggered hexagonal bubble grid.
///
/// Grid specifications:
/// - Virtual screen width budget: 400 logical pixels.
/// - Even rows (0, 2, 4...): 8 columns. X = col * (2 * r) + r
/// - Odd rows (1, 3, 5...): 7 columns. X = col * (2 * r) + (2 * r)
/// - Y coordinate spacing = topOffset + row * (r * sqrt(3))
class GridManager extends Component {
  GridManager({
    this.radius = 25.0,
    this.topOffset = 60.0,
    this.maxRows = 14,
    this.evenColumns = 8,
    this.oddColumns = 7,
  }) {
    _grid = List.generate(
      maxRows,
      (row) => List<BubbleComponent?>.filled(getColumnsForRow(row), null),
    );
  }

  /// Bubble radius (defaults to 25.0 for a 400-pixel width budget).
  final double radius;

  /// Top canvas offset where row 0 bubble centers are positioned.
  final double topOffset;

  /// Maximum vertical capacity of the game board.
  final int maxRows;

  /// Number of columns in even rows (0, 2, 4...).
  final int evenColumns;

  /// Number of columns in odd rows (1, 3, 5...).
  final int oddColumns;

  /// Dynamic 2D matrix storing active bubbles.
  late final List<List<BubbleComponent?>> _grid;

  /// Returns the top ceiling boundary Y coordinate touching the top edge of row 0 bubbles.
  double get ceilingY => topOffset - radius;

  /// Returns the column capacity for a given [row] index.
  int getColumnsForRow(int row) => (row % 2 == 0) ? evenColumns : oddColumns;

  /// Calculates the absolute canvas (x, y) center position for cell [row], [col]
  /// following Odd-r staggered hexagonal mathematics.
  Vector2 getCanvasPosition(int row, int col) {
    final double x = (row % 2 == 0)
        ? (col * (2 * radius)) + radius
        : (col * (2 * radius)) + (2 * radius);
    final double y = topOffset + (row * (radius * math.sqrt(3)));
    return Vector2(x, y);
  }

  /// Checks whether cell [row], [col] is currently occupied by a bubble.
  bool isCellOccupied(int row, int col) {
    if (row < 0 || row >= maxRows) return false;
    final int cols = getColumnsForRow(row);
    if (col < 0 || col >= cols) return false;
    return _grid[row][col] != null;
  }

  /// Places [bubble] at grid coordinate [row], [col], updates its internal
  /// coordinates, positions it on canvas, and attaches it as a child component.
  void setBubbleAt(int row, int col, BubbleComponent bubble) {
    if (row < 0 || row >= maxRows) return;
    final int cols = getColumnsForRow(row);
    if (col < 0 || col >= cols) return;

    // Displace existing bubble if present
    final BubbleComponent? existing = _grid[row][col];
    if (existing != null && existing != bubble) {
      existing.removeFromParent();
    }

    bubble.row = row;
    bubble.col = col;
    bubble.position = getCanvasPosition(row, col);

    if (bubble.parent == null) {
      add(bubble);
    }

    _grid[row][col] = bubble;
  }

  /// Clears the grid cell reference without immediately removing the component
  /// from the Flame tree, allowing custom animations (such as popping) to complete.
  BubbleComponent? detachBubbleAt(int row, int col) {
    if (row < 0 || row >= maxRows) return null;
    final int cols = getColumnsForRow(row);
    if (col < 0 || col >= cols) return null;

    final BubbleComponent? bubble = _grid[row][col];
    _grid[row][col] = null;
    return bubble;
  }

  /// Removes and detaches the bubble at [row], [col] if present.
  void removeBubbleAt(int row, int col) {
    final BubbleComponent? bubble = detachBubbleAt(row, col);
    bubble?.removeFromParent();
  }

  /// Retrieves the bubble at [row], [col] or null if cell is empty or out of bounds.
  BubbleComponent? getBubbleAt(int row, int col) {
    if (row < 0 || row >= maxRows) return null;
    final int cols = getColumnsForRow(row);
    if (col < 0 || col >= cols) return null;
    return _grid[row][col];
  }

  /// Evaluates Euclidean distance to identify the optimal empty hexagonal grid
  /// cell to anchor an incoming projectile at [impactPosition].
  GridCoord findBestSnapCell(Vector2 impactPosition, BubbleComponent? hitBubble) {
    if (hitBubble == null) {
      // Ceiling impact with no bubble: search empty slots in Row 0
      final int row0Cols = getColumnsForRow(0);
      int bestCol = 0;
      double minDistance = double.infinity;

      for (int c = 0; c < row0Cols; c++) {
        if (!isCellOccupied(0, c)) {
          final Vector2 cellPos = getCanvasPosition(0, c);
          final double dist = (cellPos - impactPosition).length;
          if (dist < minDistance) {
            minDistance = dist;
            bestCol = c;
          }
        }
      }
      return GridCoord(0, bestCol);
    }

    // Bubble collision: check all empty neighbors around hitBubble
    final List<GridCoord> neighbors = getNeighbors(hitBubble.row, hitBubble.col);
    final List<GridCoord> emptyNeighbors =
        neighbors.where((n) => !isCellOccupied(n.row, n.col)).toList();

    if (emptyNeighbors.isNotEmpty) {
      GridCoord best = emptyNeighbors.first;
      double minDistance = double.infinity;

      for (final GridCoord n in emptyNeighbors) {
        final Vector2 cellPos = getCanvasPosition(n.row, n.col);
        final double dist = (cellPos - impactPosition).length;
        if (dist < minDistance) {
          minDistance = dist;
          best = n;
        }
      }
      return best;
    }

    // Fallback: search all available empty cells in the grid closest to impact
    GridCoord fallback = const GridCoord(0, 0);
    double minDistance = double.infinity;

    for (int r = 0; r < maxRows; r++) {
      final int cols = getColumnsForRow(r);
      for (int c = 0; c < cols; c++) {
        if (!isCellOccupied(r, c)) {
          final Vector2 cellPos = getCanvasPosition(r, c);
          final double dist = (cellPos - impactPosition).length;
          if (dist < minDistance) {
            minDistance = dist;
            fallback = GridCoord(r, c);
          }
        }
      }
    }

    return fallback;
  }

  /// Snaps [bullet] into the optimal empty grid cell, creates a static [BubbleComponent],
  /// attaches it to the board, and removes the dynamic projectile.
  BubbleComponent snapBulletToGrid({
    required BulletBubble bullet,
    BubbleComponent? hitBubble,
  }) {
    final GridCoord snapCoord = findBestSnapCell(bullet.position, hitBubble);
    final BubbleComponent newBubble = BubbleComponent(
      row: snapCoord.row,
      col: snapCoord.col,
      bubbleType: bullet.bubbleType,
      radius: radius,
    );

    setBubbleAt(snapCoord.row, snapCoord.col, newBubble);
    bullet.removeFromParent();
    return newBubble;
  }

  /// Populates the grid using level matrix data.
  /// If [oneBased] is true (or matrix contains 5), format is 0: empty, 1..5: BubbleType.
  /// Otherwise, format is 0-based index (0..4).
  void populateInitialGrid(List<List<int>> levelGridData, {bool? oneBased}) {
    clear();

    final bool isOneBased =
        oneBased ?? levelGridData.any((row) => row.any((v) => v >= 5));

    for (int r = 0; r < levelGridData.length && r < maxRows; r++) {
      final List<int> rowData = levelGridData[r];
      final int maxCols = getColumnsForRow(r);

      for (int c = 0; c < rowData.length && c < maxCols; c++) {
        final int rawVal = rowData[c];
        BubbleType? type;

        if (isOneBased) {
          if (rawVal >= 1 && rawVal <= BubbleType.values.length) {
            type = BubbleType.values[rawVal - 1];
          }
        } else {
          if (rawVal >= 0 && rawVal < BubbleType.values.length) {
            type = BubbleType.values[rawVal];
          }
        }

        if (type != null) {
          final BubbleComponent bubble = BubbleComponent(
            row: r,
            col: c,
            bubbleType: type,
            radius: radius,
          );
          setBubbleAt(r, c, bubble);
        }
      }
    }
  }

  /// Whether all bubbles on the board have been cleared (Win condition).
  bool get allBubblesCleared => totalActiveBubbles == 0;

  /// Clears all bubbles from the board and removes them from the component tree.
  void clear() {
    for (int r = 0; r < maxRows; r++) {
      final int cols = getColumnsForRow(r);
      for (int c = 0; c < cols; c++) {
        final BubbleComponent? bubble = _grid[r][c];
        if (bubble != null) {
          bubble.removeFromParent();
          _grid[r][c] = null;
        }
      }
    }
  }

  /// Returns the 6 adjacent hexagonal neighbor coordinates in Odd-r horizontal layout.
  List<GridCoord> getNeighbors(int row, int col) {
    final List<GridCoord> neighbors = [];

    // Left and Right
    neighbors.add(GridCoord(row, col - 1));
    neighbors.add(GridCoord(row, col + 1));

    if (row % 2 == 0) {
      // Even row: top and bottom shifted left
      neighbors.add(GridCoord(row - 1, col - 1));
      neighbors.add(GridCoord(row - 1, col));
      neighbors.add(GridCoord(row + 1, col - 1));
      neighbors.add(GridCoord(row + 1, col));
    } else {
      // Odd row: top and bottom shifted right
      neighbors.add(GridCoord(row - 1, col));
      neighbors.add(GridCoord(row - 1, col + 1));
      neighbors.add(GridCoord(row + 1, col));
      neighbors.add(GridCoord(row + 1, col + 1));
    }

    // Filter valid grid bounds
    return neighbors.where((n) {
      if (n.row < 0 || n.row >= maxRows) return false;
      final int cols = getColumnsForRow(n.row);
      return n.col >= 0 && n.col < cols;
    }).toList();
  }

  /// Returns a flat list of all active non-null bubbles currently on the grid.
  List<BubbleComponent> get activeBubbles {
    final List<BubbleComponent> result = [];
    for (int r = 0; r < maxRows; r++) {
      final int cols = getColumnsForRow(r);
      for (int c = 0; c < cols; c++) {
        final BubbleComponent? b = _grid[r][c];
        if (b != null) {
          result.add(b);
        }
      }
    }
    return result;
  }

  /// Returns total count of occupied bubbles on the board.
  int get totalActiveBubbles => activeBubbles.length;
}
