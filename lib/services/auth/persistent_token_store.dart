import 'dart:convert';

import 'package:firedart/firedart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists firedart's auth token across app restarts using
/// shared_preferences. Without this, firedart uses the in-memory
/// VolatileStore — which means every relaunch the user appears
/// signed-out to firedart even though firebase_auth (which has its
/// own native persistence) restored their session. The mismatch
/// causes Firestore reads to fail with SignedOutException as soon as
/// AppState attaches its listeners.
///
/// firedart's TokenStore expects synchronous read/write, so we load
/// SharedPreferences once at startup (in main()) and pass it in.
/// Subsequent reads/writes hit the in-memory cache; SharedPreferences
/// flushes to disk asynchronously on its own.
class PersistentTokenStore extends TokenStore {
  PersistentTokenStore(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'firedart_token_v1';

  @override
  Token? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return Token.fromMap(map);
    } catch (_) {
      // Corrupt cache (e.g. format change). Drop it; user re-logs in.
      _prefs.remove(_key);
      return null;
    }
  }

  @override
  void write(Token? token) {
    if (token == null) {
      _prefs.remove(_key);
      return;
    }
    _prefs.setString(_key, jsonEncode(token.toMap()));
  }

  @override
  void delete() {
    _prefs.remove(_key);
  }
}
