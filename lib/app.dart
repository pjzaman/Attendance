import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'shared/app_theme.dart';

class AponAttendanceApp extends StatelessWidget {
  const AponAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apon Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}
