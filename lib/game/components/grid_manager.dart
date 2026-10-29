import 'dart:math' show Point;
import 'package:flame/components.dart';
import '../../core/audio/audio.dart';
import '../../core/utils/utils.dart';
import '../../data/models/bubble_type.dart';
import '../logic/hex_math.dart';
import '../logic/match_engine.dart';
import 'bubble_component.dart';
import 'bullet_bubble.dart';

export '../logic/hex_math.dart' show GridCoord;

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

  /// Tracks active falling bubbles during drop sequences.
  final List<BubbleComponent> _fallingBubbles = [];

  /// Returns the top ceiling boundary Y coordinate touching the top edge of row 0 bubbles.
  double get ceilingY => topOffset - radius;

  /// Returns the column capacity for a given [row] index.
  int getColumnsForRow(int row) =>
      HexMath.getColumnsForRow(row, evenCols: evenColumns, oddCols: oddColumns);

  /// Calculates the absolute canvas (x, y) center position for cell [row], [col]
  /// following Odd-r staggered hexagonal mathematics.
  Vector2 getCanvasPosition(int row, int col) => HexMath.getCanvasPosition(
        row: row,
        col: col,
        radius: radius,
        topOffset: topOffset,
      );

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

  /// Batches the popping of matched bubbles:
  /// - Dispatches exactly ONE sound trigger and ONE haptic impulse for the entire cluster.
  /// - Detaches all matched bubbles from the matrix and initiates their pop animation.
  /// - Returns the list of popped [BubbleComponent] instances.
  List<BubbleComponent> batchPopMatches(List<Point<int>> matches) {
    if (matches.isEmpty) return const [];

    // Trigger exactly ONE audio and ONE haptic impulse for the whole cluster
    SoundManager.instance.playPop();
    HapticsHelper.lightImpact();

    final List<BubbleComponent> popped = [];
    for (final Point<int> pt in matches) {
      final BubbleComponent? bubble = detachBubbleAt(pt.x, pt.y);
      if (bubble != null) {
        bubble.pop();
        popped.add(bubble);
      }
    }
    return popped;
  }

  /// Retrieves the bubble at [row], [col] or null if cell is empty or out of bounds.
  BubbleComponent? getBubbleAt(int row, int col) {
    if (row < 0 || row >= maxRows) return null;
    final int cols = getColumnsForRow(row);
    if (col < 0 || col >= cols) return null;
    return _grid[row][col];
  }

  /// Discovers all floating bubbles that have become disconnected from the ceiling anchor.
  List<Point<int>> findFloatingBubbles() => MatchEngine.findFloatingBubbles(
        isOccupied: isCellOccupied,
        maxRows: maxRows,
        evenCols: evenColumns,
        oddCols: oddColumns,
      );

  /// Discovers all disconnected orphan bubbles via BFS ceiling traversal,
  /// detaches them from the grid matrix immediately, and initiates their falling animation.
  /// Eliminates ghost duplicates by animating the exact same BubbleComponent instances.
  List<BubbleComponent> dropFloatingBubbles() {
    final List<Point<int>> floating = findFloatingBubbles();
    final List<BubbleComponent> dropped = [];

    for (final Point<int> pt in floating) {
      final BubbleComponent? bubble = _grid[pt.x][pt.y];
      // CRITICAL: Immediately clear data reference so grid no longer considers this cell occupied
      _grid[pt.x][pt.y] = null;

      if (bubble != null) {
        bubble.dropAsFloating();
        _fallingBubbles.add(bubble);
        dropped.add(bubble);
      }
    }

    return dropped;
  }

  /// Whether any active bubbles remain anchored on the grid matrix.
  bool get hasAnyBubblesOnGrid => _grid.any((row) => row.any((b) => b != null));

  /// Whether any bubbles are actively falling down the screen.
  bool get hasFallingBubbles {
    _fallingBubbles.removeWhere((b) => !b.isDropping || (!b.isMounted && b.parent == null));
    return children.whereType<BubbleComponent>().any((b) => b.isDropping) ||
        _fallingBubbles.isNotEmpty;
  }

  /// Evaluates Euclidean distance to identify the optimal empty hexagonal grid
  /// cell to anchor an incoming projectile at [impactPosition].
  GridCoord findBestSnapCell(Vector2 impactPosition, BubbleComponent? hitBubble) =>
      HexMath.findBestSnapCell(
        impactPosition: impactPosition,
        radius: radius,
        topOffset: topOffset,
        isOccupied: isCellOccupied,
        hitCell: hitBubble != null ? GridCoord(hitBubble.row, hitBubble.col) : null,
        maxRows: maxRows,
        evenCols: evenColumns,
        oddCols: oddColumns,
      );

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
  bool get allBubblesCleared => !hasAnyBubblesOnGrid && !hasFallingBubbles;

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
    // Also remove any active falling bubbles
    children.whereType<BubbleComponent>().where((b) => b.isDropping).toList().forEach(
      (b) => b.removeFromParent(),
    );
    _fallingBubbles.clear();
  }

  /// Returns the 6 adjacent hexagonal neighbor coordinates in Odd-r horizontal layout.
  List<GridCoord> getNeighbors(int row, int col) => HexMath.getNeighbors(
        row: row,
        col: col,
        maxRows: maxRows,
        evenCols: evenColumns,
        oddCols: oddColumns,
      );

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
