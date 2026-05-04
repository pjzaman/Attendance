// Entry point. Initialises Firebase + firedart (which we use for
// Firestore on Windows desktop because cloud_firestore's C++ SDK
// has linker issues there).

import 'package:firebase_core/firebase_core.dart';
import 'package:firedart/firedart.dart' as fd;
import 'package:flutter/material.dart';

import 'app.dart';
import 'config.dart';
import 'firebase_options.dart';
import 'services/firestore/firestore_repo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();
  final options = DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(options: options);

  // firedart needs its OWN auth state to authorize Firestore
  // requests. We initialize it with the same API key as firebase_auth
  // and AuthService dual-signs-in on every login so both stay in
  // sync. See services/auth/auth_service.dart.
  fd.FirebaseAuth.initialize(options.apiKey, fd.VolatileStore());
  FirestoreRepo.initialize(options.projectId);

  runApp(const AponAttendanceApp());
}
