import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bubble_shooter_game/core/audio/audio.dart';
import 'package:bubble_shooter_game/core/utils/utils.dart';
import 'package:bubble_shooter_game/data/repositories/repositories.dart';
import 'package:bubble_shooter_game/game/bubble_shooter_game.dart';
import 'package:bubble_shooter_game/presentation/overlays/overlays.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundManager.enableAudio = false;
  });

  group('WinDialog & Star-Burst Celebration Tests', () {
    test('calculateStars helper calculates star brackets accurately', () {
      // For maxShots = 30:
      // >= 15 shots remaining (50%) -> 3 stars
      // >= 8 shots remaining (25%) -> 2 stars
      // < 8 shots remaining -> 1 star
      expect(WinDialog.calculateStars(15, 30), equals(3));
      expect(WinDialog.calculateStars(20, 30), equals(3));
      expect(WinDialog.calculateStars(14, 30), equals(2));
      expect(WinDialog.calculateStars(8, 30), equals(2));
      expect(WinDialog.calculateStars(7, 30), equals(1));
      expect(WinDialog.calculateStars(1, 30), equals(1));
    });

    testWidgets('WinDialog renders title, star slots, and buttons cleanly', (tester) async {
      final game = BubbleShooterGame(levelNumber: 1);
      game.currentScore = 1500;
      game.shotsRemaining = 20;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WinDialog(game: game),
          ),
        ),
      );

      // Verify Level Cleared header and Stage label
      expect(find.text('★ LEVEL CLEARED! ★'), findsOneWidget);
      expect(find.text('STAGE 01'), findsOneWidget);

      // Verify 3 star slot placeholders
      expect(find.byIcon(Icons.star_rounded), findsWidgets);

      // Verify action buttons
      expect(find.text('NEXT LEVEL'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
      expect(find.text('STAGE SELECT'), findsOneWidget);

      // Advance through staggered star timers (300ms, 600ms, 900ms) and 1s score count
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 500));

      // After 1.5 seconds, final score displays 1500
      expect(find.text('1500'), findsOneWidget);
    });

    testWidgets('WinDialog on final level (Level 10) hides Next Level button', (tester) async {
      final game = BubbleShooterGame(levelNumber: 10);
      game.currentScore = 5000;
      game.shotsRemaining = 8;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WinDialog(game: game),
          ),
        ),
      );

      expect(find.text('NEXT LEVEL'), findsNothing);
      expect(find.text('RETRY'), findsOneWidget);
      expect(find.text('STAGE SELECT'), findsOneWidget);

      // Settle animations
      await tester.pumpAndSettle();
    });
  });

  group('SettingsDialog Modal Tests', () {
    testWidgets('SettingsDialog renders all three audio & haptic switches', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsDialog(),
          ),
        ),
      );

      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('Sound Effects (SFX)'), findsOneWidget);
      expect(find.text('Background Music (BGM)'), findsOneWidget);
      expect(find.text('Haptic Vibration'), findsOneWidget);
      expect(find.text('RESET CAMPAIGN PROGRESS'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(3));
    });

    testWidgets('Toggling switches in SettingsDialog updates preferences', (tester) async {
      await SoundManager.instance.initialize();
      await HapticsHelper.initialize();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsDialog(),
          ),
        ),
      );

      // Initially all active
      expect(SoundManager.instance.isMuted, isFalse);
      expect(SoundManager.instance.isBgmEnabled, isTrue);
      expect(HapticsHelper.isHapticsEnabled, isTrue);

      // Find all 3 switches and toggle them
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(3));

      // Toggle SFX (first switch)
      await tester.tap(switches.at(0));
      await tester.pump();
      expect(SoundManager.instance.isMuted, isTrue);

      // Toggle BGM (second switch)
      await tester.tap(switches.at(1));
      await tester.pump();
      expect(SoundManager.instance.isBgmEnabled, isFalse);

      // Toggle Haptics (third switch)
      await tester.tap(switches.at(2));
      await tester.pump();
      expect(HapticsHelper.isHapticsEnabled, isFalse);
    });

    testWidgets('Reset Campaign Progress opens confirmation and triggers reset', (tester) async {
      // Set some initial progress
      await LevelRepository.saveProgress(level: 1, score: 2000, stars: 3);
      expect(await LevelRepository.getUnlockedLevel(), equals(2));

      bool resetCallbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsDialog(
              onProgressReset: () {
                resetCallbackCalled = true;
              },
            ),
          ),
        ),
      );

      // Tap Reset button
      await tester.tap(find.text('RESET CAMPAIGN PROGRESS'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appeared
      expect(find.text('RESET PROGRESS'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to reset all unlocked stages, high scores, and stars? This action cannot be undone.',
        ),
        findsOneWidget,
      );

      // Confirm reset
      await tester.tap(find.text('RESET'));
      await tester.pumpAndSettle();

      expect(resetCallbackCalled, isTrue);
      expect(await LevelRepository.getUnlockedLevel(), equals(1));
      expect(await LevelRepository.getHighScore(1), equals(0));
    });
  });
}

