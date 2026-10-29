import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/auth_service.dart';

/// Repository interface and implementation for user authentication and session management.
class AuthRepository {
  const AuthRepository([AuthService? service]) : _service = service;

  static const AuthRepository instance = AuthRepository();

  final AuthService? _service;
  AuthService get _authService => _service ?? AuthService.instance;

  /// Stream emitting user state changes (signed in, signed out).
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Static stream shortcut for root widgets.
  static Stream<User?> get authStateStream => AuthService.instance.authStateChanges;

  /// Current authenticated Firebase user, or null if unauthenticated.
  User? get currentUser => _authService.currentUser;

  /// Registers a player with Email, Password, and gamer tag.
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String playerName,
  }) =>
      _authService.registerWithEmail(
        email: email,
        password: password,
        playerName: playerName,
      );

  /// Authenticates an existing player with Email and Password.
  Future<UserCredential?> loginWithEmail({
    required String email,
    required String password,
  }) =>
      _authService.loginWithEmail(
        email: email,
        password: password,
      );

  /// Initiates interactive Google Sign-In flow and links credential to Firebase.
  Future<UserCredential?> signInWithGoogle() => _authService.signInWithGoogle();

  /// Authenticates anonymously as a guest player.
  Future<UserCredential?> signInAnonymously() => _authService.signInAnonymously();

  /// Signs out from both Firebase and Google session.
  Future<void> signOut() => _authService.signOut();

  /// Converts technical authentication exceptions into user-friendly messages.
  static String getFriendlyErrorMessage(dynamic error) =>
      AuthService.getFriendlyErrorMessage(error);
}
