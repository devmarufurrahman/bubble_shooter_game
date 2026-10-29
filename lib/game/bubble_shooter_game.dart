import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/arcade_game_backdrop.dart';
import 'components/bullet_bubble.dart';
import 'components/cannon_component.dart';
import 'components/grid_manager.dart';

/// The core Flame engine game host for the Bubble Shooter game.
/// Features a fixed 400x700 logical viewport, procedural arcade rendering,
/// collision detection, Odd-r hex grid, interactive aiming cannon, and bullet physics.
class BubbleShooterGame extends FlameGame
    with HasCollisionDetection, PanDetector {
  BubbleShooterGame({this.levelNumber = 1})
      : super(
          camera: CameraComponent.withFixedResolution(
            width: virtualWidth,
            height: virtualHeight,
          ),
        );

  /// Target virtual resolution width.
  static const double virtualWidth = 400.0;

  /// Target virtual resolution height.
  static const double virtualHeight = 700.0;

  /// Active campaign level number.
  final int levelNumber;

  /// Manager handling Odd-r staggered hexagonal grid layout and cell queries.
  late final GridManager gridManager;

  /// Aiming cannon and bubble queue component.
  late final CannonComponent cannon;

  /// Active projectile in flight, or null if ready to shoot.
  BulletBubble? activeBullet;

  /// Guard condition: prevents shooting while a bubble is currently in motion.
  bool get isBulletFlying => activeBullet != null && activeBullet!.isMoving;

  @override
  Color backgroundColor() => const Color(0xFF060913);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Map world (0, 0) directly to the top-left of the 400x700 viewport
    camera.viewfinder.anchor = Anchor.topLeft;

    // Initialize GridManager:
    // radius = 25.0 (fits 8 columns across 400px: 8 * 50 = 400)
    // topOffset = 60.0 (leaves 35px clearance above row 0 for the ceiling line and HUD)
    gridManager = GridManager(
      radius: 25.0,
      topOffset: 60.0,
      maxRows: 14,
      evenColumns: 8,
      oddColumns: 7,
    );

    // Procedural Arcade Backdrop with ceiling line anchored to row 0 top tangent
    final backdrop = ArcadeGameBackdrop(
      ceilingY: gridManager.ceilingY,
      size: Vector2(virtualWidth, virtualHeight),
    );
    await world.add(backdrop);

    // Add GridManager to the world
    await world.add(gridManager);

    // Initialize and mount aiming cannon
    cannon = CannonComponent(
      gameWidth: virtualWidth,
      gameHeight: virtualHeight,
      ceilingY: gridManager.ceilingY,
      bubbleRadius: gridManager.radius,
    );
    await world.add(cannon);

    // Populate initial testing grid
    _populateDemoGrid();
  }

  /// Restarts the level by clearing the board, resetting cannon state,
  /// and repopulating the initial pattern.
  void restartLevel() {
    gridManager.clear();
    _populateDemoGrid();
    activeBullet?.removeFromParent();
    activeBullet = null;
    cannon.isAiming = false;
    cannon.aimAngle = 0.0;
    cannon.cycleNextBubble(gridManager);
  }

  /// Populates a multi-colored demo arcade pattern for testing.
  void _populateDemoGrid() {
    // 0: Red, 1: Blue, 2: Green, 3: Yellow, 4: Purple
    final List<List<int>> demoGrid = [
      [0, 0, 1, 1, 2, 2, 3, 3], // Row 0 (even: 8 columns)
      [4, 4, 0, 1, 2, 3, 4],    // Row 1 (odd: 7 columns)
      [3, 3, 2, 2, 1, 1, 0, 0], // Row 2 (even: 8 columns)
      [2, 0, 4, 3, 1, 2, 0],    // Row 3 (odd: 7 columns)
      [1, 4, 0, 3, 2, 1, 4, 3], // Row 4 (even: 8 columns)
    ];

    gridManager.populateInitialGrid(demoGrid);
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (isBulletFlying) return;
    final Vector2 worldPoint = camera.globalToLocal(info.eventPosition.widget);
    cannon.isAiming = true;
    cannon.aimAt(worldPoint);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isBulletFlying || !cannon.isAiming) return;
    final Vector2 worldPoint = camera.globalToLocal(info.eventPosition.widget);
    cannon.aimAt(worldPoint);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (isBulletFlying || !cannon.isAiming) return;
    cannon.isAiming = false;
    _fireBullet();
  }

  @override
  void onPanCancel() {
    cannon.isAiming = false;
  }

  /// Launches a new BulletBubble from the cannon nozzle along the aiming angle.
  void _fireBullet() {
    if (isBulletFlying) return;

    final BulletBubble bullet = BulletBubble(
      bubbleType: cannon.currentBubbleType,
      radius: gridManager.radius,
      aimAngle: cannon.aimAngle,
      gameWidth: virtualWidth,
      ceilingY: gridManager.ceilingY,
      position: cannon.nozzlePosition,
      onStopped: _onBulletStopped,
    );

    activeBullet = bullet;
    world.add(bullet);

    // Advance queue: next bubble moves into cannon, pick fresh next
    cannon.cycleNextBubble(gridManager);
  }

  /// Invoked when the projectile reaches its destination.
  void _onBulletStopped() {
    // Release flight lock so player can aim and shoot the next bubble
    activeBullet = null;
  }
}
