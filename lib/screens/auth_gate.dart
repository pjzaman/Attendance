import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/auth/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Top-level routing widget. Listens to FirebaseAuth state and swaps
/// between the LoginScreen (signed out) and the AppState-provided
/// HomeScreen (signed in). AppState is built lazily once the user is
/// authenticated; on sign-out it's torn down so the next sign-in
/// re-bootstraps cleanly.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _auth = AuthService();
  Future<AppState>? _bootstrapFuture;
  String? _currentUserId;

  Future<AppState> _bootstrap(String firebaseUid) async {
    final state = AppState();
    state.setFirebaseUid(firebaseUid);
    await state.bootstrap();
    return state;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SplashScaffold();
        }
        final user = snap.data;
        if (user == null) {
          _bootstrapFuture = null;
          _currentUserId = null;
          return LoginScreen(auth: _auth);
        }
        if (_currentUserId != user.uid) {
          _currentUserId = user.uid;
          _bootstrapFuture = _bootstrap(user.uid);
        }
        return FutureBuilder<AppState>(
          future: _bootstrapFuture,
          builder: (context, bootSnap) {
            if (bootSnap.connectionState != ConnectionState.done) {
              return const _SplashScaffold();
            }
            if (bootSnap.hasError) {
              return _BootstrapErrorScaffold(
                error: bootSnap.error!,
                onSignOut: () => _auth.signOut(),
              );
            }
            return ChangeNotifierProvider<AppState>.value(
              value: bootSnap.data!,
              child: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}

class _SplashScaffold extends StatelessWidget {
  const _SplashScaffold();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _BootstrapErrorScaffold extends StatelessWidget {
  const _BootstrapErrorScaffold({required this.error, required this.onSignOut});
  final Object error;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text("Couldn't load your workspace",
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$error',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onSignOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
