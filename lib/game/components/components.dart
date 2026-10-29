/// Centralized barrel export for all Flame game components.
library;

export 'ammo_inventory_component.dart';
export 'arcade_game_backdrop.dart';
export 'bubble_color.dart';
export 'bubble_component.dart';
export 'bubble_pop_particle.dart';
export 'bullet_bubble.dart';
export 'cannon_component.dart';
export 'danger_line_component.dart';
export 'falling_bubble_component.dart';
export 'floating_text_component.dart';
export 'grid_manager.dart';
export 'procedural_bubble_renderer.dart';
export 'trajectory_line.dart';

import 'bubble_pop_particle.dart';
/// Clean alias for procedural pop explosion particles.
typedef PopParticle = BubblePopParticle;
