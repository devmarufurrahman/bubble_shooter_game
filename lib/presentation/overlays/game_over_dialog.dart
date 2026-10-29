import 'package:flutter/material.dart';
import '../../game/bubble_shooter_game.dart';

/// Clean alias for backward-compatibility with Flame overlay naming.
typedef GameOverOverlay = GameOverDialog;

/// Arcade glassmorphic defeat dialog displayed upon running out of shots or floor breach.
class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    super.key,
    required this.game,
  });

  final BubbleShooterGame game;

  @override
  Widget build(BuildContext context) {
    final String reason = game.gameOverReason ?? 'LEVEL FAILED';

    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFF11172E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFF1744).withValues(alpha: 0.6),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF1744).withValues(alpha: 0.3),
                blurRadius: 30,
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Color(0xFFFF1744),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.0,
                  shadows: [
                    Shadow(color: Color(0xFFFF1744), blurRadius: 16),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1744).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reason,
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'FINAL SCORE: ${game.currentScore}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _GameOverButton(
                label: 'RETRY',
                icon: Icons.refresh_rounded,
                borderColor: const Color(0xFFFFD600),
                onPressed: () {
                  game.resumeEngine();
                  game.overlays.remove('GameOverOverlay');
                  game.restartLevel();
                },
              ),
              const SizedBox(height: 14),
              _GameOverButton(
                label: 'STAGE SELECT',
                icon: Icons.grid_view_rounded,
                borderColor: const Color(0xFFFF007F),
                onPressed: () {
                  game.resumeEngine();
                  game.overlays.remove('GameOverOverlay');
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _GameOverButton extends StatelessWidget {
  const _GameOverButton({
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

