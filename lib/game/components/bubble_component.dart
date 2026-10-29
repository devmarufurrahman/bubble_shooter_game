import 'dart:async';
import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'bubble_color.dart';
import 'procedural_bubble_renderer.dart';

/// Flame PositionComponent representing an individual bubble on the game board.
/// Features 3D procedural shader graphics, Odd-r coordinate tracking,
/// pop animations, and physics-driven downward drop animations.
class BubbleComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  BubbleComponent({
    required this.row,
    required this.col,
    required this.bubbleType,
    required this.radius,
    super.position,
  }) : super(
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  /// Grid row index (0-based).
  int row;

  /// Grid column index (0-based).
  int col;

  /// Active color and element type.
  BubbleType bubbleType;

  /// Visual and collision radius of the bubble.
  final double radius;

  // Collision shape
  CircleHitbox? _hitbox;

  // Pop animation state
  bool _isPopping = false;
  double _popElapsed = 0.0;
  double _popDuration = 0.18;
  Completer<void>? _popCompleter;

  // Drop animation state
  bool _isDropping = false;
  double _velocityY = 0.0;
  double _velocityX = 0.0;
  double _rotationSpeed = 0.0;
  Completer<void>? _dropCompleter;

  // Render opacity
  double _alpha = 1.0;

  /// Whether this bubble is currently playing its pop burst animation.
  bool get isPopping => _isPopping;

  /// Whether this bubble is currently dropping under gravity physics.
  bool get isDropping => _isDropping;

  /// Active circular collision boundary, or null if removed during pop or drop.
  CircleHitbox? get hitbox => _hitbox;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Add circular collision boundary
    _hitbox = CircleHitbox();
    add(_hitbox!);
  }

  /// Triggers a scale-out burst and fade-out popping animation.
  /// Returns a Future that completes once the bubble is removed from the component tree.
  Future<void> pop({double duration = 0.18}) {
    if (_isPopping) {
      return _popCompleter?.future ?? Future.value();
    }
    if (_isDropping) {
      return Future.value();
    }
    _isPopping = true;
    _popElapsed = 0.0;
    _popDuration = duration;
    _popCompleter = Completer<void>();

    // Deactivate collision hitbox during pop so it does not participate in further collisions.
    // NOTE: We deliberately do NOT call _hitbox!.removeFromParent() here because doing so
    // mid-iteration in Flame's collision loop causes ConcurrentModificationError.
    _hitbox?.collisionType = CollisionType.inactive;

    return _popCompleter!.future;
  }

  /// Initiates dynamic physics-driven falling for disconnected floating bubbles.
  /// Applies gravity acceleration, slight random spin, and fade-out before removing.
  Future<void> dropAsFloating() {
    if (_isDropping) {
      return _dropCompleter?.future ?? Future.value();
    }
    if (_isPopping) {
      return Future.value();
    }

    _isDropping = true;
    _dropCompleter = Completer<void>();

    // Immediately deactivate collision hitbox so it no longer intercepts bullets.
    // NOTE: We deliberately do NOT call _hitbox!.removeFromParent() here because doing so
    // mid-iteration in Flame's collision loop causes ConcurrentModificationError.
    _hitbox?.collisionType = CollisionType.inactive;

    // Set initial downward momentum with slight horizontal scatter & rotational spin
    final rng = math.Random();
    _velocityX = (rng.nextDouble() - 0.5) * 80.0;
    _velocityY = -30.0 - (rng.nextDouble() * 30.0);
    _rotationSpeed = (rng.nextDouble() - 0.5) * 4.0;

    return _dropCompleter!.future;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isPopping) {
      _popElapsed += dt;
      final double progress = (_popElapsed / _popDuration).clamp(0.0, 1.0);

      // Scale-out expansion curve
      scale = Vector2.all(1.0 + (progress * 0.45));
      _alpha = (1.0 - progress).clamp(0.0, 1.0);

      if (progress >= 1.0) {
        removeFromParent();
        if (_popCompleter != null && !_popCompleter!.isCompleted) {
          _popCompleter!.complete();
        }
      }
      return;
    }

    if (_isDropping) {
      // 1. Gravity physics acceleration (1200 px/sec^2)
      _velocityY += 1200.0 * dt;
      position.y += _velocityY * dt;
      position.x += _velocityX * dt;
      angle += _rotationSpeed * dt;

      // 2. Fade out opacity as bubble drops past lower threshold
      if (position.y > 550.0) {
        _alpha = (_alpha - 2.5 * dt).clamp(0.0, 1.0);
      }

      // 3. Despawn once well below screen bottom or fully faded
      double maxY = 750.0;
      if (isMounted) {
        try {
          maxY = game.size.y + 50.0;
        } catch (_) {
          maxY = 750.0;
        }
      }
      if (position.y > maxY || _alpha <= 0.0) {
        removeFromParent();
        if (_dropCompleter != null && !_dropCompleter!.isCompleted) {
          _dropCompleter!.complete();
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_alpha <= 0.0) return;

    ProceduralBubbleRenderer.renderSphere(
      canvas,
      center: Offset(radius, radius),
      radius: radius,
      bubbleType: bubbleType,
      alpha: _alpha,
    );
  }

  @override
  void onRemove() {
    // 1. Complete and dereference any active animation completers
    if (_popCompleter != null && !_popCompleter!.isCompleted) {
      _popCompleter!.complete();
    }
    _popCompleter = null;

    if (_dropCompleter != null && !_dropCompleter!.isCompleted) {
      _dropCompleter!.complete();
    }
    _dropCompleter = null;

    // 2. Inactivate collision hitbox
    if (_hitbox != null) {
      _hitbox!.collisionType = CollisionType.inactive;
      _hitbox = null;
    }

    super.onRemove();
  }
}
