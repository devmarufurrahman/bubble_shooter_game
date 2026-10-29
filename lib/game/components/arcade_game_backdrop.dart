import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Procedural background component for the Flame game viewport.
/// Renders a dark arcade gradient backdrop and a glowing top-ceiling boundary line.
class ArcadeGameBackdrop extends PositionComponent {
  ArcadeGameBackdrop({
    required this.ceilingY,
    Vector2? size,
  }) : super(
          position: Vector2.zero(),
          size: size ?? Vector2(400, 700),
          priority: -10, // Ensure backdrop stays behind all game entities
        );

  /// Vertical Y position of the ceiling boundary line.
  final double ceilingY;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final Rect fullRect = Rect.fromLTWH(0, 0, size.x, size.y);

    // 1. Dark sleek arcade gradient
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF060913),
          Color(0xFF0D1326),
          Color(0xFF14122C),
          Color(0xFF060711),
        ],
        stops: [0.0, 0.4, 0.8, 1.0],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, bgPaint);

    // 2. Subtle ambient grid lines for arcade depth
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.035)
      ..strokeWidth = 1.0;

    const double gridSpacing = 40.0;
    for (double x = 0; x <= size.x; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y <= size.y; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    // 3. Glowing ceiling boundary structure
    // Ceiling fill area above boundary
    final Rect ceilingRect = Rect.fromLTWH(0, 0, size.x, ceilingY);
    final Paint ceilingAreaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF04060C),
          const Color(0xFF0B1020).withValues(alpha: 0.9),
        ],
      ).createShader(ceilingRect);
    canvas.drawRect(ceilingRect, ceilingAreaPaint);

    // Ceiling boundary glow
    final Paint glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawLine(
      Offset(0, ceilingY),
      Offset(size.x, ceilingY),
      glowPaint,
    );

    // Sharp neon ceiling line
    final Paint linePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.85)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(0, ceilingY),
      Offset(size.x, ceilingY),
      linePaint,
    );

    // Metallic notches along ceiling line for arcade industrial styling
    final Paint notchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    for (double x = 10; x < size.x; x += 30) {
      canvas.drawLine(Offset(x, ceilingY - 6), Offset(x + 10, ceilingY), notchPaint);
    }
  }
}

