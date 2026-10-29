import 'package:flutter/material.dart';
import '../../game/bubble_shooter_game.dart';
import '../../levels/level_data.dart';
import '../../levels/level_manager.dart';
import '../game_screen.dart';

/// Arcade glassmorphic victory overlay displayed upon clearing the stage.
class WinOverlay extends StatefulWidget {
  const WinOverlay({
    super.key,
    required this.game,
  });

  final BubbleShooterGame game;

  /// Calculates earned stars (1 to 3) based on shots remaining relative to [maxShots].
  static int calculateStars(int remainingShots, int maxShots) {
    if (remainingShots >= (maxShots * 0.5).round()) return 3;
    if (remainingShots >= (maxShots * 0.25).round()) return 2;
    return 1;
  }

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay> {
  late final int _stars;

  @override
  void initState() {
    super.initState();
    final LevelConfig config = LevelConfig.getLevel(widget.game.levelNumber);
    _stars = WinOverlay.calculateStars(widget.game.shotsRemaining, config.maxShots);
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    await LevelManager.saveLevelProgress(
      widget.game.levelNumber,
      widget.game.currentScore,
      _stars,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LevelConfig config = LevelConfig.getLevel(widget.game.levelNumber);

    return Container(
      color: Colors.black.withValues(alpha: 0.8),
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
              color: const Color(0xFFFFD600).withValues(alpha: 0.6),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD600).withValues(alpha: 0.3),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '★ LEVEL CLEARED! ★',
                style: TextStyle(
                  color: Color(0xFFFFD600),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  shadows: [
                    Shadow(color: Color(0xFFFFD600), blurRadius: 16),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'STAGE ${widget.game.levelNumber.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Star Indicators based on remaining shots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final bool earned = index < _stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Icon(
                      earned ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: earned ? const Color(0xFFFFD600) : Colors.white24,
                      size: 40,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 18),
              Text(
                'FINAL SCORE: ${widget.game.currentScore}',
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SHOTS REMAINING: ${widget.game.shotsRemaining} / ${config.maxShots}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),

              const SizedBox(height: 28),

              // Progression Buttons
              if (widget.game.levelNumber < LevelManager.totalLevels) ...[
                _WinButton(
                  label: 'NEXT LEVEL',
                  icon: Icons.arrow_forward_rounded,
                  borderColor: const Color(0xFF00E5FF),
                  onPressed: () {
                    widget.game.resumeEngine();
                    widget.game.overlays.remove('WinOverlay');
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => GameScreen(levelNumber: widget.game.levelNumber + 1),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],
              _WinButton(
                label: 'STAGE SELECT',
                icon: Icons.grid_view_rounded,
                borderColor: const Color(0xFFFF007F),
                onPressed: () {
                  widget.game.resumeEngine();
                  widget.game.overlays.remove('WinOverlay');
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinButton extends StatelessWidget {
  const _WinButton({
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
