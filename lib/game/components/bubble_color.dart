import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The 5 core bubble color types used in the arcade Bubble Shooter.
enum BubbleType {
  red,
  blue,
  green,
  yellow,
  purple;

  /// Returns a random bubble type.
  static BubbleType random([math.Random? random]) {
    final rng = random ?? math.Random();
    return BubbleType.values[rng.nextInt(BubbleType.values.length)];
  }

  /// Maps an integer index safely to a BubbleType.
  static BubbleType fromIndex(int index) {
    return BubbleType.values[index.abs() % BubbleType.values.length];
  }
}

/// Palette extension providing procedural shader tints for 3D sphere rendering.
extension BubbleColorExtension on BubbleType {
  /// Base vibrant arcade color.
  Color get baseColor {
    switch (this) {
      case BubbleType.red:
        return const Color(0xFFFF1744);
      case BubbleType.blue:
        return const Color(0xFF00B0FF);
      case BubbleType.green:
        return const Color(0xFF00E676);
      case BubbleType.yellow:
        return const Color(0xFFFFD600);
      case BubbleType.purple:
        return const Color(0xFFD500F9);
    }
  }

  /// Light highlight tint for specular reflection and top-left glow.
  Color get lightTint {
    switch (this) {
      case BubbleType.red:
        return const Color(0xFFFF8A80);
      case BubbleType.blue:
        return const Color(0xFF80D8FF);
      case BubbleType.green:
        return const Color(0xFFB9F6CA);
      case BubbleType.yellow:
        return const Color(0xFFFFFF8D);
      case BubbleType.purple:
        return const Color(0xFFEA80FC);
    }
  }

  /// Deep shadow tint for outer edge gradient falloff.
  Color get shadowTint {
    switch (this) {
      case BubbleType.red:
        return const Color(0xFF8A001A);
      case BubbleType.blue:
        return const Color(0xFF00388A);
      case BubbleType.green:
        return const Color(0xFF005E28);
      case BubbleType.yellow:
        return const Color(0xFF8A6500);
      case BubbleType.purple:
        return const Color(0xFF4A0072);
    }
  }

  /// Outer neon aura/glow color.
  Color get glowColor {
    switch (this) {
      case BubbleType.red:
        return const Color(0xFFFF5252);
      case BubbleType.blue:
        return const Color(0xFF40C4FF);
      case BubbleType.green:
        return const Color(0xFF69F0AE);
      case BubbleType.yellow:
        return const Color(0xFFFFE57F);
      case BubbleType.purple:
        return const Color(0xFFE040FB);
    }
  }
}

