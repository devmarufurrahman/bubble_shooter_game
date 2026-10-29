import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service class handling Firebase Google Sign-In and session lifecycle.
class AuthService {
  AuthService._internal();

  /// Global singleton instance.
  static final AuthService instance = AuthService._internal();

  /// Factory constructor returning the singleton instance.
  factory AuthService() => instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream emitting user state changes (signed in, signed out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current authenticated Firebase user, or null if unauthenticated.
  User? get currentUser => _auth.currentUser;

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

  /// Terminates both Firebase Auth session and Google Sign-In session.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
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
}

