import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/audio/audio.dart';
import '../../core/utils/utils.dart';
import '../../data/models/models.dart';
import 'ammo_inventory_component.dart';
import 'grid_manager.dart';
import 'procedural_bubble_renderer.dart';
import 'trajectory_line.dart';

/// Arcade metallic cannon anchored at bottom-center of the screen.
/// Handles touch aim calculations, 70-degree rotation clamping,
/// raycast reflective dotted trajectory lines, bubble queue previews,
/// interactive bubble swapping with 180-degree scale-bounce animation,
/// and dynamic visual ammo inventory rendering.
class CannonComponent extends PositionComponent {
  /// Default distance from the bottom of the virtual screen.
  static const double defaultBottomOffset = 48.0;

  CannonComponent({
    required this.gameWidth,
    required this.gameHeight,
    required this.ceilingY,
    required this.bubbleRadius,
    this.bottomOffset = defaultBottomOffset,
    this.shotsNotifier,
    this.isBulletFlyingProvider,
    Vector2? position,
  }) : super(
          position: position ?? Vector2(gameWidth / 2, gameHeight - bottomOffset),
          size: Vector2.zero(),
          anchor: Anchor.center,
        ) {
    ammoInventory = AmmoInventoryComponent(
      shotsNotifier: shotsNotifier ?? ValueNotifier<int>(0),
      position: Vector2(104, 6),
      bubbleRadius: 8.5,
    );
  }

  /// Game canvas dimensions.
  final double gameWidth;
  final double gameHeight;

  /// Distance from the bottom of the viewport to the cannon pivot.
  final double bottomOffset;

  /// Top boundary limit for trajectory guides.
  final double ceilingY;

  /// Physical bubble radius.
  final double bubbleRadius;

  /// Reactive notifier tracking remaining shots.
  final ValueNotifier<int>? shotsNotifier;

  /// Provider callback checking if a bullet projectile is currently in flight.
  final bool Function()? isBulletFlyingProvider;

  /// Length of the rotating barrel cylinder in logical pixels.
  static const double barrelLength = 46.0;

  /// Maximum allowed aiming angle (70 degrees).
  static const double maxAimAngle = 70.0 * (math.pi / 180.0);

  /// Current aiming angle in radians (0 = straight up, > 0 = right, < 0 = left).
  double aimAngle = 0.0;

  /// Angle alias for [aimAngle].
  @override
  double get angle => aimAngle;
  @override
  set angle(double val) => aimAngle = val;

  /// Whether the user is actively dragging/aiming.
  bool isAiming = false;

  /// List of available bubble colors for the active level.
  List<BubbleType> availableColors = BubbleType.values;

  /// Active bubble queued to fire.
  late BubbleType currentBubbleType;

  /// Upcoming bubble queued next.
  late BubbleType nextBubbleType;

  /// Visual ammo stack component beside the cannon pedestal.
  late final AmmoInventoryComponent ammoInventory;

  // ── Bubble Swap Animation State ──
  bool _isSwapping = false;
  bool get isSwapping => _isSwapping;

  double _swapElapsed = 0.0;
  static const double _swapDuration = 0.15; // 150 milliseconds
  BubbleType? _animFromCurrent;
  BubbleType? _animFromNext;

  // Key local offsets (Centered cannon with furnished, spacious flanking controls)
  static const Offset _podCenter = Offset(-118, 6);
  static const Offset _swapBtnCenter = Offset(-64, 6);
  static const Offset _turretCenter = Offset(0, -6);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Anchor at exact horizontal center and bottomOffset above bottom
    if (position == Vector2.zero()) {
      position = Vector2(gameWidth / 2, gameHeight - bottomOffset);
    }

    initializeQueue();

    // Mount Visual Ammo Inventory beside cannon
    if (ammoInventory.parent == null) {
      add(ammoInventory);
    }
  }

  /// Picks a random color from the level's available colors.
  BubbleType _pickAvailableColor() {
    if (availableColors.isNotEmpty) {
      final math.Random rng = math.Random();
      return availableColors[rng.nextInt(availableColors.length)];
    }
    return BubbleType.random();
  }

  /// Initializes or resets the current and next bubbles in the cannon queue.
  void initializeQueue([GridManager? gridManager]) {
    if (gridManager != null && gridManager.activeBubbles.isNotEmpty) {
      currentBubbleType = pickRandomGridColor(gridManager);
      nextBubbleType = pickRandomGridColor(gridManager);
    } else {
      currentBubbleType = _pickAvailableColor();
      nextBubbleType = _pickAvailableColor();
    }
    _isSwapping = false;
    _swapElapsed = 0.0;
  }

  /// Calculates the exact world position of the cannon nozzle tip.
  Vector2 get nozzleTipPosition =>
      position +
      Vector2(
        math.sin(aimAngle) * barrelLength,
        -math.cos(aimAngle) * barrelLength,
      );

  /// Backwards-compatible alias for [nozzleTipPosition].
  Vector2 get nozzlePosition => nozzleTipPosition;

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
    _isSwapping = false;
  }

  /// Selects a random [BubbleType] currently existing on the active grid.
  /// Falls back to [availableColors] if the grid has no remaining bubbles.
  BubbleType pickRandomGridColor(GridManager gridManager) {
    final activeBubbles = gridManager.activeBubbles;
    if (activeBubbles.isEmpty) {
      return _pickAvailableColor();
    }

    final Set<BubbleType> availableTypes = activeBubbles.map((b) => b.bubbleType).toSet();
    final List<BubbleType> typeList = availableTypes.toList();
    final math.Random rng = math.Random();
    return typeList[rng.nextInt(typeList.length)];
  }

  // ── Tactical Bubble Swap ──

  /// Checks whether a touch/click in world coordinates lands on the interactive
  /// swap button, NEXT bubble pod, or swap hit region.
  bool checkSwapHit(Vector2 worldPoint) {
    final Vector2 localPoint = worldPoint - position;
    final Offset local = Offset(localPoint.x, localPoint.y);

    // Hit test 1: NEXT preview pod (radius ~ 32px)
    if ((local - _podCenter).distance <= 32.0) return true;

    // Hit test 2: Dedicated circular SWAP button (radius ~ 26px)
    if ((local - _swapBtnCenter).distance <= 26.0) return true;

    // Hit test 3: Bounding box covering entire left swap cluster
    const Rect swapHitBox = Rect.fromLTRB(-150, -30, -40, 46);
    return swapHitBox.contains(local);
  }

  /// Tactically swaps [currentBubbleType] with [nextBubbleType].
  /// Guard condition: Disallows swapping while a bullet is actively in flight or already swapping.
  /// Triggers subtle swoosh sound and haptic selection click.
  bool swapBubbles({bool? isBulletFlying}) {
    final bool flying = isBulletFlying ?? (isBulletFlyingProvider?.call() ?? false);
    if (flying || _isSwapping) return false;

    // Start 150ms 180-degree scale-bounce swap animation
    _isSwapping = true;
    _swapElapsed = 0.0;
    _animFromCurrent = currentBubbleType;
    _animFromNext = nextBubbleType;

    // Swap logical values
    final BubbleType temp = currentBubbleType;
    currentBubbleType = nextBubbleType;
    nextBubbleType = temp;

    // Play subtle audio swoosh and haptic click
    SoundManager.instance.playSwap();
    HapticsHelper.selectionClick();

    return true;
  }

  /// Notifies the cannon and visual ammo stack that a bullet was launched.
  void onShotFired([BubbleType? firedType]) {
    ammoInventory.triggerPopAnimation(firedType ?? currentBubbleType);
  }

  /// Synchronizes or resets the visual ammo count.
  void setShotsRemaining(int count) {
    ammoInventory.setShotsRemaining(count);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isSwapping) {
      _swapElapsed += dt;
      if (_swapElapsed >= _swapDuration) {
        _isSwapping = false;
        _swapElapsed = _swapDuration;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Sleek Cyber Console Chassis / Rail connecting the lower HUD controls
    _renderConsoleChassis(canvas);

    // 2. Next bubble preview queue (drawn to the left of the cannon)
    _renderNextPreviewPod(canvas);

    // 3. Interactive SWAP Button situated comfortably between NEXT pod and cannon
    _renderSwapButton(canvas);

    // 4. Metallic base pedestal centered at Offset.zero
    _renderBasePedestal(canvas);

    // 5. Rotating barrel turret & loaded bubble centered at Offset.zero
    _renderRotatingTurret(canvas);

    // 6. Draw dynamic reflective trajectory guide if player is aiming
    if (isAiming) {
      _renderTrajectoryGuide(canvas);
    }

    // 7. If currently swapping, render 180-degree arc orbit animation on top
    if (_isSwapping) {
      _renderSwapAnimation(canvas);
    }
  }

  /// Renders a futuristic cyberpunk arcade console bracket uniting the lower HUD controls.
  void _renderConsoleChassis(Canvas canvas) {
    // 1. Cyber connector rail plate between NEXT pod and Cannon Pedestal
    final Rect railRect = Rect.fromLTRB(_podCenter.dx - 10, -4, 0, 18);
    final RRect railRRect =
        RRect.fromRectAndRadius(railRect, const Radius.circular(8.0));

    final Paint railBg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1B2544),
          Color(0xFF0F1528),
          Color(0xFF070B16),
        ],
      ).createShader(railRect);
    canvas.drawRRect(railRRect, railBg);

    // Glowing cyan cyber trace lines along the rail
    final Paint tracePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35);

    canvas.drawLine(
      Offset(_podCenter.dx + 26, 6),
      const Offset(-38, 6),
      tracePaint,
    );

    // Subtle connector rail to the Ammo Magazine on the right
    final Rect rightRailRect = Rect.fromLTRB(0, -2, 104, 16);
    final RRect rightRailRRect =
        RRect.fromRectAndRadius(rightRailRect, const Radius.circular(6.0));
    final Paint rightRailBg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF161E38),
          Color(0xFF0A0E1C),
        ],
      ).createShader(rightRailRect);
    canvas.drawRRect(rightRailRRect, rightRailBg);

    final Paint rightTracePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.25);
    canvas.drawLine(
      const Offset(38, 6),
      const Offset(88, 6),
      rightTracePaint,
    );
  }

  /// Renders raycast wall-reflected dotted trajectory guideline starting precisely at the nozzle tip.
  void _renderTrajectoryGuide(Canvas canvas) {
    final List<TrajectorySegment> segments = TrajectoryLine.calculateSegments(
      origin: Offset(
        math.sin(aimAngle) * barrelLength,
        -math.cos(aimAngle) * barrelLength,
      ),
      angle: aimAngle,
      minX: bubbleRadius - position.x,
      maxX: (gameWidth - bubbleRadius) - position.x,
      ceilingY: ceilingY - position.y,
    );

    // Draw glowing dotted points along each segment
    TrajectoryLine.render(
      canvas,
      segments: segments,
      glowColor: currentBubbleType.glowColor,
    );

    // Draw small target ring at the final trajectory terminus
    if (segments.isNotEmpty) {
      final Offset targetPt = segments.last.end;
      final Paint targetPaint = Paint()
        ..color = currentBubbleType.baseColor.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      final Paint dotPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(targetPt, 8.0, targetPaint);
      canvas.drawCircle(targetPt, 2.5, dotPaint);
    }
  }

  /// Renders the "NEXT" queue preview bubble pod with futuristic glassmorphic styling.
  void _renderNextPreviewPod(Canvas canvas) {
    const double podRadius = 24.0;

    // Outer glow halo matching bubble color
    final Paint glowPaint = Paint()
      ..color = nextBubbleType.glowColor.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(_podCenter, podRadius + 2, glowPaint);

    // Pod background disk
    final Paint podBg = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF222F50),
          const Color(0xFF12192E),
          const Color(0xFF070B16),
        ],
      ).createShader(Rect.fromCircle(center: _podCenter, radius: podRadius));
    canvas.drawCircle(_podCenter, podRadius, podBg);

    // Pod neon cyan border
    final Paint podBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.7);
    canvas.drawCircle(_podCenter, podRadius, podBorder);

    // Outer tick accents
    final Paint tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.4);
    for (int deg = 0; deg < 360; deg += 90) {
      final double rad = deg * (math.pi / 180.0);
      final Offset p1 = Offset(
        _podCenter.dx + math.cos(rad) * (podRadius - 3),
        _podCenter.dy + math.sin(rad) * (podRadius - 3),
      );
      final Offset p2 = Offset(
        _podCenter.dx + math.cos(rad) * (podRadius + 2),
        _podCenter.dy + math.sin(rad) * (podRadius + 2),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // "NEXT" label badge pill above the pod
    const double pillW = 34.0;
    const double pillH = 13.0;
    final Rect pillRect = Rect.fromCenter(
      center: Offset(_podCenter.dx, _podCenter.dy - podRadius - 9.0),
      width: pillW,
      height: pillH,
    );
    final RRect pillRRect =
        RRect.fromRectAndRadius(pillRect, const Radius.circular(6.0));
    final Paint pillBg = Paint()..color = const Color(0xFF10172C);
    final Paint pillBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6);
    canvas.drawRRect(pillRRect, pillBg);
    canvas.drawRRect(pillRRect, pillBorder);

    final TextPainter tp = TextPainter(
      text: const TextSpan(
        text: 'NEXT',
        style: TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 8.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(_podCenter.dx - (tp.width / 2),
          pillRect.top + (pillH - tp.height) / 2),
    );

    // Next preview bubble (suppressed while animated swap is in flight)
    if (!_isSwapping) {
      ProceduralBubbleRenderer.renderSphere(
        canvas,
        center: _podCenter,
        radius: 15.0,
        bubbleType: nextBubbleType,
        drawShadow: false,
      );
    }
  }

  /// Renders an elevated interactive arcade SWAP button with revolving dual arrows.
  void _renderSwapButton(Canvas canvas) {
    const double btnRadius = 15.0;

    // 1. Soft interactive glow
    final Paint glowPaint = Paint()
      ..color = const Color(0xFFFFD600).withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawCircle(_swapBtnCenter, btnRadius + 2, glowPaint);

    // 2. Beveled outer metallic rim
    final Paint bezelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3B4D78),
          Color(0xFF1B243B),
          Color(0xFF0C111F),
        ],
      ).createShader(Rect.fromCircle(center: _swapBtnCenter, radius: btnRadius));
    canvas.drawCircle(_swapBtnCenter, btnRadius, bezelPaint);

    // 3. Inner neon cyan/magenta border
    final Paint btnBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _isSwapping
          ? const Color(0xFFFF007F)
          : const Color(0xFF00E5FF).withValues(alpha: 0.85);
    canvas.drawCircle(_swapBtnCenter, btnRadius, btnBorder);

    // 4. Dual curved swap arrows icon (⇄)
    canvas.save();
    canvas.translate(_swapBtnCenter.dx, _swapBtnCenter.dy);

    if (_isSwapping) {
      final double progress = (_swapElapsed / _swapDuration).clamp(0.0, 1.0);
      canvas.rotate(progress * math.pi);
    }

    final Paint arrowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFD600);

    // Upper arrow curving right
    final Path topPath = Path()
      ..moveTo(-6.5, -3.0)
      ..lineTo(5.5, -3.0)
      ..lineTo(2.5, -6.0);
    canvas.drawPath(topPath, arrowPaint);

    // Lower arrow curving left
    final Path btmPath = Path()
      ..moveTo(6.5, 3.0)
      ..lineTo(-5.5, 3.0)
      ..lineTo(-2.5, 6.0);
    canvas.drawPath(btmPath, arrowPaint);

    canvas.restore();

    // 5. "SWAP" pill badge below button
    const double pillW = 34.0;
    const double pillH = 12.0;
    final Rect pillRect = Rect.fromCenter(
      center: Offset(_swapBtnCenter.dx, _swapBtnCenter.dy + btnRadius + 8.5),
      width: pillW,
      height: pillH,
    );
    final RRect pillRRect =
        RRect.fromRectAndRadius(pillRect, const Radius.circular(5.0));

    final Paint pillBg = Paint()..color = const Color(0xFF10172C);
    final Paint pillBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFFFD600).withValues(alpha: 0.6);
    canvas.drawRRect(pillRRect, pillBg);
    canvas.drawRRect(pillRRect, pillBorder);

    final TextPainter tp = TextPainter(
      text: const TextSpan(
        text: 'SWAP',
        style: TextStyle(
          color: Color(0xFFFFD600),
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(_swapBtnCenter.dx - (tp.width / 2),
          pillRect.top + (pillH - tp.height) / 2),
    );
  }

  /// Renders the 180-degree semicircular arc orbit and scale-bounce animation
  /// between the cannon nozzle bubble and the NEXT preview bubble.
  void _renderSwapAnimation(Canvas canvas) {
    final double t = (_swapElapsed / _swapDuration).clamp(0.0, 1.0);
    // Smooth cubic easing curve
    final double curved = Curves.easeInOutCubic.transform(t);

    // 180-degree rotation angle (0 to pi radians)
    final double theta = curved * math.pi;

    // Scale-bounce: starts at 1.0, scales up to ~1.20 at midpoint, then settles to 1.0
    final double scale = 1.0 + 0.20 * math.sin(curved * math.pi);

    // Midpoint between current bubble in cannon and NEXT pod
    final Offset mid = Offset(
      (_turretCenter.dx + _podCenter.dx) / 2,
      (_turretCenter.dy + _podCenter.dy) / 2,
    );

    final Offset offsetR = _turretCenter - mid;
    final double radius = offsetR.distance;
    final double initialAngle = math.atan2(offsetR.dy, offsetR.dx);

    // Bubble A (departing cannon to NEXT pod)
    final Offset posA = mid +
        Offset(
          math.cos(initialAngle + theta) * radius,
          math.sin(initialAngle + theta) * radius,
        );

    // Bubble B (departing NEXT pod into cannon)
    final Offset posB = mid +
        Offset(
          math.cos(initialAngle + math.pi + theta) * radius,
          math.sin(initialAngle + math.pi + theta) * radius,
        );

    // Glowing orbital swoosh trail
    final Paint trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45 * (1.0 - (t - 0.5).abs() * 2));
    canvas.drawCircle(mid, radius, trailPaint);

    // Draw animated Bubble A
    if (_animFromCurrent != null) {
      final double rA = (bubbleRadius * 0.95) * scale;
      ProceduralBubbleRenderer.renderSphere(
        canvas,
        center: posA,
        radius: rA,
        bubbleType: _animFromCurrent!,
        drawShadow: false,
      );
    }

    // Draw animated Bubble B
    if (_animFromNext != null) {
      final double rB = 14.0 * scale;
      ProceduralBubbleRenderer.renderSphere(
        canvas,
        center: posB,
        radius: rB,
        bubbleType: _animFromNext!,
        drawShadow: false,
      );
    }
  }

  /// Renders the metallic pedestal base centered at local [Offset.zero].
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

  /// Renders rotating barrel turret and active bubble pointing upward along the negative Y-axis.
  void _renderRotatingTurret(Canvas canvas) {
    canvas.save();
    canvas.rotate(aimAngle);

    // 1. Barrel nozzle cylinder pointing upward along negative Y-axis
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

    // 2. Active ready-to-shoot bubble nestled at the barrel base (y = -6)
    // (suppressed while animated swap is in flight)
    if (!_isSwapping) {
      ProceduralBubbleRenderer.renderSphere(
        canvas,
        center: _turretCenter,
        radius: bubbleRadius * 0.95,
        bubbleType: currentBubbleType,
        drawShadow: false,
      );
    }

    // 3. Central pivot cap centered at Offset.zero
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
