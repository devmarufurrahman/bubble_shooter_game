import 'dart:math' as math;
import 'package:flame/components.dart';
import 'bubble_color.dart';
import 'bubble_component.dart';

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

  /// Removes and detaches the bubble at [row], [col] if present.
  void removeBubbleAt(int row, int col) {
    if (row < 0 || row >= maxRows) return;
    final int cols = getColumnsForRow(row);
    if (col < 0 || col >= cols) return;

    final BubbleComponent? bubble = _grid[row][col];
    if (bubble != null) {
      bubble.removeFromParent();
      _grid[row][col] = null;
    }
  }

  /// Retrieves the bubble at [row], [col] or null if cell is empty or out of bounds.
  BubbleComponent? getBubbleAt(int row, int col) {
    if (row < 0 || row >= maxRows) return null;
    final int cols = getColumnsForRow(row);
    if (col < 0 || col >= cols) return null;
    return _grid[row][col];
  }

  /// Populates the grid using raw level matrix data.
  /// [levelGridData] contains rows of integers representing [BubbleType] indices.
  /// Values outside [0, 4] represent empty cells.
  void populateInitialGrid(List<List<int>> levelGridData) {
    clear();

    for (int r = 0; r < levelGridData.length && r < maxRows; r++) {
      final List<int> rowData = levelGridData[r];
      final int maxCols = getColumnsForRow(r);

      for (int c = 0; c < rowData.length && c < maxCols; c++) {
        final int typeIndex = rowData[c];
        if (typeIndex >= 0 && typeIndex < BubbleType.values.length) {
          final BubbleComponent bubble = BubbleComponent(
            row: r,
            col: c,
            bubbleType: BubbleType.values[typeIndex],
            radius: radius,
          );
          setBubbleAt(r, c, bubble);
        }
      }
    }
  }

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

