import 'dart:math' show Point;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

import '../core/audio/audio.dart';
import '../core/constants/constants.dart';
import '../core/utils/utils.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'components/components.dart';
import 'logic/logic.dart';

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
  static const double virtualWidth = GameConstants.virtualWidth;

  /// Target virtual resolution height.
  static const double virtualHeight = GameConstants.virtualHeight;

  /// Active campaign level number.
  final int levelNumber;

  /// Active level configuration settings.
  late final LevelConfig levelConfig;

  /// Manager handling Odd-r staggered hexagonal grid layout and cell queries.
  late final GridManager gridManager;

  /// Aiming cannon and bubble queue component.
  late final CannonComponent cannon;

  /// Dynamic pulsating neon danger threshold boundary line.
  late final DangerLineComponent dangerLine;

  /// Active projectile in flight, or null if ready to shoot.
  BulletBubble? activeBullet;

  /// Flag indicating whether match-3 popping or drop cascades are currently running.
  bool isProcessingMatch = false;

  /// Remaining shot/ammo capacity for this stage.
  int shotsRemaining = 0;

  /// Reactive notifier for HUD shot count updates.
  final ValueNotifier<int> shotsNotifier = ValueNotifier<int>(0);

  /// Floor line threshold Y coordinate (100px above cannon pivot).
  static const double dangerThresholdY = GameConstants.dangerThresholdY;

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
  Color backgroundColor() => GameConstants.backgroundDark;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize SoundManager
    await SoundManager.instance.initialize();

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

    // Procedural Arcade Backdrop with ceiling line
    final backdrop = ArcadeGameBackdrop(
      ceilingY: gridManager.ceilingY,
      size: Vector2(virtualWidth, virtualHeight),
    );
    await world.add(backdrop);

    // Dynamic Pulsating Danger Zone Warning Line
    dangerLine = DangerLineComponent(
      dangerThresholdY: dangerThresholdY,
      gameWidth: virtualWidth,
      gameHeight: virtualHeight,
      gridManager: gridManager,
    );
    await world.add(dangerLine);

    // Add GridManager to the world
    await world.add(gridManager);

    // Initialize and mount aiming cannon
    cannon = CannonComponent(
      gameWidth: virtualWidth,
      gameHeight: virtualHeight,
      ceilingY: gridManager.ceilingY,
      bubbleRadius: gridManager.radius,
      shotsNotifier: shotsNotifier,
      isBulletFlyingProvider: () => isBulletFlying,
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
    cannon.setShotsRemaining(shotsRemaining);
    gameOverReason = null;
    isProcessingMatch = false;

    activeBullet?.removeFromParent();
    activeBullet = null;

    // Remove any remaining falling bubbles or floating texts
    gridManager.children
        .whereType<BubbleComponent>()
        .where((b) => b.isDropping)
        .toList()
        .forEach((b) => b.removeFromParent());
    world.children
        .whereType<BubbleComponent>()
        .where((b) => b.isDropping)
        .toList()
        .forEach((b) => b.removeFromParent());
    world.children.whereType<FallingBubbleComponent>().toList().forEach(
      (b) => b.removeFromParent(),
    );
    world.children.whereType<FloatingTextComponent>().toList().forEach(
      (t) => t.removeFromParent(),
    );

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

    // Tactical Bubble Swap: if player taps the swap button or NEXT pod, swap bubbles
    if (cannon.checkSwapHit(worldPoint)) {
      cannon.swapBubbles(isBulletFlying: isBulletFlying);
      return;
    }

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

    // Consume one shot and animate ammo stack pop
    shotsRemaining--;
    shotsNotifier.value = shotsRemaining;
    cannon.onShotFired(cannon.currentBubbleType);

    // Trigger firing audio effect and tactile feedback
    SoundManager.instance.playShoot();
    HapticsHelper.selectionClick();

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
      onBounce: () => SoundManager.instance.playBounce(),
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
      // Dispatches batch pop: exactly ONE audio and ONE haptic impulse for the entire cluster
      final List<BubbleComponent> popped = gridManager.batchPopMatches(matches);

      // Spawn sparkling particle explosion & calculate cluster centroid
      double sumX = 0;
      double sumY = 0;
      for (final BubbleComponent bubble in popped) {
        sumX += bubble.position.x;
        sumY += bubble.position.y;
        world.add(
          BubblePopParticle(
            position: bubble.position.clone(),
            bubbleType: bubble.bubbleType,
          ),
        );
      }

      // Award +100 points per popped bubble
      final int points = popped.length * 100;
      _addScore(points);

      // Spawn floating score popup at centroid (+100, +400 COMBO x2!, etc.)
      if (popped.isNotEmpty) {
        final Vector2 centroid = Vector2(
          sumX / popped.length,
          sumY / popped.length,
        );
        final String scoreLabel = popped.length > 3
            ? '+$points COMBO x${popped.length - 2}!'
            : '+$points';
        world.add(
          FloatingTextComponent(
            text: scoreLabel,
            position: centroid,
            textColor: popped.length > 3
                ? const Color(0xFFFF007F)
                : const Color(0xFFFFD600),
            fontSize: popped.length > 3 ? 19.0 : 16.0,
          ),
        );
      }

      // Brief aesthetic pause for pop burst animation
      await Future.delayed(const Duration(milliseconds: 140));

      // 3. Floating / Disconnected bubble drop cascade
      final List<BubbleComponent> dropped =
          MatchChecker.dropFloatingBubbles(gridManager);

      if (dropped.isNotEmpty) {
        // Also spawn particles and floating "+200 DROP!" popups at detachment points
        for (final BubbleComponent falling in dropped) {
          world.add(
            BubblePopParticle(
              position: falling.position.clone(),
              bubbleType: falling.bubbleType,
              particleCount: 8,
            ),
          );
          world.add(
            FloatingTextComponent(
              text: '+200 DROP!',
              position: falling.position.clone(),
              textColor: const Color(0xFF00E5FF),
              fontSize: 13.0,
            ),
          );
        }
        // Award +200 bonus points per dropped orphan bubble
        _addScore(dropped.length * 200);
      }
    }

    // Wait for all falling / dropping animations to complete before evaluating win condition
    if (gridManager.hasFallingBubbles) {
      await waitForFallingBubbles();
    }

    // 4. Win / Defeat condition evaluations
    if (!gridManager.hasAnyBubblesOnGrid && !gridManager.hasFallingBubbles) {
      await handleLevelVictory();
      isProcessingMatch = false;
      return;
    }

    final bool reachedDangerLine =
        snappedBubble.position.y >= dangerThresholdY ||
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

  /// Waits until all falling orphan bubbles have completely exited the screen
  /// and detached from the component tree, or until [timeout] is reached.
  Future<void> waitForFallingBubbles({
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    final DateTime start = DateTime.now();
    while (gridManager.hasFallingBubbles &&
        DateTime.now().difference(start) < timeout) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
  }

  /// Calculates earned stars (1 to 3) based on shots remaining for this level.
  int calculateStars() {
    if (shotsRemaining >= (levelConfig.maxShots * 0.5).round()) return 3;
    if (shotsRemaining >= (levelConfig.maxShots * 0.25).round()) return 2;
    return 1;
  }

  void _addScore(int points) {
    currentScore += points;
    scoreNotifier.value = currentScore;

    if (currentScore > highScore) {
      highScore = currentScore;
      LevelManager.saveScore(levelNumber, currentScore);
    }
  }

  Future<void> handleLevelVictory() async {
    SoundManager.instance.playWin();
    final int stars = calculateStars();
    await LevelManager.saveLevelProgress(levelNumber, currentScore, stars);
    pauseEngine();
    overlays.add('WinOverlay');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Lifecycle memory leak audit: ensure active component tree remains bounded
    assert(() {
      final int totalComponents =
          world.children.length + gridManager.children.length + children.length;
      if (totalComponents > 250) {
        debugPrint(
          'WARNING [BubbleShooterGame]: High component count ($totalComponents) detected. '
          'World: ${world.children.length}, Grid: ${gridManager.children.length}, Game: ${children.length}',
        );
      }
      return true;
    }());
  }

  bool _isDisposed = false;

  /// Whether the game and its resources have been torn down.
  bool get isDisposed => _isDisposed;

  /// Explicitly tears down game resources, components, grid references,
  /// and reactive controllers to guarantee leak-free disposal.
  void onDisposeGame() {
    if (_isDisposed) return;
    _isDisposed = true;

    pauseEngine();
    overlays.clear();

    // 1. Detach and nullify active projectile in flight
    activeBullet?.removeFromParent();
    activeBullet = null;

    // 2. Clear cannon and grid components
    try {
      cannon.isAiming = false;
    } catch (_) {}

    try {
      gridManager.clear();
    } catch (_) {}

    // 3. Remove all remaining children from world and game tree
    try {
      world.removeAll(world.children);
    } catch (_) {}
    try {
      removeAll(children);
    } catch (_) {}

    // 4. Dispose UI ValueNotifier instances
    try {
      scoreNotifier.dispose();
      shotsNotifier.dispose();
    } catch (_) {}
  }

  void handleGameOver(String reason) {
    SoundManager.instance.playGameOver();
    gameOverReason = reason;
    pauseEngine();
    overlays.add('GameOverOverlay');
  }
}
