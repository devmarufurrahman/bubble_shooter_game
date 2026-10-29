import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth/auth_service.dart';
import 'firebase_options.dart';
import 'ui/level_select_screen.dart';
import 'ui/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with auto-detected platform configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set system UI overlay for full arcade immersion
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF070A14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const BubbleShooterApp());
}

/// The root application widget configuring arcade themes and the authentication gateway.
class BubbleShooterApp extends StatelessWidget {
  const BubbleShooterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubble Shooter Arcade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070A14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFF007F),
          tertiary: Color(0xFFFFD600),
          surface: Color(0xFF131A33),
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Observes Firebase Auth state changes and smoothly transitions between
/// [LoginScreen] and [LevelSelectScreen].
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF070A14),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
              ),
            ),
          );
        }

        final bool isAuthenticated = snapshot.hasData && snapshot.data != null;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: isAuthenticated
              ? const LevelSelectScreen(key: ValueKey('LevelSelectScreen'))
              : const LoginScreen(key: ValueKey('LoginScreen')),
        );
      },
    );
  }
}
