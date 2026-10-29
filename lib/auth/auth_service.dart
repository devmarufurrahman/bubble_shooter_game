import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Production-ready service handling Firebase Email/Password authentication,
/// Google Sign-In, Anonymous guest play, and session state.
class AuthService {
  AuthService._internal();

  /// Global singleton instance.
  static final AuthService instance = AuthService._internal();

  /// Factory constructor returning the singleton instance.
  factory AuthService() => instance;

  FirebaseAuth? _authInstance;
  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream emitting user state changes (signed in, signed out).
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream<User?>.empty();
    }
  }

  /// Current authenticated Firebase user, or null if unauthenticated.
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Registers a new player with Email, Password, and gamer tag / display name.
  /// Updates profile name and reloads user to persist state.
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String playerName,
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;
      if (user != null) {
        await user.updateDisplayName(playerName.trim());
        await user.reload();
      }

      developer.log(
        'Registered user: ${user?.email} as $playerName (${user?.uid})',
        name: 'AuthService',
      );
      return credential;
    } on FirebaseAuthException catch (e, stackTrace) {
      developer.log(
        'FirebaseAuthException during registration: [${e.code}] ${e.message}',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during registration: $e',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Authenticates an existing player using Email and Password.
  Future<UserCredential?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      developer.log(
        'Logged in user: ${credential.user?.email} (${credential.user?.uid})',
        name: 'AuthService',
      );
      return credential;
    } on FirebaseAuthException catch (e, stackTrace) {
      developer.log(
        'FirebaseAuthException during login: [${e.code}] ${e.message}',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during login: $e',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Initiates interactive Google Sign-In flow and links credential to Firebase.
  /// Returns [UserCredential] on success, or null if aborted by the user.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        developer.log('Google sign-in was aborted by user.', name: 'AuthService');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      developer.log(
        'Google sign-in successful: ${userCredential.user?.email} (${userCredential.user?.uid})',
        name: 'AuthService',
      );
      return userCredential;
    } on FirebaseAuthException catch (e, stackTrace) {
      developer.log(
        'FirebaseAuthException during Google sign-in: [${e.code}] ${e.message}',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during Google sign-in: $e',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Authenticates anonymously as a guest player for instant access.
  Future<UserCredential?> signInAnonymously() async {
    try {
      final UserCredential credential = await _auth.signInAnonymously();
      final User? user = credential.user;
      if (user != null && (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName('Guest Pilot');
        await user.reload();
      }
      developer.log('Guest sign-in successful: ${user?.uid}', name: 'AuthService');
      return credential;
    } on FirebaseAuthException catch (e, stackTrace) {
      developer.log(
        'FirebaseAuthException during anonymous sign-in: [${e.code}] ${e.message}',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error during anonymous sign-in: $e',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Terminates Firebase Auth session and any active Google Sign-In session safely.
  Future<void> signOut() async {
    try {
      final List<Future<void>> signoutTasks = [_auth.signOut()];
      if (await _googleSignIn.isSignedIn()) {
        signoutTasks.add(_googleSignIn.signOut());
      }
      await Future.wait(signoutTasks);
      developer.log('Sign-out completed successfully.', name: 'AuthService');
    } catch (e, stackTrace) {
      developer.log(
        'Error during sign-out: $e',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Converts technical authentication exceptions into friendly messages for the UI.
  static String getFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email address is already registered. Please log in.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'operation-not-allowed':
          return 'This sign-in method is currently disabled. Please contact support.';
        case 'weak-password':
          return 'The password is too weak. Please use at least 6 characters.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'user-not-found':
          return 'No account found with this email. Please register first.';
        case 'wrong-password':
          return 'Incorrect password. Please verify and try again.';
        case 'invalid-credential':
          return 'Invalid credentials. Please verify your email and password.';
        case 'network-request-failed':
          return 'Network connection error. Please check your internet and try again.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again in a few moments.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return error?.toString() ?? 'An unexpected error occurred. Please try again.';
  }
}
