import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'bubble_color.dart';

/// Procedural particle explosion spawned when bubbles match, pop, or drop.
/// Disperses 10-14 tiny sparkling circular fragments matching the bubble's color palette,
/// animating velocity, gravity, radius shrinking (4px -> 0), and opacity fade-out over 0.4s.
class BubblePopParticle extends ParticleSystemComponent {
  BubblePopParticle({
    required Vector2 position,
    required BubbleType bubbleType,
    int particleCount = 12,
  }) : super(
          position: position,
          particle: _buildPopParticle(bubbleType, particleCount),
        );

  /// Constructs the composite particle hierarchy using [AcceleratedParticle] and [ComputedParticle].
  static Particle _buildPopParticle(BubbleType bubbleType, int count) {
    final math.Random rng = math.Random();
    final Color baseColor = bubbleType.baseColor;
    final Color highlightColor = bubbleType.highlightColor;

    return Particle.generate(
      count: count,
      lifespan: 0.4,
      generator: (i) {
        // Random 360-degree dispersion angle
        final double angle = rng.nextDouble() * 2 * math.pi;

        // High initial burst velocity (80 to 220 px/s)
        final double speed = 80.0 + rng.nextDouble() * 140.0;
        final Vector2 initialVelocity = Vector2(
          math.cos(angle) * speed,
          math.sin(angle) * speed,
        );

        // Slight random variation in initial radius (~4px)
        final double initialRadius = 3.2 + rng.nextDouble() * 1.6;

        // Alternate between base color and sparkling highlight tint
        final Color particleColor = rng.nextBool() ? baseColor : highlightColor;

        return AcceleratedParticle(
          speed: initialVelocity,
          // Gravity acceleration pulling particles downward slightly
          acceleration: Vector2(0, 220.0),
          child: ComputedParticle(
            renderer: (Canvas canvas, Particle particle) {
              final double t = particle.progress; // 0.0 at birth -> 1.0 at death
              final double remaining = (1.0 - t).clamp(0.0, 1.0);

              // Radius shrinks from ~4px down to 0 over 0.4 seconds
              final double currentRadius = initialRadius * remaining;
              if (currentRadius <= 0.1) return;

              // Fade out opacity over time
              final Paint paint = Paint()
                ..color = particleColor.withValues(alpha: remaining)
                ..style = PaintingStyle.fill;

              canvas.drawCircle(Offset.zero, currentRadius, paint);

              // Center sparkle highlight during first half of life
              if (t < 0.45) {
                final double sparkleAlpha = (1.0 - t * 2.2).clamp(0.0, 1.0);
                final Paint sparklePaint = Paint()
                  ..color = Colors.white.withValues(alpha: sparkleAlpha)
                  ..style = PaintingStyle.fill;
                canvas.drawCircle(Offset.zero, currentRadius * 0.45, sparklePaint);
              }
            },
          ),
        );
      },
    );
  }
}

