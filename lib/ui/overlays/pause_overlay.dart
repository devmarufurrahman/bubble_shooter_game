import 'package:flutter/material.dart';
import '../../game/bubble_shooter_game.dart';

/// Arcade glassmorphic pause dialog overlay.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.game,
  });

  final BubbleShooterGame game;

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
                'STAGE ${game.levelNumber.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),
              _OverlayButton(
                label: 'RESUME',
                icon: Icons.play_arrow_rounded,
                borderColor: const Color(0xFF00E5FF),
                onPressed: () {
                  game.resumeEngine();
                  game.overlays.remove('PauseOverlay');
                },
              ),
              const SizedBox(height: 14),
              _OverlayButton(
                label: 'RESTART',
                icon: Icons.refresh_rounded,
                borderColor: const Color(0xFFFFD600),
                onPressed: () {
                  game.resumeEngine();
                  game.overlays.remove('PauseOverlay');
                  game.restartLevel();
                },
              ),
              const SizedBox(height: 14),
              _OverlayButton(
                label: 'EXIT',
                icon: Icons.exit_to_app_rounded,
                borderColor: const Color(0xFFFF007F),
                onPressed: () {
                  game.resumeEngine();
                  game.overlays.remove('PauseOverlay');
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

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
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

