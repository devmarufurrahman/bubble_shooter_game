import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized utility helper for tactile device haptic vibrations.
/// Silently catches any platform errors so web/desktop/unsupported devices never crash.
class HapticsHelper {
  HapticsHelper._();

  /// SharedPreferences key for haptic vibration toggle.
  static const String prefKeyHaptics = 'bubble_shooter_haptics_enabled';

  /// Reactive notifier for real-time haptic toggle state in UI switches.
  static final ValueNotifier<bool> isHapticsEnabledNotifier = ValueNotifier<bool>(true);

  /// Current haptic toggle state.
  static bool get isHapticsEnabled => isHapticsEnabledNotifier.value;

  /// Loads persisted haptic settings.
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isHapticsEnabledNotifier.value = prefs.getBool(prefKeyHaptics) ?? true;
    } catch (_) {}
  }

  /// Toggles haptic feedback state and persists to [SharedPreferences].
  static Future<void> toggleHaptics() async {
    await setHapticsEnabled(!isHapticsEnabledNotifier.value);
  }

  /// Sets haptic feedback enabled/disabled state and persists to [SharedPreferences].
  static Future<void> setHapticsEnabled(bool enabled) async {
    if (isHapticsEnabledNotifier.value == enabled) return;
    isHapticsEnabledNotifier.value = enabled;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyHaptics, enabled);
    } catch (_) {}
  }

  static int _lastVibrateTimestamp = 0;

  /// Default debounce cooldown window in milliseconds to prevent platform channel spam.
  static const int defaultHapticCooldownMs = 40;

  /// Clears the debounce timestamp (useful in unit testing).
  static void resetDebounce() {
    _lastVibrateTimestamp = 0;
  }

  static bool _canVibrate([int cooldownMs = defaultHapticCooldownMs]) {
    if (!isHapticsEnabledNotifier.value) return false;

    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastVibrateTimestamp < cooldownMs) {
      return false;
    }
    _lastVibrateTimestamp = now;

    try {
      // Accessing ServicesBinding.instance throws StateError in uninitialized test environments
      ServicesBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Triggered during standard match-3 pops or minor interaction events.
  static Future<void> lightImpact([int cooldownMs = defaultHapticCooldownMs]) async {
    if (!_canVibrate(cooldownMs)) return;
    try {
      await HapticFeedback.lightImpact().catchError((_) {});
    } catch (_) {}
  }

  /// Triggered during 4+ bubble cascades or orphan drops.
  static Future<void> mediumImpact([int cooldownMs = defaultHapticCooldownMs]) async {
    if (!_canVibrate(cooldownMs)) return;
    try {
      await HapticFeedback.mediumImpact().catchError((_) {});
    } catch (_) {}
  }

  /// Triggered on level victory or game-over thresholds.
  static Future<void> heavyImpact([int cooldownMs = defaultHapticCooldownMs]) async {
    if (!_canVibrate(cooldownMs)) return;
    try {
      await HapticFeedback.heavyImpact().catchError((_) {});
    } catch (_) {}
  }

  /// Triggered on subtle UI selections or wall bounces.
  static Future<void> selectionClick([int cooldownMs = defaultHapticCooldownMs]) async {
    if (!_canVibrate(cooldownMs)) return;
    try {
      await HapticFeedback.selectionClick().catchError((_) {});
    } catch (_) {}
  }
}
