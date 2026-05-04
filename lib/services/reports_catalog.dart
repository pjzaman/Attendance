import '../models/report_def.dart';

/// Hardcoded catalog of every report from the redesign doc §4.7.
/// `available` flags reflect whether the data plumbing exists for v1;
/// the rest render a "coming soon" state in the runner so the hub IA
/// stays faithful to the doc.
class ReportsCatalog {
  static List<ReportDef> all() => const <ReportDef>[
        // ── Employee ──────────────────────────────────────────────
        ReportDef(
          id: 'rpt_emp_all_summary',
          category: ReportCategory.employee,
          name: 'All Summary',
          description:
              'Workforce roster with completeness, designations, departments.',
          available: true,
        ),
        ReportDef(
          id: 'rpt_emp_individual_summary',
          category: ReportCategory.employee,
          name: 'Individual Summary',
          description: 'Per-employee deep-dive on profile + activity.',
        ),
        ReportDef(
          id: 'rpt_emp_asset',
          category: ReportCategory.employee,
          name: 'Asset Report',
          description: 'Assigned assets per employee.',
        ),
        // ── Attendance ────────────────────────────────────────────
        ReportDef(
          id: 'rpt_att_all_employees',
          category: ReportCategory.attendance,
          name: 'All Employees',
          description: 'Attendance status for every employee in the period.',
          available: true,
        ),
        ReportDef(
          id: 'rpt_att_late_early',
          category: ReportCategory.attendance,
          name: 'Late & Early',
          description: 'Late arrivals and early departures with grace deltas.',
        ),
        ReportDef(
          id: 'rpt_att_individual_employee',
          category: ReportCategory.attendance,
          name: 'Individual Employee',
          description: 'Per-employee daily attendance log.',
        ),
        ReportDef(
          id: 'rpt_att_individual_overtime',
          category: ReportCategory.attendance,
          name: 'Individual Overtime',
          description: 'Per-employee overtime hours by policy.',
        ),
        ReportDef(
          id: 'rpt_att_break_time',
          category: ReportCategory.attendance,
          name: 'Break Time Report',
          description: 'Break duration vs policy per employee.',
        ),
        ReportDef(
          id: 'rpt_att_activity_log',
          category: ReportCategory.attendance,
          name: 'Activity Log',
          description: 'Audit trail of all device punches.',
          available: true,
        ),
        ReportDef(
          id: 'rpt_att_daily_log',
          category: ReportCategory.attendance,
          name: 'Daily Log',
          description: 'Day-by-day attendance summaries.',
          available: true,
        ),
        ReportDef(
          id: 'rpt_att_summary',
          category: ReportCategory.attendance,
          name: 'Summary',
          description: 'High-level KPIs: present, absent, leave, OT.',
          available: true,
        ),
        ReportDef(
          id: 'rpt_att_live_tracking',
          category: ReportCategory.attendance,
          name: 'Live Tracking',
          description: 'GPS check-in feed (paid add-on placeholder).',
        ),
        ReportDef(
          id: 'rpt_att_devices_log',
          category: ReportCategory.attendance,
          name: 'Devices Log',
          description: 'Which device recorded each punch.',
        ),
        // ── Leave ─────────────────────────────────────────────────
        ReportDef(
          id: 'rpt_leave_request_status',
          category: ReportCategory.leave,
          name: 'Request Status',
          description: 'Pending / approved / rejected leave requests.',
          available: true,
        ),
        ReportDef(
          id: 'rpt_leave_balance',
          category: ReportCategory.leave,
          name: 'Balance',
          description: 'Org-wide leave balances per type per employee.',
          available: true,
        ),
        // ── Payroll ───────────────────────────────────────────────
        ReportDef(
          id: 'rpt_pay_salary_sheet',
          category: ReportCategory.payroll,
          name: 'Salary Sheet',
          description: 'Gross / earnings / deductions / net per pay period.',
        ),
        ReportDef(
          id: 'rpt_pay_summary',
          category: ReportCategory.payroll,
          name: 'Summary Report',
          description: 'Roll-up of payroll across pay periods.',
        ),
        ReportDef(
          id: 'rpt_pay_individual_summary',
          category: ReportCategory.payroll,
          name: 'Individual Summary',
          description: 'Per-employee payroll history.',
        ),
        ReportDef(
          id: 'rpt_pay_disbursement',
          category: ReportCategory.payroll,
          name: 'Disbursement Sheet',
          description: 'Bank-ready payment file for the pay period.',
        ),
      ];
}
