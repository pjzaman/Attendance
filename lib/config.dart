// Centralised config — defaults are baked in, .env overrides at runtime.

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._({
    required this.deviceIp,
    required this.devicePort,
    required this.commKey,
    required this.deviceId,
    required this.connectTimeoutMs,
    required this.recvTimeoutMs,
    required this.lateThreshold,
    required this.halfDayHours,
    required this.standardShiftHours,
  });

  final String deviceIp;
  final int devicePort;
  final int commKey;
  final int deviceId;
  final int connectTimeoutMs;
  final int recvTimeoutMs;

  /// Format "HH:mm". Punches after this on a given day mark it `late`.
  final String lateThreshold;

  /// Worked hours below this → `halfDay`.
  final double halfDayHours;

  /// Standard daily shift in hours (used for OT calculation in the future).
  final double standardShiftHours;

  static late AppConfig _instance;
  static AppConfig get instance => _instance;

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env missing is fine — we have defaults.
    }
    _instance = AppConfig._(
      deviceIp: _str('ZK_DEVICE_IP', '192.168.0.150'),
      devicePort: _int('ZK_DEVICE_PORT', 4370),
      commKey: _int('ZK_COMM_KEY', 0),
      deviceId: _int('ZK_DEVICE_ID', 1),
      connectTimeoutMs: _int('ZK_CONNECT_TIMEOUT_MS', 5000),
      recvTimeoutMs: _int('ZK_RECV_TIMEOUT_MS', 10000),
      lateThreshold: _str('LATE_THRESHOLD', '09:30'),
      halfDayHours: _double('HALF_DAY_HOURS', 4),
      standardShiftHours: _double('STANDARD_SHIFT_HOURS', 8),
    );
  }

  static String _str(String k, String d) => dotenv.env[k]?.trim().isNotEmpty ?? false
      ? dotenv.env[k]!.trim()
      : d;
  static int _int(String k, int d) => int.tryParse(_str(k, '$d')) ?? d;
  static double _double(String k, double d) =>
      double.tryParse(_str(k, '$d')) ?? d;
}
