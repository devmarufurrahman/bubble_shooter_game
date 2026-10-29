import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/audio/sound_manager.dart';
import '../game/bubble_shooter_game.dart';
import '../levels/level_manager.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/pause_overlay.dart';
import 'overlays/win_overlay.dart';

/// Host screen wrapping Flame's GameWidget with arcade HUD, victory, defeat, and pause overlays.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.levelNumber,
  });

  final int levelNumber;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BubbleShooterGame _game;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _game = BubbleShooterGame(levelNumber: widget.levelNumber);
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final int score = await LevelManager.instance.getHighScore(widget.levelNumber);
    if (mounted) {
      setState(() => _highScore = score);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D1A),
      body: SafeArea(
        child: Stack(
          children: [
            // Flame Game Canvas Host
            GameWidget<BubbleShooterGame>(
              game: _game,
              overlayBuilderMap: {
                'hud': (context, game) => _GameHudOverlay(
                      levelNumber: widget.levelNumber,
                      highScore: _highScore,
                      scoreNotifier: game.scoreNotifier,
                      shotsNotifier: game.shotsNotifier,
                      onPausePressed: game.pauseGame,
                      onBackPressed: () => Navigator.of(context).maybePop(),
                    ),
                'WinOverlay': (context, game) => WinOverlay(game: game),
                'GameOverOverlay': (context, game) =>
                    GameOverOverlay(game: game),
                'PauseOverlay': (context, game) => PauseOverlay(game: game),
              },
              initialActiveOverlays: const ['hud'],
            ),
          ],
        ),
      ),
    );
  }
}

/// In-game top arcade HUD overlay.
class _GameHudOverlay extends StatelessWidget {
  const _GameHudOverlay({
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
      top: 12,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Exit / Back Button
          _ArcadeIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Level Select',
            onTap: onBackPressed,
          ),

          // Level, Live Score, and Shots Left Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            fontSize: 11,
                          ),
                        ),
                        if (highScore > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            'BEST: $highScore',
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      margin: const EdgeInsets.only(top: 4),
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
                            color: lowAmmo ? const Color(0xFFFF1744) : const Color(0xFF00E5FF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'SHOTS: $shots',
                            style: TextStyle(
                              color: lowAmmo ? const Color(0xFFFF5252) : const Color(0xFFE0F7FA),
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

          // Right Actions: Sound Mute/Unmute & Pause Menu
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: SoundManager.instance.isMutedNotifier,
                builder: (context, isMuted, _) {
                  return _ArcadeIconButton(
                    icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    iconColor: isMuted ? const Color(0xFFFF5252) : const Color(0xFF00E5FF),
                    tooltip: isMuted ? 'Unmute Sound' : 'Mute Sound',
                    onTap: () => SoundManager.instance.toggleMute(),
                  );
                },
              ),
              const SizedBox(width: 8),
              _ArcadeIconButton(
                icon: Icons.pause_rounded,
                tooltip: 'Pause Game',
                onTap: onPausePressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact circular icon button for HUD.
class _ArcadeIconButton extends StatelessWidget {
  const _ArcadeIconButton({
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF131A33).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
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
            child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
