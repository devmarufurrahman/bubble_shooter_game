import 'package:shared_preferences/shared_preferences.dart';

/// Manages level unlocks, star ratings, and persistent high scores.
class LevelManager {
  LevelManager._internal();

  /// Global singleton instance.
  static final LevelManager instance = LevelManager._internal();

  /// Factory constructor returning the singleton instance.
  factory LevelManager() => instance;

  /// Total number of playable arcade levels.
  static const int totalLevels = 10;

  static const String _keyUnlockedLevel = 'bubble_shooter_unlocked_level';
  static const String _keyHighScorePrefix = 'bubble_shooter_high_score_level_';

  /// Retrieves the highest unlocked level index (1-based, clamped between 1 and 10).
  /// Defaults to Level 1 unlocked.
  Future<int> getUnlockedLevel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int unlocked = prefs.getInt(_keyUnlockedLevel) ?? 1;
    return unlocked.clamp(1, totalLevels);
  }

  /// Unlocks the next level if [currentLevel] is completed and matches or exceeds
  /// the currently stored unlocked progress.
  Future<void> unlockNextLevel(int currentLevel) async {
    if (currentLevel < 1 || currentLevel >= totalLevels) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int currentUnlocked = prefs.getInt(_keyUnlockedLevel) ?? 1;

    if (currentLevel >= currentUnlocked) {
      final int nextLevel = (currentLevel + 1).clamp(1, totalLevels);
      await prefs.setInt(_keyUnlockedLevel, nextLevel);
    }
  }

  /// Resets all campaign progress back to Level 1 and clears all high scores.
  Future<void> resetProgress() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUnlockedLevel, 1);
    for (int i = 1; i <= totalLevels; i++) {
      await prefs.remove('$_keyHighScorePrefix$i');
    }
  }

  /// Retrieves the recorded high score for a specific [level].
  /// Returns 0 if no score has been recorded yet.
  Future<int> getHighScore(int level) async {
    if (level < 1 || level > totalLevels) return 0;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyHighScorePrefix$level') ?? 0;
  }

  /// Persists [score] for [level] if it exceeds the existing recorded high score.
  Future<void> saveScore(int level, int score) async {
    if (level < 1 || level > totalLevels || score <= 0) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int currentHigh = prefs.getInt('$_keyHighScorePrefix$level') ?? 0;

    if (score > currentHigh) {
      await prefs.setInt('$_keyHighScorePrefix$level', score);
    }
  }

  /// Convenience check to determine if a specific [level] is accessible.
  Future<bool> isLevelUnlocked(int level) async {
    final int unlocked = await getUnlockedLevel();
    return level <= unlocked;
  }
}

