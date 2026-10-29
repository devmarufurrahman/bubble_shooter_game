import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import 'procedural_bubble_renderer.dart';

/// Renders a dynamic vertical arcade ammo stack of mini 3D glossy bubbles
/// beside the cannon pedestal representing upcoming ammunition.
/// Provides smooth scale-down pop transitions whenever a bullet is fired.
class AmmoInventoryComponent extends PositionComponent {
  AmmoInventoryComponent({
    required this.shotsNotifier,
    this.maxVisibleBubbles = 5,
    this.bubbleRadius = 8.5,
    this.spacing = 15.0,
    Vector2? position,
  })  : _shotsRemaining = shotsNotifier.value,
        super(
          position: position ?? Vector2(72, 8),
          size: Vector2(36, 110),
          anchor: Anchor.center,
        ) {
    shotsNotifier.addListener(_onShotsChanged);
  }

  /// Reactive notifier tracking remaining shots in the current game session.
  final ValueNotifier<int> shotsNotifier;

  /// Maximum mini bubbles displayed before adding the `+N` overflow badge.
  final int maxVisibleBubbles;

  /// Radius of each mini 3D glossy sphere.
  final double bubbleRadius;

  /// Vertical step distance between consecutive bubbles in the stack.
  final double spacing;

  /// Current visual shot count.
  int _shotsRemaining = 0;
  int get shotsRemaining => _shotsRemaining;

  /// Pop/shrink animation state for the topmost consumed bubble.
  bool _isPopping = false;
  double _popElapsed = 0.0;
  static const double _popDuration = 0.20; // 200ms scale-down transition
  BubbleType? _poppingBubbleType;

  /// Palette colors cycled for the ammo stack display.
  List<BubbleType> ammoPalette = BubbleType.values;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _shotsRemaining = shotsNotifier.value;
  }

  @override
  void onRemove() {
    shotsNotifier.removeListener(_onShotsChanged);
    super.onRemove();
  }

  void _onShotsChanged() {
    final int newCount = shotsNotifier.value;
    if (newCount < _shotsRemaining && !_isPopping) {
      triggerPopAnimation();
    } else {
      _shotsRemaining = newCount;
    }
  }

  /// Manually synchronizes or resets the visual ammo count.
  void setShotsRemaining(int count) {
    _shotsRemaining = count;
    _isPopping = false;
    _popElapsed = 0.0;
  }

  /// Initiates a smooth scale-down pop transition for the top bubble.
  void triggerPopAnimation([BubbleType? bubbleType]) {
    _isPopping = true;
    _popElapsed = 0.0;
    _poppingBubbleType = bubbleType ?? BubbleType.blue;
    _shotsRemaining = shotsNotifier.value;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isPopping) {
      _popElapsed += dt;
      if (_popElapsed >= _popDuration) {
        _isPopping = false;
        _popElapsed = 0.0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final int total = _shotsRemaining;
    final int visibleCount = math.min(total, maxVisibleBubbles);

    // 1. Background capsule track with neon border
    _renderBackdrop(canvas, visibleCount);

    // 2. "AMMO" Label badge
    _renderHeader(canvas);

    // If completely out of shots, render empty ghost outline
    if (total <= 0 && !_isPopping) {
      _renderEmptyState(canvas);
      return;
    }

    final double popProgress = _isPopping
        ? (_popElapsed / _popDuration).clamp(0.0, 1.0)
        : 0.0;

    // 3. Render animated popping top bubble if currently shrinking
    if (_isPopping && popProgress < 1.0) {
      final double popScale = (1.0 - popProgress);
      final double popAlpha = (1.0 - popProgress).clamp(0.0, 1.0);
      final Offset topSlot = _getSlotOffset(0);

      canvas.save();
      canvas.translate(topSlot.dx, topSlot.dy);
      canvas.scale(popScale);

      ProceduralBubbleRenderer.renderSphere(
        canvas,
        center: Offset.zero,
        radius: bubbleRadius,
        bubbleType: _poppingBubbleType ?? BubbleType.blue,
        drawShadow: false,
      );

      // Expanding sparkle pop ring
      final Paint ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * popScale
        ..color = Colors.white.withValues(alpha: 0.85 * popAlpha);
      canvas.drawCircle(Offset.zero, bubbleRadius * (1.0 + popProgress * 0.6), ringPaint);

      canvas.restore();
    }

    // 4. Render stack of upcoming mini 3D glossy bubbles
    // While popping, the remaining bubbles smoothly slide upward into the newly vacated slots
    final double slideUp = _isPopping ? (1.0 - popProgress) * spacing : 0.0;

    for (int i = 0; i < visibleCount; i++) {
      final Offset slot = _getSlotOffset(i);
      final Offset animatedPos = Offset(slot.dx, slot.dy - slideUp);
      final BubbleType type = ammoPalette[i % ammoPalette.length];

      ProceduralBubbleRenderer.renderSphere(
        canvas,
        center: animatedPos,
        radius: bubbleRadius,
        bubbleType: type,
        drawShadow: false,
      );

      // Glowing active rim for topmost ready ammo bubble
      if (i == 0 && !_isPopping) {
        final Paint activeRim = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.7);
        canvas.drawCircle(animatedPos, bubbleRadius + 1.8, activeRim);
      }
    }

    // 5. "+N" badge on bottom bubble when shotsRemaining > maxVisibleBubbles
    if (total > maxVisibleBubbles) {
      final int extra = total - maxVisibleBubbles;
      final Offset bottomSlot = _getSlotOffset(visibleCount - 1);
      final Offset badgePos = Offset(bottomSlot.dx, bottomSlot.dy - slideUp);
      _renderOverflowBadge(canvas, badgePos, extra);
    }
  }

  Offset _getSlotOffset(int index) {
    // Top slot starts at y = -24.0, spacing downwards
    const double startY = -24.0;
    return Offset(0.0, startY + (index * spacing));
  }

  void _renderBackdrop(Canvas canvas, int visibleCount) {
    const double podW = 26.0;
    const double podH = 92.0;
    const Rect podRect = Rect.fromLTWH(-podW / 2, -34.0, podW, podH);
    final RRect podRRect = RRect.fromRectAndRadius(podRect, const Radius.circular(13.0));

    // Dark glassmorphic background
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1F2B48),
          Color(0xFF0F1528),
          Color(0xFF070A14),
        ],
      ).createShader(podRect);
    canvas.drawRRect(podRRect, bgPaint);

    // Glowing cyan outline
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.5);
    canvas.drawRRect(podRRect, borderPaint);
  }

  void _renderHeader(Canvas canvas) {
    final TextPainter tp = TextPainter(
      text: const TextSpan(
        text: 'AMMO',
        style: TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -47.0));
  }

  void _renderOverflowBadge(Canvas canvas, Offset center, int extra) {
    final String label = '+$extra';
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFFFFD600),
          fontSize: 9.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 4.0),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double badgeW = math.max(tp.width + 8.0, 20.0);
    const double badgeH = 13.0;
    final Rect badgeRect = Rect.fromCenter(center: center, width: badgeW, height: badgeH);
    final RRect badgeRRect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(6.5));

    // Badge background disk
    final Paint badgeBg = Paint()
      ..color = const Color(0xFF131A33).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(badgeRRect, badgeBg);

    // Badge gold neon border
    final Paint badgeBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFFFD600).withValues(alpha: 0.85);
    canvas.drawRRect(badgeRRect, badgeBorder);

    tp.paint(canvas, Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)));
  }

  void _renderEmptyState(Canvas canvas) {
    final TextPainter tp = TextPainter(
      text: const TextSpan(
        text: 'EMPTY',
        style: TextStyle(
          color: Color(0xFFFF1744),
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, 4.0));
  }
}
