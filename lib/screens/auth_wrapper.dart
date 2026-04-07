import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart' show firebaseInitialized;
import '../providers/art_collection_provider.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';
import 'vault_shell.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // If Firebase is not available, go straight to app in local mode
    if (!firebaseInitialized) {
      return ChangeNotifierProvider(
        create: (_) => ArtCollectionProvider()..loadArtworks(),
        child: const VaultShell(),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1C1B1A),
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white38,
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        // Save user profile
        FirestoreService().saveUserProfile(user.uid, {
          'email': user.email,
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'lastLogin': DateTime.now().toIso8601String(),
        });

        return ChangeNotifierProvider(
          create: (_) => ArtCollectionProvider()..loadArtworks(uid: user.uid),
          child: const VaultShell(),
        );
      },
    );
  }
}
