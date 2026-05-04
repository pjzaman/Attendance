enum Gender { male, female, other }

extension GenderX on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  static Gender? fromName(String? s) {
    if (s == null) return null;
    return Gender.values.firstWhere(
      (g) => g.name == s,
      orElse: () => Gender.other,
    );
  }
}

enum EmploymentType { permanent, contract, intern, casual }

extension EmploymentTypeX on EmploymentType {
  String get label {
    switch (this) {
      case EmploymentType.permanent:
        return 'Permanent';
      case EmploymentType.contract:
        return 'Contract';
      case EmploymentType.intern:
        return 'Intern';
      case EmploymentType.casual:
        return 'Casual';
    }
  }

  static EmploymentType? fromName(String? s) {
    if (s == null) return null;
    return EmploymentType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => EmploymentType.permanent,
    );
  }
}

enum MaritalStatus { single, married, divorced, widowed, other }

extension MaritalStatusX on MaritalStatus {
  String get label {
    switch (this) {
      case MaritalStatus.single:
        return 'Single';
      case MaritalStatus.married:
        return 'Married';
      case MaritalStatus.divorced:
        return 'Divorced';
      case MaritalStatus.widowed:
        return 'Widowed';
      case MaritalStatus.other:
        return 'Other';
    }
  }

  static MaritalStatus? fromName(String? s) {
    if (s == null) return null;
    return MaritalStatus.values.firstWhere(
      (m) => m.name == s,
      orElse: () => MaritalStatus.other,
    );
  }
}

/// Extended HR profile for an employee. Stored separately from the
/// device-synced [Employee] (which is just userId/name/privilege) since
/// these fields are HR-managed locally and not part of the device data.
class EmployeeProfile {
  EmployeeProfile({
    required this.userId,
    // Personal
    this.firstName,
    this.lastName,
    this.displayName,
    this.gender,
    this.dateOfBirth,
    this.phone,
    this.email,
    this.maritalStatus,
    this.nationality,
    this.address,
    // Employment
    this.joiningDate,
    this.employmentType,
    this.division,
    this.department,
    this.grade,
    this.designation,
    this.groupLabel,
    this.team,
    this.employmentRole,
    this.lineManagerUserId,
    this.scheduleId,
    this.officeLocationId,
    // Bank
    this.bankName,
    this.bankBranch,
    this.bankAccountNo,
    this.bankRouting,
    this.bankSwift,
    this.updatedAt,
  });

  final String userId;

  // ─── Personal ─────────────────────────────────────────────────
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String? phone;
  final String? email;
  final MaritalStatus? maritalStatus;
  final String? nationality;
  final String? address;

  // ─── Employment ───────────────────────────────────────────────
  final DateTime? joiningDate;
  final EmploymentType? employmentType;
  final String? division;
  final String? department;
  final String? grade;
  final String? designation;
  final String? groupLabel;
  final String? team;
  final String? employmentRole;
  final String? lineManagerUserId;
  final String? scheduleId;

  /// `OfficeLocation.id` — the workspace this employee usually punches
  /// in at. Free-text employee `address` is separate (it's the home
  /// address).
  final String? officeLocationId;

  // ─── Bank ─────────────────────────────────────────────────────
  final String? bankName;
  final String? bankBranch;
  final String? bankAccountNo;
  final String? bankRouting;
  final String? bankSwift;

  final DateTime? updatedAt;

  /// Fields that count toward the Profile Completeness meter. Chosen
  /// to match the doc's "drives data quality" intent — basics first,
  /// banking + employment last.
  static const List<String> completenessFieldKeys = <String>[
    'firstName',
    'lastName',
    'gender',
    'dateOfBirth',
    'phone',
    'email',
    'address',
    'joiningDate',
    'employmentType',
    'designation',
    'department',
    'bankName',
    'bankAccountNo',
  ];

  /// Returns 0.0 – 1.0.
  double get completeness {
    final filled = _completenessFilledCount();
    return filled / completenessFieldKeys.length;
  }

  int _completenessFilledCount() {
    final values = <String, Object?>{
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'phone': phone,
      'email': email,
      'address': address,
      'joiningDate': joiningDate,
      'employmentType': employmentType,
      'designation': designation,
      'department': department,
      'bankName': bankName,
      'bankAccountNo': bankAccountNo,
    };
    int n = 0;
    for (final k in completenessFieldKeys) {
      final v = values[k];
      if (v == null) continue;
      if (v is String && v.trim().isEmpty) continue;
      n++;
    }
    return n;
  }

  EmployeeProfile copyWith({
    String? firstName,
    String? lastName,
    String? displayName,
    Gender? gender,
    DateTime? dateOfBirth,
    String? phone,
    String? email,
    MaritalStatus? maritalStatus,
    String? nationality,
    String? address,
    DateTime? joiningDate,
    EmploymentType? employmentType,
    String? division,
    String? department,
    String? grade,
    String? designation,
    String? groupLabel,
    String? team,
    String? employmentRole,
    String? lineManagerUserId,
    String? scheduleId,
    String? officeLocationId,
    String? bankName,
    String? bankBranch,
    String? bankAccountNo,
    String? bankRouting,
    String? bankSwift,
    DateTime? updatedAt,
  }) =>
      EmployeeProfile(
        userId: userId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        displayName: displayName ?? this.displayName,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        nationality: nationality ?? this.nationality,
        address: address ?? this.address,
        joiningDate: joiningDate ?? this.joiningDate,
        employmentType: employmentType ?? this.employmentType,
        division: division ?? this.division,
        department: department ?? this.department,
        grade: grade ?? this.grade,
        designation: designation ?? this.designation,
        groupLabel: groupLabel ?? this.groupLabel,
        team: team ?? this.team,
        employmentRole: employmentRole ?? this.employmentRole,
        lineManagerUserId: lineManagerUserId ?? this.lineManagerUserId,
        scheduleId: scheduleId ?? this.scheduleId,
        officeLocationId: officeLocationId ?? this.officeLocationId,
        bankName: bankName ?? this.bankName,
        bankBranch: bankBranch ?? this.bankBranch,
        bankAccountNo: bankAccountNo ?? this.bankAccountNo,
        bankRouting: bankRouting ?? this.bankRouting,
        bankSwift: bankSwift ?? this.bankSwift,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toMap() => <String, Object?>{
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'display_name': displayName,
        'gender': gender?.name,
        'date_of_birth':
            dateOfBirth == null ? null : _dateOnly(dateOfBirth!),
        'phone': phone,
        'email': email,
        'marital_status': maritalStatus?.name,
        'nationality': nationality,
        'address': address,
        'joining_date':
            joiningDate == null ? null : _dateOnly(joiningDate!),
        'employment_type': employmentType?.name,
        'division': division,
        'department': department,
        'grade': grade,
        'designation': designation,
        'group_label': groupLabel,
        'team': team,
        'employment_role': employmentRole,
        'line_manager_user_id': lineManagerUserId,
        'schedule_id': scheduleId,
        'office_location_id': officeLocationId,
        'bank_name': bankName,
        'bank_branch': bankBranch,
        'bank_account_no': bankAccountNo,
        'bank_routing': bankRouting,
        'bank_swift': bankSwift,
        'updated_at': updatedAt?.toUtc().toIso8601String(),
      };

  factory EmployeeProfile.fromMap(Map<String, Object?> m) => EmployeeProfile(
        userId: m['user_id']! as String,
        firstName: m['first_name'] as String?,
        lastName: m['last_name'] as String?,
        displayName: m['display_name'] as String?,
        gender: GenderX.fromName(m['gender'] as String?),
        dateOfBirth: m['date_of_birth'] == null
            ? null
            : DateTime.parse(m['date_of_birth']! as String),
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        maritalStatus:
            MaritalStatusX.fromName(m['marital_status'] as String?),
        nationality: m['nationality'] as String?,
        address: m['address'] as String?,
        joiningDate: m['joining_date'] == null
            ? null
            : DateTime.parse(m['joining_date']! as String),
        employmentType:
            EmploymentTypeX.fromName(m['employment_type'] as String?),
        division: m['division'] as String?,
        department: m['department'] as String?,
        grade: m['grade'] as String?,
        designation: m['designation'] as String?,
        groupLabel: m['group_label'] as String?,
        team: m['team'] as String?,
        employmentRole: m['employment_role'] as String?,
        lineManagerUserId: m['line_manager_user_id'] as String?,
        scheduleId: m['schedule_id'] as String?,
        officeLocationId: m['office_location_id'] as String?,
        bankName: m['bank_name'] as String?,
        bankBranch: m['bank_branch'] as String?,
        bankAccountNo: m['bank_account_no'] as String?,
        bankRouting: m['bank_routing'] as String?,
        bankSwift: m['bank_swift'] as String?,
        updatedAt: m['updated_at'] == null
            ? null
            : DateTime.parse(m['updated_at']! as String).toLocal(),
      );

  /// Returns an empty profile for a new employee.
  factory EmployeeProfile.empty(String userId) =>
      EmployeeProfile(userId: userId);
}
