import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a crisp Google "G" logo procedurally on a Canvas using pure geometry and Path.
/// Eliminates dependency on external raster or SVG assets.
class ProceduralGoogleLogo extends StatelessWidget {
  const ProceduralGoogleLogo({super.key, this.size = 24.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double strokeWidth = radius * 0.42;
    final double arcRadius = radius - strokeWidth / 2;
    final Rect arcRect = Rect.fromCircle(center: center, radius: arcRadius);

    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Convert degrees to radians
    double toRad(double deg) => deg * (math.pi / 180.0);

    // Arcs:
    // Red: Top arc (~200° to ~315°)
    canvas.drawArc(arcRect, toRad(200), toRad(115), false, redPaint);

    // Blue: Right arc (~315° to ~45°)
    canvas.drawArc(arcRect, toRad(315), toRad(90), false, bluePaint);

    // Green: Bottom arc (~45° to ~140°)
    canvas.drawArc(arcRect, toRad(45), toRad(95), false, greenPaint);

    // Yellow: Left arc (~140° to ~200°)
    canvas.drawArc(arcRect, toRad(140), toRad(60), false, yellowPaint);

    // Horizontal bar of the "G" in Blue
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final Rect barRect = Rect.fromLTRB(
      center.dx - strokeWidth * 0.1,
      center.dy - strokeWidth / 2,
      center.dx + radius,
      center.dy + strokeWidth / 2,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

