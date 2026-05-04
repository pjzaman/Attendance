import '../models/tracking_method.dart';

/// Seed a default tracking method on first launch — Device-only since
/// that's what AppConfig already supports. The Settings → Tracking
/// Methods tab lets HR enable Mobile App / Web channels per location.
class TrackingMethodSeed {
  static List<TrackingMethod> defaults() {
    final now = DateTime.now();
    return <TrackingMethod>[
      TrackingMethod(
        id: 'tm_default',
        name: 'Default — Device only',
        effectiveDate: DateTime(now.year, 1, 1),
        allowDevice: true,
      ),
    ];
  }
}
