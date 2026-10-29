import 'package:flutter/material.dart';

import '../../core/audio/audio.dart';
import '../../core/utils/utils.dart';
import '../../data/repositories/repositories.dart';

/// Arcade settings dialog modal for audio, sound effects, haptic vibrations,
/// and campaign progress management.
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({
    super.key,
    this.onProgressReset,
  });

  /// Optional callback invoked when the user confirms resetting progress.
  final VoidCallback? onProgressReset;

  /// Displays the [SettingsDialog] as a modal bottom sheet or dialog.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onProgressReset,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (_) => SettingsDialog(onProgressReset: onProgressReset),
    );
  }

  Future<void> _confirmResetProgress(BuildContext context) async {
    HapticsHelper.selectionClick();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A33),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF1744), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF1744), size: 24),
            SizedBox(width: 8),
            Text(
              'RESET PROGRESS',
              style: TextStyle(
                color: Color(0xFFFF1744),
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to reset all unlocked stages, high scores, and stars? This action cannot be undone.',
          style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticsHelper.selectionClick();
              Navigator.of(ctx).pop(false);
            },
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF1744),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              HapticsHelper.heavyImpact();
              Navigator.of(ctx).pop(true);
            },
            child: const Text(
              'RESET',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await LevelRepository.resetProgress();
      if (!context.mounted) return;
      onProgressReset?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Campaign progress successfully reset.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF19203C),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF11172E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                blurRadius: 28,
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, color: Color(0xFF00E5FF), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'SETTINGS',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () {
                        HapticsHelper.selectionClick();
                        Navigator.of(context).maybePop();
                      },
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),

                // 1. Sound Effects (SFX) Toggle
                ValueListenableBuilder<bool>(
                  valueListenable: SoundManager.instance.isMutedNotifier,
                  builder: (context, isMuted, _) {
                    final bool isEnabled = !isMuted;
                    return _SettingsSwitchTile(
                      icon: isEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      title: 'Sound Effects (SFX)',
                      subtitle: isEnabled ? 'Active' : 'Muted',
                      value: isEnabled,
                      accentColor: const Color(0xFF00E5FF),
                      onChanged: (val) {
                        HapticsHelper.selectionClick();
                        SoundManager.instance.setMuted(!val);
                      },
                    );
                  },
                ),

                const SizedBox(height: 10),

                // 2. Background Music (BGM) Toggle
                ValueListenableBuilder<bool>(
                  valueListenable: SoundManager.instance.isBgmEnabledNotifier,
                  builder: (context, isBgmEnabled, _) {
                    return _SettingsSwitchTile(
                      icon: isBgmEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                      title: 'Background Music (BGM)',
                      subtitle: isBgmEnabled ? 'Active' : 'Muted',
                      value: isBgmEnabled,
                      accentColor: const Color(0xFFFF007F),
                      onChanged: (val) {
                        HapticsHelper.selectionClick();
                        SoundManager.instance.setBgmEnabled(val);
                      },
                    );
                  },
                ),

                const SizedBox(height: 10),

                // 3. Haptic Vibration Toggle
                ValueListenableBuilder<bool>(
                  valueListenable: HapticsHelper.isHapticsEnabledNotifier,
                  builder: (context, isHapticsEnabled, _) {
                    return _SettingsSwitchTile(
                      icon: isHapticsEnabled ? Icons.vibration_rounded : Icons.smartphone_rounded,
                      title: 'Haptic Vibration',
                      subtitle: isHapticsEnabled ? 'Enabled' : 'Disabled',
                      value: isHapticsEnabled,
                      accentColor: const Color(0xFFFFD600),
                      onChanged: (val) {
                        HapticsHelper.selectionClick();
                        HapticsHelper.setHapticsEnabled(val);
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),

                // Reset Game Progress Action
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _confirmResetProgress(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1744).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF1744).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, color: Color(0xFFFF1744), size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'RESET CAMPAIGN PROGRESS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFFF5252),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticsHelper.selectionClick();
                      Navigator.of(context).maybePop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19203C),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

/// Extracted switch tile for settings preferences.
class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF151D36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? accentColor.withValues(alpha: 0.3) : Colors.white10,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: value ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: value ? accentColor : Colors.white38,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: accentColor,
            activeTrackColor: accentColor.withValues(alpha: 0.35),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
