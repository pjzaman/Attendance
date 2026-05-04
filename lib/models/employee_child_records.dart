// The 7 child collections attached to an employee per the redesign
// doc §4.2 — Family Members / Educational Info / Trainings /
// Employment Histories / Disciplinary Actions / Achievements /
// Addresses. Each has its own lightweight model + DB table; the UI
// renders them all through a shared list + add-dialog pattern.

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? _parseDateOnly(Object? v) {
  if (v == null) return null;
  return DateTime.parse(v as String);
}

// ─── Family ─────────────────────────────────────────────────────────

class FamilyMember {
  FamilyMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    this.dateOfBirth,
    this.contactPhone,
    this.notes,
  });

  final String id;
  final String userId;
  final String name;
  final String relationship;
  final DateTime? dateOfBirth;
  final String? contactPhone;
  final String? notes;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'user_id': userId,
        'name': name,
        'relationship': relationship,
        'date_of_birth':
            dateOfBirth == null ? null : _dateOnly(dateOfBirth!),
        'contact_phone': contactPhone,
        'notes': notes,
      };

  factory FamilyMember.fromMap(Map<String, Object?> m) => FamilyMember(
        id: m['id']! as String,
        userId: m['user_id']! as String,
        name: m['name']! as String,
        relationship: m['relationship']! as String,
        dateOfBirth: _parseDateOnly(m['date_of_birth']),
        contactPhone: m['contact_phone'] as String?,
        notes: m['notes'] as String?,
      );
}

// ─── Education ──────────────────────────────────────────────────────

class EducationEntry {
  EducationEntry({
    required this.id,
    required this.userId,
    required this.degree,
    this.institution,
    this.fieldOfStudy,
    this.startYear,
    this.endYear,
    this.notes,
  });

  final String id;
  final String userId;
  final String degree;
  final String? institution;
  final String? fieldOfStudy;
  final int? startYear;
  final int? endYear;
  final String? notes;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'user_id': userId,
        'degree': degree,
        'institution': institution,
        'field_of_study': fieldOfStudy,
        'start_year': startYear,
        'end_year': endYear,
        'notes': notes,
      };

  factory EducationEntry.fromMap(Map<String, Object?> m) => EducationEntry(
        id: m['id']! as String,
        userId: m['user_id']! as String,
        degree: m['degree']! as String,
        institution: m['institution'] as String?,
        fieldOfStudy: m['field_of_study'] as String?,
        startYear: m['start_year'] as int?,
        endYear: m['end_year'] as int?,
        notes: m['notes'] as String?,
      );
}

// ─── Training ───────────────────────────────────────────────────────

class TrainingEntry {
  TrainingEntry({
    required this.id,
    required this.userId,
    required this.title,
    this.provider,
    this.completedDate,
    this.certificateNumber,
    this.notes,
  });

  final String id;
  final String userId;
  final String title;
  final String? provider;
  final DateTime? completedDate;
  final String? certificateNumber;
  final String? notes;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'user_id': userId,
        'title': title,
        'provider': provider,
        'completed_date':
            completedDate == null ? null : _dateOnly(completedDate!),
        'certificate_number': certificateNumber,
        'notes': notes,
      };

  factory TrainingEntry.fromMap(Map<String, Object?> m) => TrainingEntry(
        id: m['id']! as String,
        userId: m['user_id']! as String,
        title: m['title']! as String,
        provider: m['provider'] as String?,
        completedDate: _parseDateOnly(m['completed_date']),
        certificateNumber: m['certificate_number'] as String?,
        notes: m['notes'] as String?,
      );
}

// ─── Employment History ─────────────────────────────────────────────

class EmploymentHistoryEntry {
  EmploymentHistoryEntry({
    required this.id,
    required this.userId,
    required this.employer,
    required this.position,
    this.startDate,
    this.endDate,
    this.reasonForLeaving,
    this.notes,
  });

  final String id;
  final String userId;
  final String employer;
  final String position;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? reasonForLeaving;
  final String? notes;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'user_id': userId,
        'employer': employer,
        'position': position,
        'start_date': startDate == null ? null : _dateOnly(startDate!),
        'end_date': endDate == null ? null : _dateOnly(endDate!),
        'reason_for_leaving': reasonForLeaving,
        'notes': notes,
      };

  factory EmploymentHistoryEntry.fromMap(Map<String, Object?> m) =>
      EmploymentHistoryEntry(
        id: m['id']! as String,
        userId: m['user_id']! as String,
        employer: m['employer']! as String,
        position: m['position']! as String,
        startDate: _parseDateOnly(m['start_date']),
        endDate: _parseDateOnly(m['end_date']),
        reasonForLeaving: m['reason_for_leaving'] as String?,
        notes: m['notes'] as String?,
      );
}

// ─── Disciplinary Action ────────────────────────────────────────────

class DisciplinaryAction {
  DisciplinaryAction({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.description,
    this.action,
    this.notes,
  });

  final String id;
  final String userId;
  final DateTime date;

  /// Free text — `Verbal warning`, `Written warning`, `Suspension`, etc.
  final String type;
  final String description;
  final String? action;
  final String? notes;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'user_id': userId,
        'date': _dateOnly(date),
        'type': type,
        'description': description,
        'action': action,
        'notes': notes,
      };

  factory DisciplinaryAction.fromMap(Map<String, Object?> m) =>
      DisciplinaryAction(
        id: m['id']! as String,
        userId: m['user_id']! as String,
        date: DateTime.parse(m['date']! as String),
        type: m['type']! as String,
        description: m['description']! as String,
        action: m['action'] as String?,
        notes: m['notes'] as String?,
      );
}

// ─── Achievement ────────────────────────────────────────────────────

class Achievement {
  Achievement({
    required this.id,
    required this.userId,
    required this.title,
    this.date,
    this.description,
    this.notes,
  });

  final String id;
  final String userId;
  final String title;
  final DateTime? date;
  final String? description;
  final String? notes;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'user_id': userId,
        'title': title,
        'date': date == null ? null : _dateOnly(date!),
        'description': description,
        'notes': notes,
      };

  factory Achievement.fromMap(Map<String, Object?> m) => Achievement(
        id: m['id']! as String,
        userId: m['user_id']! as String,
        title: m['title']! as String,
        date: _parseDateOnly(m['date']),
        description: m['description'] as String?,
        notes: m['notes'] as String?,
      );
}

// ─── Address ────────────────────────────────────────────────────────

enum EmployeeAddressType { home, permanent, mailing, emergency, other }

extension EmployeeAddressTypeX on EmployeeAddressType {
  String get label {
    switch (this) {
      case EmployeeAddressType.home:
        return 'Home';
      case EmployeeAddressType.permanent:
        return 'Permanent';
      case EmployeeAddressType.mailing:
        return 'Mailing';
      case EmployeeAddressType.emergency:
        return 'Emergency';
      case EmployeeAddressType.other:
        return 'Other';
    }
  }

  static EmployeeAddressType fromName(String? s) {
    if (s == null) return EmployeeAddressType.other;
    return EmployeeAddressType.values.firstWhere(
      (t) => t.name == s,
      orElse: () => EmployeeAddressType.other,
    );
  }
}

class EmployeeAddress {
  EmployeeAddress({
    required this.id,
    required this.userId,
    required this.type,
    required this.addressLine,
    this.city,
    this.country,
    this.isPrimary = false,
    this.notes,
  });

  final String id;
  final String userId;
  final EmployeeAddressType type;
  final String addressLine;
  final String? city;
  final String? country;
  final bool isPrimary;
  final String? notes;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'user_id': userId,
        'type': type.name,
        'address_line': addressLine,
        'city': city,
        'country': country,
        'is_primary': isPrimary ? 1 : 0,
        'notes': notes,
      };

  factory EmployeeAddress.fromMap(Map<String, Object?> m) => EmployeeAddress(
        id: m['id']! as String,
        userId: m['user_id']! as String,
        type: EmployeeAddressTypeX.fromName(m['type'] as String?),
        addressLine: m['address_line']! as String,
        city: m['city'] as String?,
        country: m['country'] as String?,
        isPrimary: ((m['is_primary'] as int?) ?? 0) == 1,
        notes: m['notes'] as String?,
      );
}
