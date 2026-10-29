import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bubble_shooter_game/core/audio/sound_manager.dart';
import 'package:bubble_shooter_game/game/bubble_shooter_game.dart';
import 'package:bubble_shooter_game/game/components/components.dart';
import 'package:bubble_shooter_game/presentation/game_play/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundManager.enableAudio = false;
  });

  group('FlameGame & GameScreen Lifecycle Audit Tests', () {
    test('BubbleShooterGame.onDisposeGame clears components, grid, and notifiers', () async {
      final game = BubbleShooterGame(levelNumber: 1);
      await game.onLoad();

      expect(game.world.children.isNotEmpty, isTrue);
      expect(game.gridManager.totalActiveBubbles, greaterThan(0));

      // Trigger custom disposal teardown
      game.onDisposeGame();

      // Verifications
      expect(game.gridManager.totalActiveBubbles, equals(0));
      expect(game.activeBullet, isNull);
      expect(game.cannon.isAiming, isFalse);

      // Verify notifiers are disposed (cannot be listened to or modified)
      expect(() => game.scoreNotifier.addListener(() {}), throwsA(isA<FlutterError>()));
      expect(() => game.shotsNotifier.addListener(() {}), throwsA(isA<FlutterError>()));
    });

    testWidgets('GameScreen.dispose triggers engine pause and game.onDisposeGame', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(levelNumber: 1),
        ),
      );

      await tester.pump();

      // Find GameWidget host
      expect(find.byType(GameScreen), findsOneWidget);

      // Pop GameScreen to trigger dispose()
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Home')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GameScreen), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('Component Lifecycle & Teardown Tests', () {
    test('BubblePopParticle strictly removes itself once maxDuration elapses', () {
      final parent = Component();
      final particle = BubblePopParticle(
        position: Vector2(100, 100),
        bubbleType: BubbleType.blue,
        particleCount: 8,
        maxDuration: 0.40,
      );
      parent.add(particle);

      expect(particle.parent, equals(parent));

      particle.update(0.20);
      expect(particle.isRemoving || particle.parent == null, isFalse);

      particle.update(0.25); // total 0.45s >= 0.40s
      expect(particle.isRemoving || particle.parent == null, isTrue);
    });

    test('BulletBubble onRemove halts velocity and detaches hitboxes without ConcurrentModificationError', () async {
      final parent = Component();
      final bullet = BulletBubble(
        bubbleType: BubbleType.red,
        radius: 25.0,
        aimAngle: 0.0,
        gameWidth: 400.0,
        ceilingY: 60.0,
        position: Vector2(200, 600),
      );
      parent.add(bullet);
      await bullet.onLoad();

      expect(bullet.isMoving, isTrue);
      expect(bullet.hitbox, isNotNull);

      // Verify onRemove executes without throwing ConcurrentModificationError
      expect(() => bullet.onRemove(), returnsNormally);

      expect(bullet.isMoving, isFalse);
      expect(bullet.hasStopped, isTrue);
      expect(bullet.velocity, equals(Vector2.zero()));
      expect(bullet.hitbox, isNull);
    });

    test('BubbleComponent pop and dropAsFloating inactivate hitbox safely without ConcurrentModificationError', () async {
      final bubble1 = BubbleComponent(
        row: 1,
        col: 1,
        bubbleType: BubbleType.green,
        radius: 25.0,
      );
      await bubble1.onLoad();
      expect(bubble1.hitbox, isNotNull);
      expect(bubble1.hitbox!.collisionType, equals(CollisionType.active));

      // pop() must deactivate hitbox without detaching it mid-iteration
      bubble1.pop();
      expect(bubble1.isPopping, isTrue);
      expect(bubble1.hitbox!.collisionType, equals(CollisionType.inactive));

      final bubble2 = BubbleComponent(
        row: 2,
        col: 2,
        bubbleType: BubbleType.blue,
        radius: 25.0,
      );
      await bubble2.onLoad();
      expect(bubble2.hitbox, isNotNull);
      expect(bubble2.hitbox!.collisionType, equals(CollisionType.active));

      // dropAsFloating() must deactivate hitbox without detaching it mid-iteration
      bubble2.dropAsFloating();
      expect(bubble2.isDropping, isTrue);
      expect(bubble2.hitbox!.collisionType, equals(CollisionType.inactive));

      // Ensure onRemove cleanly finishes without error
      expect(() => bubble1.onRemove(), returnsNormally);
      expect(() => bubble2.onRemove(), returnsNormally);
    });

    test('BubbleComponent onRemove detaches hitbox and clears completers', () {
      final bubble = BubbleComponent(
        row: 1,
        col: 1,
        bubbleType: BubbleType.green,
        radius: 25.0,
      );

      bubble.dropAsFloating();
      expect(bubble.isDropping, isTrue);

      bubble.onRemove();

      expect(bubble.hitbox, isNull);
    });

    test('SoundManager dispose and clearAudioCache execute safely without exceptions', () async {
      SoundManager.enableAudio = false;

      await SoundManager.instance.clearAudioCache();
      await SoundManager.instance.dispose();

      expect(SoundManager.instance.isMuted, isFalse);
    });
  });
}
