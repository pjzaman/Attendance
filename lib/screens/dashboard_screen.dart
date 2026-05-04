import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/daily_summary.dart';
import '../models/employee.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/date_navigator.dart';
import '../widgets/empty_state.dart';
import '../widgets/kpi_card.dart';
import '../widgets/status_card.dart';
import '../widgets/status_pill.dart';

enum _Mode { mySpace, workspace }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _Mode _mode = _Mode.workspace;
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  Employee? _myEmployee;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final showFirstRunHint = state.totalPunches == 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: const StatusCard(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ModeAndDateRow(
            mode: _mode,
            onModeChanged: (m) => setState(() => _mode = m),
            date: _date,
            onDateChanged: (d) =>
                setState(() => _date = DateUtils.dateOnly(d)),
            showDateNavigator: _mode == _Mode.workspace,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_mode == _Mode.workspace)
            _WorkspaceBody(state: state, date: _date)
          else
            _MySpaceBody(
              state: state,
              employee: _myEmployee,
              onPickEmployee: (e) => setState(() => _myEmployee = e),
            ),
          if (showFirstRunHint) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            const _FirstRunHint(),
          ],
        ],
      ),
    );
  }
}

class _ModeAndDateRow extends StatelessWidget {
  const _ModeAndDateRow({
    required this.mode,
    required this.onModeChanged,
    required this.date,
    required this.onDateChanged,
    required this.showDateNavigator,
  });

  final _Mode mode;
  final ValueChanged<_Mode> onModeChanged;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final bool showDateNavigator;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        SegmentedButton<_Mode>(
          segments: const <ButtonSegment<_Mode>>[
            ButtonSegment(
              value: _Mode.mySpace,
              icon: Icon(Icons.person_outline, size: 16),
              label: Text('My Space'),
            ),
            ButtonSegment(
              value: _Mode.workspace,
              icon: Icon(Icons.groups_outlined, size: 16),
              label: Text('Workspace'),
            ),
          ],
          selected: <_Mode>{mode},
          onSelectionChanged: (s) => onModeChanged(s.first),
          showSelectedIcon: false,
        ),
        if (showDateNavigator)
          DateNavigator(date: date, onChanged: onDateChanged),
      ],
    );
  }
}

// ─── Workspace ───────────────────────────────────────────────────────

class _WorkspaceBody extends StatelessWidget {
  const _WorkspaceBody({required this.state, required this.date});

  final AppState state;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final stats = _DayStats.compute(state.daily, state.employees, date);
    final priorWeek = date.subtract(const Duration(days: 7));
    final priorStats =
        _hasDataFor(state.daily, priorWeek)
            ? _DayStats.compute(state.daily, state.employees, priorWeek)
            : null;

    double? deltaPct(int now, int? prior) {
      if (prior == null || prior == 0) return null;
      return ((now - prior) / prior) * 100.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Today’s Attendance · ${DateFormat('EEEE, MMM d, y').format(date)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _KpiGrid(cards: <Widget>[
          KpiCard(
            label: 'Total Employees',
            value: '${stats.total}',
            tone: StatusTone.info,
            icon: Icons.people_outline,
          ),
          KpiCard(
            label: 'Present',
            value: '${stats.present}',
            tone: StatusTone.success,
            delta: deltaPct(stats.present, priorStats?.present),
            subLabel: priorStats == null ? null : 'vs last week',
            icon: Icons.check_circle_outline,
          ),
          KpiCard(
            label: 'Absent',
            value: '${stats.absent}',
            tone: StatusTone.danger,
            delta: priorStats == null
                ? null
                : -1 * (deltaPct(stats.absent, priorStats.absent) ?? 0),
            subLabel: priorStats == null ? null : 'vs last week',
            icon: Icons.cancel_outlined,
          ),
          KpiCard(
            label: 'Late',
            value: '${stats.late}',
            tone: StatusTone.warning,
            delta: priorStats == null
                ? null
                : -1 * (deltaPct(stats.late, priorStats.late) ?? 0),
            subLabel: priorStats == null ? null : 'vs last week',
            icon: Icons.schedule,
          ),
          KpiCard(
            label: 'Half-Day',
            value: '${stats.halfDay}',
            tone: StatusTone.warning,
            icon: Icons.hourglass_bottom,
          ),
          KpiCard(
            label: 'Avg Hours',
            value: stats.avgHoursLabel,
            tone: StatusTone.muted,
            icon: Icons.timer_outlined,
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _UpcomingHolidayTile(state: state),
      ],
    );
  }

  static bool _hasDataFor(List<DailySummary> daily, DateTime d) {
    return daily.any((s) => DateUtils.isSameDay(s.date, d));
  }
}

class _DayStats {
  _DayStats({
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.avgWorkedMinutes,
  });

  final int total;
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final double avgWorkedMinutes;

  String get avgHoursLabel {
    if (avgWorkedMinutes == 0) return '—';
    final h = avgWorkedMinutes ~/ 60;
    final m = (avgWorkedMinutes % 60).round();
    return '${h}h ${m}m';
  }

  static _DayStats compute(
    List<DailySummary> daily,
    List<Employee> employees,
    DateTime date,
  ) {
    final today =
        daily.where((d) => DateUtils.isSameDay(d.date, date)).toList();
    final present =
        today.where((d) => d.checkIn != null).toList();
    final late = today
        .where((d) => d.status == AttendanceStatus.late)
        .length;
    final halfDay = today
        .where((d) => d.status == AttendanceStatus.halfDay)
        .length;
    final total = employees.length;
    final absent = (total - present.length).clamp(0, total);
    final avg = present.isEmpty
        ? 0.0
        : present.map((d) => d.workedMinutes).reduce((a, b) => a + b) /
            present.length;
    return _DayStats(
      total: total,
      present: present.length,
      absent: absent,
      late: late,
      halfDay: halfDay,
      avgWorkedMinutes: avg,
    );
  }
}

// ─── My Space ────────────────────────────────────────────────────────

class _MySpaceBody extends StatelessWidget {
  const _MySpaceBody({
    required this.state,
    required this.employee,
    required this.onPickEmployee,
  });

  final AppState state;
  final Employee? employee;
  final ValueChanged<Employee?> onPickEmployee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final picker = Row(
      children: <Widget>[
        Text(
          'Viewing as',
          style:
              theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
          child: DropdownButtonFormField<Employee>(
            initialValue: employee,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              hintText: 'Select an employee',
            ),
            items: <DropdownMenuItem<Employee>>[
              for (final e in state.employees)
                DropdownMenuItem(
                  value: e,
                  child: Text(
                    e.name.isNotEmpty
                        ? '${e.name}  (id ${e.userId})'
                        : 'id ${e.userId}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: onPickEmployee,
          ),
        ),
      ],
    );

    if (employee == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          picker,
          const SizedBox(height: AppSpacing.lg),
          const EmptyState(
            icon: Icons.person_search_outlined,
            title: 'Pick an employee to see attendance',
            message:
                'My Space shows the selected employee’s month-to-date stats. '
                'Until single-user auth is wired up, pick from the list.',
          ),
        ],
      );
    }

    final mtd = _MonthToDateStats.compute(state.daily, employee!.userId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        picker,
        const SizedBox(height: AppSpacing.md),
        Text(
          'Month to date · ${DateFormat('MMMM y').format(DateTime.now())}',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _KpiGrid(cards: <Widget>[
          KpiCard(
            label: 'Present Days',
            value: '${mtd.present}',
            tone: StatusTone.success,
            icon: Icons.check_circle_outline,
          ),
          KpiCard(
            label: 'Late',
            value: '${mtd.late}',
            tone: StatusTone.warning,
            icon: Icons.schedule,
          ),
          KpiCard(
            label: 'Half-Day',
            value: '${mtd.halfDay}',
            tone: StatusTone.warning,
            icon: Icons.hourglass_bottom,
          ),
          KpiCard(
            label: 'Hours MTD',
            value: mtd.totalHoursLabel,
            tone: StatusTone.info,
            icon: Icons.timer_outlined,
          ),
        ]),
      ],
    );
  }
}

class _MonthToDateStats {
  _MonthToDateStats({
    required this.present,
    required this.late,
    required this.halfDay,
    required this.totalMinutes,
  });

  final int present;
  final int late;
  final int halfDay;
  final int totalMinutes;

  String get totalHoursLabel {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }

  static _MonthToDateStats compute(
      List<DailySummary> daily, String userId) {
    final mine = daily.where((d) => d.userId == userId).toList();
    final present = mine.where((d) => d.checkIn != null).length;
    final late = mine
        .where((d) => d.status == AttendanceStatus.late)
        .length;
    final halfDay = mine
        .where((d) => d.status == AttendanceStatus.halfDay)
        .length;
    final total = mine.fold<int>(0, (a, d) => a + d.workedMinutes);
    return _MonthToDateStats(
      present: present,
      late: late,
      halfDay: halfDay,
      totalMinutes: total,
    );
  }
}

// ─── Layout helpers ──────────────────────────────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.cards});
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
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

class _FirstRunHint extends StatelessWidget {
  const _FirstRunHint();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('First-run checklist',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              const Text('1. Make sure the office PC can ping 192.168.0.150.'),
              const Text('2. Click "Ping device" — should turn green.'),
              const Text('3. Click "Sync now" — first sync may take 30-60s.'),
              const Text('4. Check the Punches and Daily tabs to verify '
                  'derivation matches expectations.'),
              const Text('5. Use the Export tab to dump CSV/XLSX for review.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingHolidayTile extends StatelessWidget {
  const _UpcomingHolidayTile({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = state.upcomingHoliday();
    final dateFmt = DateFormat('EEEE, MMM d, y');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.statusWarning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.statusWarning.withValues(alpha: 0.4),
                ),
              ),
              alignment: Alignment.center,
              child: h == null
                  ? const Icon(Icons.celebration_outlined,
                      color: AppColors.statusWarning, size: 24)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          DateFormat('MMM').format(h.date).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusWarning,
                          ),
                        ),
                        Text(
                          '${h.date.day}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: h == null
                  ? Text(
                      'No upcoming holidays — add some in Settings → Holidays.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.hintColor),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('Upcoming holiday',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 2),
                        Text(
                          h.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${dateFmt.format(h.date)}  ·  in ${_daysUntil(h.date)} day${_daysUntil(h.date) == 1 ? "" : "s"}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static int _daysUntil(DateTime d) {
    final today = DateUtils.dateOnly(DateTime.now());
    final dd = DateUtils.dateOnly(d);
    return dd.difference(today).inDays;
  }
}
