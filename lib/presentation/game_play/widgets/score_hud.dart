import 'package:flutter/material.dart';

import '../../../core/audio/sound_manager.dart';
import '../../../core/utils/haptics_helper.dart';
import '../../overlays/settings_dialog.dart';

/// Top arcade HUD bar widget displaying Stage number, Score, High score, Ammo count,
/// and interactive buttons for Level select, Mute, Settings, and Pause.
///
/// Anchored inside a SafeArea with a fixed height and a glassmorphic semi-transparent
/// backdrop with bottom border so it sits cleanly above the Flame game playfield.
class ScoreHudOverlay extends StatelessWidget {
  const ScoreHudOverlay({
    super.key,
    required this.levelNumber,
    required this.highScore,
    required this.scoreNotifier,
    required this.shotsNotifier,
    required this.onPausePressed,
    required this.onBackPressed,
  });

  final int levelNumber;
  final int highScore;
  final ValueNotifier<int> scoreNotifier;
  final ValueNotifier<int> shotsNotifier;
  final VoidCallback onPausePressed;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 84.0,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF060913).withValues(alpha: 0.85),
            border: const Border(
              bottom: BorderSide(
                color: Color(0x3300E5FF),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Exit / Back Button
              ArcadeIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: 'Level Select',
                onTap: onBackPressed,
              ),
              const SizedBox(width: 6),

              // Level, Live Score, and Shots Left Badge (Expanded with FittedBox)
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A33).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'STAGE ${levelNumber.toString().padLeft(2, '0')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ValueListenableBuilder<int>(
                            valueListenable: scoreNotifier,
                            builder: (context, score, _) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'SCORE: $score',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (highScore > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      'BEST: $highScore',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFFFD600),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          ValueListenableBuilder<int>(
                            valueListenable: shotsNotifier,
                            builder: (context, shots, _) {
                              final bool lowAmmo = shots <= 5;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 2),
                                margin: const EdgeInsets.only(top: 3),
                                decoration: BoxDecoration(
                                  color: lowAmmo
                                      ? const Color(0xFFFF1744).withValues(alpha: 0.2)
                                      : const Color(0xFF00E5FF).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: lowAmmo
                                        ? const Color(0xFFFF1744)
                                        : const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.adjust_rounded,
                                      size: 11,
                                      color: lowAmmo
                                          ? const Color(0xFFFF1744)
                                          : const Color(0xFF00E5FF),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'SHOTS: $shots',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: lowAmmo
                                            ? const Color(0xFFFF5252)
                                            : const Color(0xFFE0F7FA),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Right Actions: Sound Mute/Unmute, Settings & Pause Menu
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: SoundManager.instance.isMutedNotifier,
                      builder: (context, isMuted, _) {
                        return ArcadeIconButton(
                          icon: isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          iconColor: isMuted
                              ? const Color(0xFFFF5252)
                              : const Color(0xFF00E5FF),
                          tooltip: isMuted ? 'Unmute Sound' : 'Mute Sound',
                          onTap: () {
                            HapticsHelper.selectionClick();
                            SoundManager.instance.toggleMute();
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    ArcadeIconButton(
                      icon: Icons.tune_rounded,
                      tooltip: 'Settings',
                      iconColor: const Color(0xFF00E5FF),
                      onTap: () {
                        HapticsHelper.selectionClick();
                        SettingsDialog.show(context);
                      },
                    ),
                    const SizedBox(width: 6),
                    ArcadeIconButton(
                      icon: Icons.pause_rounded,
                      tooltip: 'Pause Game',
                      onTap: () {
                        HapticsHelper.selectionClick();
                        onPausePressed();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact circular icon button for HUD.
class ArcadeIconButton extends StatelessWidget {
  const ArcadeIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF131A33).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor ?? Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
