import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/repositories.dart';
import '../../game/bubble_shooter_game.dart';
import '../overlays/overlays.dart';
import 'widgets/score_hud.dart';

/// Host screen wrapping Flame's GameWidget with arcade HUD, victory, defeat, and pause overlays.
/// Manages engine lifecycle and ensures comprehensive memory cleanup on disposal.
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
    final int score = await LevelRepository.getHighScore(widget.levelNumber);
    if (mounted) {
      setState(() => _highScore = score);
    }
  }

  @override
  void dispose() {
    // 1. Pause engine ticker immediately to halt background processing
    _game.pauseEngine();

    // 2. Clear and detach all registered overlays
    _game.overlays.clear();

    // 3. Explicitly trigger deep game and component teardown
    _game.onDisposeGame();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D1A),
      body: SafeArea(
        child: Stack(
          children: [
            // Flame Game Canvas Host centered with fixed aspect ratio letterboxing
            Center(
              child: AspectRatio(
                aspectRatio: BubbleShooterGame.virtualWidth / BubbleShooterGame.virtualHeight,
                child: GameWidget<BubbleShooterGame>(
                  game: _game,
                  overlayBuilderMap: {
                    'hud': (context, game) => ScoreHudOverlay(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

