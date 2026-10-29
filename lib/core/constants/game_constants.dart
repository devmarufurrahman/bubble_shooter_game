import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Centralized arcade game design system constants including dimensions,
/// physics tuning, and neon color palettes.
class GameConstants {
  GameConstants._();

  // ── Viewport & Resolution ──
  static const double virtualWidth = 400.0;
  static const double virtualHeight = 700.0;

  // ── Grid Dimensions ──
  static const double defaultBubbleRadius = 25.0;
  static const double topHudOffset = 110.0;
  static const double defaultTopOffset = topHudOffset;
  static const int evenColumns = 8;
  static const int oddColumns = 7;
  static const int maxRows = 14;

  // ── Physics & Cannon ──
  static const double bulletSpeed = 750.0;
  static const double fallingGravity = 700.0;
  static const double particleGravity = 220.0;
  static const double cannonBottomOffset = 48.0;
  static const double barrelLength = 46.0;
  static const double dangerThresholdY = 552.0;

  /// Maximum allowed aiming angle (70 degrees in radians).
  static const double maxAimAngle = 70.0 * (math.pi / 180.0);

  // ── Neon Arcade Color Palette ──
  static const Color backgroundDark = Color(0xFF060913);
  static const Color scaffoldBackground = Color(0xFF070A14);
  static const Color surfaceOverlay = Color(0xFF11172E);
  static const Color surfaceCard = Color(0xFF131A33);
  static const Color surfacePill = Color(0xFF19203C);
  static const Color dividerBorder = Color(0xFF1F2B4C);

  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonPink = Color(0xFFFF007F);
  static const Color neonGold = Color(0xFFFFD600);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonRed = Color(0xFFFF1744);
}

