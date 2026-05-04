import 'package:firebase_auth/firebase_auth.dart';
import 'package:firedart/firedart.dart' as fd;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps both auth SDKs so the rest of the app doesn't have to know
/// they exist. We use:
///
///   - `firebase_auth` for the canonical user record (UI-facing,
///     supports Google sign-in, password reset emails, etc.)
///   - `firedart`'s FirebaseAuth so its Firestore client (which we
///     use because cloud_firestore is broken on Windows desktop)
///     can attach a valid ID token to each request.
///
/// On every sign-in/out we keep both sides in lockstep. Email/password
/// works directly with firedart. Google sign-in is firebase_auth-only
/// and bypasses firedart's auth — Firestore reads from a Google-only
/// session would fail under tightened rules. Until we wire Google
/// → custom-token swap, Apon's deployment uses email/password.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  static bool get googleSignInSupported {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Mirror to firedart so its Firestore client picks up a token.
    // Failures here surface to the caller — we want sign-in to fail
    // loudly if Firestore is going to be broken downstream.
    await fd.FirebaseAuth.instance.signIn(email.trim(), password);
    return cred;
  }

  /// Returns null if the user cancelled the Google account picker.
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return _auth.signInWithPopup(provider);
    }
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    // NOTE: firedart doesn't support Google sign-in (no Google→custom-
    // token swap baked in). Firestore rules that require auth will
    // reject reads from Google-only sessions. Currently the rules are
    // permissive while we evaluate the right path.
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    if (!kIsWeb && googleSignInSupported) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    try {
      fd.FirebaseAuth.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
