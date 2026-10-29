import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'bubble_color.dart';
import 'procedural_bubble_renderer.dart';

/// Dynamic projectile bubble fired from the cannon with wall-bouncing physics.
class BulletBubble extends PositionComponent with CollisionCallbacks {
  BulletBubble({
    required this.bubbleType,
    required this.radius,
    required double aimAngle,
    required this.gameWidth,
    required this.ceilingY,
    this.speed = 750.0,
    this.onStopped,
    super.position,
  })  : velocity = Vector2(math.sin(aimAngle) * speed, -math.cos(aimAngle) * speed),
        super(
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  /// Color/element type of the projectile.
  final BubbleType bubbleType;

  /// Radius of the bubble.
  final double radius;

  /// Movement velocity in pixels per second.
  Vector2 velocity;

  /// Speed scalar (defaults to 750.0 px/sec).
  final double speed;

  /// Right wall boundary (game viewport width).
  final double gameWidth;

  /// Top ceiling boundary coordinate.
  final double ceilingY;

  /// Notification callback invoked when the bullet reaches the ceiling or grid.
  final VoidCallback? onStopped;

  /// Whether the bullet is actively in flight.
  bool _isMoving = true;

  /// Whether the bullet has completed its flight and ceased moving.
  bool _hasStopped = false;

  bool get isMoving => _isMoving;
  bool get hasStopped => _hasStopped;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Add collision boundary for grid bubble interactions
    add(CircleHitbox());
  }

  /// Halts the projectile physics and locks its current position.
  void stopMovement() {
    if (_hasStopped) return;
    _isMoving = false;
    _hasStopped = true;
    velocity = Vector2.zero();
    onStopped?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isMoving) return;

    // Advance position by velocity
    position += velocity * dt;

    // Left wall bounce (x - radius <= 0)
    if (position.x - radius <= 0) {
      position.x = radius;
      velocity.x = velocity.x.abs(); // Reflect rightward
    }
    // Right wall bounce (x + radius >= gameWidth)
    else if (position.x + radius >= gameWidth) {
      position.x = gameWidth - radius;
      velocity.x = -velocity.x.abs(); // Reflect leftward
    }

    // Top ceiling boundary
    if (position.y - radius <= ceilingY) {
      position.y = ceilingY + radius;
      stopMovement();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Procedural 3D bubble render matching the grid bubbles
    ProceduralBubbleRenderer.renderSphere(
      canvas,
      center: Offset(radius, radius),
      radius: radius,
      bubbleType: bubbleType,
    );
  }
}

