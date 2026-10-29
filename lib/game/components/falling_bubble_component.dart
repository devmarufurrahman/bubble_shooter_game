import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'bubble_color.dart';
import 'procedural_bubble_renderer.dart';

/// Floating bubble detached from the ceiling anchor that falls under arcade gravity.
class FallingBubbleComponent extends PositionComponent {
  FallingBubbleComponent({
    required this.bubbleType,
    required this.radius,
    required Vector2 startPosition,
    Vector2? initialVelocity,
  })  : velocity = initialVelocity ??
            Vector2(
              (_rng.nextDouble() - 0.5) * 100.0,
              -40.0 - (_rng.nextDouble() * 40.0),
            ),
        super(
          position: startPosition,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  /// Bubble color type.
  final BubbleType bubbleType;

  /// Physical radius.
  final double radius;

  /// Current flight velocity.
  Vector2 velocity;

  static final math.Random _rng = math.Random();

  /// Downward gravity acceleration (px / sec^2).
  static const double gravity = 700.0;

  @override
  void update(double dt) {
    super.update(dt);

    // Apply downward gravity acceleration
    velocity.y += gravity * dt;
    position += velocity * dt;

    // Despawn once well below screen bottom
    if (position.y > 800) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    ProceduralBubbleRenderer.renderSphere(
      canvas,
      center: Offset(radius, radius),
      radius: radius,
      bubbleType: bubbleType,
      drawShadow: true,
    );
  }
}

