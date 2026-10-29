import '../game/components/bubble_color.dart';

/// Configuration model representing the difficulty, shot capacity,
/// active color palette, and initial layout of a stage.
class LevelConfig {
  final int levelNumber;
  final int maxShots;
  final List<BubbleType> availableColors;
  final List<List<int>> initialGrid;

  const LevelConfig({
    required this.levelNumber,
    required this.maxShots,
    required this.availableColors,
    required this.initialGrid,
  });

  /// Converts a grid matrix integer to its corresponding [BubbleType].
  ///
  /// Matrix values:
  /// - 0: Empty cell
  /// - 1: Red
  /// - 2: Blue
  /// - 3: Green
  /// - 4: Yellow
  /// - 5: Purple
  static BubbleType? bubbleTypeFromInt(int value) {
    switch (value) {
      case 1:
        return BubbleType.red;
      case 2:
        return BubbleType.blue;
      case 3:
        return BubbleType.green;
      case 4:
        return BubbleType.yellow;
      case 5:
        return BubbleType.purple;
      default:
        return null;
    }
  }

  /// Retrieves the [LevelConfig] for [levelNumber] (clamped between 1 and 10).
  static LevelConfig getLevel(int levelNumber) {
    final int index = (levelNumber - 1).clamp(0, levels.length - 1);
    return levels[index];
  }

  /// Complete list of 10 progressive arcade levels.
  static const List<LevelConfig> levels = [
    // Level 1: Gentle Introduction (3 colors, 3 rows, 30 shots)
    LevelConfig(
      levelNumber: 1,
      maxShots: 30,
      availableColors: [BubbleType.red, BubbleType.blue, BubbleType.green],
      initialGrid: [
        [1, 1, 2, 2, 3, 3, 1, 1], // Row 0 (8)
        [2, 2, 3, 3, 1, 1, 2],    // Row 1 (7)
        [3, 3, 1, 1, 2, 2, 3, 3], // Row 2 (8)
      ],
    ),

    // Level 2: Horizontal Stripes (3 colors, 4 rows, 28 shots)
    LevelConfig(
      levelNumber: 2,
      maxShots: 28,
      availableColors: [BubbleType.red, BubbleType.blue, BubbleType.green],
      initialGrid: [
        [1, 1, 1, 1, 2, 2, 2, 2], // Row 0 (8)
        [3, 3, 3, 1, 1, 1, 1],    // Row 1 (7)
        [2, 2, 2, 2, 3, 3, 3, 3], // Row 2 (8)
        [1, 1, 2, 2, 3, 3, 1],    // Row 3 (7)
      ],
    ),

    // Level 3: Checkerboard Pattern (4 colors, 4 rows, 26 shots)
    LevelConfig(
      levelNumber: 3,
      maxShots: 26,
      availableColors: [BubbleType.red, BubbleType.blue, BubbleType.green, BubbleType.yellow],
      initialGrid: [
        [4, 1, 4, 1, 2, 3, 2, 3], // Row 0 (8)
        [1, 4, 1, 3, 2, 3, 2],    // Row 1 (7)
        [4, 4, 1, 1, 2, 2, 3, 3], // Row 2 (8)
        [2, 3, 4, 1, 4, 1, 2],    // Row 3 (7)
      ],
    ),

    // Level 4: V-Shaped Chevrons (4 colors, 5 rows, 24 shots)
    LevelConfig(
      levelNumber: 4,
      maxShots: 24,
      availableColors: [BubbleType.red, BubbleType.blue, BubbleType.green, BubbleType.yellow],
      initialGrid: [
        [1, 2, 3, 4, 4, 3, 2, 1], // Row 0 (8)
        [2, 3, 4, 0, 4, 3, 2],    // Row 1 (7)
        [3, 4, 0, 1, 1, 0, 4, 3], // Row 2 (8)
        [4, 0, 1, 2, 2, 1, 0],    // Row 3 (7)
        [0, 1, 2, 3, 3, 2, 1, 0], // Row 4 (8)
      ],
    ),

    // Level 5: Clustered Islands (4 colors, 5 rows, 22 shots)
    LevelConfig(
      levelNumber: 5,
      maxShots: 22,
      availableColors: [BubbleType.red, BubbleType.blue, BubbleType.green, BubbleType.yellow],
      initialGrid: [
        [4, 4, 0, 1, 1, 0, 2, 2], // Row 0 (8)
        [4, 3, 3, 1, 2, 2, 3],    // Row 1 (7)
        [3, 3, 4, 4, 1, 1, 3, 3], // Row 2 (8)
        [0, 2, 2, 3, 3, 4, 0],    // Row 3 (7)
        [1, 1, 0, 4, 4, 0, 2, 2], // Row 4 (8)
      ],
    ),

    // Level 6: Diamond Fortress (4 colors, 6 rows, 20 shots)
    LevelConfig(
      levelNumber: 6,
      maxShots: 20,
      availableColors: [BubbleType.red, BubbleType.blue, BubbleType.green, BubbleType.yellow],
      initialGrid: [
        [2, 2, 2, 4, 4, 2, 2, 2], // Row 0 (8)
        [2, 3, 3, 4, 3, 3, 2],    // Row 1 (7)
        [1, 3, 1, 1, 1, 1, 3, 1], // Row 2 (8)
        [1, 1, 4, 2, 4, 1, 1],    // Row 3 (7)
        [0, 4, 3, 2, 2, 3, 4, 0], // Row 4 (8)
        [0, 0, 1, 4, 1, 0, 0],    // Row 5 (7)
      ],
    ),

    // Level 7: Rainbow Waves (5 colors, 6 rows, 19 shots)
    LevelConfig(
      levelNumber: 7,
      maxShots: 19,
      availableColors: [BubbleType.red, BubbleType.blue, BubbleType.green, BubbleType.yellow, BubbleType.purple],
      initialGrid: [
        [5, 5, 1, 1, 2, 2, 3, 3], // Row 0 (8)
        [4, 5, 5, 1, 2, 3, 4],    // Row 1 (7)
        [3, 4, 5, 5, 1, 2, 3, 4], // Row 2 (8)
        [2, 3, 4, 5, 1, 2, 3],    // Row 3 (7)
        [1, 2, 3, 4, 5, 1, 2, 3], // Row 4 (8)
        [5, 4, 3, 2, 1, 5, 4],    // Row 5 (7)
      ],
    ),

    // Level 8: Spiral Pinwheel (5 colors, 6 rows, 18 shots)
    LevelConfig(
      levelNumber: 8,
      maxShots: 18,
      availableColors: [BubbleType.red, BubbleType.blue, BubbleType.green, BubbleType.yellow, BubbleType.purple],
      initialGrid: [
        [1, 2, 5, 5, 5, 5, 2, 1], // Row 0 (8)
        [2, 3, 4, 1, 4, 3, 2],    // Row 1 (7)
        [3, 4, 1, 2, 2, 1, 4, 3], // Row 2 (8)
        [5, 1, 3, 0, 3, 1, 5],    // Row 3 (7)
        [4, 5, 2, 1, 1, 2, 5, 4], // Row 4 (8)
        [3, 2, 1, 5, 1, 2, 3],    // Row 5 (7)
      ],
    ),

    // Level 9: Honeycomb Shield (5 colors, 7 rows, 17 shots)
    LevelConfig(
      levelNumber: 9,
      maxShots: 17,
      availableColors: [BubbleType.red, BubbleType.blue, BubbleType.green, BubbleType.yellow, BubbleType.purple],
      initialGrid: [
        [5, 4, 3, 2, 1, 3, 4, 5], // Row 0 (8)
        [5, 4, 2, 1, 2, 4, 5],    // Row 1 (7)
        [1, 2, 3, 4, 5, 3, 2, 1], // Row 2 (8)
        [1, 3, 5, 2, 5, 3, 1],    // Row 3 (7)
        [2, 4, 1, 3, 3, 1, 4, 2], // Row 4 (8)
        [2, 5, 4, 0, 4, 5, 2],    // Row 5 (7)
        [0, 1, 3, 5, 5, 3, 1, 0], // Row 6 (8)
      ],
    ),

    // Level 10: Arcade Master Fortress (5 colors, 7 rows, 16 shots)
    LevelConfig(
      levelNumber: 10,
      maxShots: 16,
      availableColors: [BubbleType.red, BubbleType.blue, BubbleType.green, BubbleType.yellow, BubbleType.purple],
      initialGrid: [
        [5, 5, 4, 4, 3, 3, 2, 2], // Row 0 (8)
        [1, 5, 4, 3, 2, 1, 5],    // Row 1 (7)
        [1, 1, 5, 4, 3, 2, 2, 1], // Row 2 (8)
        [2, 3, 5, 1, 5, 3, 2],    // Row 3 (7)
        [3, 4, 1, 2, 2, 1, 4, 3], // Row 4 (8)
        [4, 5, 3, 0, 3, 5, 4],    // Row 5 (7)
        [5, 1, 2, 4, 4, 2, 1, 5], // Row 6 (8)
      ],
    ),
  ];
}

