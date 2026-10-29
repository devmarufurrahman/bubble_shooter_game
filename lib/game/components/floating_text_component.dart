import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Arcade floating score popup component (+100, COMBO x2, +200 DROP!).
/// Renders high-contrast stroked arcade typography that springs in with an elastic
/// scale curve, glides vertically upward, and smoothly fades out before self-removing.
class FloatingTextComponent extends PositionComponent {
  FloatingTextComponent({
    required this.text,
    required Vector2 position,
    this.textColor = const Color(0xFFFFD600), // Vibrant neon gold default
    this.strokeColor = const Color(0xFF070A14), // Dark outline for maximum contrast
    this.fontSize = 17.0,
    this.floatSpeed = 60.0,
    this.duration = 0.70,
  }) : super(
          position: position,
          anchor: Anchor.center,
          priority: 150, // Float on top of bubbles and backdrop
        );

  /// Score or combo string (e.g. '+100', '+300 COMBO!', '+200 DROP!').
  final String text;

  /// Interior fill color of the text.
  final Color textColor;

  /// Exterior outline stroke color.
  final Color strokeColor;

  /// Font size in logical pixels.
  final double fontSize;

  /// Vertical float velocity in pixels per second.
  final double floatSpeed;

  /// Total duration of the animation before removal.
  final double duration;

  double _elapsed = 0.0;
  double _scale = 0.5;
  double _opacity = 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    // Self-destruct upon completion of lifecycle
    if (_elapsed >= duration) {
      removeFromParent();
      return;
    }

    // 1. Float vertically upward
    position.y -= floatSpeed * dt;

    final double t = (_elapsed / duration).clamp(0.0, 1.0);

    // 2. Elastic scale pop: starts at 0.5, springs up to 1.25, then eases to 1.0
    if (t < 0.35) {
      final double progress = t / 0.35;
      final double elastic = Curves.easeOutBack.transform(progress);
      _scale = 0.5 + (0.75 * elastic); // 0.5 -> 1.25
    } else {
      final double decay = (t - 0.35) / 0.65;
      _scale = 1.25 - (0.25 * decay); // 1.25 -> 1.0
    }

    // 3. Opacity lifecycle: solid 1.0 until 55% of duration, then fades to 0.0
    if (t < 0.55) {
      _opacity = 1.0;
    } else {
      _opacity = (1.0 - ((t - 0.55) / 0.45)).clamp(0.0, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_opacity <= 0.0) return;

    final double currentSize = fontSize * _scale;

    // 1. Pass 1: Crisp exterior outline stroke
    final TextPainter strokePainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: currentSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = strokeColor.withValues(alpha: _opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 2. Pass 2: Vibrant glowing text fill
    final TextPainter fillPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: currentSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: textColor.withValues(alpha: _opacity),
          shadows: [
            Shadow(
              color: textColor.withValues(alpha: _opacity * 0.75),
              blurRadius: 8.0,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Centered drawing relative to component Anchor.center
    final Offset drawOffset = Offset(
      -fillPainter.width / 2,
      -fillPainter.height / 2,
    );

    strokePainter.paint(canvas, drawOffset);
    fillPainter.paint(canvas, drawOffset);
  }
}

