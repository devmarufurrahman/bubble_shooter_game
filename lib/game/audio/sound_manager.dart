import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Production-ready singleton audio manager for game sound effects,
/// asset preloading, and persisted mute preferences.
class SoundManager {
  SoundManager._internal();

  /// Shared singleton instance.
  static final SoundManager instance = SoundManager._internal();

  /// Factory constructor returning the singleton instance.
  factory SoundManager() => instance;

  /// Global switch to enable or disable audio playback.
  /// Defaults to true; can be disabled in headless CI or unit tests.
  static bool enableAudio = true;

  /// SharedPreferences key for sound mute status.
  static const String prefKeyMuted = 'bubble_shooter_sound_muted';

  /// Standard sound asset filenames.
  static const String shootSfx = 'shoot.wav';
  static const String popSfx = 'pop.wav';
  static const String bounceSfx = 'bounce.wav';
  static const String winSfx = 'win.wav';
  static const String gameOverSfx = 'game_over.wav';

  /// List of all SFX filenames for batch preloading.
  static const List<String> allSfx = [
    shootSfx,
    popSfx,
    bounceSfx,
    winSfx,
    gameOverSfx,
  ];

  /// Reactive notifier for real-time sound mute state in the UI.
  final ValueNotifier<bool> isMutedNotifier = ValueNotifier<bool>(false);

  /// Current mute status.
  bool get isMuted => isMutedNotifier.value;

  bool _isInitialized = false;

  /// Preloads audio files and retrieves persisted mute settings.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Load persisted mute preference
    try {
      final prefs = await SharedPreferences.getInstance();
      isMutedNotifier.value = prefs.getBool(prefKeyMuted) ?? false;
    } catch (e) {
      debugPrint('SoundManager: Failed to load mute preference: $e');
    }

    if (!enableAudio) return;

    // Preload audio files safely
    try {
      await FlameAudio.audioCache.loadAll(allSfx);
    } catch (e) {
      debugPrint('SoundManager: Audio preload skipped or failed: $e');
    }
  }

  /// Toggles sound mute on/off and persists preference to [SharedPreferences].
  Future<void> toggleMute() async {
    final bool nextMuted = !isMutedNotifier.value;
    isMutedNotifier.value = nextMuted;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyMuted, nextMuted);
    } catch (e) {
      debugPrint('SoundManager: Failed to persist mute preference: $e');
    }
  }

  /// Directly updates the mute state.
  Future<void> setMuted(bool muted) async {
    if (isMutedNotifier.value == muted) return;
    isMutedNotifier.value = muted;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyMuted, muted);
    } catch (e) {
      debugPrint('SoundManager: Failed to persist mute preference: $e');
    }
  }

  /// Safely plays an SFX asset file wrapped in synchronous and asynchronous error handlers.
  void _playSafe(String fileName, {double volume = 1.0}) {
    if (!enableAudio || isMuted) return;

    try {
      FlameAudio.play(fileName, volume: volume).catchError((Object error) {
        // Silently intercept async platform channel errors (e.g. headless tests or missing assets)
        debugPrint('SoundManager: Async audio ignored ($fileName): $error');
        return AudioPlayer();
      });
    } catch (e) {
      // Safe playback: silently catch audio errors to protect the game loop
      debugPrint('SoundManager: Audio trigger ignored ($fileName): $e');
    }
  }

  /// Sound triggered when the cannon launches a bullet bubble.
  void playShoot() => _playSafe(shootSfx, volume: 0.85);

  /// Sound triggered when a flying bullet bounces off lateral walls.
  void playBounce() => _playSafe(bounceSfx, volume: 0.65);

  /// Sound triggered when bubbles match-3 pop or dropped orphans burst.
  void playPop() => _playSafe(popSfx, volume: 0.95);

  /// Sound triggered upon completing a stage.
  void playWin() => _playSafe(winSfx, volume: 1.0);

  /// Sound triggered upon running out of ammo or breaching the danger floor line.
  void playGameOver() => _playSafe(gameOverSfx, volume: 1.0);
}
