import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  String? get userId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Use Firebase's built-in Google provider (works on web and mobile)
      final googleProvider = GoogleAuthProvider();

      if (kIsWeb) {
        return await _auth.signInWithPopup(googleProvider);
      } else {
        return await _auth.signInWithProvider(googleProvider);
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(displayName);
      return credential;
    } catch (e) {
      debugPrint('Error registering: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  /// Get a user-friendly error message
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No existe una cuenta con ese correo';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con ese correo';
        case 'weak-password':
          return 'La contraseña es demasiado débil';
        case 'invalid-email':
          return 'Correo electrónico inválido';
        case 'too-many-requests':
          return 'Demasiados intentos. Intenta más tarde';
        default:
          return error.message ?? 'Error de autenticación';
      }
    }
    return 'Error inesperado. Intenta de nuevo';
  }
}
