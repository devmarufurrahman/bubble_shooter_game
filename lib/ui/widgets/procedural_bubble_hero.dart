import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a shiny, arcade-themed cluster of glossy spheres entirely via
/// Canvas, Path, and RadialGradient. Used as the main hero logo visual.
class ProceduralBubbleHero extends StatelessWidget {
  const ProceduralBubbleHero({
    super.key,
    this.size = 140.0,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BubbleHeroPainter(),
      ),
    );
  }
}

class _BubbleHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;

    // Draw three overlapping vibrant arcade spheres
    _drawSphere(
      canvas: canvas,
      center: Offset(center - size.width * 0.2, center + size.height * 0.1),
      radius: size.width * 0.28,
      baseColor: const Color(0xFF00E5FF),
      deepColor: const Color(0xFF0051FF),
    );

    _drawSphere(
      canvas: canvas,
      center: Offset(center + size.width * 0.2, center + size.height * 0.1),
      radius: size.width * 0.28,
      baseColor: const Color(0xFFFF007F),
      deepColor: const Color(0xFF8A00FF),
    );

    _drawSphere(
      canvas: canvas,
      center: Offset(center, center - size.height * 0.12),
      radius: size.width * 0.32,
      baseColor: const Color(0xFFFFD600),
      deepColor: const Color(0xFFFF6D00),
    );
  }

  void _drawSphere({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color baseColor,
    required Color deepColor,
  }) {
    // 1. Ambient outer glow
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: 0.4),
          baseColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));
    canvas.drawCircle(center, radius * 1.4, glowPaint);

    // 2. Spherical 3D shading
    final Paint spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: 0.9),
          baseColor,
          deepColor,
          deepColor.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.25, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, spherePaint);

    // 3. Specular curved highlight path
    final Path highlightPath = Path();
    final double hlW = radius * 0.42;
    final double hlH = radius * 0.22;
    final Offset hlCenter = Offset(center.dx - radius * 0.32, center.dy - radius * 0.35);

    highlightPath.addOval(
      Rect.fromCenter(
        center: hlCenter,
        width: hlW,
        height: hlH,
      ),
    );

    final Paint hlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(hlCenter.dx, hlCenter.dy);
    canvas.rotate(-math.pi / 4);
    canvas.translate(-hlCenter.dx, -hlCenter.dy);
    canvas.drawPath(highlightPath, hlPaint);
    canvas.restore();

    // 4. Subtle inner reflection arc
    final Path rimPath = Path();
    final Rect rimRect = Rect.fromCircle(center: center, radius: radius * 0.88);
    rimPath.addArc(rimRect, math.pi * 0.2, math.pi * 0.6);

    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawPath(rimPath, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
