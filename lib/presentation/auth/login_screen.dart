import 'package:flutter/material.dart';

import '../../core/utils/utils.dart';
import '../../data/repositories/repositories.dart';
import '../../ui/widgets/arcade_background.dart';
import '../../ui/widgets/procedural_bubble_hero.dart';
import '../../ui/widgets/procedural_google_logo.dart';
import 'register_screen.dart';
import 'widgets/arcade_input_field.dart';

/// Arcade-styled login screen featuring Email/Password authentication,
/// Google Sign-In, and instant Guest Play capabilities.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepository();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isGuestLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E1122),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFFF1744), width: 1.5),
        ),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF1744), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEmailLogin() async {
    HapticsHelper.selectionClick();
    if (_isLoading || _isGoogleLoading || _isGuestLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticsHelper.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await _authRepository.loginWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      if (credential == null) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar(AuthRepository.getFriendlyErrorMessage(e));
    }
  }

  Future<void> _handleGoogleSignIn() async {
    HapticsHelper.selectionClick();
    if (_isLoading || _isGoogleLoading || _isGuestLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      final credential = await _authRepository.signInWithGoogle();
      if (!mounted) return;
      if (credential == null) {
        setState(() => _isGoogleLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      _showErrorSnackBar(AuthRepository.getFriendlyErrorMessage(e));
    }
  }

  Future<void> _handleGuestPlay() async {
    HapticsHelper.selectionClick();
    if (_isLoading || _isGoogleLoading || _isGuestLoading) return;

    setState(() => _isGuestLoading = true);

    try {
      final credential = await _authRepository.signInAnonymously();
      if (!mounted) return;
      if (credential == null) {
        setState(() => _isGuestLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGuestLoading = false);
      _showErrorSnackBar(AuthRepository.getFriendlyErrorMessage(e));
    }
  }

  void _navigateToRegister() {
    HapticsHelper.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A14),
      body: ArcadeBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 420,
                      minHeight: constraints.maxHeight > 40 ? constraints.maxHeight - 40 : 0,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Arcade Title Header
                          const _ArcadeTitleHeader(),

                          const SizedBox(height: 14),

                          // Procedural Hero Graphic
                          const ProceduralBubbleHero(size: 96),

                          const SizedBox(height: 18),

                          // Arcade Glowing Card Container
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11172D).withValues(alpha: 0.9),
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
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const Text(
                              'PILOT LOGIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your credentials to enter the arena',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Email Field
                            ArcadeInputField(
                              controller: _emailController,
                              labelText: 'EMAIL ADDRESS',
                              hintText: 'pilot@galaxy.arcade',
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter your email address';
                                }
                                final bool isValid = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                ).hasMatch(val.trim());
                                if (!isValid) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            // Password Field with Show/Hide toggle
                            ArcadeInputField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              labelText: 'PASSWORD',
                              hintText: '••••••••',
                              prefixIcon: Icons.lock_rounded,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleEmailLogin(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: Colors.white60,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (val.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 22),

                            // Primary Action: Play Now / Login Button
                            _ArcadeLoginButton(
                              label: 'PLAY NOW / LOGIN',
                              icon: Icons.sports_esports_rounded,
                              isLoading: _isLoading,
                              onPressed: _handleEmailLogin,
                            ),

                            const SizedBox(height: 16),

                            // Divider
                            Row(
                              children: [
                                const Expanded(child: Divider(color: Colors.white12)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider(color: Colors.white12)),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Google Sign-In Secondary Button
                            _GoogleLoginButton(
                              isLoading: _isGoogleLoading,
                              onPressed: _handleGoogleSignIn,
                            ),

                            const SizedBox(height: 10),

                            // Guest Play Option
                            _GuestPlayButton(
                              isLoading: _isGuestLoading,
                              onPressed: _handleGuestPlay,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // "Don't have an account? Register" Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        InkWell(
                          onTap: _navigateToRegister,
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              'Register',
                              style: TextStyle(
                                color: Color(0xFFFF007F),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.5,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFFF007F),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Footer Arcade Subtext
                    Text(
                      'RETRO ARCADE ENGINE • 10 CHALLENGE LEVELS',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  ),
),
);
  }
}

/// Header with glowing neon shadows.
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
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 34,
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
                    Shadow(color: Color(0xFF00E5FF), blurRadius: 16),
                  ],
                ),
              ),
              TextSpan(
                text: 'SHOOTER',
                style: TextStyle(
                  color: Color(0xFFFF007F),
                  shadows: [
                    Shadow(color: Color(0xFFFF007F), blurRadius: 18),
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

/// Primary Play Now / Login Button.
class _ArcadeLoginButton extends StatelessWidget {
  const _ArcadeLoginButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF0051FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00E5FF), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
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

/// Google Sign-In Secondary Button.
class _GoogleLoginButton extends StatelessWidget {
  const _GoogleLoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF19203C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3F4E7A),
                width: 1.2,
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          ProceduralGoogleLogo(size: 20),
                          SizedBox(width: 10),
                          Text(
                            'CONTINUE WITH GOOGLE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
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

/// Instant Guest Play Button.
class _GuestPlayButton extends StatelessWidget {
  const _GuestPlayButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          foregroundColor: const Color(0xFFFFD600),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD600)),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFFFD600)),
                    SizedBox(width: 6),
                    Text(
                      'GUEST PLAY • INSTANT ACCESS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
