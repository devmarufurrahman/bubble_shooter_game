import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'grid_manager.dart';

/// Dynamic neon danger threshold boundary line.
/// Continuously monitors the lowest occupied bubble in [GridManager] and switches
/// into a high-visibility "CRITICAL" warning mode when bubbles approach within 1-2 rows
/// of the danger line, triggering rapid sine-wave red pulsations and a bottom vignette flash.
class DangerLineComponent extends PositionComponent {
  DangerLineComponent({
    required this.dangerThresholdY,
    required this.gameWidth,
    required this.gameHeight,
    required this.gridManager,
    Vector2? position,
  }) : super(
          position: position ?? Vector2(0, 0),
          size: Vector2(gameWidth, gameHeight),
          priority: -5, // In front of backdrop, behind active bubbles and cannon
        );

  /// Vertical threshold Y coordinate where reaching triggers defeat.
  final double dangerThresholdY;

  /// Game canvas width.
  final double gameWidth;

  /// Game canvas height.
  final double gameHeight;

  /// Reference to the active hexagonal grid manager.
  final GridManager gridManager;

  /// Whether bubbles are dangerously close (within 1-2 rows) to the threshold.
  bool _isCritical = false;
  bool get isCritical => _isCritical;

  /// Internal timer driving the rapid red sine-wave pulsation.
  double _pulseTimer = 0.0;

  /// Cached lowest bubble coordinate.
  double _lowestBubbleY = 0.0;
  double get lowestBubbleY => _lowestBubbleY;

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;

    // 1. Calculate row height in Odd-r layout
    final double rowHeight = gridManager.radius * 1.7320508; // radius * sqrt(3)
    // Within 2 rows of threshold:
    final double criticalThreshold = dangerThresholdY - (rowHeight * 2.0);

    // 2. Discover the lowest active bubble center on the board
    double maxActiveY = 0.0;
    for (final bubble in gridManager.activeBubbles) {
      if (bubble.position.y > maxActiveY) {
        maxActiveY = bubble.position.y;
      }
    }
    _lowestBubbleY = maxActiveY;

    // 3. Switch critical state based on proximity
    _isCritical = maxActiveY >= criticalThreshold && maxActiveY > 0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final double y = dangerThresholdY;

    if (_isCritical) {
      _renderCriticalMode(canvas, y);
    } else {
      _renderCalmMode(canvas, y);
    }
  }

  /// Renders high-priority alarm: rapid red sine wave pulsation, wide neon aura,
  /// hazard chevron stripes, and a subtle red vignette over the bottom screen edge.
  void _renderCriticalMode(Canvas canvas, double y) {
    // Rapid pulsation between 0.25 and 1.0 (frequency ~9 rad/s)
    final double pulse = (math.sin(_pulseTimer * 9.0) * 0.40 + 0.60).clamp(0.0, 1.0);

    // 1. Flashing red bottom vignette gradient overlay
    final Rect vignetteRect = Rect.fromLTWH(0, y - 50, gameWidth, gameHeight - (y - 50));
    final Paint vignettePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFFFF1744).withValues(alpha: 0.12 * pulse),
          const Color(0xFFFF1744).withValues(alpha: 0.28 * pulse),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(vignetteRect);
    canvas.drawRect(vignetteRect, vignettePaint);

    // 2. Broad glowing aura along danger line
    final Paint auraPaint = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.45 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawLine(Offset(0, y), Offset(gameWidth, y), auraPaint);

    // 3. Sharp neon red boundary line
    final Paint sharpLine = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.95 * pulse)
      ..strokeWidth = 2.2;
    canvas.drawLine(Offset(0, y), Offset(gameWidth, y), sharpLine);

    // 4. Animated hazard dashes traveling along the line
    final Paint dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * pulse)
      ..strokeWidth = 2.0;

    const double dashLen = 14.0;
    const double gap = 12.0;
    final double offset = (_pulseTimer * 40.0) % (dashLen + gap);

    for (double x = -dashLen + offset; x < gameWidth; x += (dashLen + gap)) {
      final double startX = x.clamp(0.0, gameWidth);
      final double endX = (x + dashLen).clamp(0.0, gameWidth);
      if (endX > startX) {
        canvas.drawLine(Offset(startX, y), Offset(endX, y), dashPaint);
      }
    }

    // 5. Pulsing "⚠ DANGER ⚠" center badge
    _renderDangerBadge(canvas, y, pulse);
  }

  /// Renders calm / non-critical state: subtle dashed cyan line with dim glow.
  void _renderCalmMode(Canvas canvas, double y) {
    // Subtle faint cyan glow
    final Paint subtleGlow = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawLine(Offset(0, y), Offset(gameWidth, y), subtleGlow);

    // Faint dashed line
    final Paint subtleDashes = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
      ..strokeWidth = 1.2;

    const double dashLen = 8.0;
    const double gap = 8.0;
    for (double x = 0; x < gameWidth; x += (dashLen + gap)) {
      canvas.drawLine(Offset(x, y), Offset(x + dashLen, y), subtleDashes);
    }
  }

  void _renderDangerBadge(Canvas canvas, double y, double pulse) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: '⚠ DANGER ZONE ⚠',
        style: TextStyle(
          color: Colors.white.withValues(alpha: pulse),
          fontSize: 9.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          shadows: [
            Shadow(
              color: const Color(0xFFFF1744).withValues(alpha: pulse),
              blurRadius: 8.0,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const double padH = 10.0;
    const double padV = 3.0;
    final Rect badgeRect = Rect.fromCenter(
      center: Offset(gameWidth / 2, y),
      width: tp.width + (padH * 2),
      height: tp.height + (padV * 2),
    );
    final RRect badgeRRect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(6.0));

    // Badge background
    final Paint badgeBg = Paint()
      ..color = const Color(0xFF160307).withValues(alpha: 0.90 * pulse)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(badgeRRect, badgeBg);

    // Badge border
    final Paint badgeBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.90 * pulse);
    canvas.drawRRect(badgeRRect, badgeBorder);

    tp.paint(canvas, Offset((gameWidth / 2) - (tp.width / 2), y - (tp.height / 2)));
  }
}

