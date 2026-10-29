import 'package:flutter/material.dart';

import '../../core/utils/utils.dart';
import '../../data/repositories/repositories.dart';
import '../../ui/widgets/arcade_background.dart';
import '../../ui/widgets/procedural_google_logo.dart';
import 'widgets/arcade_input_field.dart';

/// Arcade-styled registration screen collecting Gamer Tag, Email, and Password
/// with real-time validation and seamless Google Sign-In alternative.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepository();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
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

  Future<void> _handleRegister() async {
    HapticsHelper.selectionClick();
    if (_isLoading || _isGoogleLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticsHelper.heavyImpact();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await _authRepository.registerWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        playerName: _nameController.text,
      );

      if (!mounted) return;
      if (credential != null) {
        // Pop back to root; AuthWrapper handles transitioning to StageSelectScreen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar(AuthRepository.getFriendlyErrorMessage(e));
    }
  }

  Future<void> _handleGoogleSignIn() async {
    HapticsHelper.selectionClick();
    if (_isLoading || _isGoogleLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      final credential = await _authRepository.signInWithGoogle();
      if (!mounted) return;
      if (credential != null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() => _isGoogleLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      _showErrorSnackBar(AuthRepository.getFriendlyErrorMessage(e));
    }
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
                          // Arcade Top Brand Header
                          const _ArcadeHeaderBadge(),

                          const SizedBox(height: 16),

                          const Text(
                            'CREATE PROFILE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.0,
                              shadows: [
                                Shadow(color: Color(0xFFFF007F), blurRadius: 18),
                              ],
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      'Join the Galactic Bubble League & save progress',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Registration Card Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11172D).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFF007F).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF007F).withValues(alpha: 0.15),
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
                            // 1. Gamer Tag / Player Name
                            ArcadeInputField(
                              controller: _nameController,
                              labelText: 'GAMER TAG / PILOT NAME',
                              hintText: 'e.g. StarLord99',
                              prefixIcon: Icons.badge_rounded,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter your pilot name';
                                }
                                if (val.trim().length < 3) {
                                  return 'Pilot name must be at least 3 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            // 2. Email Address
                            ArcadeInputField(
                              controller: _emailController,
                              focusNode: _emailFocus,
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

                            // 3. Password
                            ArcadeInputField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              labelText: 'PASSWORD',
                              hintText: '••••••••',
                              prefixIcon: Icons.lock_rounded,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
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
                                  return 'Please enter a password';
                                }
                                if (val.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            // 4. Confirm Password
                            ArcadeInputField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocus,
                              labelText: 'CONFIRM PASSWORD',
                              hintText: '••••••••',
                              prefixIcon: Icons.verified_user_rounded,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleRegister(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: Colors.white60,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() =>
                                      _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (val != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Primary Action: Create Account Button
                            _ArcadePrimaryButton(
                              label: 'CREATE ACCOUNT',
                              icon: Icons.rocket_launch_rounded,
                              gradientColors: const [Color(0xFFFF007F), Color(0xFF9C27B0)],
                              borderColor: const Color(0xFFFF007F),
                              isLoading: _isLoading,
                              onPressed: _handleRegister,
                            ),

                            const SizedBox(height: 18),

                            // Divider: Or Continue With
                            Row(
                              children: [
                                const Expanded(child: Divider(color: Colors.white12)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'OR CONTINUE WITH',
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

                            const SizedBox(height: 16),

                            // Google Sign-In Quick Action
                            _GoogleQuickButton(
                              isLoading: _isGoogleLoading,
                              onPressed: _handleGoogleSignIn,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // "Already have an account? Login" Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticsHelper.selectionClick();
                            Navigator.of(context).maybePop();
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.5,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF00E5FF),
                              ),
                            ),
                          ),
                        ),
                      ],
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

/// Header Badge displaying arcade edition flair.
class _ArcadeHeaderBadge extends StatelessWidget {
  const _ArcadeHeaderBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF007F).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF007F).withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF007F).withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Text(
        '★ NEW PILOT REGISTRATION ★',
        style: TextStyle(
          color: Color(0xFFFF007F),
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 2.5,
        ),
      ),
    );
  }
}

/// Primary Arcade Action Button with gradient and glowing neon drop shadow.
class _ArcadePrimaryButton extends StatelessWidget {
  const _ArcadePrimaryButton({
    required this.label,
    required this.icon,
    required this.gradientColors,
    required this.borderColor,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final List<Color> gradientColors;
  final Color borderColor;
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
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.35),
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

/// Secondary button executing Google Sign-In with procedural logo.
class _GoogleQuickButton extends StatelessWidget {
  const _GoogleQuickButton({
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
                      mainAxisSize: MainAxisSize.min,
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
    );
  }
}
