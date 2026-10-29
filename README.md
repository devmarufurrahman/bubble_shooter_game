# Bubble Shooter Game — Technical Architecture & Project Specification

---

## 1. Executive Overview & Tech Stack

This project is a high-performance, responsive, 2D arcade Bubble Shooter game engineered using Flutter and the Flame Engine. Designed for zero-asset runtime execution, all visual elements—including 3D spherical glossy bubbles, cannons, aiming guides, and particles—are rendered procedurally via code onto the canvas. The application implements an offline-first architecture for player progression, backed by Firebase Authentication for user identity.

| Layer / Domain | Technology / Library | Architectural Role |
| --- | --- | --- |
| **Core Framework** | Flutter (Dart 3+) | Application lifecycle, widget tree, responsive layout scaffolding |
| **Game Engine** | Flame Engine (`^1.18.0`) | Game loop, component tree lifecycle, canvas rendering, collision detection |
| **Authentication** | Firebase Auth (`firebase_auth`, `google_sign_in`) | Email/Password user registration, Google OAuth, and Anonymous/Guest play |
| **Local Persistence** | `shared_preferences` | High-throughput, offline-first storage for level unlocks, stars, and high scores |
| **Audio Engine** | `flame_audio` / Platform Services | Cached SFX playback with cooldown debouncing and hardware haptic feedback |
| **Procedural Graphics** | Flutter `Canvas`, `Path`, `RadialGradient` | Asset-free rendering of 3D shaded bubbles, trajectory lines, and HUD badges |

---

## 2. Technical Architecture & Design Patterns

The codebase is organized around a feature-driven, decoupled architecture to ensure that the 60/120 FPS game rendering loop remains strictly isolated from Flutter widget rebuilds and platform channels.

```
lib/
├── app/
│   ├── app.dart                   # Global MaterialApp & dark arcade theme
│   └── routes.dart                # Route definitions & transitions
├── core/
│   ├── audio/
│   │   ├── sound_manager.dart     # Debounced audio playback pool
│   │   └── audio.dart             # Central barrel export
│   ├── constants/
│   │   ├── app_colors.dart        # Neon arcade color palette
│   │   ├── game_constants.dart    # Physics constants, layout offsets
│   │   └── constants.dart         # Central barrel export
│   └── utils/
│       ├── haptics_helper.dart    # Safe, throttled hardware haptics
│       └── utils.dart             # Central barrel export
├── data/
│   ├── models/
│   │   ├── bubble_type.dart       # BubbleType enum & color palette mappings
│   │   ├── level_config.dart      # Static matrix data for stages 1-10
│   │   └── models.dart            # Central barrel export
│   └── repositories/
│       ├── auth_repository.dart   # Firebase Auth service layer
│       ├── level_repository.dart  # SharedPreferences persistence layer
│       └── repositories.dart      # Central barrel export
├── game/
│   ├── components/
│   │   ├── bubble_component.dart  # Procedural 3D bubble component
│   │   ├── bullet_bubble.dart     # Dynamic projectile with collision & reflection
│   │   ├── cannon_component.dart  # Aim-clamped rotational launcher & swap trigger
│   │   ├── grid_manager.dart      # Hex grid matrix component
│   │   ├── trajectory_line.dart   # Dotted raycast reflection guide
│   │   ├── pop_particle.dart      # Burst particle system component
│   │   ├── floating_text.dart     # Animated +Score canvas popups
│   │   └── components.dart        # Central barrel export
│   ├── logic/
│   │   ├── hex_math.dart          # Pure mathematical formulas for hex grids
│   │   ├── match_engine.dart      # BFS Match-3 & ceiling anchor algorithms
│   │   └── logic.dart             # Central barrel export
│   ├── bubble_shooter_game.dart   # Core FlameGame instance
│   └── game.dart                  # Game layer barrel export
├── presentation/
│   ├── auth/
│   │   ├── login_screen.dart      # Email/Password & Google Sign-In UI
│   │   └── register_screen.dart   # Account creation with gamer tag
│   ├── stage_select/
│   │   ├── widgets/
│   │   │   ├── stage_card.dart    # Adaptive stage selector tile
│   │   │   └── user_header.dart   # Dynamic user badge with stars count
│   │   └── stage_select_screen.dart
│   ├── game_play/
│   │   ├── overlays/
│   │   │   ├── win_dialog.dart    # Animated 3-star level cleared modal
│   │   │   ├── game_over_dialog.dart
│   │   │   ├── pause_dialog.dart
│   │   │   ├── settings_dialog.dart
│   │   │   └── overlays.dart      # Central barrel export
│   │   ├── widgets/
│   │   │   ├── score_hud.dart     # Glassmorphic top stat overlay
│   │   │   └── ammo_counter.dart  # Mini visual ammo stack
│   │   └── game_screen.dart       # Host widget for Flame GameWidget
│   └── presentation.dart          # UI layer barrel export
└── main.dart
```

### Centralized Barrel Importer System

Every sub-domain exports its public components via an index barrel file (`constants.dart`, `components.dart`, `logic.dart`, etc.). This eliminates relative path traversal (e.g., `../../../../`) and decouples implementation files from consumer components.

### Decoupled Hexagonal Math (Odd-r Staggered Coordinate System)

Grid layout mathematics are decoupled from Flame rendering into a pure, testable Dart class (`HexMath`):

* **Horizontal Staggering:**
  * Even Rows ($r = 0, 2, 4, \dots$): 8 columns. Centroid $X = c \times (2 \times \text{radius}) + \text{radius}$
  * Odd Rows ($r = 1, 3, 5, \dots$): 7 columns. Centroid $X = c \times (2 \times \text{radius}) + (2 \times \text{radius})$

* **Vertical Spacing:**
  * Successive rows interlock into the hex crevices:
    $$Y = k\text{TopHudOffset} + \left(r \times \text{radius} \times \sqrt{3}\right)$$

* **Clearance Isolation ($k\text{TopHudOffset}$):** The ceiling line and Row 0 are pushed down by a fixed offset ($110\text{ px}$) to prevent the top Flutter HUD bar from visually occluding the bubble field.

### Puzzle Resolution Engine

1. **Snapping & Impact Resolution:** When a flying projectile (`BulletBubble`) collides with a static bubble or crosses the ceiling boundary, the engine evaluates adjacent vacant coordinates in the Odd-r grid and snaps the projectile into the closest mathematical slot using Euclidean distance minimization.
2. **BFS Match-3 Algorithm:** From the newly snapped slot, a Breadth-First Search (BFS) traverses all valid hex neighbors sharing the identical `BubbleType`. If the cluster size $\ge 3$, all matched bubbles are flagged for removal.
3. **Ceiling Anchor Traversal (Floating Bubble Drop):** Following a match pop, a global BFS root-check executes from all extant bubbles in Row 0 (the ceiling anchor). Any bubble unreachable from Row 0 is classified as floating/disconnected. These bubbles are detached from the matrix, given downward gravity physics ($1200\text{ px/s}^2$), and purged upon exiting the viewport.

### Reactive State Decoupling (`ValueNotifier`)

In-game metrics such as score, combos, and shots remaining are tracked via `ValueNotifier<int>` primitives rather than pushing setState rebuilds down the widget tree. The top HUD widgets consume these values using `ValueListenableBuilder`, keeping UI repaints isolated from the Flame game canvas.

---

## 3. Core Mechanics & Gameplay Features

* **Procedural 3D Glossy Spheres:** Rendered entirely via Canvas draw calls using a multi-layered technique:
  * Spherical base using an eccentric `RadialGradient` offset towards $(-0.35r, -0.35r)$ transitioning from specular highlight to deep boundary shade.
  * Secondary specular arc/crescent overlay near the top-left rim to simulate reflective glass curvature.
  * Five standardized game palettes: Crimson Red, Azure Blue, Emerald Green, Amber Yellow, and Royal Purple.

* **Rotational Cannon & Reflective Raycast Trajectory:**
  * Anchored horizontally at screen center (`Anchor.center`, $x = \text{size.x} / 2$).
  * Touch-driven pan detection rotates the cannon barrel with clamped angles between $-70^\circ$ and $+70^\circ$ to prevent downward shots.
  * Dotted trajectory line computes screen boundary collisions and projects an angle-of-incidence wall reflection raycast.

* **Tactical Bubble Swap:** Players can swap the actively loaded bubble with the upcoming bubble in the queue via a dedicated swap button, triggering an animated 180-degree rotation. Swapping is locked while a projectile is airborne.
* **Visual Ammo Stack:** The remaining shot allocation is rendered as a physical stack of mini 3D bubbles adjacent to the cannon base. Each fired shot scales down and pops the topmost bubble from the visual inventory.
* **Juicy Arcade Feedback & VFX:**
  * **Burst Particles:** Matched bubbles spawn 10–14 radial `CircleParticle` instances tinted to match the parent bubble, expanding with outward velocity and fading over $0.4\text{ seconds}$.
  * **Floating Score Indicators:** Matched centroids and dropped clusters spawn canvas text popups (`+100`, `+300 COMBO!`, `+200 DROP!`) that scale up elastically, drift upward, and fade out.
  * **Pulsating Danger Threshold:** A neon boundary line spans the lower grid. When any bubble drops within two rows of this limit, the boundary pulses with a sinusoidal red glow to signal impending defeat.

* **10-Level Progressive Campaign:**
  * **Levels 1–3:** Low complexity, 3 active colors, generous ammo allocations ($26\text{–}30\text{ shots}$).
  * **Levels 4–7:** Moderate density, 4 active colors, introduction of isolated color clusters.
  * **Levels 8–10:** High density, 5 active colors, constrained ammo ($16\text{–}18\text{ shots}$), and staggered patterns requiring wall bank shots.

---

## 4. UI/UX & Responsive Layout Engine

* **Separated Authentication Flow:**
  * **Registration (`RegisterScreen`):** Form validation capturing Gamer Tag/Display Name, Email, Password, and Password Confirmation. Updates Firebase user profile metadata upon creation.
  * **Login (`LoginScreen`):** Authenticates existing credentials, offers Google Sign-In, and provides an immediate Guest Play mode via anonymous authentication.

* **Adaptive Stage Select Dashboard:**
  * Displays levels 1 through 10 with clear visual differentiation between unlocked and locked stages.
  * Dynamically queries local persistence to display earned stars ($0\text{–}3$) and recorded high scores.
  * Top profile header displays player avatar, gamer tag, and cumulative star counter (e.g., `18/30 Stars`).

* **Fluid Dynamic Multi-Screen Wrapping:**
  * Replaces rigid horizontal `Row` containers with `Wrap` and `LayoutBuilder`.
  * If horizontal space becomes constrained (e.g., small phones, split-screen mode, accessibility font scaling), profile badges, action buttons, and modal dialog options automatically flow to the next line without causing `RenderFlex` overflows.
  * Modal dialog action buttons ("Next Level", "Retry", "Stage Select") dynamically reflow between horizontal rows on tablets and vertical stacks on compact screens.

* **Letterboxed Game Canvas:**
  * The Flame `GameWidget` operates inside a logical virtual resolution of $400 \times 700$.
  * Hosted inside an `AspectRatio` and centered via `BoxFit.contain`. This guarantees that physics, touch coordinates, and trajectory rays never distort across 16:9, 19.5:9, or 4:3 tablet aspect ratios.

---

## 5. Performance Engineering & Stability

### Platform Channel Throttling

During aiming drag events (`onPanUpdate`), continuous invocations across the Flutter method channel (such as haptics or audio commands) are completely eliminated. Touch drags execute pure in-memory trigonometric calculations. Haptic feedback is strictly limited to discrete events (`onPanDown`, `onPanEnd`, or button presses). This directly resolves Android `MessageQueue` saturation issues where thousands of pending tasks could previously flood the platform bridge.

### Debounced Audio Management (`SoundManager`)

The audio system wraps `FlameAudio` with an internal timestamp cooldown engine ($80\text{ ms}$ threshold). When large bubble clusters collapse simultaneously, audio play requests are batched into a single trigger rather than queuing dozens of simultaneous native sound requests.

### Lifecycle Cleanup & Anti-Ghosting Guarantees

* **Component Teardown:** The `dispose()` lifecycle of `GameScreen` explicitly invokes engine pausing, clears Flutter overlay references, and disposes all active `ValueNotifier` instances.
* **Ghost Bubble Elimination:** When floating bubbles are identified, they are immediately dereferenced from the grid matrix ($M[r][c] = \text{null}$) and transformed into active falling components. Once their $Y$-coordinate exceeds the screen height, they invoke `removeFromParent()` to clear their memory footprint and remove attached hitboxes from Flame's collision detection tree.
* **Win Condition Synchronization:** The "Level Cleared" evaluation routine validates that no dropping bubbles remain active on the canvas before triggering the victory dialog, preventing premature modal displays.

### Offline-First Data Strategy

All level progression metrics (maximum unlocked stage, high scores, earned stars) are read and written synchronously through local storage (`SharedPreferences`). By keeping state persistence entirely on-device, the game maintains zero latency during level transitions and remains fully functional in offline environments.
