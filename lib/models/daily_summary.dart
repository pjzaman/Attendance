/// Derived once per (user_id, date) from the raw punch list. Mirrors the
/// shape of `Apon ERP/attendance-service/derive.py`'s output.
enum AttendanceStatus {
  present,
  late,
  halfDay,
  absent;

  String get wireValue {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.late:
        return 'late';
      case AttendanceStatus.halfDay:
        return 'halfDay';
      case AttendanceStatus.absent:
        return 'absent';
    }
  }

  static AttendanceStatus fromWire(String? s) {
    switch (s) {
      case 'late':
        return AttendanceStatus.late;
      case 'halfDay':
        return AttendanceStatus.halfDay;
      case 'absent':
        return AttendanceStatus.absent;
      default:
        return AttendanceStatus.present;
    }
  }
}

class DailySummary {
  DailySummary({
    required this.userId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.workedMinutes = 0,
    this.notes = '',
  });

  /// Device-side user_id (e.g. "EMP001"). Maps to `Employee.zktecoUserId`.
  final String userId;

  /// Calendar date (year/month/day; time fields are zero).
  final DateTime date;

  final DateTime? checkIn;
  final DateTime? checkOut;
  final int workedMinutes;
  final AttendanceStatus status;
  final String notes;

  Duration get worked => Duration(minutes: workedMinutes);

  Map<String, Object?> toMap() => <String, Object?>{
        'user_id': userId,
        'date': date.toIso8601String().substring(0, 10),
        'check_in': checkIn?.toIso8601String(),
        'check_out': checkOut?.toIso8601String(),
        'worked_minutes': workedMinutes,
        'status': status.wireValue,
        'notes': notes,
      };

  factory DailySummary.fromMap(Map<String, Object?> m) => DailySummary(
        userId: m['user_id']! as String,
        date: DateTime.parse(m['date']! as String),
        checkIn: m['check_in'] != null
            ? DateTime.parse(m['check_in']! as String).toLocal()
            : null,
        checkOut: m['check_out'] != null
            ? DateTime.parse(m['check_out']! as String).toLocal()
            : null,
        workedMinutes: (m['worked_minutes'] as int?) ?? 0,
        status: AttendanceStatus.fromWire(m['status'] as String?),
        notes: (m['notes'] as String?) ?? '',
      );
}
