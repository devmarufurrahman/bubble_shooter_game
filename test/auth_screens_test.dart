import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bubble_shooter_game/auth/auth_service.dart';
import 'package:bubble_shooter_game/data/repositories/repositories.dart';
import 'package:bubble_shooter_game/presentation/auth/auth.dart';
import 'package:bubble_shooter_game/presentation/game_play/game_screen.dart';
import 'package:bubble_shooter_game/presentation/stage_select/stage_select_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService & Error Handling Tests', () {
    test('getFriendlyErrorMessage maps known FirebaseAuth error codes', () {
      expect(
        AuthService.getFriendlyErrorMessage(
          FirebaseAuthException(code: 'email-already-in-use'),
        ),
        contains('already registered'),
      );

      expect(
        AuthService.getFriendlyErrorMessage(
          FirebaseAuthException(code: 'invalid-email'),
        ),
        contains('valid email'),
      );

      expect(
        AuthService.getFriendlyErrorMessage(
          FirebaseAuthException(code: 'weak-password'),
        ),
        contains('too weak'),
      );

      expect(
        AuthService.getFriendlyErrorMessage(
          FirebaseAuthException(code: 'wrong-password'),
        ),
        contains('Incorrect password'),
      );

      expect(
        AuthService.getFriendlyErrorMessage(
          FirebaseAuthException(code: 'invalid-credential'),
        ),
        contains('Invalid credentials'),
      );

      expect(
        AuthService.getFriendlyErrorMessage(
          FirebaseAuthException(code: 'network-request-failed'),
        ),
        contains('Network connection error'),
      );

      expect(
        AuthRepository.getFriendlyErrorMessage(
          FirebaseAuthException(code: 'user-not-found'),
        ),
        contains('No account found'),
      );
    });
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('LoginScreen renders all required forms and action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify title & badges
      expect(find.text('PILOT LOGIN'), findsOneWidget);
      expect(find.text('EMAIL ADDRESS'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);

      // Verify action buttons
      expect(find.text('PLAY NOW / LOGIN'), findsOneWidget);
      expect(find.text('CONTINUE WITH GOOGLE'), findsOneWidget);
      expect(find.text('GUEST PLAY • INSTANT ACCESS'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('LoginScreen validates empty email and password on submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      final loginBtn = find.text('PLAY NOW / LOGIN');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();

      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('LoginScreen validates invalid email format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      final loginBtn = find.text('PLAY NOW / LOGIN');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('LoginScreen navigates to RegisterScreen when Register is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      final registerLink = find.text('Register');
      await tester.ensureVisible(registerLink);
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      // Should now be on RegisterScreen
      expect(find.text('CREATE PROFILE'), findsOneWidget);
      expect(find.text('GAMER TAG / PILOT NAME'), findsOneWidget);
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('RegisterScreen renders fields with gamer tag and password confirmation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      expect(find.text('CREATE PROFILE'), findsOneWidget);
      expect(find.text('GAMER TAG / PILOT NAME'), findsOneWidget);
      expect(find.text('EMAIL ADDRESS'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('RegisterScreen validates short gamer tag and password mismatch', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Enter 2-char name (minimum is 3)
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(4));

      await tester.enterText(fields.at(0), 'AB'); // Gamer Tag
      await tester.enterText(fields.at(1), 'pilot@galaxy.com'); // Email
      await tester.enterText(fields.at(2), 'secret123'); // Password
      await tester.enterText(fields.at(3), 'mismatch456'); // Confirm Password

      final createAccountBtn = find.text('CREATE ACCOUNT');
      await tester.ensureVisible(createAccountBtn);
      await tester.tap(createAccountBtn);
      await tester.pump();

      expect(find.text('Pilot name must be at least 3 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('RegisterScreen allows popping back to login via Login link', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/login',
          routes: {
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
          },
        ),
      );

      // Go to register
      final registerLink = find.text('Register');
      await tester.ensureVisible(registerLink);
      await tester.tap(registerLink);
      await tester.pumpAndSettle();
      expect(find.text('CREATE PROFILE'), findsOneWidget);

      // Tap Login link
      final loginLink = find.text('Login');
      await tester.ensureVisible(loginLink);
      await tester.tap(loginLink);
      await tester.pumpAndSettle();
      expect(find.text('PILOT LOGIN'), findsOneWidget);
    });
  });

  group('StageSelectScreen Header Profile Tests', () {
    testWidgets('StageSelectScreen renders stage list and header badge cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StageSelectScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('STAGE SELECT'), findsOneWidget);
      expect(find.text('CHALLENGE STAGES 01 - 10'), findsOneWidget);
      expect(find.text('LV 01'), findsOneWidget);
    });

    testWidgets('StageSelectScreen renders without RenderFlex overflow on narrow screens', (tester) async {
      // Test narrow screen width (e.g., 360 logical pixels) where 9.6px overflow previously occurred
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: StageSelectScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // No assertion or overflow error should be thrown
      expect(tester.takeException(), isNull);
      expect(find.text('STAGE SELECT'), findsOneWidget);
    });

    testWidgets('StageSelectScreen renders adaptively on iPhone 14 dimensions (390x844)', (tester) async {
      // iPhone 14 viewport simulation: 390 x 844 logical pixels, DPR 3.0
      tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(top: 47 * 3.0, bottom: 34 * 3.0);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        const MaterialApp(
          home: StageSelectScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('STAGE SELECT'), findsOneWidget);
      expect(find.text('LV 01'), findsOneWidget);
    });
  });

  group('GameScreen Responsive HUD Tests', () {
    testWidgets('GameScreen HUD renders without RenderFlex overflow on iPhone 14 (390x844)', (tester) async {
      tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(top: 47 * 3.0, bottom: 34 * 3.0);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(levelNumber: 1),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('GameScreen HUD renders without RenderFlex overflow on narrow viewport (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(levelNumber: 1),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.byType(GameScreen), findsOneWidget);
    });
  });
}
