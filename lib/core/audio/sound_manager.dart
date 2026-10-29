import 'dart:async' show unawaited;
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

  /// SharedPreferences key for background music status.
  static const String prefKeyBgm = 'bubble_shooter_bgm_enabled';

  /// Debounce intervals in milliseconds to prevent platform channel flooding.
  static const int popDebounceMs = 80;
  static const int bounceDebounceMs = 60;
  static const int shootDebounceMs = 50;
  static const int defaultDebounceMs = 50;

  /// Tracks the last epoch timestamp (ms) when each sound asset was triggered.
  final Map<String, int> _lastPlayedTimes = <String, int>{};

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

  /// Reactive notifier for real-time BGM state in the UI.
  final ValueNotifier<bool> isBgmEnabledNotifier = ValueNotifier<bool>(true);

  /// Current background music status.
  bool get isBgmEnabled => isBgmEnabledNotifier.value;

  bool _isInitialized = false;

  /// Preloads audio files and retrieves persisted mute settings.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Load persisted mute preference and BGM preference
    try {
      final prefs = await SharedPreferences.getInstance();
      isMutedNotifier.value = prefs.getBool(prefKeyMuted) ?? false;
      isBgmEnabledNotifier.value = prefs.getBool(prefKeyBgm) ?? true;
    } catch (e) {
      debugPrint('SoundManager: Failed to load audio preferences: $e');
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

  /// Toggles background music on/off and persists preference to [SharedPreferences].
  Future<void> toggleBgm() async {
    await setBgmEnabled(!isBgmEnabledNotifier.value);
  }

  /// Directly updates the BGM enabled state.
  Future<void> setBgmEnabled(bool enabled) async {
    if (isBgmEnabledNotifier.value == enabled) return;
    isBgmEnabledNotifier.value = enabled;

    if (!enabled) {
      stopBgm();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyBgm, enabled);
    } catch (e) {
      debugPrint('SoundManager: Failed to persist BGM preference: $e');
    }
  }

  /// Safely stops any actively playing background music.
  void stopBgm() {
    if (!enableAudio) return;

    try {
      FlameAudio.bgm.stop().catchError((Object error) {
        debugPrint('SoundManager: Async BGM stop ignored: $error');
      });
    } catch (e) {
      debugPrint('SoundManager: BGM stop ignored: $e');
    }
  }

  /// Safely plays an SFX asset file wrapped in rate-limiting debounce,
  /// strict zero-overhead guards when muted/disabled, and fire-and-forget execution.
  void _playSafe(
    String fileName, {
    double volume = 1.0,
    int debounceMs = defaultDebounceMs,
  }) {
    // 1. Immediate zero-overhead guard when muted or audio is globally disabled
    if (!enableAudio || isMuted) return;

    // 2. Strict rate-limiting debounce check per sound asset
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int lastPlayed = _lastPlayedTimes[fileName] ?? 0;
    if (now - lastPlayed < debounceMs) {
      return;
    }
    _lastPlayedTimes[fileName] = now;

    // 3. Fire-and-forget execution wrapped safely with timeout guard
    try {
      unawaited(
        FlameAudio.play(fileName, volume: volume)
            .timeout(const Duration(seconds: 3))
            .then<void>((_) {})
            .catchError((Object error) {
          // Silently intercept async platform channel errors or timeouts
          debugPrint('SoundManager: Async audio ignored ($fileName): $error');
        }),
      );
    } catch (e) {
      // Safe playback: silently catch synchronous audio errors
      debugPrint('SoundManager: Audio trigger ignored ($fileName): $e');
    }
  }

  /// Resets debounce timestamps (useful for unit testing).
  void resetDebounceTimers() {
    _lastPlayedTimes.clear();
  }

  /// Sound triggered when the cannon launches a bullet bubble.
  void playShoot() => _playSafe(shootSfx, volume: 0.85, debounceMs: shootDebounceMs);

  /// Sound triggered when a flying bullet bounces off lateral walls.
  void playBounce() => _playSafe(bounceSfx, volume: 0.65, debounceMs: bounceDebounceMs);

  /// Sound triggered when bubbles match-3 pop or dropped orphans burst.
  void playPop() => _playSafe(popSfx, volume: 0.95, debounceMs: popDebounceMs);

  /// Sound triggered when swapping current bubble with next queued bubble.
  void playSwap() => _playSafe(bounceSfx, volume: 0.55, debounceMs: defaultDebounceMs);

  /// Sound triggered upon completing a stage.
  void playWin() => _playSafe(winSfx, volume: 1.0, debounceMs: defaultDebounceMs);

  /// Sparkling chime SFX triggered sequentially as victory stars lock into place.
  void playChime() => _playSafe(bounceSfx, volume: 0.85, debounceMs: defaultDebounceMs);

  /// Sound triggered upon running out of ammo or breaching the danger floor line.
  void playGameOver() => _playSafe(gameOverSfx, volume: 1.0, debounceMs: defaultDebounceMs);

  /// Disposes audio caches, stops background music, and resets the initialized state.
  Future<void> dispose() async {
    try {
      stopBgm();
      await FlameAudio.audioCache.clearAll();
      _lastPlayedTimes.clear();
      _isInitialized = false;
    } catch (e) {
      debugPrint('SoundManager: Error during dispose: $e');
    }
  }

  /// Clears active sound pools from cache memory to free system resources.
  Future<void> clearAudioCache() async {
    try {
      await FlameAudio.audioCache.clearAll();
    } catch (e) {
      debugPrint('SoundManager: Failed to clear audio cache: $e');
    }
  }
}

