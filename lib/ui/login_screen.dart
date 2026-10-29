import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import 'widgets/arcade_background.dart';
import 'widgets/procedural_bubble_hero.dart';
import 'widgets/procedural_google_logo.dart';

/// Arcade-style login screen featuring glowing neon surfaces, procedural graphics,
/// and reactive Google Sign-In handling.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService.instance;
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final credential = await _authService.signInWithGoogle();
      if (!mounted) return;

      if (credential == null) {
        // Sign in was cancelled by user
        setState(() => _isLoading = false);
        return;
      }

      // Successful login will naturally trigger AuthWrapper state transition.
      // Reset local loading flag in case of navigation delays.
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD50000),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
          ),
          content: Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sign-in failed. Please check your connection and try again.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A14),
      body: ArcadeBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Arcade Title Header
                    const _ArcadeTitleHeader(),

                    const SizedBox(height: 28),

                    // Procedural Hero Graphic
                    const ProceduralBubbleHero(size: 150),

                    const SizedBox(height: 36),

                    // Arcade Glowing Card Container
                    _ArcadeLoginCard(
                      isLoading: _isLoading,
                      onSignInPressed: _handleGoogleSignIn,
                    ),

                    const SizedBox(height: 24),

                    // Footer Arcade Subtext
                    Text(
                      'RETRO ARCADE ENGINE • 10 CHALLENGE LEVELS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modular Arcade Title Header with glowing neon shadows.
class _ArcadeTitleHeader extends StatelessWidget {
  const _ArcadeTitleHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD600).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD600).withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD600).withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Text(
            '★ ARCADE EDITION ★',
            style: TextStyle(
              color: Color(0xFFFFD600),
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 3.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.0,
              fontFamily: 'sans-serif',
            ),
            children: [
              TextSpan(
                text: 'BUBBLE\n',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  shadows: [
                    Shadow(
                      color: Color(0xFF00E5FF),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: 'SHOOTER',
                style: TextStyle(
                  color: Color(0xFFFF007F),
                  shadows: [
                    Shadow(
                      color: Color(0xFFFF007F),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Glowing glassmorphic container holding sign-in actions.
class _ArcadeLoginCard extends StatelessWidget {
  const _ArcadeLoginCard({
    required this.isLoading,
    required this.onSignInPressed,
  });

  final bool isLoading;
  final VoidCallback onSignInPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF11172D).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'PLAYER AUTHENTICATION',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to track high scores and unlock all 10 challenge stages.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _GoogleSignInArcadeButton(
            isLoading: isLoading,
            onPressed: onSignInPressed,
          ),
        ],
      ),
    );
  }
}

/// Arcade styled button executing Google Sign-In with glowing border and spinner.
class _GoogleSignInArcadeButton extends StatelessWidget {
  const _GoogleSignInArcadeButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
        highlightColor: const Color(0xFFFF007F).withValues(alpha: 0.1),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF19203C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLoading
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF3F4E7A),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                blurRadius: 14,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF00E5FF),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        ProceduralGoogleLogo(size: 22),
                        SizedBox(width: 14),
                        Text(
                          'CONTINUE WITH GOOGLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
