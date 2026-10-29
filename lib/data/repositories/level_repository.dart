import '../../levels/level_manager.dart';

export '../../levels/level_manager.dart' show LevelManager;

/// Repository interface and implementation for managing level progression,
/// high scores, and earned stars.
class LevelRepository {
  const LevelRepository();

  static const LevelRepository instance = LevelRepository();

  /// Total number of campaign levels available.
  static const int totalLevels = LevelManager.totalLevels;

  /// Retrieves the highest unlocked level index (1-10).
  static Future<int> getUnlockedLevel() => LevelManager.getUnlockedLevel();

  /// Retrieves the high score recorded for [level].
  static Future<int> getHighScore(int level) => LevelManager.getHighScore(level);

  /// Retrieves the stars earned for [level] (0-3).
  static Future<int> getStars(int level) => LevelManager.getStars(level);

  /// Persists score, stars, and unlocks next stage atomically.
  static Future<void> saveLevelProgress(int level, int score, int stars) =>
      LevelManager.saveLevelProgress(level, score, stars);

  /// Named-parameter variant for progress persistence.
  static Future<void> saveProgress({
    required int level,
    required int score,
    required int stars,
  }) =>
      LevelManager.saveLevelProgress(level, score, stars);

  /// Unlocks the next level if [currentLevel] matches or exceeds current unlock.
  static Future<void> unlockNextLevel(int currentLevel) =>
      LevelManager.unlockNextLevel(currentLevel);

  /// Saves the score if it exceeds current record.
  static Future<void> saveScore(int level, int score) =>
      LevelManager.saveScore(level, score);

  /// Resets all campaign progress.
  static Future<void> resetProgress() => LevelManager.resetProgress();

  /// Checks if [level] is unlocked.
  static Future<bool> isLevelUnlocked(int level) => LevelManager.isLevelUnlocked(level);
}
