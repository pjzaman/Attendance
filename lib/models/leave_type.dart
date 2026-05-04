enum LeaveGenderConstraint { any, femaleOnly, maleOnly }

extension LeaveGenderConstraintX on LeaveGenderConstraint {
  String get label {
    switch (this) {
      case LeaveGenderConstraint.any:
        return 'Any';
      case LeaveGenderConstraint.femaleOnly:
        return 'Female only';
      case LeaveGenderConstraint.maleOnly:
        return 'Male only';
    }
  }
}

/// One row in the Labour Law leave catalog. Toggleable, gender-aware,
/// editable per the redesign doc §4.10. Replaces the hardcoded leave
/// type list previously embedded in the request editor.
class LeaveType {
  const LeaveType({
    required this.id,
    required this.name,
    required this.code,
    this.defaultDaysPerYear = 0,
    this.genderConstraint = LeaveGenderConstraint.any,
    this.isPaid = true,
    this.isActive = true,
  });

  final String id;
  final String name;

  /// Short code shown in compact lists (`AL`, `SL`).
  final String code;

  /// Default annual entitlement in days. `0` = no preset cap (e.g.
  /// Unpaid).
  final int defaultDaysPerYear;
  final LeaveGenderConstraint genderConstraint;
  final bool isPaid;
  final bool isActive;

  LeaveType copyWith({
    String? name,
    String? code,
    int? defaultDaysPerYear,
    LeaveGenderConstraint? genderConstraint,
    bool? isPaid,
    bool? isActive,
  }) =>
      LeaveType(
        id: id,
        name: name ?? this.name,
        code: code ?? this.code,
        defaultDaysPerYear: defaultDaysPerYear ?? this.defaultDaysPerYear,
        genderConstraint: genderConstraint ?? this.genderConstraint,
        isPaid: isPaid ?? this.isPaid,
        isActive: isActive ?? this.isActive,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'code': code,
        'default_days': defaultDaysPerYear,
        'gender_constraint': genderConstraint.name,
        'is_paid': isPaid ? 1 : 0,
        'is_active': isActive ? 1 : 0,
      };

  factory LeaveType.fromMap(Map<String, Object?> m) => LeaveType(
        id: m['id']! as String,
        name: m['name']! as String,
        code: m['code']! as String,
        defaultDaysPerYear: (m['default_days'] as int?) ?? 0,
        genderConstraint: LeaveGenderConstraint.values.firstWhere(
          (g) => g.name == m['gender_constraint'],
          orElse: () => LeaveGenderConstraint.any,
        ),
        isPaid: ((m['is_paid'] as int?) ?? 1) == 1,
        isActive: ((m['is_active'] as int?) ?? 1) == 1,
      );
}
