import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'bubble_color.dart';
import 'procedural_bubble_renderer.dart';

/// Flame PositionComponent representing an individual bubble on the game board.
/// Features 3D procedural shader graphics, Odd-r coordinate tracking, and pop animations.
class BubbleComponent extends PositionComponent with CollisionCallbacks {
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

  // Animation and visual state
  bool _isPopping = false;
  double _popElapsed = 0.0;
  double _popDuration = 0.18;
  Completer<void>? _popCompleter;
  double _alpha = 1.0;

  bool get isPopping => _isPopping;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Add circular collision boundary
    add(CircleHitbox());
  }

  /// Triggers a scale-out burst and fade-out popping animation.
  /// Returns a Future that completes once the bubble is removed from the component tree.
  Future<void> pop({double duration = 0.18}) {
    if (_isPopping) {
      return _popCompleter?.future ?? Future.value();
    }
    _isPopping = true;
    _popElapsed = 0.0;
    _popDuration = duration;
    _popCompleter = Completer<void>();
    return _popCompleter!.future;
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
}
