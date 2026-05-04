/// Audit row for every salary change. Written automatically whenever
/// AppState.upsertEmployeeSalary fires — gives HR a "what did we pay
/// this person and when did it change" trail without needing to crawl
/// past payslips.
class SalaryHistoryEntry {
  SalaryHistoryEntry({
    required this.id,
    required this.userId,
    required this.changedAt,
    required this.basic,
    required this.totalAllowances,
    required this.totalDeductions,
    this.grade,
    this.structure,
    this.currency = 'BDT',
    this.notes,
    this.changedBy,
  });

  final String id;
  final String userId;
  final DateTime changedAt;

  // Snapshot of the salary at the time of the change.
  final double basic;
  final double totalAllowances;
  final double totalDeductions;
  final String? grade;
  final String? structure;
  final String currency;
  final String? notes;

  /// `AppUser.id` of whoever saved the change. `null` until auth lands.
  final String? changedBy;

  double get gross => basic + totalAllowances;
  double get netPayable => gross - totalDeductions;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'user_id': userId,
        'changed_at': changedAt.toUtc().toIso8601String(),
        'basic': basic,
        'total_allowances': totalAllowances,
        'total_deductions': totalDeductions,
        'grade': grade,
        'structure': structure,
        'currency': currency,
        'notes': notes,
        'changed_by': changedBy,
      };

  factory SalaryHistoryEntry.fromMap(Map<String, Object?> m) =>
      SalaryHistoryEntry(
        id: m['id']! as String,
        userId: m['user_id']! as String,
        changedAt: DateTime.parse(m['changed_at']! as String).toLocal(),
        basic: ((m['basic'] as num?) ?? 0).toDouble(),
        totalAllowances: ((m['total_allowances'] as num?) ?? 0).toDouble(),
        totalDeductions: ((m['total_deductions'] as num?) ?? 0).toDouble(),
        grade: m['grade'] as String?,
        structure: m['structure'] as String?,
        currency: (m['currency'] as String?) ?? 'BDT',
        notes: m['notes'] as String?,
        changedBy: m['changed_by'] as String?,
      );
}
