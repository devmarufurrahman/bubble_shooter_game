import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/audio/audio.dart';
import '../../core/utils/utils.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../game/bubble_shooter_game.dart';
import '../../ui/game_screen.dart';

/// Clean alias for backward-compatibility with Flame overlay naming.
typedef WinOverlay = WinDialog;

/// Arcade glassmorphic victory dialog displayed upon clearing the stage.
/// Features a sequential star-burst celebration animation with sparkling audio/haptics,
/// a smooth 1-second counting score display, and responsive navigation controls.
class WinDialog extends StatefulWidget {
  const WinDialog({
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
  State<WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends State<WinDialog> with SingleTickerProviderStateMixin {
  late final int _stars;
  late final AnimationController _scoreController;
  late final Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    final LevelConfig config = LevelConfig.getLevel(widget.game.levelNumber);
    _stars = WinDialog.calculateStars(widget.game.shotsRemaining, config.maxShots);
    _saveProgress();

    // 1-second counting score animation
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    );
    _scoreController.forward();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    await LevelRepository.saveProgress(
      level: widget.game.levelNumber,
      score: widget.game.currentScore,
      stars: _stars,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LevelConfig config = LevelConfig.getLevel(widget.game.levelNumber);

    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                blurRadius: 32,
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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

              // Staggered Animated Star-Burst Slots (300ms intervals)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return _AnimatedStarSlot(
                    index: index,
                    isEarned: index < _stars,
                    delay: Duration(milliseconds: 300 * (index + 1)),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Animated Score Counter (0 to currentScore over 1 second)
              AnimatedBuilder(
                animation: _scoreAnimation,
                builder: (context, _) {
                  final int animatedScore =
                      (_scoreAnimation.value * widget.game.currentScore).round();
                  return Column(
                    children: [
                      Text(
                        'FINAL SCORE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$animatedScore',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(color: Color(0xFF00E5FF), blurRadius: 14),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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

              const SizedBox(height: 24),

              // Navigation Action Buttons
              if (widget.game.levelNumber < LevelRepository.totalLevels) ...[
                _WinButton(
                  label: 'NEXT LEVEL',
                  icon: Icons.arrow_forward_rounded,
                  borderColor: const Color(0xFF00E5FF),
                  onPressed: () {
                    HapticsHelper.selectionClick();
                    widget.game.resumeEngine();
                    widget.game.overlays.remove('WinOverlay');
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => GameScreen(levelNumber: widget.game.levelNumber + 1),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              _WinButton(
                label: 'RETRY',
                icon: Icons.refresh_rounded,
                borderColor: const Color(0xFFFFD600),
                onPressed: () {
                  HapticsHelper.selectionClick();
                  widget.game.resumeEngine();
                  widget.game.overlays.remove('WinOverlay');
                  widget.game.restartLevel();
                },
              ),
              const SizedBox(height: 12),
              _WinButton(
                label: 'STAGE SELECT',
                icon: Icons.grid_view_rounded,
                borderColor: const Color(0xFFFF007F),
                onPressed: () {
                  HapticsHelper.selectionClick();
                  widget.game.resumeEngine();
                  widget.game.overlays.remove('WinOverlay');
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

/// An individual star slot that displays an empty placeholder slot and
/// animates into a bursting golden star with elastic bounce when earned.
class _AnimatedStarSlot extends StatefulWidget {
  const _AnimatedStarSlot({
    required this.index,
    required this.isEarned,
    required this.delay,
  });

  final int index;
  final bool isEarned;
  final Duration delay;

  @override
  State<_AnimatedStarSlot> createState() => _AnimatedStarSlotState();
}

class _AnimatedStarSlotState extends State<_AnimatedStarSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  Timer? _popTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    if (widget.isEarned) {
      _popTimer = Timer(widget.delay, () {
        if (!mounted) return;
        _controller.forward();
        SoundManager.instance.playChime();
        HapticsHelper.mediumImpact();
      });
    }
  }

  @override
  void dispose() {
    _popTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Empty Star Slot Placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0B1020),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
              ),
              child: Icon(
                Icons.star_rounded,
                color: Colors.white.withValues(alpha: 0.15),
                size: 24,
              ),
            ),

            // Popping Star Burst (Earned)
            if (widget.isEarned)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD600).withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFD600),
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Arcade-styled interactive navigation button with neon border and tactile feedback.
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
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
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
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
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
