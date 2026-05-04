// Entry point. Initialises Firebase + dotenv, then mounts the app.
// AppState bootstrap (which opens the local sqflite DB and starts
// listeners) is deferred until after the user signs in — see
// AuthGate.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config.dart';
import 'firebase_options.dart';
import 'services/firestore/firestore_repo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirestoreRepo.initialize(
    DefaultFirebaseOptions.currentPlatform.projectId,
  );

  runApp(const AponAttendanceApp());
}
