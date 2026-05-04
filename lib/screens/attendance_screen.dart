import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../models/punch.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Employee? _selectedEmployee;

  @override
  Widget build(BuildContext context) {
    if (_selectedEmployee == null) {
      return _EmployeePicker(
        onPick: (e) => setState(() => _selectedEmployee = e),
      );
    }
    return _EmployeeCalendarView(
      employee: _selectedEmployee!,
      onBack: () => setState(() => _selectedEmployee = null),
    );
  }
}

class _EmployeePicker extends StatefulWidget {
  const _EmployeePicker({required this.onPick});
  final ValueChanged<Employee> onPick;

  @override
  State<_EmployeePicker> createState() => _EmployeePickerState();
}

class _EmployeePickerState extends State<_EmployeePicker> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<AppState>().employees;
    if (employees.isEmpty) {
      return const Center(
        child: Text('No employees yet — run a sync.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? employees
        : employees
            .where((e) =>
                e.name.toLowerCase().contains(q) ||
                e.userId.toLowerCase().contains(q))
            .toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Pick an employee',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search by name or user id…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No matches.',
                        style: TextStyle(color: Colors.grey)),
                  )
                : Card(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        final initial = (e.name.isNotEmpty
                                ? e.name
                                : e.userId.isNotEmpty
                                    ? e.userId
                                    : '?')
                            .substring(0, 1)
                            .toUpperCase();
                        return ListTile(
                          leading: CircleAvatar(child: Text(initial)),
                          title: Text(
                              e.name.isNotEmpty ? e.name : '(no name)'),
                          subtitle: Text('user_id: ${e.userId}'
                              '${e.isAdmin ? "  •  ADMIN" : ""}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => widget.onPick(e),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCalendarView extends StatefulWidget {
  const _EmployeeCalendarView({
    required this.employee,
    required this.onBack,
  });

  final Employee employee;
  final VoidCallback onBack;

  @override
  State<_EmployeeCalendarView> createState() => _EmployeeCalendarViewState();
}

class _EmployeeCalendarViewState extends State<_EmployeeCalendarView> {
  late DateTime _viewMonth;
  DateTime? _selectedDay;
  Future<List<Punch>>? _monthPunches;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _loadMonth();
  }

  void _loadMonth() {
    final state = context.read<AppState>();
    _monthPunches = state.fetchPunchesForMonth(
      _viewMonth,
      userId: widget.employee.userId,
    );
  }

  void _shiftMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta, 1);
      _selectedDay = null;
      _loadMonth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Header(
            employee: widget.employee,
            onBack: widget.onBack,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: FutureBuilder<List<Punch>>(
              future: _monthPunches,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Failed to load punches: ${snap.error}',
                        style: const TextStyle(color: Colors.grey)),
                  );
                }
                final punches = snap.data ?? <Punch>[];
                final byDay = _groupByDay(punches);

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _MonthNav(
                        month: _viewMonth,
                        onPrev: () => _shiftMonth(-1),
                        onNext: () => _shiftMonth(1),
                        totalPunches: punches.length,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _MonthGrid(
                        month: _viewMonth,
                        selectedDay: _selectedDay,
                        countsByDay: byDay.map(
                            (k, v) => MapEntry(k, v.length)),
                        onPick: (d) => setState(() => _selectedDay = d),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _DayPanel(
                        day: _selectedDay,
                        punches: _selectedDay == null
                            ? const <Punch>[]
                            : byDay[_dayKey(_selectedDay!)] ?? const <Punch>[],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _dayKey(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(d);

  Map<String, List<Punch>> _groupByDay(List<Punch> punches) {
    final map = <String, List<Punch>>{};
    for (final p in punches) {
      map.putIfAbsent(_dayKey(p.timestamp), () => <Punch>[]).add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    return map;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.employee, required this.onBack});
  final Employee employee;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final initial = (employee.name.isNotEmpty
            ? employee.name
            : employee.userId.isNotEmpty
                ? employee.userId
                : '?')
        .substring(0, 1)
        .toUpperCase();
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to employee list',
          onPressed: onBack,
        ),
        const SizedBox(width: AppSpacing.sm),
        CircleAvatar(child: Text(initial)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                employee.name.isNotEmpty ? employee.name : '(no name)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'user_id: ${employee.userId}'
                '${employee.isAdmin ? "  •  ADMIN" : ""}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthNav extends StatelessWidget {
  const _MonthNav({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.totalPunches,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final int totalPunches;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('MMMM y').format(month),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
          tooltip: 'Next month',
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$totalPunches punch${totalPunches == 1 ? "" : "es"}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDay,
    required this.countsByDay,
    required this.onPick,
  });

  final DateTime month;
  final DateTime? selectedDay;
  final Map<String, int> countsByDay;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = month.weekday; // 1=Mon..7=Sun
    final leadingBlanks = firstWeekday - 1;
    final totalCells =
        ((leadingBlanks + daysInMonth) / 7.0).ceil() * 7;
    final today = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);
    final selectedKey =
        selectedDay == null ? '' : DateFormat('yyyy-MM-dd').format(selectedDay!);

    final cells = <Widget>[];
    for (int i = 0; i < totalCells; i++) {
      final dayNum = i - leadingBlanks + 1;
      if (dayNum < 1 || dayNum > daysInMonth) {
        cells.add(const SizedBox.shrink());
        continue;
      }
      final date = DateTime(month.year, month.month, dayNum);
      final key = DateFormat('yyyy-MM-dd').format(date);
      final count = countsByDay[key] ?? 0;
      final isToday = key == todayKey;
      final isSelected = key == selectedKey;
      cells.add(_DayCell(
        day: dayNum,
        count: count,
        isToday: isToday,
        isSelected: isSelected,
        onTap: () => onPick(date),
      ));
    }

    final weekdayLabels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                for (final w in weekdayLabels)
                  Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
              children: cells,
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.count,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final int count;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPunches = count > 0;

    Color? bg;
    Color? border;
    if (isSelected) {
      bg = AppColors.brandPrimary.withValues(alpha: 0.15);
      border = AppColors.brandPrimary;
    } else if (isToday) {
      border = AppColors.brandPrimary.withValues(alpha: 0.5);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: border == null ? null : Border.all(color: border),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$day',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            if (hasPunches)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandAccent,
                  ),
                ),
              )
            else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.day, required this.punches});
  final DateTime? day;
  final List<Punch> punches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (day == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Pick a day on the calendar to see punches.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ),
      );
    }

    final dayLabel = DateFormat('EEEE, MMMM d, y').format(day!);
    if (punches.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(dayLabel, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text('No punches on this day.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor)),
            ],
          ),
        ),
      );
    }

    final first = punches.first.timestamp;
    final last = punches.last.timestamp;
    final spanMinutes =
        last.difference(first).inMinutes.clamp(0, 60 * 24);
    final spanHours = (spanMinutes / 60).toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(dayLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                        Text(
                          '${punches.length} punch'
                          '${punches.length == 1 ? "" : "es"} · '
                          'span ${spanHours}h',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            for (int i = 0; i < punches.length; i++)
              _PunchTile(
                punch: punches[i],
                kind: _kindFor(i, punches.length),
              ),
          ],
        ),
      ),
    );
  }

  _PunchKind _kindFor(int index, int total) {
    if (total == 1) return _PunchKind.single;
    if (index == 0) return _PunchKind.checkIn;
    if (index == total - 1) return _PunchKind.checkOut;
    return _PunchKind.mid;
  }
}

enum _PunchKind { checkIn, checkOut, mid, single }

class _PunchTile extends StatelessWidget {
  const _PunchTile({required this.punch, required this.kind});
  final Punch punch;
  final _PunchKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFmt = DateFormat('HH:mm:ss');
    final fullFmt = DateFormat('EEE, MMM d y · HH:mm:ss');

    return ExpansionTile(
      tilePadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      leading: _KindChip(kind: kind),
      title: Text(
        timeFmt.format(punch.timestamp),
        style: theme.textTheme.titleMedium?.copyWith(
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
      subtitle: Text(_kindLabel(kind),
          style:
              theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
      children: <Widget>[
        _DetailRow(
            label: 'Full timestamp', value: fullFmt.format(punch.timestamp)),
        _DetailRow(label: 'User id', value: punch.userId),
        _DetailRow(
            label: 'Derived',
            value: '$_PunchKind.${kind.name} '
                '(by order within the day)'),
        _DetailRow(
          label: 'raw_status',
          value: '${punch.rawStatus}',
          hint: 'Device-reported status code (sticky-key bug — '
              'ignored by derivation)',
        ),
        _DetailRow(
          label: 'raw_punch',
          value: '${punch.rawPunch}',
          hint: 'Device-reported punch type (sticky-key bug — '
              'ignored by derivation)',
        ),
      ],
    );
  }

  String _kindLabel(_PunchKind k) {
    switch (k) {
      case _PunchKind.checkIn:
        return 'Check-in (first punch of the day)';
      case _PunchKind.checkOut:
        return 'Check-out (last punch of the day)';
      case _PunchKind.mid:
        return 'Mid-day punch';
      case _PunchKind.single:
        return 'Only punch on this day';
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.hint,
  });

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SelectableText(value, style: theme.textTheme.bodyMedium),
                if (hint != null)
                  Text(hint!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontStyle: FontStyle.italic,
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind});
  final _PunchKind kind;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (kind) {
      case _PunchKind.checkIn:
        label = 'In';
        color = AppColors.success;
        break;
      case _PunchKind.checkOut:
        label = 'Out';
        color = AppColors.error;
        break;
      case _PunchKind.mid:
        label = 'Mid';
        color = AppColors.warning;
        break;
      case _PunchKind.single:
        label = 'Only';
        color = AppColors.brandPrimary;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
