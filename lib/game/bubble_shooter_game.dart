import 'dart:math' show Point;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../levels/level_data.dart';
import '../levels/level_manager.dart';
import 'components/arcade_game_backdrop.dart';
import 'components/bubble_component.dart';
import 'components/bullet_bubble.dart';
import 'components/cannon_component.dart';
import 'components/falling_bubble_component.dart';
import 'components/grid_manager.dart';
import 'logic/match_checker.dart';

/// The core Flame engine game host for the Bubble Shooter game.
/// Coordinates the Odd-r hex board, interactive cannon, projectile physics,
/// Match-3 flood-fill, and floating orphan drop cascades.
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

  /// Active level configuration settings.
  late final LevelConfig levelConfig;

  /// Manager handling Odd-r staggered hexagonal grid layout and cell queries.
  late final GridManager gridManager;

  /// Aiming cannon and bubble queue component.
  late final CannonComponent cannon;

  /// Active projectile in flight, or null if ready to shoot.
  BulletBubble? activeBullet;

  /// Flag indicating whether match-3 popping or drop cascades are currently running.
  bool isProcessingMatch = false;

  /// Remaining shot/ammo capacity for this stage.
  int shotsRemaining = 0;

  /// Reactive notifier for HUD shot count updates.
  final ValueNotifier<int> shotsNotifier = ValueNotifier<int>(0);

  /// Floor line threshold Y coordinate (100px above cannon pivot).
  static const double dangerThresholdY = 552.0;

  /// Reason description if game ended in defeat.
  String? gameOverReason;

  /// Guard condition: prevents shooting while a bubble is in flight or resolving matches.
  bool get isBulletFlying => activeBullet != null && activeBullet!.isMoving;

  /// Whether the user is permitted to aim and shoot.
  bool get canAimAndShoot =>
      !isBulletFlying && !isProcessingMatch && shotsRemaining > 0;

  /// Player current score during this gameplay session.
  int currentScore = 0;

  /// Highest recorded score for this level.
  int highScore = 0;

  /// Reactive notifier for real-time HUD score updates.
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);

  @override
  Color backgroundColor() => const Color(0xFF060913);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Map world (0, 0) directly to the top-left of the 400x700 viewport
    camera.viewfinder.anchor = Anchor.topLeft;

    // Load recorded high score
    highScore = await LevelManager.instance.getHighScore(levelNumber);

    // Load level configuration
    levelConfig = LevelConfig.getLevel(levelNumber);
    shotsRemaining = levelConfig.maxShots;
    shotsNotifier.value = shotsRemaining;

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

    // Procedural Arcade Backdrop with ceiling line and danger floor line
    final backdrop = ArcadeGameBackdrop(
      ceilingY: gridManager.ceilingY,
      dangerLineY: dangerThresholdY,
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
    cannon.availableColors = levelConfig.availableColors;
    await world.add(cannon);

    // Populate level grid and initialize cannon queue
    gridManager.populateInitialGrid(levelConfig.initialGrid, oneBased: true);
    cannon.initializeQueue(gridManager);
  }

  /// Pauses the game engine and displays the Pause overlay modal.
  void pauseGame() {
    pauseEngine();
    overlays.add('PauseOverlay');
  }

  /// Restarts the level by clearing the board, resetting score, ammo,
  /// and repopulating the initial stage pattern.
  void restartLevel() {
    resumeEngine();
    currentScore = 0;
    scoreNotifier.value = 0;
    shotsRemaining = levelConfig.maxShots;
    shotsNotifier.value = shotsRemaining;
    gameOverReason = null;
    isProcessingMatch = false;

    activeBullet?.removeFromParent();
    activeBullet = null;

    // Remove any remaining falling bubbles
    world.children.whereType<FallingBubbleComponent>().forEach((b) => b.removeFromParent());

    gridManager.clear();
    gridManager.populateInitialGrid(levelConfig.initialGrid, oneBased: true);

    cannon.isAiming = false;
    cannon.aimAngle = 0.0;
    cannon.initializeQueue(gridManager);

    overlays.remove('WinOverlay');
    overlays.remove('GameOverOverlay');
    overlays.remove('PauseOverlay');
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (!canAimAndShoot) return;
    final Vector2 worldPoint = camera.globalToLocal(info.eventPosition.widget);
    cannon.isAiming = true;
    cannon.aimAt(worldPoint);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (!canAimAndShoot || !cannon.isAiming) return;
    final Vector2 worldPoint = camera.globalToLocal(info.eventPosition.widget);
    cannon.aimAt(worldPoint);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (!canAimAndShoot || !cannon.isAiming) return;
    cannon.isAiming = false;
    _fireBullet();
  }

  @override
  void onPanCancel() {
    cannon.isAiming = false;
  }

  /// Launches a new BulletBubble from the cannon nozzle along the aiming angle.
  void _fireBullet() {
    if (!canAimAndShoot) return;

    // Consume one shot
    shotsRemaining--;
    shotsNotifier.value = shotsRemaining;

    final Vector2 spawnPos = cannon.nozzleTipPosition.clone();

    late final BulletBubble bullet;
    bullet = BulletBubble(
      bubbleType: cannon.currentBubbleType,
      radius: gridManager.radius,
      aimAngle: cannon.aimAngle,
      gameWidth: virtualWidth,
      ceilingY: gridManager.ceilingY,
      position: spawnPos,
      onImpact: (hitBubble) => _handleBulletImpact(bullet, hitBubble),
    );

    activeBullet = bullet;
    world.add(bullet);
  }

  /// Orchestrates grid snapping, Match-3 flood-fill, floating drops, and game state.
  Future<void> _handleBulletImpact(
    BulletBubble bullet,
    BubbleComponent? hitBubble,
  ) async {
    if (isProcessingMatch) return;
    isProcessingMatch = true;

    // 1. Grid Snapping: snap bullet into optimal hex cell
    final BubbleComponent snappedBubble = gridManager.snapBulletToGrid(
      bullet: bullet,
      hitBubble: hitBubble,
    );
    activeBullet = null;

    // 2. Match-3 BFS Check
    final List<Point<int>> matches = MatchChecker.findMatches(
      snappedBubble.row,
      snappedBubble.col,
      snappedBubble.bubbleType,
      gridManager,
    );

    if (matches.length >= 3) {
      // Pop all contiguous matching bubbles
      for (final Point<int> pt in matches) {
        final BubbleComponent? bubble = gridManager.detachBubbleAt(pt.x, pt.y);
        bubble?.pop();
      }

      // Award +100 points per popped bubble
      _addScore(matches.length * 100);

      // Brief aesthetic pause for pop burst animation
      await Future.delayed(const Duration(milliseconds: 140));

      // 3. Floating / Disconnected bubble drop cascade
      final List<FallingBubbleComponent> dropped = MatchChecker.dropFloatingBubbles(
        gridManager,
        world,
      );

      if (dropped.isNotEmpty) {
        // Award +200 bonus points per dropped orphan bubble
        _addScore(dropped.length * 200);
      }
    }

    // 4. Win / Defeat condition evaluations
    if (gridManager.allBubblesCleared) {
      await handleLevelVictory();
      isProcessingMatch = false;
      return;
    }

    final bool reachedDangerLine = snappedBubble.position.y >= dangerThresholdY ||
        gridManager.activeBubbles.any((b) => b.position.y >= dangerThresholdY);

    if (reachedDangerLine) {
      handleGameOver('BUBBLES REACHED DANGER LINE');
      isProcessingMatch = false;
      return;
    }

    if (shotsRemaining <= 0) {
      handleGameOver('OUT OF SHOTS');
      isProcessingMatch = false;
      return;
    }

    // 5. Advance cannon queue and re-enable input
    cannon.cycleNextBubble(gridManager);
    isProcessingMatch = false;
  }

  void _addScore(int points) {
    currentScore += points;
    scoreNotifier.value = currentScore;

    if (currentScore > highScore) {
      highScore = currentScore;
      LevelManager.instance.saveScore(levelNumber, currentScore);
    }
  }

  Future<void> handleLevelVictory() async {
    await LevelManager.instance.unlockNextLevel(levelNumber);
    await LevelManager.instance.saveScore(levelNumber, currentScore);
    pauseEngine();
    overlays.add('WinOverlay');
  }

  void handleGameOver(String reason) {
    gameOverReason = reason;
    pauseEngine();
    overlays.add('GameOverOverlay');
  }
}
