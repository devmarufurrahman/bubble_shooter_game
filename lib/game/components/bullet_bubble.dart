import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'bubble_color.dart';
import 'bubble_component.dart';
import 'procedural_bubble_renderer.dart';

/// Dynamic projectile bubble fired from the cannon with wall-bouncing physics,
/// collision callbacks, and grid snapping triggers.
class BulletBubble extends PositionComponent with CollisionCallbacks {
  BulletBubble({
    required this.bubbleType,
    required this.radius,
    required double aimAngle,
    required this.gameWidth,
    required this.ceilingY,
    this.speed = 750.0,
    this.onStopped,
    this.onImpact,
    this.onBounce,
    super.position,
  })  : velocity = Vector2(math.sin(aimAngle) * speed, -math.cos(aimAngle) * speed),
        super(
          size: Vector2.zero(),
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

  /// Notification callback invoked when movement halts.
  final VoidCallback? onStopped;

  /// Callback triggered upon impact with another bubble or the ceiling.
  final void Function(BubbleComponent? hitBubble)? onImpact;

  /// Callback triggered whenever the bullet reflects off lateral walls.
  final VoidCallback? onBounce;

  /// Whether the bullet is actively in flight.
  bool _isMoving = true;

  /// Whether the bullet has completed its flight and ceased moving.
  bool _hasStopped = false;

  bool get isMoving => _isMoving;
  bool get hasStopped => _hasStopped;

  /// Cached reference to the collision hitbox.
  CircleHitbox? _hitbox;
  CircleHitbox? get hitbox => _hitbox;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Add collision boundary centered at Vector2.zero
    _hitbox = CircleHitbox(
      radius: radius,
      anchor: Anchor.center,
      position: Vector2.zero(),
    );
    add(_hitbox!);
  }

  /// Halts the projectile physics and locks its current position.
  void stopMovement() {
    if (_hasStopped) return;
    _isMoving = false;
    _hasStopped = true;
    velocity = Vector2.zero();
    _hitbox?.collisionType = CollisionType.inactive;
    onStopped?.call();
  }

  @override
  void onRemove() {
    stopMovement();
    if (_hitbox != null) {
      _hitbox!.collisionType = CollisionType.inactive;
      _hitbox = null;
    }
    super.onRemove();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (!_isMoving || _hasStopped) return;

    if (other is BubbleComponent) {
      stopMovement();
      onImpact?.call(other);
    }
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
      if (velocity.x < 0) {
        velocity.x = velocity.x.abs(); // Reflect rightward
        onBounce?.call();
      }
    }
    // Right wall bounce (x + radius >= gameWidth)
    else if (position.x + radius >= gameWidth) {
      position.x = gameWidth - radius;
      if (velocity.x > 0) {
        velocity.x = -velocity.x.abs(); // Reflect leftward
        onBounce?.call();
      }
    }

    // Top ceiling boundary: bullet hits ceiling when position.y - radius <= ceilingY
    // (with ceilingY = kTopHudOffset - radius, this triggers when position.y <= kTopHudOffset).
    // Zero bullets should ever fly above kTopHudOffset (ceilingY + radius).
    if (position.y - radius <= ceilingY || position.y <= ceilingY + radius) {
      position.y = ceilingY + radius;
      stopMovement();
      onImpact?.call(null);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Procedural 3D bubble render centered directly at Offset.zero
    ProceduralBubbleRenderer.renderSphere(
      canvas,
      center: Offset.zero,
      radius: radius,
      bubbleType: bubbleType,
    );
  }
}
