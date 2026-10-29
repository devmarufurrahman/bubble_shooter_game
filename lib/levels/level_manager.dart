import 'package:shared_preferences/shared_preferences.dart';

/// Manages level progression, unlock state, star ratings, and persistent high scores.
/// Provides both static API methods and a singleton instance proxy for backward compatibility.
class LevelManager {
  LevelManager._();

  /// Total number of playable arcade levels.
  static const int totalLevels = 10;

  /// Consistent SharedPreferences key constants.
  static const String keyUnlockedLevel = 'unlocked_level';
  static String keyScore(int level) => 'level_${level}_score';
  static String keyStars(int level) => 'level_${level}_stars';

  /// Singleton instance proxy allowing instance-style calls (`LevelManager.instance...`).
  static const LevelManagerInstance instance = LevelManagerInstance();

  /// Retrieves the highest unlocked level index (1-based, clamped between 1 and 10).
  /// Defaults to Level 1 unlocked.
  static Future<int> getUnlockedLevel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int unlocked = prefs.getInt(keyUnlockedLevel) ??
        prefs.getInt('bubble_shooter_unlocked_level') ??
        1;
    return unlocked.clamp(1, totalLevels);
  }

  /// Retrieves the recorded high score for a specific [level].
  /// Returns 0 if no score has been recorded yet.
  static Future<int> getHighScore(int level) async {
    if (level < 1 || level > totalLevels) return 0;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyScore(level)) ??
        prefs.getInt('bubble_shooter_high_score_level_$level') ??
        0;
  }

  /// Retrieves the earned stars count for a specific [level] (0 to 3).
  /// Returns 0 if level has not been completed.
  static Future<int> getStars(int level) async {
    if (level < 1 || level > totalLevels) return 0;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int stars = prefs.getInt(keyStars(level)) ?? 0;
    return stars.clamp(0, 3);
  }

  /// Atomically persists high score, stars earned, and unlocks the next level.
  ///
  /// - High score is updated only if [score] > existing score.
  /// - Stars are updated only if [stars] > existing stars.
  /// - Unlocks [level] + 1 up to [totalLevels].
  static Future<void> saveLevelProgress(int level, int score, int stars) async {
    if (level < 1 || level > totalLevels) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. Read existing high score; update if score > existingScore
    final int existingScore = await getHighScore(level);
    if (score > existingScore) {
      await prefs.setInt(keyScore(level), score);
    }

    // 2. Read existing stars; update if stars > existingStars
    final int existingStars = await getStars(level);
    final int validStars = stars.clamp(0, 3);
    if (validStars > existingStars) {
      await prefs.setInt(keyStars(level), validStars);
    }

    // 3. Unlock next level (level + 1 up to totalLevels)
    final int currentUnlocked = await getUnlockedLevel();
    if (level >= currentUnlocked && level < totalLevels) {
      final int nextLevel = (level + 1).clamp(1, totalLevels);
      await prefs.setInt(keyUnlockedLevel, nextLevel);
    }
  }

  /// Unlocks the next level if [currentLevel] is completed and matches or exceeds
  /// the currently stored unlocked progress.
  static Future<void> unlockNextLevel(int currentLevel) async {
    if (currentLevel < 1 || currentLevel >= totalLevels) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int currentUnlocked = await getUnlockedLevel();

    if (currentLevel >= currentUnlocked) {
      final int nextLevel = (currentLevel + 1).clamp(1, totalLevels);
      await prefs.setInt(keyUnlockedLevel, nextLevel);
    }
  }

  /// Persists [score] for [level] if it exceeds the existing recorded high score.
  static Future<void> saveScore(int level, int score) async {
    if (level < 1 || level > totalLevels || score <= 0) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int currentHigh = await getHighScore(level);

    if (score > currentHigh) {
      await prefs.setInt(keyScore(level), score);
    }
  }

  /// Resets all campaign progress back to Level 1 and clears all high scores & stars.
  static Future<void> resetProgress() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyUnlockedLevel, 1);
    await prefs.remove('bubble_shooter_unlocked_level');

    for (int i = 1; i <= totalLevels; i++) {
      await prefs.remove(keyScore(i));
      await prefs.remove(keyStars(i));
      await prefs.remove('bubble_shooter_high_score_level_$i');
    }
  }

  /// Convenience check to determine if a specific [level] is accessible.
  static Future<bool> isLevelUnlocked(int level) async {
    final int unlocked = await getUnlockedLevel();
    return level <= unlocked;
  }
}

/// Instance proxy delegating to static [LevelManager] methods.
class LevelManagerInstance {
  const LevelManagerInstance();

  Future<int> getUnlockedLevel() => LevelManager.getUnlockedLevel();
  Future<int> getHighScore(int level) => LevelManager.getHighScore(level);
  Future<int> getStars(int level) => LevelManager.getStars(level);
  Future<void> saveLevelProgress(int level, int score, int stars) =>
      LevelManager.saveLevelProgress(level, score, stars);
  Future<void> unlockNextLevel(int currentLevel) =>
      LevelManager.unlockNextLevel(currentLevel);
  Future<void> saveScore(int level, int score) =>
      LevelManager.saveScore(level, score);
  Future<void> resetProgress() => LevelManager.resetProgress();
  Future<bool> isLevelUnlocked(int level) =>
      LevelManager.isLevelUnlocked(level);
}
