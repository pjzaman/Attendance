import '../config.dart';
import '../models/device.dart';

/// Seed the registry with the existing single-device connection from
/// [AppConfig] on first launch. The actual sync still goes through
/// AppConfig today; this just surfaces the connection in the Devices
/// page so it's no longer hidden behind .env.
class DeviceSeed {
  static Device defaultDevice() {
    final c = AppConfig.instance;
    return Device(
      id: 'dev_primary',
      name: 'Primary device',
      brand: 'ZKTeco',
      model: 'UFACE-800',
      ipAddress: c.deviceIp,
      port: c.devicePort,
      commKey: c.commKey,
      connectTimeoutMs: c.connectTimeoutMs,
      recvTimeoutMs: c.recvTimeoutMs,
    );
  }
}
