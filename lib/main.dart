// Entry point. Initialises Firebase + firedart (which we use for
// Firestore on Windows desktop because cloud_firestore's C++ SDK
// has linker issues there).

import 'package:firebase_core/firebase_core.dart';
import 'package:firedart/firedart.dart' as fd;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config.dart';
import 'firebase_options.dart';
import 'services/auth/persistent_token_store.dart';
import 'services/firestore/firestore_repo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();
  final options = DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(options: options);

  // Persistent token store for firedart so its session survives app
  // restarts. Without it, firedart appears signed-out on every
  // relaunch even though firebase_auth restored its session, and
  // Firestore reads fail with SignedOutException.
  final prefs = await SharedPreferences.getInstance();
  fd.FirebaseAuth.initialize(options.apiKey, PersistentTokenStore(prefs));
  FirestoreRepo.initialize(options.projectId);

  runApp(const AponAttendanceApp());
}
