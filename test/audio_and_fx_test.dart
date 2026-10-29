import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bubble_shooter_game/core/audio/audio.dart';
import 'package:bubble_shooter_game/core/utils/utils.dart';
import 'package:bubble_shooter_game/game/components/bubble_color.dart';
import 'package:bubble_shooter_game/game/components/bubble_pop_particle.dart';
import 'package:bubble_shooter_game/game/components/bullet_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundManager.enableAudio = false;
  });

  group('SoundManager Audio System Tests', () {
    test('SoundManager follows singleton pattern', () {
      final s1 = SoundManager.instance;
      final s2 = SoundManager();
      expect(identical(s1, s2), isTrue);
    });

    test('Initial mute status is false by default', () async {
      final sound = SoundManager.instance;
      await sound.initialize();
      expect(sound.isMuted, isFalse);
      expect(sound.isMutedNotifier.value, isFalse);
    });

    test('toggleMute toggles value and persists to SharedPreferences', () async {
      final sound = SoundManager.instance;
      await sound.initialize();

      expect(sound.isMuted, isFalse);

      await sound.toggleMute();
      expect(sound.isMuted, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SoundManager.prefKeyMuted), isTrue);

      await sound.toggleMute();
      expect(sound.isMuted, isFalse);
      expect(prefs.getBool(SoundManager.prefKeyMuted), isFalse);
    });

    test('setMuted explicitly updates mute status', () async {
      final sound = SoundManager.instance;
      await sound.setMuted(true);
      expect(sound.isMuted, isTrue);

      await sound.setMuted(false);
      expect(sound.isMuted, isFalse);
    });

    test('Audio playback methods execute safely without throwing', () {
      final sound = SoundManager.instance;

      expect(() => sound.playShoot(), returnsNormally);
      expect(() => sound.playBounce(), returnsNormally);
      expect(() => sound.playPop(), returnsNormally);
      expect(() => sound.playWin(), returnsNormally);
      expect(() => sound.playChime(), returnsNormally);
      expect(() => sound.playGameOver(), returnsNormally);
      expect(() => sound.stopBgm(), returnsNormally);
    });

    test('BGM toggle and persistence in SoundManager', () async {
      final sound = SoundManager.instance;
      await sound.initialize();

      expect(sound.isBgmEnabled, isTrue);

      await sound.toggleBgm();
      expect(sound.isBgmEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SoundManager.prefKeyBgm), isFalse);

      await sound.setBgmEnabled(true);
      expect(sound.isBgmEnabled, isTrue);
      expect(prefs.getBool(SoundManager.prefKeyBgm), isTrue);
    });
  });

  group('HapticsHelper Toggle & Persistence Tests', () {
    test('Haptics enabled toggle and preferences persistence', () async {
      await HapticsHelper.initialize();
      expect(HapticsHelper.isHapticsEnabled, isTrue);

      await HapticsHelper.toggleHaptics();
      expect(HapticsHelper.isHapticsEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(HapticsHelper.prefKeyHaptics), isFalse);

      await HapticsHelper.setHapticsEnabled(true);
      expect(HapticsHelper.isHapticsEnabled, isTrue);
      expect(prefs.getBool(HapticsHelper.prefKeyHaptics), isTrue);
    });

    test('Haptics methods execute safely when enabled or disabled', () async {
      await HapticsHelper.setHapticsEnabled(true);
      expect(() => HapticsHelper.lightImpact(), returnsNormally);
      expect(() => HapticsHelper.mediumImpact(), returnsNormally);
      expect(() => HapticsHelper.heavyImpact(), returnsNormally);
      expect(() => HapticsHelper.selectionClick(), returnsNormally);

      await HapticsHelper.setHapticsEnabled(false);
      expect(() => HapticsHelper.lightImpact(), returnsNormally);
      expect(() => HapticsHelper.selectionClick(), returnsNormally);
    });
  });

  group('Procedural BubblePopParticle Tests', () {
    test('BubblePopParticle creates a valid particle system at target coordinates', () {
      final Vector2 targetPos = Vector2(150.0, 220.0);
      final particleSystem = BubblePopParticle(
        position: targetPos,
        bubbleType: BubbleType.purple,
        particleCount: 14,
      );

      expect(particleSystem.position.x, equals(150.0));
      expect(particleSystem.position.y, equals(220.0));
      expect(particleSystem.particle, isNotNull);
      expect(particleSystem.particle?.lifespan, equals(0.4));
    });

    test('BubblePopParticle renders each BubbleType using valid colors', () {
      for (final type in BubbleType.values) {
        final particle = BubblePopParticle(
          position: Vector2.zero(),
          bubbleType: type,
        );
        expect(particle.particle, isNotNull);
      }
    });
  });

  group('BulletBubble Wall Bounce Audio Callback Tests', () {
    test('BulletBubble triggers onBounce callback when hitting lateral boundary', () {
      bool bounceCalled = false;

      final bullet = BulletBubble(
        bubbleType: BubbleType.red,
        radius: 25.0,
        aimAngle: -0.8, // Moving leftwards
        gameWidth: 400.0,
        ceilingY: 60.0,
        position: Vector2(26.0, 300.0),
        onBounce: () => bounceCalled = true,
      );

      expect(bullet.velocity.x, lessThan(0));

      // Advance by dt to cross left boundary (x <= 25.0)
      bullet.update(0.05);

      expect(bounceCalled, isTrue);
      expect(bullet.velocity.x, greaterThan(0)); // Reflected rightwards
    });
  });
}

