import '../models/office_location.dart';

/// Seed a single placeholder location on first launch so other surfaces
/// (Devices, future Employee filters) have something to reference.
class OfficeLocationSeed {
  static List<OfficeLocation> defaults() => <OfficeLocation>[
        OfficeLocation(
          id: 'loc_hq',
          name: 'Head Office',
          shortName: 'HQ',
        ),
      ];
}
