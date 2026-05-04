/// Per-employee current salary record. v1 keeps the breakdown simple:
/// basic + total allowances + total deductions, with optional notes
/// for the line-by-line. The Payslip generator snapshots these
/// numbers at period close so subsequent salary edits don't rewrite
/// history.
class EmployeeSalary {
  EmployeeSalary({
    required this.userId,
    required this.basic,
    this.totalAllowances = 0,
    this.totalDeductions = 0,
    this.grade,
    this.structure,
    this.currency = 'BDT',
    this.notes,
    this.effectiveFrom,
    this.updatedAt,
  });

  /// Doubles as primary key — one current salary per employee.
  final String userId;

  final double basic;
  final double totalAllowances;
  final double totalDeductions;

  /// Pay grade label — free text until the Grades registry lands.
  final String? grade;

  /// Salary-structure label — free text until the Structures registry
  /// lands.
  final String? structure;

  final String currency;
  final String? notes;
  final DateTime? effectiveFrom;
  final DateTime? updatedAt;

  double get gross => basic + totalAllowances;
  double get netPayable => gross - totalDeductions;

  EmployeeSalary copyWith({
    double? basic,
    double? totalAllowances,
    double? totalDeductions,
    String? grade,
    String? structure,
    String? currency,
    String? notes,
    DateTime? effectiveFrom,
    DateTime? updatedAt,
  }) =>
      EmployeeSalary(
        userId: userId,
        basic: basic ?? this.basic,
        totalAllowances: totalAllowances ?? this.totalAllowances,
        totalDeductions: totalDeductions ?? this.totalDeductions,
        grade: grade ?? this.grade,
        structure: structure ?? this.structure,
        currency: currency ?? this.currency,
        notes: notes ?? this.notes,
        effectiveFrom: effectiveFrom ?? this.effectiveFrom,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toMap() => <String, Object?>{
        'user_id': userId,
        'basic': basic,
        'total_allowances': totalAllowances,
        'total_deductions': totalDeductions,
        'grade': grade,
        'structure': structure,
        'currency': currency,
        'notes': notes,
        'effective_from':
            effectiveFrom == null ? null : _dateOnly(effectiveFrom!),
        'updated_at': updatedAt?.toUtc().toIso8601String(),
      };

  factory EmployeeSalary.fromMap(Map<String, Object?> m) => EmployeeSalary(
        userId: m['user_id']! as String,
        basic: ((m['basic'] as num?) ?? 0).toDouble(),
        totalAllowances: ((m['total_allowances'] as num?) ?? 0).toDouble(),
        totalDeductions: ((m['total_deductions'] as num?) ?? 0).toDouble(),
        grade: m['grade'] as String?,
        structure: m['structure'] as String?,
        currency: (m['currency'] as String?) ?? 'BDT',
        notes: m['notes'] as String?,
        effectiveFrom: m['effective_from'] == null
            ? null
            : DateTime.parse(m['effective_from']! as String),
        updatedAt: m['updated_at'] == null
            ? null
            : DateTime.parse(m['updated_at']! as String).toLocal(),
      );

  factory EmployeeSalary.empty(String userId) =>
      EmployeeSalary(userId: userId, basic: 0);
}
