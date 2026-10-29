import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bubble_shooter_game/data/models/models.dart';
import 'package:bubble_shooter_game/game/components/bubble_component.dart';
import 'package:bubble_shooter_game/game/components/danger_line_component.dart';
import 'package:bubble_shooter_game/game/components/floating_text_component.dart';
import 'package:bubble_shooter_game/game/components/grid_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FloatingTextComponent Tests', () {
    test('Initializes with target text, position, and default parameters', () {
      final textComp = FloatingTextComponent(
        text: '+100',
        position: Vector2(100, 200),
      );

      expect(textComp.text, equals('+100'));
      expect(textComp.position.x, equals(100));
      expect(textComp.position.y, equals(200));
      expect(textComp.duration, equals(0.70));
    });

    test('Floats vertically upward on update', () {
      final textComp = FloatingTextComponent(
        text: '+300 COMBO x1!',
        position: Vector2(150, 300),
        floatSpeed: 60.0,
      );

      textComp.update(0.1); // moves upward by 60 * 0.1 = 6px
      expect(textComp.position.y, closeTo(294.0, 0.001));

      textComp.update(0.2); // moves upward by 60 * 0.2 = 12px
      expect(textComp.position.y, closeTo(282.0, 0.001));
    });

    test('Self-removes after exceeding duration lifecycle', () {
      final parent = Component();
      final textComp = FloatingTextComponent(
        text: '+200 DROP!',
        position: Vector2(200, 250),
        duration: 0.70,
      );
      parent.add(textComp);

      expect(textComp.parent, equals(parent));

      textComp.update(0.40);
      expect(textComp.isMounted || textComp.parent == parent, isTrue);

      textComp.update(0.35); // total 0.75s >= 0.70s
      expect(textComp.isRemoving || textComp.parent == null, isTrue);
    });
  });

  group('DangerLineComponent Tests', () {
    const double dangerThresholdY = 552.0;
    const double gameWidth = 400.0;
    const double gameHeight = 700.0;

    late GridManager gridManager;
    late DangerLineComponent dangerLine;

    setUp(() {
      gridManager = GridManager(
        radius: 25.0,
        topOffset: 60.0,
        maxRows: 14,
        evenColumns: 8,
        oddColumns: 7,
      );

      dangerLine = DangerLineComponent(
        dangerThresholdY: dangerThresholdY,
        gameWidth: gameWidth,
        gameHeight: gameHeight,
        gridManager: gridManager,
      );
    });

    test('Calm mode when grid has bubbles far above danger threshold', () {
      // Row 0 bubble at y = 60.0, far above 552.0
      gridManager.setBubbleAt(
        0,
        0,
        BubbleComponent(
          row: 0,
          col: 0,
          bubbleType: BubbleType.red,
          radius: 25.0,
        ),
      );

      dangerLine.update(0.016);

      expect(dangerLine.isCritical, isFalse);
      expect(dangerLine.lowestBubbleY, closeTo(60.0, 0.1));
    });

    test(
      'Critical mode activated when bubble reaches within 2 rows of threshold',
      () {
        // Row 10 is at y = 60 + 10 * (25 * sqrt(3)) ≈ 493.0
        // 552 - (2 * 43.3) ≈ 465.4. Since 493.0 >= 465.4, it is critical!
        gridManager.setBubbleAt(
          10,
          0,
          BubbleComponent(
            row: 10,
            col: 0,
            bubbleType: BubbleType.blue,
            radius: 25.0,
          ),
        );

        dangerLine.update(0.016);

        expect(dangerLine.isCritical, isTrue);
        expect(dangerLine.lowestBubbleY, greaterThan(465.0));
      },
    );

    test('Critical mode resets to calm when danger bubbles are cleared', () {
      // Place critical bubble in row 10
      gridManager.setBubbleAt(
        10,
        0,
        BubbleComponent(
          row: 10,
          col: 0,
          bubbleType: BubbleType.blue,
          radius: 25.0,
        ),
      );
      dangerLine.update(0.016);
      expect(dangerLine.isCritical, isTrue);

      // Clear grid
      gridManager.clear();
      dangerLine.update(0.016);
      expect(dangerLine.isCritical, isFalse);
    });
  });
}
