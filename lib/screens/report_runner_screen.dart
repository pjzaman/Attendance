import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/daily_summary.dart';
import '../models/employee.dart';
import '../models/leave_type.dart';
import '../models/punch.dart';
import '../models/report_def.dart';
import '../models/request.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/app_data_table.dart';
import '../widgets/detail_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/kpi_card.dart';
import '../widgets/status_pill.dart';

class ReportRunnerScreen extends StatefulWidget {
  const ReportRunnerScreen({
    super.key,
    required this.report,
    required this.onBack,
  });

  final ReportDef report;
  final VoidCallback onBack;

  @override
  State<ReportRunnerScreen> createState() => _ReportRunnerScreenState();
}

class _ReportRunnerScreenState extends State<ReportRunnerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late DateTime _from;
  late DateTime _to;

  /// Hidden column ids for the active report — read straight from
  /// AppState so changes persist across runner sessions via the meta
  /// table.
  Set<String> _hiddenFor(AppState state) =>
      <String>{...state.hiddenColumnsFor(widget.report.id)};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = DateTime(now.year, now.month + 1, 0);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _from, end: _to),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _from = DateUtils.dateOnly(picked.start);
        _to = DateUtils.dateOnly(picked.end);
      });
    }
  }

  Future<void> _openColumnPicker(BuildContext context) async {
    final state = context.read<AppState>();
    final spec = _buildStatContent(widget.report, state, _from, _to);
    if (spec == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No columns to pick on this report.')),
      );
      return;
    }
    final result = await showDetailDrawer<Set<String>>(
      context,
      width: 420,
      child: _ColumnPickerDrawer(
        columns: spec.pickerColumns(),
        initialHidden: _hiddenFor(state),
      ),
    );
    if (result != null) {
      await state.setReportHiddenColumns(widget.report.id, result);
    }
  }

  Future<void> _download(BuildContext context) async {
    final state = context.read<AppState>();
    final spec = _buildStatContent(widget.report, state, _from, _to);
    if (spec == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No exportable data on this report yet — wait for the data plumbing slice.',
          ),
        ),
      );
      return;
    }

    final hidden = _hiddenFor(state);
    final headers = spec.exportHeaders(hidden);
    final rows = spec.exportRows(hidden);
    if (headers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All columns are hidden — nothing to export.'),
        ),
      );
      return;
    }

    final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final defaultName =
        '${widget.report.id}_$stamp.csv'.replaceAll(' ', '_');

    // Capture the messenger before awaiting so the snackbar pipeline
    // survives the file dialog round-trip.
    final messenger = ScaffoldMessenger.of(context);

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save report CSV',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: <String>['csv'],
    );
    if (path == null) return;

    try {
      final file = await state.exportService
          .writeRowsCsv(path, headers: headers, rows: rows);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusSuccess,
          content: Text('Saved ${rows.length} rows → ${file.path}'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusDanger,
          content: Text('Save failed: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isStatistic = _tab.index == 1;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Header(
            report: widget.report,
            from: _from,
            to: _to,
            starred: state.starredReports.contains(widget.report.id),
            isStatistic: isStatistic,
            onBack: widget.onBack,
            onPickRange: _pickRange,
            onToggleStar: () =>
                state.toggleStarredReport(widget.report.id),
            onPickColumns: () => _openColumnPicker(context),
            onDownload: () => _download(context),
          ),
          const SizedBox(height: AppSpacing.md),
          TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: (_) => setState(() {}),
            tabs: const <Tab>[
              Tab(text: 'Summary'),
              Tab(text: 'Statistic'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: <Widget>[
                _SummaryView(
                    report: widget.report, state: state, from: _from, to: _to),
                _StatisticView(
                  report: widget.report,
                  state: state,
                  from: _from,
                  to: _to,
                  hidden: _hiddenFor(state),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.report,
    required this.from,
    required this.to,
    required this.starred,
    required this.isStatistic,
    required this.onBack,
    required this.onPickRange,
    required this.onToggleStar,
    required this.onPickColumns,
    required this.onDownload,
  });

  final ReportDef report;
  final DateTime from;
  final DateTime to;
  final bool starred;
  final bool isStatistic;
  final VoidCallback onBack;
  final VoidCallback onPickRange;
  final VoidCallback onToggleStar;
  final VoidCallback onPickColumns;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, y');
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to reports',
          onPressed: onBack,
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: report.category.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child:
              Icon(report.category.icon, color: report.category.color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      report.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (!report.available)
                    const StatusPill(
                      label: 'Coming soon',
                      tone: StatusTone.muted,
                      dense: true,
                    ),
                ],
              ),
              Text(
                '${report.category.label}  ·  ${report.description}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: onPickRange,
          icon: const Icon(Icons.date_range, size: 16),
          label:
              Text('${dateFmt.format(from)} – ${dateFmt.format(to)}'),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          icon: Icon(
            starred ? Icons.star : Icons.star_border,
            color: starred ? AppColors.statusWarning : theme.hintColor,
          ),
          tooltip: starred ? 'Unstar' : 'Star',
          onPressed: onToggleStar,
        ),
        IconButton(
          icon: const Icon(Icons.view_column_outlined),
          tooltip: isStatistic ? 'Pick columns' : 'Switch to Statistic to pick columns',
          onPressed: isStatistic && report.available ? onPickColumns : null,
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined),
          tooltip: isStatistic ? 'Download CSV' : 'Switch to Statistic to download',
          onPressed: isStatistic && report.available ? onDownload : null,
        ),
      ],
    );
  }
}

// ─── Summary view (per-report KPI grid) ──────────────────────────────

class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.report,
    required this.state,
    required this.from,
    required this.to,
  });

  final ReportDef report;
  final AppState state;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    if (!report.available) return const _ComingSoon();
    switch (report.id) {
      case 'rpt_emp_all_summary':
        return _EmployeeAllSummary(state: state);
      case 'rpt_att_summary':
      case 'rpt_att_all_employees':
      case 'rpt_att_daily_log':
        return _AttendanceSummary(state: state, from: from, to: to);
      case 'rpt_att_activity_log':
        return _ActivityLogSummary(state: state, from: from, to: to);
      case 'rpt_leave_request_status':
        return _LeaveRequestStatusSummary(
            state: state, from: from, to: to);
      case 'rpt_leave_balance':
        return _LeaveBalanceSummary(state: state);
      default:
        return const _ComingSoon();
    }
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon();
  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.construction_outlined,
      title: 'Report coming soon',
      message:
          'This report is part of the spec but its data plumbing ships in '
          'a later phase. Star it now and it\'ll be ready when you come back.',
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.cards});
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cols = w >= 1200
          ? 4
          : w >= 900
              ? 3
              : w >= 540
                  ? 2
                  : 1;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.9,
        children: cards,
      );
    });
  }
}

class _EmployeeAllSummary extends StatelessWidget {
  const _EmployeeAllSummary({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final total = state.employees.length;
    final admins = state.employees.where((e) => e.isAdmin).length;
    final withProfile = state.employeeProfiles.values
        .where((p) => p.completeness > 0)
        .length;
    final avgCompleteness = state.employeeProfiles.isEmpty
        ? 0.0
        : state.employeeProfiles.values
                .map((p) => p.completeness)
                .reduce((a, b) => a + b) /
            state.employeeProfiles.length;

    return SingleChildScrollView(
      child: _KpiGrid(cards: <Widget>[
        KpiCard(
          label: 'Total Employees',
          value: '$total',
          tone: StatusTone.info,
          icon: Icons.people_outline,
        ),
        KpiCard(
          label: 'Admins',
          value: '$admins',
          tone: StatusTone.warning,
          icon: Icons.shield_outlined,
        ),
        KpiCard(
          label: 'With profile data',
          value: '$withProfile',
          tone: StatusTone.success,
          icon: Icons.fact_check_outlined,
        ),
        KpiCard(
          label: 'Avg completeness',
          value: '${(avgCompleteness * 100).round()}%',
          tone: avgCompleteness >= 0.75
              ? StatusTone.success
              : avgCompleteness >= 0.5
                  ? StatusTone.warning
                  : StatusTone.danger,
          icon: Icons.trending_up,
        ),
      ]),
    );
  }
}

class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary(
      {required this.state, required this.from, required this.to});
  final AppState state;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final inRange = state.daily
        .where((d) => !d.date.isBefore(from) && !d.date.isAfter(to))
        .toList();
    final present = inRange.where((d) => d.checkIn != null).length;
    final absent =
        inRange.where((d) => d.status == AttendanceStatus.absent).length;
    final late =
        inRange.where((d) => d.status == AttendanceStatus.late).length;
    final halfDay =
        inRange.where((d) => d.status == AttendanceStatus.halfDay).length;
    final totalMinutes =
        inRange.fold<int>(0, (a, d) => a + d.workedMinutes);
    final hours = totalMinutes / 60;

    return SingleChildScrollView(
      child: _KpiGrid(cards: <Widget>[
        KpiCard(
          label: 'Records',
          value: '${inRange.length}',
          tone: StatusTone.info,
          icon: Icons.list_alt,
        ),
        KpiCard(
          label: 'Present',
          value: '$present',
          tone: StatusTone.success,
          icon: Icons.check_circle_outline,
        ),
        KpiCard(
          label: 'Absent',
          value: '$absent',
          tone: StatusTone.danger,
          icon: Icons.cancel_outlined,
        ),
        KpiCard(
          label: 'Late',
          value: '$late',
          tone: StatusTone.warning,
          icon: Icons.schedule,
        ),
        KpiCard(
          label: 'Half-Day',
          value: '$halfDay',
          tone: StatusTone.warning,
          icon: Icons.hourglass_bottom,
        ),
        KpiCard(
          label: 'Total Hours',
          value: hours.toStringAsFixed(1),
          tone: StatusTone.info,
          icon: Icons.timer_outlined,
        ),
      ]),
    );
  }
}

class _ActivityLogSummary extends StatelessWidget {
  const _ActivityLogSummary(
      {required this.state, required this.from, required this.to});
  final AppState state;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final inRange = state.recentPunches
        .where((p) =>
            !p.timestamp.isBefore(from) &&
            !p.timestamp.isAfter(to.add(const Duration(days: 1))))
        .toList();
    final users = inRange.map((p) => p.userId).toSet().length;
    final days = inRange
        .map((p) =>
            DateTime(p.timestamp.year, p.timestamp.month, p.timestamp.day))
        .toSet()
        .length;
    final avgPerDay = days == 0 ? 0.0 : inRange.length / days;

    return SingleChildScrollView(
      child: _KpiGrid(cards: <Widget>[
        KpiCard(
          label: 'Punches',
          value: '${inRange.length}',
          tone: StatusTone.info,
          icon: Icons.fingerprint,
        ),
        KpiCard(
          label: 'Active users',
          value: '$users',
          tone: StatusTone.success,
          icon: Icons.person_outline,
        ),
        KpiCard(
          label: 'Days with activity',
          value: '$days',
          tone: StatusTone.info,
          icon: Icons.calendar_today_outlined,
        ),
        KpiCard(
          label: 'Avg punches / day',
          value: avgPerDay.toStringAsFixed(1),
          tone: StatusTone.muted,
          icon: Icons.bar_chart,
        ),
      ]),
    );
  }
}

class _LeaveRequestStatusSummary extends StatelessWidget {
  const _LeaveRequestStatusSummary(
      {required this.state, required this.from, required this.to});
  final AppState state;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final inRange = state.requests
        .where((r) => r.type == RequestType.leave)
        .where((r) =>
            !r.fromDate.isBefore(from) &&
            !r.fromDate.isAfter(to))
        .toList();
    final pending =
        inRange.where((r) => r.status == RequestStatus.pending).length;
    final approved =
        inRange.where((r) => r.status == RequestStatus.approved).length;
    final rejected =
        inRange.where((r) => r.status == RequestStatus.rejected).length;

    return SingleChildScrollView(
      child: _KpiGrid(cards: <Widget>[
        KpiCard(
          label: 'Total',
          value: '${inRange.length}',
          tone: StatusTone.info,
          icon: Icons.list_alt,
        ),
        KpiCard(
          label: 'Pending',
          value: '$pending',
          tone: StatusTone.warning,
          icon: Icons.hourglass_top_outlined,
        ),
        KpiCard(
          label: 'Approved',
          value: '$approved',
          tone: StatusTone.success,
          icon: Icons.check_circle_outline,
        ),
        KpiCard(
          label: 'Rejected',
          value: '$rejected',
          tone: StatusTone.danger,
          icon: Icons.cancel_outlined,
        ),
      ]),
    );
  }
}

class _LeaveBalanceSummary extends StatelessWidget {
  const _LeaveBalanceSummary({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final activeTypes = state.activeLeaveTypes;
    final totalEntitled = activeTypes.fold<int>(
        0, (a, t) => a + t.defaultDaysPerYear * state.employees.length);
    final year = DateTime.now().year;
    int totalUsed = 0;
    int totalPending = 0;
    for (final r in state.requests.where((r) => r.type == RequestType.leave)) {
      if (r.fromDate.year != year) continue;
      final days = r.toDate == null
          ? 1
          : r.toDate!.difference(r.fromDate).inDays + 1;
      if (r.status == RequestStatus.approved) totalUsed += days;
      if (r.status == RequestStatus.pending) totalPending += days;
    }
    return SingleChildScrollView(
      child: _KpiGrid(cards: <Widget>[
        KpiCard(
          label: 'Active leave types',
          value: '${activeTypes.length}',
          tone: StatusTone.info,
          icon: Icons.beach_access_outlined,
        ),
        KpiCard(
          label: 'Total entitled (org)',
          value: '$totalEntitled',
          subLabel: 'days × employees',
          tone: StatusTone.info,
          icon: Icons.summarize_outlined,
        ),
        KpiCard(
          label: 'Used this year',
          value: '$totalUsed',
          tone: StatusTone.success,
          icon: Icons.check_circle_outline,
        ),
        KpiCard(
          label: 'Pending',
          value: '$totalPending',
          tone: StatusTone.warning,
          icon: Icons.hourglass_top_outlined,
        ),
      ]),
    );
  }
}

// ─── Statistic view ──────────────────────────────────────────────────

class _StatisticView extends StatelessWidget {
  const _StatisticView({
    required this.report,
    required this.state,
    required this.from,
    required this.to,
    required this.hidden,
  });

  final ReportDef report;
  final AppState state;
  final DateTime from;
  final DateTime to;
  final Set<String> hidden;

  @override
  Widget build(BuildContext context) {
    if (!report.available) return const _ComingSoon();
    final spec = _buildStatContent(report, state, from, to);
    if (spec == null) return const _ComingSoon();
    return spec.buildTable(hidden);
  }
}

// ─── Stat-tab spec model ─────────────────────────────────────────────

/// One pickable column entry surfaced in the column-picker drawer.
class _PickerColumn {
  _PickerColumn({
    required this.id,
    required this.label,
    required this.exportable,
  });
  final String id;
  final String label;
  final bool exportable;
}

/// Type-erased view of a stat-tab spec — the dispatcher returns this so
/// the runner can render + drive the picker / export without knowing
/// the per-report row type.
abstract class _StatTabContent {
  Widget buildTable(Set<String> hidden);
  List<_PickerColumn> pickerColumns();
  List<String> exportHeaders(Set<String> hidden);
  List<List<String>> exportRows(Set<String> hidden);
}

class _TypedStatTab<T> implements _StatTabContent {
  _TypedStatTab({
    required this.columns,
    required this.rows,
    this.initialSortColumnId,
    this.initialSortAscending = true,
  });

  final List<DataColumnDef<T>> columns;
  final List<T> rows;
  final String? initialSortColumnId;
  final bool initialSortAscending;

  @override
  Widget buildTable(Set<String> hidden) => AppDataTable<T>(
        rows: rows,
        columns: columns,
        hiddenColumnIds: hidden,
        initialSortColumnId: initialSortColumnId,
        initialSortAscending: initialSortAscending,
      );

  @override
  List<_PickerColumn> pickerColumns() => <_PickerColumn>[
        for (final c in columns)
          _PickerColumn(
            id: c.id,
            label: c.label,
            exportable: c.exportValue != null,
          ),
      ];

  @override
  List<String> exportHeaders(Set<String> hidden) => <String>[
        for (final c in columns)
          if (!hidden.contains(c.id) && c.exportValue != null) c.label,
      ];

  @override
  List<List<String>> exportRows(Set<String> hidden) {
    final visible = <DataColumnDef<T>>[
      for (final c in columns)
        if (!hidden.contains(c.id) && c.exportValue != null) c,
    ];
    return <List<String>>[
      for (final r in rows)
        <String>[for (final c in visible) c.exportValue!(r)],
    ];
  }
}

// ─── Per-report stat builders ───────────────────────────────────────

_StatTabContent? _buildStatContent(
  ReportDef report,
  AppState state,
  DateTime from,
  DateTime to,
) {
  if (!report.available) return null;
  switch (report.id) {
    case 'rpt_emp_all_summary':
      return _employeeAllStat(state);
    case 'rpt_att_summary':
    case 'rpt_att_all_employees':
    case 'rpt_att_daily_log':
      return _dailyLogStat(state, from, to);
    case 'rpt_att_activity_log':
      return _activityLogStat(state, from, to);
    case 'rpt_leave_request_status':
      return _leaveRequestStat(state, from, to);
    case 'rpt_leave_balance':
      return _leaveBalanceStat(state);
    default:
      return null;
  }
}

_TypedStatTab<Employee> _employeeAllStat(AppState state) {
  return _TypedStatTab<Employee>(
    rows: state.employees,
    initialSortColumnId: 'user_id',
    initialSortAscending: true,
    columns: <DataColumnDef<Employee>>[
      DataColumnDef(
        id: 'user_id',
        label: 'User ID',
        sortKey: (e) => e.userId,
        cell: (_, e) => Text(e.userId),
        exportValue: (e) => e.userId,
        width: 120,
      ),
      DataColumnDef(
        id: 'name',
        label: 'Name',
        sortKey: (e) => e.name,
        cell: (_, e) => Text(e.name.isEmpty ? '—' : e.name),
        exportValue: (e) => e.name,
      ),
      DataColumnDef(
        id: 'designation',
        label: 'Designation',
        sortKey: (e) => state.profileFor(e.userId).designation ?? '',
        cell: (_, e) =>
            Text(state.profileFor(e.userId).designation ?? '—'),
        exportValue: (e) => state.profileFor(e.userId).designation ?? '',
      ),
      DataColumnDef(
        id: 'department',
        label: 'Department',
        sortKey: (e) => state.profileFor(e.userId).department ?? '',
        cell: (_, e) =>
            Text(state.profileFor(e.userId).department ?? '—'),
        exportValue: (e) => state.profileFor(e.userId).department ?? '',
      ),
      DataColumnDef(
        id: 'completeness',
        label: 'Completeness',
        numeric: true,
        sortKey: (e) =>
            (state.profileFor(e.userId).completeness * 100).round(),
        cell: (_, e) {
          final pct =
              (state.profileFor(e.userId).completeness * 100).round();
          return Text('$pct%');
        },
        exportValue: (e) =>
            '${(state.profileFor(e.userId).completeness * 100).round()}%',
        width: 130,
      ),
      DataColumnDef(
        id: 'admin',
        label: 'Role',
        sortKey: (e) => e.isAdmin ? 'admin' : 'user',
        cell: (_, e) => StatusPill(
          label: e.isAdmin ? 'Admin' : 'User',
          tone: e.isAdmin ? StatusTone.warning : StatusTone.muted,
          dense: true,
        ),
        exportValue: (e) => e.isAdmin ? 'Admin' : 'User',
        width: 110,
      ),
    ],
  );
}

_TypedStatTab<DailySummary> _dailyLogStat(
    AppState state, DateTime from, DateTime to) {
  final rows = state.daily
      .where((d) => !d.date.isBefore(from) && !d.date.isAfter(to))
      .toList();
  final dateFmt = DateFormat('yyyy-MM-dd');
  final timeFmt = DateFormat('HH:mm');
  return _TypedStatTab<DailySummary>(
    rows: rows,
    initialSortColumnId: 'date',
    initialSortAscending: false,
    columns: <DataColumnDef<DailySummary>>[
      DataColumnDef(
        id: 'date',
        label: 'Date',
        sortKey: (d) => d.date.toIso8601String(),
        cell: (_, d) => Text(dateFmt.format(d.date)),
        exportValue: (d) => dateFmt.format(d.date),
        width: 120,
      ),
      DataColumnDef(
        id: 'user',
        label: 'User',
        sortKey: (d) => d.userId,
        cell: (_, d) => Text(d.userId),
        exportValue: (d) => d.userId,
        width: 110,
      ),
      DataColumnDef(
        id: 'in',
        label: 'In',
        sortKey: (d) => d.checkIn?.toIso8601String() ?? '',
        cell: (_, d) =>
            Text(d.checkIn != null ? timeFmt.format(d.checkIn!) : '—'),
        exportValue: (d) =>
            d.checkIn != null ? timeFmt.format(d.checkIn!) : '',
        width: 80,
      ),
      DataColumnDef(
        id: 'out',
        label: 'Out',
        sortKey: (d) => d.checkOut?.toIso8601String() ?? '',
        cell: (_, d) =>
            Text(d.checkOut != null ? timeFmt.format(d.checkOut!) : '—'),
        exportValue: (d) =>
            d.checkOut != null ? timeFmt.format(d.checkOut!) : '',
        width: 80,
      ),
      DataColumnDef(
        id: 'hours',
        label: 'Hours',
        numeric: true,
        sortKey: (d) => d.workedMinutes,
        cell: (_, d) => Text((d.workedMinutes / 60).toStringAsFixed(2)),
        exportValue: (d) => (d.workedMinutes / 60).toStringAsFixed(2),
        width: 90,
      ),
      DataColumnDef(
        id: 'status',
        label: 'Status',
        sortKey: (d) => d.status.wireValue,
        cell: (_, d) => StatusPill(
          label: _attendanceStatusLabel(d.status),
          tone: _attendanceStatusTone(d.status),
          dense: true,
        ),
        exportValue: (d) => _attendanceStatusLabel(d.status),
        width: 110,
      ),
    ],
  );
}

String _attendanceStatusLabel(AttendanceStatus s) {
  switch (s) {
    case AttendanceStatus.present:
      return 'Present';
    case AttendanceStatus.late:
      return 'Late';
    case AttendanceStatus.halfDay:
      return 'Half-Day';
    case AttendanceStatus.absent:
      return 'Absent';
  }
}

StatusTone _attendanceStatusTone(AttendanceStatus s) {
  switch (s) {
    case AttendanceStatus.present:
      return StatusTone.success;
    case AttendanceStatus.late:
      return StatusTone.warning;
    case AttendanceStatus.halfDay:
      return StatusTone.warning;
    case AttendanceStatus.absent:
      return StatusTone.danger;
  }
}

_TypedStatTab<Punch> _activityLogStat(
    AppState state, DateTime from, DateTime to) {
  final rows = state.recentPunches
      .where((p) =>
          !p.timestamp.isBefore(from) &&
          !p.timestamp.isAfter(to.add(const Duration(days: 1))))
      .toList();
  final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
  return _TypedStatTab<Punch>(
    rows: rows,
    initialSortColumnId: 'timestamp',
    initialSortAscending: false,
    columns: <DataColumnDef<Punch>>[
      DataColumnDef(
        id: 'timestamp',
        label: 'Timestamp',
        sortKey: (p) => p.timestamp.toIso8601String(),
        cell: (_, p) => Text(fmt.format(p.timestamp)),
        exportValue: (p) => fmt.format(p.timestamp),
        width: 200,
      ),
      DataColumnDef(
        id: 'user',
        label: 'User',
        sortKey: (p) => p.userId,
        cell: (_, p) => Text(p.userId),
        exportValue: (p) => p.userId,
        width: 110,
      ),
      DataColumnDef(
        id: 'raw_status',
        label: 'raw_status',
        numeric: true,
        sortKey: (p) => p.rawStatus,
        cell: (_, p) => Text('${p.rawStatus}'),
        exportValue: (p) => '${p.rawStatus}',
        width: 110,
      ),
      DataColumnDef(
        id: 'raw_punch',
        label: 'raw_punch',
        numeric: true,
        sortKey: (p) => p.rawPunch,
        cell: (_, p) => Text('${p.rawPunch}'),
        exportValue: (p) => '${p.rawPunch}',
        width: 110,
      ),
    ],
  );
}

_TypedStatTab<Request> _leaveRequestStat(
    AppState state, DateTime from, DateTime to) {
  final rows = state.requests
      .where((r) => r.type == RequestType.leave)
      .where((r) =>
          !r.fromDate.isBefore(from) && !r.fromDate.isAfter(to))
      .toList();
  final dateFmt = DateFormat('MMM d, y');
  final typesById = <String, LeaveType>{
    for (final t in state.leaveTypes) t.id: t,
  };
  String typeLabel(Request r) =>
      typesById[r.leaveType]?.name ?? r.leaveType ?? '';
  int dayCount(Request r) => r.toDate == null
      ? 1
      : r.toDate!.difference(r.fromDate).inDays + 1;

  return _TypedStatTab<Request>(
    rows: rows,
    initialSortColumnId: 'created',
    initialSortAscending: false,
    columns: <DataColumnDef<Request>>[
      DataColumnDef(
        id: 'user',
        label: 'User',
        sortKey: (r) => r.requesterUserId,
        cell: (_, r) => Text(r.requesterUserId),
        exportValue: (r) => r.requesterUserId,
        width: 110,
      ),
      DataColumnDef(
        id: 'type',
        label: 'Leave type',
        sortKey: (r) => r.leaveType ?? '',
        cell: (_, r) => Text(typeLabel(r).isEmpty ? '—' : typeLabel(r)),
        exportValue: typeLabel,
        width: 130,
      ),
      DataColumnDef(
        id: 'from',
        label: 'From',
        sortKey: (r) => r.fromDate.toIso8601String(),
        cell: (_, r) => Text(dateFmt.format(r.fromDate)),
        exportValue: (r) => dateFmt.format(r.fromDate),
        width: 120,
      ),
      DataColumnDef(
        id: 'to',
        label: 'To',
        sortKey: (r) => r.toDate?.toIso8601String() ?? '',
        cell: (_, r) =>
            Text(r.toDate == null ? '—' : dateFmt.format(r.toDate!)),
        exportValue: (r) =>
            r.toDate == null ? '' : dateFmt.format(r.toDate!),
        width: 120,
      ),
      DataColumnDef(
        id: 'days',
        label: 'Days',
        numeric: true,
        sortKey: (r) => dayCount(r),
        cell: (_, r) => Text('${dayCount(r)}'),
        exportValue: (r) => '${dayCount(r)}',
        width: 80,
      ),
      DataColumnDef(
        id: 'status',
        label: 'Status',
        sortKey: (r) => r.status.name,
        cell: (_, r) => StatusPill(
          label: r.status.label,
          tone: _requestStatusTone(r.status),
          dense: true,
        ),
        exportValue: (r) => r.status.label,
        width: 110,
      ),
      DataColumnDef(
        id: 'created',
        label: 'Submitted',
        sortKey: (r) => r.createdAt.toIso8601String(),
        cell: (_, r) =>
            Text(DateFormat('MMM d, y').format(r.createdAt)),
        exportValue: (r) => DateFormat('MMM d, y').format(r.createdAt),
        width: 130,
      ),
    ],
  );
}

StatusTone _requestStatusTone(RequestStatus s) {
  switch (s) {
    case RequestStatus.pending:
      return StatusTone.warning;
    case RequestStatus.approved:
      return StatusTone.success;
    case RequestStatus.rejected:
      return StatusTone.danger;
    case RequestStatus.cancelled:
      return StatusTone.muted;
  }
}

class _BalanceRow {
  _BalanceRow({
    required this.userId,
    required this.name,
    required this.typeName,
    required this.typeCode,
    required this.entitled,
    required this.used,
    required this.pending,
  });
  final String userId;
  final String name;
  final String typeName;
  final String typeCode;
  final int entitled;
  final int used;
  final int pending;
}

_TypedStatTab<_BalanceRow> _leaveBalanceStat(AppState state) {
  final activeTypes = state.activeLeaveTypes;
  final year = DateTime.now().year;

  final rows = <_BalanceRow>[];
  for (final e in state.employees) {
    for (final t in activeTypes) {
      int used = 0;
      int pending = 0;
      for (final r in state.requests.where((r) =>
          r.type == RequestType.leave &&
          r.requesterUserId == e.userId &&
          r.leaveType == t.id)) {
        if (r.fromDate.year != year) continue;
        final days = r.toDate == null
            ? 1
            : r.toDate!.difference(r.fromDate).inDays + 1;
        if (r.status == RequestStatus.approved) used += days;
        if (r.status == RequestStatus.pending) pending += days;
      }
      rows.add(_BalanceRow(
        userId: e.userId,
        name: e.name.isEmpty ? '—' : e.name,
        typeName: t.name,
        typeCode: t.code,
        entitled: t.defaultDaysPerYear,
        used: used,
        pending: pending,
      ));
    }
  }

  return _TypedStatTab<_BalanceRow>(
    rows: rows,
    initialSortColumnId: 'user',
    initialSortAscending: true,
    columns: <DataColumnDef<_BalanceRow>>[
      DataColumnDef(
        id: 'user',
        label: 'User',
        sortKey: (r) => r.userId,
        cell: (_, r) => Text(r.userId),
        exportValue: (r) => r.userId,
        width: 110,
      ),
      DataColumnDef(
        id: 'name',
        label: 'Name',
        sortKey: (r) => r.name,
        cell: (_, r) => Text(r.name),
        exportValue: (r) => r.name,
      ),
      DataColumnDef(
        id: 'type',
        label: 'Leave type',
        sortKey: (r) => r.typeName,
        cell: (_, r) => Text('${r.typeCode}  ·  ${r.typeName}'),
        exportValue: (r) => '${r.typeCode} · ${r.typeName}',
        width: 160,
      ),
      DataColumnDef(
        id: 'entitled',
        label: 'Entitled',
        numeric: true,
        sortKey: (r) => r.entitled,
        cell: (_, r) => Text(r.entitled == 0 ? '—' : '${r.entitled}'),
        exportValue: (r) => '${r.entitled}',
        width: 100,
      ),
      DataColumnDef(
        id: 'used',
        label: 'Used',
        numeric: true,
        sortKey: (r) => r.used,
        cell: (_, r) => Text('${r.used}'),
        exportValue: (r) => '${r.used}',
        width: 90,
      ),
      DataColumnDef(
        id: 'pending',
        label: 'Pending',
        numeric: true,
        sortKey: (r) => r.pending,
        cell: (_, r) => Text('${r.pending}'),
        exportValue: (r) => '${r.pending}',
        width: 90,
      ),
      DataColumnDef(
        id: 'remaining',
        label: 'Remaining',
        numeric: true,
        sortKey: (r) => r.entitled == 0 ? -1 : r.entitled - r.used,
        cell: (_, r) => Text(
          r.entitled == 0 ? '—' : '${r.entitled - r.used}',
        ),
        exportValue: (r) =>
            r.entitled == 0 ? '' : '${r.entitled - r.used}',
        width: 110,
      ),
    ],
  );
}

// ─── Column picker drawer ───────────────────────────────────────────

class _ColumnPickerDrawer extends StatefulWidget {
  const _ColumnPickerDrawer({
    required this.columns,
    required this.initialHidden,
  });
  final List<_PickerColumn> columns;
  final Set<String> initialHidden;

  @override
  State<_ColumnPickerDrawer> createState() => _ColumnPickerDrawerState();
}

class _ColumnPickerDrawerState extends State<_ColumnPickerDrawer> {
  late Set<String> _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = <String>{...widget.initialHidden};
  }

  @override
  Widget build(BuildContext context) {
    final allHidden =
        widget.columns.every((c) => _hidden.contains(c.id));

    return DetailDrawer(
      title: 'Columns',
      subtitle: 'Pick which columns to show in the table and include in '
          'CSV export. Sort persists; hidden columns are skipped on download.',
      actions: <Widget>[
        TextButton(
          onPressed: () => setState(() => _hidden.clear()),
          child: const Text('Show all'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: allHidden
              ? null
              : () => Navigator.of(context).pop<Set<String>>(_hidden),
          child: const Text('Apply'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (allHidden)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'At least one column must remain visible.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.statusDanger,
                    ),
              ),
            ),
          for (final c in widget.columns)
            CheckboxListTile(
              value: !_hidden.contains(c.id),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _hidden.remove(c.id);
                } else {
                  _hidden.add(c.id);
                }
              }),
              title: Row(
                children: <Widget>[
                  Expanded(child: Text(c.label)),
                  if (!c.exportable)
                    const StatusPill(
                      label: 'Display only',
                      tone: StatusTone.muted,
                      dense: true,
                    ),
                ],
              ),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
