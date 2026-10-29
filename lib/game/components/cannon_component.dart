import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'bubble_color.dart';
import 'grid_manager.dart';
import 'procedural_bubble_renderer.dart';

/// Arcade metallic cannon anchored at bottom-center of the screen.
/// Handles touch aim calculations, 70-degree rotation clamping,
/// raycast reflective dotted trajectory lines, and bubble queue previews.
class CannonComponent extends PositionComponent {
  CannonComponent({
    required this.gameWidth,
    required this.gameHeight,
    required this.ceilingY,
    required this.bubbleRadius,
    Vector2? position,
  }) : super(
          position: position ?? Vector2(gameWidth / 2, gameHeight - 70),
          size: Vector2.all(90),
          anchor: Anchor.center,
        );

  /// Game canvas dimensions.
  final double gameWidth;
  final double gameHeight;

  /// Top boundary limit for trajectory guides.
  final double ceilingY;

  /// Physical bubble radius.
  final double bubbleRadius;

  /// Length of the rotating barrel cylinder in logical pixels.
  static const double barrelLength = 46.0;

  /// Maximum allowed aiming angle (70 degrees).
  static const double maxAimAngle = 70.0 * (math.pi / 180.0);

  /// Current aiming angle in radians (0 = straight up, > 0 = right, < 0 = left).
  double aimAngle = 0.0;

  /// Whether the user is actively dragging/aiming.
  bool isAiming = false;

  /// Active bubble queued to fire.
  late BubbleType currentBubbleType;

  /// Upcoming bubble queued next.
  late BubbleType nextBubbleType;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Default initial queue
    currentBubbleType = BubbleType.random();
    nextBubbleType = BubbleType.random();
  }

  /// Calculates world position of the cannon nozzle tip.
  Vector2 get nozzlePosition {
    return position +
        Vector2(
          math.sin(aimAngle) * barrelLength,
          -math.cos(aimAngle) * barrelLength,
        );
  }

  /// Updates the aim rotation based on an input target point in world coordinates.
  void aimAt(Vector2 targetPoint) {
    // Prevent pointing downwards: clamp touch point to at least 10px above the cannon
    final double effectiveTargetY = math.min(targetPoint.y, position.y - 10.0);
    final double dx = targetPoint.x - position.x;
    final double dy = effectiveTargetY - position.y;

    // Angle relative to straight up (dy is negative, dx is offset)
    final double rawAngle = math.atan2(dy, dx) + (math.pi / 2);

    // Clamp rotation strictly between -70° and +70°
    aimAngle = rawAngle.clamp(-maxAimAngle, maxAimAngle);
  }

  /// Advances the bubble queue: promotes [nextBubbleType] to [currentBubbleType]
  /// and selects a fresh [nextBubbleType] from active colors remaining on the grid.
  void cycleNextBubble(GridManager gridManager) {
    currentBubbleType = nextBubbleType;
    nextBubbleType = pickRandomGridColor(gridManager);
  }

  /// Selects a random [BubbleType] currently existing on the active grid.
  /// Falls back to complete random if the grid has no remaining bubbles.
  BubbleType pickRandomGridColor(GridManager gridManager) {
    final activeBubbles = gridManager.activeBubbles;
    if (activeBubbles.isEmpty) {
      return BubbleType.random();
    }

    // Collect unique colors currently on board
    final Set<BubbleType> availableTypes = activeBubbles.map((b) => b.bubbleType).toSet();
    final List<BubbleType> typeList = availableTypes.toList();
    final math.Random rng = math.Random();
    return typeList[rng.nextInt(typeList.length)];
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Draw dynamic reflective trajectory guide if player is aiming
    if (isAiming) {
      _renderTrajectoryGuide(canvas);
    }

    // 2. Next bubble preview queue (drawn to the left of the cannon)
    _renderNextPreviewPod(canvas);

    // 3. Metallic base pedestal
    _renderBasePedestal(canvas);

    // 4. Rotating barrel turret & loaded bubble
    _renderRotatingTurret(canvas);
  }

  /// Renders raycast wall-reflected dotted trajectory guideline.
  void _renderTrajectoryGuide(Canvas canvas) {
    // Nozzle tip in local canvas coordinates
    Offset current = Offset(
      math.sin(aimAngle) * barrelLength,
      -math.cos(aimAngle) * barrelLength,
    );

    Offset dir = Offset(
      math.sin(aimAngle),
      -math.cos(aimAngle),
    );

    // Bounds in local coordinates
    final double localMinX = bubbleRadius - position.x;
    final double localMaxX = (gameWidth - bubbleRadius) - position.x;
    final double localCeilingY = ceilingY - position.y;

    final List<_GuideSegment> segments = [];

    // Max 3 raycast segments (2 wall reflections + ceiling)
    for (int bounce = 0; bounce < 3; bounce++) {
      if (dir.dy >= 0) break; // Trajectory must travel upwards

      final double tCeiling = (localCeilingY - current.dy) / dir.dy;

      if (dir.dx < 0) {
        // Traveling left: test left wall intersection
        final double tWall = (localMinX - current.dx) / dir.dx;
        if (tWall < tCeiling) {
          final Offset hit = Offset(localMinX, current.dy + dir.dy * tWall);
          segments.add(_GuideSegment(current, hit));
          current = hit;
          dir = Offset(-dir.dx, dir.dy); // Bounce right
        } else {
          final Offset hit = Offset(current.dx + dir.dx * tCeiling, localCeilingY);
          segments.add(_GuideSegment(current, hit));
          break;
        }
      } else if (dir.dx > 0) {
        // Traveling right: test right wall intersection
        final double tWall = (localMaxX - current.dx) / dir.dx;
        if (tWall < tCeiling) {
          final Offset hit = Offset(localMaxX, current.dy + dir.dy * tWall);
          segments.add(_GuideSegment(current, hit));
          current = hit;
          dir = Offset(-dir.dx, dir.dy); // Bounce left
        } else {
          final Offset hit = Offset(current.dx + dir.dx * tCeiling, localCeilingY);
          segments.add(_GuideSegment(current, hit));
          break;
        }
      } else {
        // Straight up
        final Offset hit = Offset(current.dx, localCeilingY);
        segments.add(_GuideSegment(current, hit));
        break;
      }
    }

    // Draw glowing dotted points along each segment
    final Paint glowPaint = Paint()
      ..color = currentBubbleType.glowColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final Paint dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    const double dotSpacing = 16.0;

    for (final seg in segments) {
      final double dist = (seg.end - seg.start).distance;
      if (dist <= 0) continue;
      final Offset step = (seg.end - seg.start) / dist;

      for (double d = 0; d < dist; d += dotSpacing) {
        final Offset pt = seg.start + (step * d);
        canvas.drawCircle(pt, 4.0, glowPaint);
        canvas.drawCircle(pt, 2.2, dotPaint);
      }
    }

    // Draw small target ring at the final trajectory terminus
    if (segments.isNotEmpty) {
      final Offset targetPt = segments.last.end;
      final Paint targetPaint = Paint()
        ..color = currentBubbleType.baseColor.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(targetPt, 8.0, targetPaint);
      canvas.drawCircle(targetPt, 2.5, dotPaint);
    }
  }

  /// Renders the "NEXT" queue preview bubble pod slightly to the left.
  void _renderNextPreviewPod(Canvas canvas) {
    const Offset podCenter = Offset(-72, 8);
    const double podRadius = 24.0;

    // Pod background disk
    final Paint podBg = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1F2B48),
          const Color(0xFF0F1528),
          const Color(0xFF070A14),
        ],
      ).createShader(Rect.fromCircle(center: podCenter, radius: podRadius));
    canvas.drawCircle(podCenter, podRadius, podBg);

    // Pod glowing border
    final Paint podBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6);
    canvas.drawCircle(podCenter, podRadius, podBorder);

    // "NEXT" label badge above the pod
    final TextPainter tp = TextPainter(
      text: const TextSpan(
        text: 'NEXT',
        style: TextStyle(
          color: Color(0xFFFFD600),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(podCenter.dx - (tp.width / 2), podCenter.dy - podRadius - 13));

    // Next preview bubble
    ProceduralBubbleRenderer.renderSphere(
      canvas,
      center: podCenter,
      radius: 14.0,
      bubbleType: nextBubbleType,
      drawShadow: false,
    );
  }

  /// Renders the metallic pedestal base with arcade angle graduations.
  void _renderBasePedestal(Canvas canvas) {
    const double baseRadius = 38.0;

    // Drop shadow
    final Paint baseShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawCircle(const Offset(0, 4), baseRadius, baseShadow);

    // Metallic base gradient
    final Paint basePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF283655),
          Color(0xFF161F36),
          Color(0xFF0B101E),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: baseRadius));
    canvas.drawCircle(Offset.zero, baseRadius, basePaint);

    // Outer neon cyan trim
    final Paint baseTrim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset.zero, baseRadius, baseTrim);

    // Decorative radial tick notches
    final Paint notchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.4);

    for (int deg = -60; deg <= 60; deg += 30) {
      final double rad = deg * (math.pi / 180.0);
      final Offset p1 = Offset(math.sin(rad) * (baseRadius - 6), -math.cos(rad) * (baseRadius - 6));
      final Offset p2 = Offset(math.sin(rad) * (baseRadius - 1), -math.cos(rad) * (baseRadius - 1));
      canvas.drawLine(p1, p2, notchPaint);
    }
  }

  /// Renders rotating barrel turret and the active bubble loaded ready to fire.
  void _renderRotatingTurret(Canvas canvas) {
    canvas.save();
    canvas.rotate(aimAngle);

    // 1. Barrel nozzle cylinder
    const double barrelWidth = 30.0;
    const double halfW = barrelWidth / 2;
    final Rect barrelRect = Rect.fromLTWH(-halfW, -barrelLength, barrelWidth, barrelLength);

    final Paint barrelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF0D1322),
          Color(0xFF2E3D60),
          Color(0xFF4A5F8E),
          Color(0xFF2E3D60),
          Color(0xFF0D1322),
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(barrelRect);

    final RRect barrelRRect = RRect.fromRectAndRadius(barrelRect, const Radius.circular(6));
    canvas.drawRRect(barrelRRect, barrelPaint);

    // Barrel rim highlight
    final Paint barrelRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.8);
    canvas.drawRRect(barrelRRect, barrelRim);

    // Muzzle tip band
    final Paint muzzleBand = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(-halfW, -barrelLength, barrelWidth, 5), muzzleBand);

    // 2. Active ready-to-shoot bubble nestled at the barrel base
    ProceduralBubbleRenderer.renderSphere(
      canvas,
      center: const Offset(0, -6),
      radius: bubbleRadius * 0.95,
      bubbleType: currentBubbleType,
      drawShadow: false,
    );

    // 3. Central pivot cap
    final Paint pivotPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF536894), Color(0xFF161F36)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 10));
    canvas.drawCircle(Offset.zero, 10, pivotPaint);

    final Paint pivotRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.9);
    canvas.drawCircle(Offset.zero, 10, pivotRing);

    canvas.restore();
  }
}

class _GuideSegment {
  final Offset start;
  final Offset end;
  const _GuideSegment(this.start, this.end);
}

