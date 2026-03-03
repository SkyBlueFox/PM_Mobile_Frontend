import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_api.dart';
import 'token_storage.dart';

class AuthRepository {
  final AuthApi api;
  final TokenStorage storage;

  AuthRepository({
    required this.api,
    required this.storage,
  });

  Future<String> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign in cancelled');
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final user = userCredential.user;
    if (user == null) {
      throw Exception('Firebase user null');
    }

    final firebaseIdToken = await user.getIdToken();
    
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw Exception('Failed to get Firebase ID token');
    }

    try {
      await api.loginWithFirebase(firebaseIdToken);
    } on EmailNotWhitelistedException {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      rethrow;
    }

  await storage.saveToken(firebaseIdToken);

  return firebaseIdToken;
  }

  Future<String?> getSavedToken() => storage.readToken();

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await storage.clearToken();
  }
}

class EmailNotWhitelistedException implements Exception {
  final String message;
  EmailNotWhitelistedException([this.message = 'Email is not in whitelist']);
  @override
  String toString() => message;
}