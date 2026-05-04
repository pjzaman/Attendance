enum SessionType { leave, payroll }

extension SessionTypeX on SessionType {
  String get label {
    switch (this) {
      case SessionType.leave:
        return 'Leave';
      case SessionType.payroll:
        return 'Payroll';
    }
  }

  static SessionType fromName(String? s) {
    if (s == null) return SessionType.leave;
    return SessionType.values.firstWhere(
      (t) => t.name == s,
      orElse: () => SessionType.leave,
    );
  }
}

/// A configurable period for leave / payroll. Per the doc §4.4: "Session
/// selector in the corner — leave year / period." Multiple sessions may
/// exist per type, but only one per type is `isActive` at a time.
class Session {
  Session({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.isActive = false,
  });

  final String id;
  final String name;
  final SessionType type;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  Session copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) =>
      Session(
        id: id,
        name: name ?? this.name,
        type: type,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        isActive: isActive ?? this.isActive,
      );

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'type': type.name,
        'start_date': _dateOnly(startDate),
        'end_date': _dateOnly(endDate),
        'is_active': isActive ? 1 : 0,
      };

  factory Session.fromMap(Map<String, Object?> m) => Session(
        id: m['id']! as String,
        name: m['name']! as String,
        type: SessionTypeX.fromName(m['type'] as String?),
        startDate: DateTime.parse(m['start_date']! as String),
        endDate: DateTime.parse(m['end_date']! as String),
        isActive: ((m['is_active'] as int?) ?? 0) == 1,
      );
}
