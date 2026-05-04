import 'package:flutter/material.dart';

import '../shared/app_theme.dart';

enum ReportCategory { employee, attendance, leave, payroll }

extension ReportCategoryX on ReportCategory {
  String get label {
    switch (this) {
      case ReportCategory.employee:
        return 'Employee';
      case ReportCategory.attendance:
        return 'Attendance';
      case ReportCategory.leave:
        return 'Leave';
      case ReportCategory.payroll:
        return 'Payroll';
    }
  }

  Color get color {
    switch (this) {
      case ReportCategory.employee:
        return AppColors.brandPrimary;
      case ReportCategory.attendance:
        return AppColors.statusSuccess;
      case ReportCategory.leave:
        return AppColors.statusWarning;
      case ReportCategory.payroll:
        return const Color(0xFF8B5CF6); // muted purple
    }
  }

  IconData get icon {
    switch (this) {
      case ReportCategory.employee:
        return Icons.people_outline;
      case ReportCategory.attendance:
        return Icons.event_available_outlined;
      case ReportCategory.leave:
        return Icons.beach_access_outlined;
      case ReportCategory.payroll:
        return Icons.payments_outlined;
    }
  }
}

/// Static metadata for a single report. The actual data-fetching +
/// rendering happens in [ReportRunnerScreen] — this is just the catalog
/// entry surfaced on the Reports hub.
class ReportDef {
  const ReportDef({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    this.available = false,
  });

  final String id;
  final ReportCategory category;
  final String name;
  final String description;

  /// `false` = listed in the hub but the runner shows a "coming soon"
  /// state. We surface unavailable reports so the IA matches the doc
  /// even before each one's data plumbing exists.
  final bool available;
}
