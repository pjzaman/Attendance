import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../models/employee_salary.dart';
import '../models/payslip.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/app_data_table.dart';
import '../widgets/detail_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_row.dart';
import '../widgets/kpi_card.dart';
import '../widgets/status_pill.dart';
import 'employee_salary_editor_drawer.dart';
import 'payslip_editor_drawer.dart';

/// Payroll → Salary screen with three inner tabs per the doc §4.8:
/// Employee Salaries / Payslips / Salary Info.
class PayrollSalaryScreen extends StatefulWidget {
  const PayrollSalaryScreen({super.key});

  @override
  State<PayrollSalaryScreen> createState() => _PayrollSalaryScreenState();
}

class _PayrollSalaryScreenState extends State<PayrollSalaryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.employees.isEmpty) {
      return const EmptyState(
        icon: Icons.payments_outlined,
        title: 'No employees yet',
        message:
            'Salary records need employees first. Run a sync to pull them.',
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const <Tab>[
              Tab(text: 'Employee Salaries'),
              Tab(text: 'Payslips'),
              Tab(text: 'Salary Info'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const <Widget>[
                _SalariesTab(),
                _PayslipsTab(),
                _SalaryInfoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Salaries tab ────────────────────────────────────────────────────

class _SalariesTab extends StatefulWidget {
  const _SalariesTab();
  @override
  State<_SalariesTab> createState() => _SalariesTabState();
}

class _SalariesTabState extends State<_SalariesTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fmt = NumberFormat('#,##0.00');
    final q = _query.toLowerCase();
    final employees = q.isEmpty
        ? state.employees
        : state.employees
            .where((e) =>
                e.name.toLowerCase().contains(q) ||
                e.userId.toLowerCase().contains(q))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilterRow(
          searchController: _searchCtrl,
          onSearchChanged: (v) => setState(() => _query = v.trim()),
          searchHint: 'Search by name or user id…',
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: AppDataTable<Employee>(
            rows: employees,
            initialSortColumnId: 'name',
            initialSortAscending: true,
            emptyState: const EmptyState(
              icon: Icons.search_off,
              title: 'No employees match',
            ),
            columns: <DataColumnDef<Employee>>[
              DataColumnDef(
                id: 'user_id',
                label: 'User ID',
                sortKey: (e) => e.userId,
                cell: (_, e) => Text(e.userId),
                width: 110,
              ),
              DataColumnDef(
                id: 'name',
                label: 'Name',
                sortKey: (e) => e.name,
                cell: (_, e) => Text(e.name.isEmpty ? '—' : e.name),
              ),
              DataColumnDef(
                id: 'grade',
                label: 'Grade',
                sortKey: (e) => state.salaryFor(e.userId).grade ?? '',
                cell: (_, e) =>
                    Text(state.salaryFor(e.userId).grade ?? '—'),
                width: 110,
              ),
              DataColumnDef(
                id: 'structure',
                label: 'Structure',
                sortKey: (e) => state.salaryFor(e.userId).structure ?? '',
                cell: (_, e) =>
                    Text(state.salaryFor(e.userId).structure ?? '—'),
                width: 160,
              ),
              DataColumnDef(
                id: 'gross',
                label: 'Gross',
                numeric: true,
                sortKey: (e) => state.salaryFor(e.userId).gross,
                cell: (_, e) {
                  final s = state.salaryFor(e.userId);
                  return Text(s.gross == 0 ? '—' : fmt.format(s.gross));
                },
                width: 130,
              ),
              DataColumnDef(
                id: 'earning',
                label: 'Earning',
                numeric: true,
                sortKey: (e) => state.salaryFor(e.userId).totalAllowances,
                cell: (_, e) {
                  final s = state.salaryFor(e.userId);
                  return Text(s.totalAllowances == 0
                      ? '—'
                      : fmt.format(s.totalAllowances));
                },
                width: 130,
              ),
              DataColumnDef(
                id: 'deduction',
                label: 'Deduction',
                numeric: true,
                sortKey: (e) => state.salaryFor(e.userId).totalDeductions,
                cell: (_, e) {
                  final s = state.salaryFor(e.userId);
                  return Text(s.totalDeductions == 0
                      ? '—'
                      : fmt.format(s.totalDeductions));
                },
                width: 130,
              ),
              DataColumnDef(
                id: 'net',
                label: 'Net Payable',
                numeric: true,
                sortKey: (e) => state.salaryFor(e.userId).netPayable,
                cell: (_, e) {
                  final s = state.salaryFor(e.userId);
                  return Text(
                    s.basic == 0 ? '—' : fmt.format(s.netPayable),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  );
                },
                width: 140,
              ),
              DataColumnDef(
                id: 'edit',
                label: '',
                cell: (context, e) => Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _openEditor(context, state, e),
                    child: Text(
                      state.salaryFor(e.userId).basic == 0
                          ? 'Set'
                          : 'Edit',
                    ),
                  ),
                ),
                width: 80,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    AppState state,
    Employee employee,
  ) async {
    final result = await showDetailDrawer<EmployeeSalaryEditorResult>(
      context,
      width: 540,
      child: EmployeeSalaryEditorDrawer(
        employee: employee,
        initial: state.salaryFor(employee.userId),
      ),
    );
    if (result == null) return;
    if (result.deletedUserId != null) {
      await state.deleteEmployeeSalary(result.deletedUserId!);
    } else if (result.saved != null) {
      await state.upsertEmployeeSalary(result.saved!);
    }
  }
}

// ─── Payslips tab ────────────────────────────────────────────────────

class _PayslipsTab extends StatefulWidget {
  const _PayslipsTab();
  @override
  State<_PayslipsTab> createState() => _PayslipsTabState();
}

class _PayslipsTabState extends State<_PayslipsTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final empById = <String, Employee>{
      for (final e in state.employees) e.userId: e,
    };
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, y');
    final q = _query.toLowerCase();
    final rows = q.isEmpty
        ? state.payslips
        : state.payslips.where((p) {
            final name = empById[p.userId]?.name.toLowerCase() ?? '';
            return p.userId.toLowerCase().contains(q) ||
                name.contains(q);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilterRow(
          searchController: _searchCtrl,
          onSearchChanged: (v) => setState(() => _query = v.trim()),
          searchHint: 'Search by name or user id…',
          onNew: () => _openGenerateDialog(context, state),
          newLabel: 'Generate payslips',
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: rows.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No payslips yet',
                  message:
                      'Click Generate payslips to create a draft batch '
                      'for a pay period.',
                )
              : AppDataTable<Payslip>(
                  rows: rows,
                  initialSortColumnId: 'period',
                  initialSortAscending: false,
                  columns: <DataColumnDef<Payslip>>[
                    DataColumnDef(
                      id: 'period',
                      label: 'Period',
                      sortKey: (p) => p.periodStart.toIso8601String(),
                      cell: (_, p) => Text(
                          '${dateFmt.format(p.periodStart)} – '
                          '${dateFmt.format(p.periodEnd)}'),
                      width: 220,
                    ),
                    DataColumnDef(
                      id: 'user',
                      label: 'Employee',
                      sortKey: (p) =>
                          empById[p.userId]?.name ?? p.userId,
                      cell: (_, p) {
                        final e = empById[p.userId];
                        final name =
                            e?.name.isNotEmpty == true ? e!.name : '';
                        return Text(name.isEmpty
                            ? p.userId
                            : '$name  ·  ${p.userId}');
                      },
                    ),
                    DataColumnDef(
                      id: 'gross',
                      label: 'Gross',
                      numeric: true,
                      sortKey: (p) => p.gross,
                      cell: (_, p) => Text(fmt.format(p.gross)),
                      width: 130,
                    ),
                    DataColumnDef(
                      id: 'deduction',
                      label: 'Deduction',
                      numeric: true,
                      sortKey: (p) => p.totalDeductions,
                      cell: (_, p) =>
                          Text(fmt.format(p.totalDeductions)),
                      width: 130,
                    ),
                    DataColumnDef(
                      id: 'net',
                      label: 'Net Payable',
                      numeric: true,
                      sortKey: (p) => p.netPayable,
                      cell: (_, p) => Text(
                        fmt.format(p.netPayable),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      width: 140,
                    ),
                    DataColumnDef(
                      id: 'status',
                      label: 'Status',
                      sortKey: (p) => p.status.name,
                      cell: (_, p) => StatusPill(
                        label: p.status.label,
                        tone: _statusTone(p.status),
                        dense: true,
                      ),
                      width: 130,
                    ),
                    DataColumnDef(
                      id: 'edit',
                      label: '',
                      cell: (context, p) => Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              _openEditor(context, state, p, empById),
                          child: const Text('Open'),
                        ),
                      ),
                      width: 90,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    AppState state,
    Payslip p,
    Map<String, Employee> empById,
  ) async {
    final result = await showDetailDrawer<PayslipEditorResult>(
      context,
      width: 540,
      child: PayslipEditorDrawer(
        payslip: p,
        employee: empById[p.userId],
      ),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deletePayslip(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertPayslip(result.saved!);
    }
  }

  Future<void> _openGenerateDialog(
      BuildContext context, AppState state) async {
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, 1);
    DateTime end = DateTime(now.year, now.month + 1, 0);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateD) {
        final fmt = DateFormat('MMM d, y');
        return AlertDialog(
          title: const Text('Generate payslips'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Creates draft payslips for every employee with a salary '
                  'record. Existing payslips for the same period are skipped.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: ctx,
                      initialDateRange:
                          DateTimeRange(start: start, end: end),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setStateD(() {
                        start = DateUtils.dateOnly(picked.start);
                        end = DateUtils.dateOnly(picked.end);
                      });
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                      '${fmt.format(start)} – ${fmt.format(end)}'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${state.employeeSalaries.length} employee'
                  '${state.employeeSalaries.length == 1 ? "" : "s"} '
                  'with salary records',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).hintColor),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Generate'),
            ),
          ],
        );
      }),
    );
    if (ok != true) return;
    final created = await state.generatePayslipsForPeriod(
      periodStart: start,
      periodEnd: end,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(created == 0
            ? 'No new payslips — all employees already have one for this period.'
            : 'Created $created draft payslip${created == 1 ? "" : "s"}.'),
      ),
    );
  }

  StatusTone _statusTone(PayslipStatus s) {
    switch (s) {
      case PayslipStatus.draft:
        return StatusTone.muted;
      case PayslipStatus.processed:
        return StatusTone.warning;
      case PayslipStatus.disbursed:
        return StatusTone.success;
    }
  }
}

// ─── Salary Info tab ─────────────────────────────────────────────────

class _SalaryInfoTab extends StatelessWidget {
  const _SalaryInfoTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final salaries = state.employeeSalaries.values
        .where((s) => s.basic > 0)
        .toList();

    if (salaries.isEmpty) {
      return const EmptyState(
        icon: Icons.summarize_outlined,
        title: 'No salary records yet',
        message:
            'Set salaries on the Employee Salaries tab to populate the rollup.',
      );
    }

    final totalGross = salaries.fold<double>(0, (a, s) => a + s.gross);
    final totalEarning =
        salaries.fold<double>(0, (a, s) => a + s.totalAllowances);
    final totalDeduction =
        salaries.fold<double>(0, (a, s) => a + s.totalDeductions);
    final totalNet =
        salaries.fold<double>(0, (a, s) => a + s.netPayable);

    final fmt = NumberFormat('#,##0.00');

    final byGrade = <String, List<EmployeeSalary>>{};
    for (final s in salaries) {
      final key = (s.grade ?? '').isEmpty ? 'Ungraded' : s.grade!;
      byGrade.putIfAbsent(key, () => <EmployeeSalary>[]).add(s);
    }
    final gradeRows = byGrade.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 1200
                ? 4
                : c.maxWidth >= 900
                    ? 3
                    : c.maxWidth >= 540
                        ? 2
                        : 1;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.9,
              children: <Widget>[
                KpiCard(
                  label: 'Employees with salary',
                  value: '${salaries.length}',
                  tone: StatusTone.info,
                  icon: Icons.people_outline,
                ),
                KpiCard(
                  label: 'Total Gross',
                  value: fmt.format(totalGross),
                  tone: StatusTone.info,
                  icon: Icons.summarize_outlined,
                ),
                KpiCard(
                  label: 'Total Earning',
                  value: fmt.format(totalEarning),
                  tone: StatusTone.success,
                  icon: Icons.trending_up,
                ),
                KpiCard(
                  label: 'Total Deduction',
                  value: fmt.format(totalDeduction),
                  tone: StatusTone.danger,
                  icon: Icons.trending_down,
                ),
                KpiCard(
                  label: 'Total Net Payable',
                  value: fmt.format(totalNet),
                  tone: StatusTone.success,
                  icon: Icons.payments_outlined,
                ),
                KpiCard(
                  label: 'Avg Net (per employee)',
                  value: fmt.format(totalNet / salaries.length),
                  tone: StatusTone.muted,
                  icon: Icons.bar_chart,
                ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          Text('By grade',
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                          child: Text('Grade',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700))),
                      SizedBox(
                          width: 70,
                          child: Text('Count',
                              textAlign: TextAlign.right,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700))),
                      SizedBox(
                          width: 130,
                          child: Text('Total Net',
                              textAlign: TextAlign.right,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor),
                for (int i = 0; i < gradeRows.length; i++) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm),
                    child: Row(
                      children: <Widget>[
                        Expanded(child: Text(gradeRows[i].key)),
                        SizedBox(
                            width: 70,
                            child: Text('${gradeRows[i].value.length}',
                                textAlign: TextAlign.right)),
                        SizedBox(
                          width: 130,
                          child: Text(
                            fmt.format(gradeRows[i].value.fold<double>(
                                0, (a, s) => a + s.netPayable)),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < gradeRows.length - 1)
                    Divider(height: 1, color: theme.dividerColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
