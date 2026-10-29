import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative bubble data for the procedural arcade background.
class _BackgroundBubble {
  final double xRatio;
  final double yRatio;
  final double radius;
  final Color primaryColor;
  final Color glowColor;
  final double opacity;

  const _BackgroundBubble({
    required this.xRatio,
    required this.yRatio,
    required this.radius,
    required this.primaryColor,
    required this.glowColor,
    required this.opacity,
  });
}

/// Polished arcade-style background rendered entirely through procedural shaders,
/// Canvas draws, Path curves, and RadialGradients.
class ArcadeBackground extends StatelessWidget {
  const ArcadeBackground({
    super.key,
    required this.child,
    this.showFloatingBubbles = true,
  });

  final Widget child;
  final bool showFloatingBubbles;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Deep Space Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF070A14),
                Color(0xFF0F1528),
                Color(0xFF161331),
                Color(0xFF070814),
              ],
              stops: [0.0, 0.35, 0.75, 1.0],
            ),
          ),
        ),

        // Glowing Ambient Radial Glows (Procedural lighting)
        Positioned(
          top: -80,
          left: -60,
          width: 260,
          height: 260,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.18),
                  const Color(0xFF00E5FF).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -80,
          width: 320,
          height: 320,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF007F).withValues(alpha: 0.15),
                  const Color(0xFFFF007F).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Canvas Procedural Bubbles
        if (showFloatingBubbles)
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ArcadeCanvasPainter(),
              ),
            ),
          ),

        // Foreground content
        Positioned.fill(child: child),
      ],
    );
  }
}

class _ArcadeCanvasPainter extends CustomPainter {
  const _ArcadeCanvasPainter();

  static const List<_BackgroundBubble> bubbles = [
    _BackgroundBubble(
      xRatio: 0.15,
      yRatio: 0.18,
      radius: 46,
      primaryColor: Color(0xFF00E5FF),
      glowColor: Color(0xFF0077FF),
      opacity: 0.35,
    ),
    _BackgroundBubble(
      xRatio: 0.85,
      yRatio: 0.22,
      radius: 60,
      primaryColor: Color(0xFFFF007F),
      glowColor: Color(0xFF8A00FF),
      opacity: 0.30,
    ),
    _BackgroundBubble(
      xRatio: 0.25,
      yRatio: 0.58,
      radius: 35,
      primaryColor: Color(0xFF76FF03),
      glowColor: Color(0xFF00E676),
      opacity: 0.25,
    ),
    _BackgroundBubble(
      xRatio: 0.80,
      yRatio: 0.72,
      radius: 52,
      primaryColor: Color(0xFFFFD600),
      glowColor: Color(0xFFFF6D00),
      opacity: 0.30,
    ),
    _BackgroundBubble(
      xRatio: 0.50,
      yRatio: 0.88,
      radius: 40,
      primaryColor: Color(0xFFD500F9),
      glowColor: Color(0xFF651FFF),
      opacity: 0.28,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final Offset center = Offset(size.width * b.xRatio, size.height * b.yRatio);
      final double r = b.radius;

      // Outer Glow
      final Paint glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            b.glowColor.withValues(alpha: b.opacity * 0.7),
            b.glowColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 1.5));
      canvas.drawCircle(center, r * 1.5, glowPaint);

      // Bubble Body (Radial Gradient for spherical 3D appearance)
      final Paint bodyPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.85,
          colors: [
            b.primaryColor.withValues(alpha: b.opacity),
            b.glowColor.withValues(alpha: b.opacity * 0.75),
            b.glowColor.withValues(alpha: b.opacity * 0.1),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, bodyPaint);

      // Bubble Rim Stroke
      final Paint rimPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: b.opacity * 0.9),
            b.primaryColor.withValues(alpha: b.opacity * 0.4),
            b.glowColor.withValues(alpha: b.opacity * 0.2),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, rimPaint);

      // Specular Highlight (Procedural Path with crescent reflection)
      final Path highlightPath = Path();
      final double hRadiusX = r * 0.38;
      final double hRadiusY = r * 0.22;
      final Offset hCenter = Offset(center.dx - r * 0.32, center.dy - r * 0.35);

      highlightPath.addOval(
        Rect.fromCenter(
          center: hCenter,
          width: hRadiusX * 2,
          height: hRadiusY * 2,
        ),
      );

      final Paint highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: b.opacity * 0.95)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(hCenter.dx, hCenter.dy);
      canvas.rotate(-math.pi / 4);
      canvas.translate(-hCenter.dx, -hCenter.dy);
      canvas.drawPath(highlightPath, highlightPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
