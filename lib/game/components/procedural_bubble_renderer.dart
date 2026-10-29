import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'bubble_color.dart';

/// Reusable procedural shader engine drawing photorealistic 3D glossy spheres
/// with specular crescent highlights and depth shadows.
class ProceduralBubbleRenderer {
  const ProceduralBubbleRenderer._();

  /// Renders a 3D spherical bubble on [canvas] centered at [center] with [radius].
  static void renderSphere(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required BubbleType bubbleType,
    double alpha = 1.0,
    bool drawShadow = true,
  }) {
    if (alpha <= 0.0) return;

    // 1. Soft drop shadow behind the bubble
    if (drawShadow) {
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.28 * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.16);
      canvas.drawCircle(
        Offset(center.dx + radius * 0.08, center.dy + radius * 0.12),
        radius * 0.92,
        shadowPaint,
      );
    }

    // 2. Main spherical 3D radial gradient offset towards top-left (-0.35r, -0.35r)
    final Paint spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.88,
        colors: [
          Colors.white.withValues(alpha: 0.95 * alpha),
          bubbleType.lightTint.withValues(alpha: 0.95 * alpha),
          bubbleType.baseColor.withValues(alpha: 0.95 * alpha),
          bubbleType.shadowTint.withValues(alpha: 0.95 * alpha),
          bubbleType.shadowTint.withValues(alpha: 0.98 * alpha),
        ],
        stops: const [0.0, 0.18, 0.52, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, spherePaint);

    // 3. Subtle outer rim stroke for clean glassy border
    final Paint rimBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.5 * alpha),
          bubbleType.lightTint.withValues(alpha: 0.2 * alpha),
          bubbleType.shadowTint.withValues(alpha: 0.1 * alpha),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 0.5, rimBorderPaint);

    // 4. Primary crescent specular highlight near top-left
    final Path highlightPath = Path();
    final double hlW = radius * 0.44;
    final double hlH = radius * 0.22;
    final Offset hlCenter = Offset(center.dx - radius * 0.35, center.dy - radius * 0.38);

    highlightPath.addOval(
      Rect.fromCenter(
        center: hlCenter,
        width: hlW,
        height: hlH,
      ),
    );

    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85 * alpha)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(hlCenter.dx, hlCenter.dy);
    canvas.rotate(-math.pi / 4);
    canvas.translate(-hlCenter.dx, -hlCenter.dy);
    canvas.drawPath(highlightPath, highlightPaint);
    canvas.restore();

    // 5. Secondary soft bottom-right reflection arc for depth
    final Path secondaryRimPath = Path();
    final Rect secondaryRect = Rect.fromCircle(center: center, radius: radius * 0.84);
    secondaryRimPath.addArc(secondaryRect, math.pi * 0.18, math.pi * 0.6);

    final Paint secondaryRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, radius * 0.06)
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.35 * alpha);
    canvas.drawPath(secondaryRimPath, secondaryRimPaint);
  }
}

