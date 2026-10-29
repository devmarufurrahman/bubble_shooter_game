import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/bubble_shooter_game.dart';
import '../levels/level_manager.dart';

/// Host screen wrapping Flame's GameWidget with arcade HUD and modal overlays.
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
                'hud': (BuildContext context, BubbleShooterGame game) {
                  return _GameHudOverlay(
                    levelNumber: widget.levelNumber,
                    highScore: _highScore,
                    onPausePressed: () => game.overlays.add('pauseMenu'),
                    onBackPressed: () => Navigator.of(context).maybePop(),
                  );
                },
                'pauseMenu': (BuildContext context, BubbleShooterGame game) {
                  return _PauseMenuOverlay(
                    levelNumber: widget.levelNumber,
                    onResumePressed: () => game.overlays.remove('pauseMenu'),
                    onRestartPressed: () {
                      game.overlays.remove('pauseMenu');
                      game.restartLevel();
                    },
                    onExitPressed: () {
                      game.overlays.remove('pauseMenu');
                      Navigator.of(context).maybePop();
                    },
                  );
                },
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
    required this.onPausePressed,
    required this.onBackPressed,
  });

  final int levelNumber;
  final int highScore;
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

          // Level & High Score Center Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    fontSize: 13,
                  ),
                ),
                Text(
                  'HIGH SCORE: $highScore',
                  style: const TextStyle(
                    color: Color(0xFFFFD600),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Pause Menu Button
          _ArcadeIconButton(
            icon: Icons.pause_rounded,
            tooltip: 'Pause Game',
            onTap: onPausePressed,
          ),
        ],
      ),
    );
  }
}

/// Glassmorphic Pause Modal Overlay with arcade neon highlights.
class _PauseMenuOverlay extends StatelessWidget {
  const _PauseMenuOverlay({
    required this.levelNumber,
    required this.onResumePressed,
    required this.onRestartPressed,
    required this.onExitPressed,
  });

  final int levelNumber;
  final VoidCallback onResumePressed;
  final VoidCallback onRestartPressed;
  final VoidCallback onExitPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF11172E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFF007F).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF007F).withValues(alpha: 0.25),
                blurRadius: 28,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GAME PAUSED',
                style: TextStyle(
                  color: Color(0xFFFF007F),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.0,
                  shadows: [
                    Shadow(
                      color: Color(0xFFFF007F),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'STAGE ${levelNumber.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),
              _PauseButton(
                label: 'RESUME',
                icon: Icons.play_arrow_rounded,
                borderColor: const Color(0xFF00E5FF),
                onPressed: onResumePressed,
              ),
              const SizedBox(height: 14),
              _PauseButton(
                label: 'RESTART',
                icon: Icons.refresh_rounded,
                borderColor: const Color(0xFFFFD600),
                onPressed: onRestartPressed,
              ),
              const SizedBox(height: 14),
              _PauseButton(
                label: 'LEVEL SELECT',
                icon: Icons.grid_view_rounded,
                borderColor: const Color(0xFFFF007F),
                onPressed: onExitPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action button inside Pause overlay.
class _PauseButton extends StatelessWidget {
  const _PauseButton({
    required this.label,
    required this.icon,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF19203C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.5,
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
class _ArcadeIconButton extends StatelessWidget {
  const _ArcadeIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

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
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
