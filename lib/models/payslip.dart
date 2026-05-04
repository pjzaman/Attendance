enum PayslipStatus { draft, processed, disbursed }

extension PayslipStatusX on PayslipStatus {
  String get label {
    switch (this) {
      case PayslipStatus.draft:
        return 'Draft';
      case PayslipStatus.processed:
        return 'Processed';
      case PayslipStatus.disbursed:
        return 'Disbursed';
    }
  }

  static PayslipStatus fromName(String? s) {
    if (s == null) return PayslipStatus.draft;
    return PayslipStatus.values.firstWhere(
      (st) => st.name == s,
      orElse: () => PayslipStatus.draft,
    );
  }
}

/// One pay-period payslip per employee. Snapshots the basic /
/// allowances / deductions at issue time so subsequent salary edits
/// don't change history.
class Payslip {
  Payslip({
    required this.id,
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.basic,
    required this.totalAllowances,
    required this.totalDeductions,
    required this.status,
    required this.createdAt,
    this.currency = 'BDT',
    this.notes,
    this.processedAt,
    this.disbursedAt,
    this.workingDays = 0,
    this.presentDays = 0,
    this.absentDays = 0,
    this.lateDays = 0,
    this.leaveDays = 0,
    this.attendanceDeduction = 0,
  });

  final String id;
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double basic;
  final double totalAllowances;

  /// Static deductions snapshotted from the salary record (tax, fixed
  /// allowances reversal, etc.). Attendance-driven deduction is
  /// tracked separately as [attendanceDeduction].
  final double totalDeductions;
  final String currency;
  final String? notes;
  final PayslipStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? disbursedAt;

  // ─── Attendance breakdown ──────────────────────────────────────
  /// Scheduled working days within the period.
  final int workingDays;

  /// Days the employee actually checked in.
  final int presentDays;

  /// `workingDays - presentDays - leaveDays`, clamped to >= 0.
  final int absentDays;

  /// Days marked late (subset of presentDays).
  final int lateDays;

  /// Approved leave days within the period.
  final int leaveDays;

  /// Computed at generate time: per-day basic × unaccounted-absent
  /// days. Stored as a snapshot so subsequent attendance edits don't
  /// rewrite issued payslips.
  final double attendanceDeduction;

  double get gross => basic + totalAllowances;
  double get netPayable => gross - totalDeductions - attendanceDeduction;

  Payslip copyWith({
    DateTime? periodStart,
    DateTime? periodEnd,
    double? basic,
    double? totalAllowances,
    double? totalDeductions,
    String? currency,
    String? notes,
    PayslipStatus? status,
    DateTime? processedAt,
    DateTime? disbursedAt,
    int? workingDays,
    int? presentDays,
    int? absentDays,
    int? lateDays,
    int? leaveDays,
    double? attendanceDeduction,
  }) =>
      Payslip(
        id: id,
        userId: userId,
        periodStart: periodStart ?? this.periodStart,
        periodEnd: periodEnd ?? this.periodEnd,
        basic: basic ?? this.basic,
        totalAllowances: totalAllowances ?? this.totalAllowances,
        totalDeductions: totalDeductions ?? this.totalDeductions,
        currency: currency ?? this.currency,
        notes: notes ?? this.notes,
        status: status ?? this.status,
        createdAt: createdAt,
        processedAt: processedAt ?? this.processedAt,
        disbursedAt: disbursedAt ?? this.disbursedAt,
        workingDays: workingDays ?? this.workingDays,
        presentDays: presentDays ?? this.presentDays,
        absentDays: absentDays ?? this.absentDays,
        lateDays: lateDays ?? this.lateDays,
        leaveDays: leaveDays ?? this.leaveDays,
        attendanceDeduction:
            attendanceDeduction ?? this.attendanceDeduction,
      );

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'user_id': userId,
        'period_start': _dateOnly(periodStart),
        'period_end': _dateOnly(periodEnd),
        'basic': basic,
        'total_allowances': totalAllowances,
        'total_deductions': totalDeductions,
        'currency': currency,
        'notes': notes,
        'status': status.name,
        'created_at': createdAt.toUtc().toIso8601String(),
        'processed_at': processedAt?.toUtc().toIso8601String(),
        'disbursed_at': disbursedAt?.toUtc().toIso8601String(),
        'working_days': workingDays,
        'present_days': presentDays,
        'absent_days': absentDays,
        'late_days': lateDays,
        'leave_days': leaveDays,
        'attendance_deduction': attendanceDeduction,
      };

  factory Payslip.fromMap(Map<String, Object?> m) => Payslip(
        id: m['id']! as String,
        userId: m['user_id']! as String,
        periodStart: DateTime.parse(m['period_start']! as String),
        periodEnd: DateTime.parse(m['period_end']! as String),
        basic: ((m['basic'] as num?) ?? 0).toDouble(),
        totalAllowances: ((m['total_allowances'] as num?) ?? 0).toDouble(),
        totalDeductions: ((m['total_deductions'] as num?) ?? 0).toDouble(),
        currency: (m['currency'] as String?) ?? 'BDT',
        notes: m['notes'] as String?,
        status: PayslipStatusX.fromName(m['status'] as String?),
        createdAt: DateTime.parse(m['created_at']! as String).toLocal(),
        processedAt: m['processed_at'] == null
            ? null
            : DateTime.parse(m['processed_at']! as String).toLocal(),
        disbursedAt: m['disbursed_at'] == null
            ? null
            : DateTime.parse(m['disbursed_at']! as String).toLocal(),
        workingDays: (m['working_days'] as int?) ?? 0,
        presentDays: (m['present_days'] as int?) ?? 0,
        absentDays: (m['absent_days'] as int?) ?? 0,
        lateDays: (m['late_days'] as int?) ?? 0,
        leaveDays: (m['leave_days'] as int?) ?? 0,
        attendanceDeduction:
            ((m['attendance_deduction'] as num?) ?? 0).toDouble(),
      );
}
