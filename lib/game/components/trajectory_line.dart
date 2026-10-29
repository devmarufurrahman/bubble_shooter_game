import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Segment representing a single raycast bounce of the trajectory line.
class TrajectorySegment {
  final Offset start;
  final Offset end;
  const TrajectorySegment(this.start, this.end);
}

/// Standalone mathematical trajectory calculator and renderer for aiming guides.
class TrajectoryLine {
  const TrajectoryLine._();

  /// Calculates raycast reflection segments off lateral boundaries and ceiling.
  static List<TrajectorySegment> calculateSegments({
    required Offset origin,
    required double angle,
    required double minX,
    required double maxX,
    required double ceilingY,
    int maxBounces = 3,
  }) {
    Offset current = origin;
    Offset dir = Offset(math.sin(angle), -math.cos(angle));

    final List<TrajectorySegment> segments = [];

    for (int bounce = 0; bounce < maxBounces; bounce++) {
      if (dir.dy >= 0) break; // Trajectory must travel upwards

      final double tCeiling = (ceilingY - current.dy) / dir.dy;

      if (dir.dx < 0) {
        final double tWall = (minX - current.dx) / dir.dx;
        if (tWall < tCeiling) {
          final Offset hit = Offset(minX, current.dy + dir.dy * tWall);
          segments.add(TrajectorySegment(current, hit));
          current = hit;
          dir = Offset(-dir.dx, dir.dy);
        } else {
          final Offset hit = Offset(current.dx + dir.dx * tCeiling, ceilingY);
          segments.add(TrajectorySegment(current, hit));
          break;
        }
      } else if (dir.dx > 0) {
        final double tWall = (maxX - current.dx) / dir.dx;
        if (tWall < tCeiling) {
          final Offset hit = Offset(maxX, current.dy + dir.dy * tWall);
          segments.add(TrajectorySegment(current, hit));
          current = hit;
          dir = Offset(-dir.dx, dir.dy);
        } else {
          final Offset hit = Offset(current.dx + dir.dx * tCeiling, ceilingY);
          segments.add(TrajectorySegment(current, hit));
          break;
        }
      } else {
        final Offset hit = Offset(current.dx, ceilingY);
        segments.add(TrajectorySegment(current, hit));
        break;
      }
    }

    return segments;
  }

  /// Renders glowing arcade dotted trajectory along [segments].
  static void render(
    Canvas canvas, {
    required List<TrajectorySegment> segments,
    required Color glowColor,
    Color dotColor = Colors.white,
    double dotSpacing = 16.0,
    double dotRadius = 2.2,
    double glowRadius = 4.0,
  }) {
    final Paint glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final Paint dotPaint = Paint()
      ..color = dotColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    for (final seg in segments) {
      final double dist = (seg.end - seg.start).distance;
      if (dist <= 0) continue;
      final Offset step = (seg.end - seg.start) / dist;

      for (double d = 0; d < dist; d += dotSpacing) {
        final Offset pt = seg.start + (step * d);
        canvas.drawCircle(pt, glowRadius, glowPaint);
        canvas.drawCircle(pt, dotRadius, dotPaint);
      }
    }
  }
}

