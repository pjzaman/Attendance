enum HolidayType { public, optional, company }

extension HolidayTypeX on HolidayType {
  String get label {
    switch (this) {
      case HolidayType.public:
        return 'Public';
      case HolidayType.optional:
        return 'Optional';
      case HolidayType.company:
        return 'Company';
    }
  }

  static HolidayType fromName(String? s) {
    if (s == null) return HolidayType.public;
    return HolidayType.values.firstWhere(
      (t) => t.name == s,
      orElse: () => HolidayType.public,
    );
  }
}

/// A single holiday entry. Wired into [Schedule.worksOn] so duty-roster
/// cells correctly show "Holiday" on matching days when the schedule's
/// `includeHolidays` flag is off.
class Holiday {
  Holiday({
    required this.id,
    required this.name,
    required this.date,
    this.type = HolidayType.public,
    this.notes,
  });

  final String id;
  final String name;

  /// Calendar date (year-month-day; time ignored).
  final DateTime date;
  final HolidayType type;
  final String? notes;

  Holiday copyWith({
    String? name,
    DateTime? date,
    HolidayType? type,
    String? notes,
  }) =>
      Holiday(
        id: id,
        name: name ?? this.name,
        date: date ?? this.date,
        type: type ?? this.type,
        notes: notes ?? this.notes,
      );

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'date': _dateOnly(date),
        'type': type.name,
        'notes': notes,
      };

  factory Holiday.fromMap(Map<String, Object?> m) => Holiday(
        id: m['id']! as String,
        name: m['name']! as String,
        date: DateTime.parse(m['date']! as String),
        type: HolidayTypeX.fromName(m['type'] as String?),
        notes: m['notes'] as String?,
      );
}
