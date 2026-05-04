import '../models/session.dart';

/// Default sessions seeded on first launch — a calendar-year leave
/// session and a calendar-year payroll session, both based on the
/// current year. Replaces the implicit "DateTime.now().year" the
/// leave module previously hardcoded.
class SessionSeed {
  static List<Session> defaults() {
    final year = DateTime.now().year;
    return <Session>[
      Session(
        id: 'sess_leave_$year',
        name: 'Calendar Year $year',
        type: SessionType.leave,
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31),
        isActive: true,
      ),
      Session(
        id: 'sess_payroll_$year',
        name: 'Calendar Year $year',
        type: SessionType.payroll,
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31),
        isActive: true,
      ),
    ];
  }
}
