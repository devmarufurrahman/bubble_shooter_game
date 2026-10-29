import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// The core Flame engine game host for the Bubble Shooter game.
/// Encapsulates level progression, physics loop, and procedural Canvas renders.
class BubbleShooterGame extends FlameGame {
  BubbleShooterGame({required this.levelNumber});

  /// The active campaign level index (1 to 10).
  final int levelNumber;

  @override
  Color backgroundColor() => const Color(0xFF090D1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Foundation ready for Task 2 bubble grid & shooter mechanics
  }
}

