/// Per the doc §3.8: "A single 'Tracking Method' record can include
/// Mobile App, Web, Attendance Device — the user is told how they can
/// clock in, all in one place." Assigned per [OfficeLocation] with an
/// effective date.
class TrackingMethod {
  TrackingMethod({
    required this.id,
    required this.name,
    required this.effectiveDate,
    this.officeLocationId,
    this.allowMobileApp = false,
    this.allowWeb = false,
    this.allowDevice = true,
    this.isActive = true,
    this.notes,
  });

  final String id;
  final String name;

  /// `OfficeLocation.id` this method applies to. `null` = applies
  /// org-wide as a fallback when no location-specific record matches.
  final String? officeLocationId;

  /// First date this method is in effect. Earlier dates fall through
  /// to whichever method covers them.
  final DateTime effectiveDate;

  final bool allowMobileApp;
  final bool allowWeb;
  final bool allowDevice;

  final bool isActive;
  final String? notes;

  /// Number of channels enabled. Useful for the row summary line.
  int get enabledChannelCount =>
      (allowMobileApp ? 1 : 0) + (allowWeb ? 1 : 0) + (allowDevice ? 1 : 0);

  TrackingMethod copyWith({
    String? name,
    String? officeLocationId,
    bool clearOfficeLocation = false,
    DateTime? effectiveDate,
    bool? allowMobileApp,
    bool? allowWeb,
    bool? allowDevice,
    bool? isActive,
    String? notes,
  }) =>
      TrackingMethod(
        id: id,
        name: name ?? this.name,
        officeLocationId: clearOfficeLocation
            ? null
            : (officeLocationId ?? this.officeLocationId),
        effectiveDate: effectiveDate ?? this.effectiveDate,
        allowMobileApp: allowMobileApp ?? this.allowMobileApp,
        allowWeb: allowWeb ?? this.allowWeb,
        allowDevice: allowDevice ?? this.allowDevice,
        isActive: isActive ?? this.isActive,
        notes: notes ?? this.notes,
      );

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'office_location_id': officeLocationId,
        'effective_date': _dateOnly(effectiveDate),
        'allow_mobile_app': allowMobileApp ? 1 : 0,
        'allow_web': allowWeb ? 1 : 0,
        'allow_device': allowDevice ? 1 : 0,
        'is_active': isActive ? 1 : 0,
        'notes': notes,
      };

  factory TrackingMethod.fromMap(Map<String, Object?> m) => TrackingMethod(
        id: m['id']! as String,
        name: m['name']! as String,
        officeLocationId: m['office_location_id'] as String?,
        effectiveDate: DateTime.parse(m['effective_date']! as String),
        allowMobileApp: ((m['allow_mobile_app'] as int?) ?? 0) == 1,
        allowWeb: ((m['allow_web'] as int?) ?? 0) == 1,
        allowDevice: ((m['allow_device'] as int?) ?? 0) == 1,
        isActive: ((m['is_active'] as int?) ?? 1) == 1,
        notes: m['notes'] as String?,
      );
}
