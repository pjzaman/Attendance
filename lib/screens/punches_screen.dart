import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../models/punch.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_row.dart';

class PunchesScreen extends StatefulWidget {
  const PunchesScreen({super.key});

  @override
  State<PunchesScreen> createState() => _PunchesScreenState();
}

class _PunchesScreenState extends State<PunchesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _showRaw = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final punches = state.recentPunches;

    if (punches.isEmpty) {
      return const EmptyState(
        icon: Icons.fingerprint,
        title: 'No punches yet',
        message: 'Run a sync to pull punches from the device.',
      );
    }

    final employees = <String, Employee>{
      for (final e in state.employees) e.userId: e,
    };

    final filtered = _filter(punches, employees, _query);
    final groups = _groupByDay(filtered);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FilterRow(
            searchController: _searchCtrl,
            onSearchChanged: (v) => setState(() => _query = v.trim()),
            searchHint: 'Search by name or user id…',
            onShowView: () => _openViewDrawer(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _query.isEmpty
                ? 'Showing ${punches.length} most recent (of ${state.totalPunches} total)'
                : '${filtered.length} match${filtered.length == 1 ? "" : "es"} '
                    'in ${punches.length} loaded',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: groups.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'No punches match this search',
                    message: 'Try a different name or user id.',
                  )
                : Card(
                    child: ListView.builder(
                      itemCount: groups.length,
                      itemBuilder: (context, i) => _DaySection(
                        group: groups[i],
                        employees: employees,
                        showRaw: _showRaw,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openViewDrawer(BuildContext context) async {
    final result = await showDetailDrawer<bool>(
      context,
      child: _ViewOptionsDrawer(initialShowRaw: _showRaw),
    );
    if (result != null && mounted) {
      setState(() => _showRaw = result);
    }
  }

  List<Punch> _filter(
    List<Punch> punches,
    Map<String, Employee> employees,
    String query,
  ) {
    if (query.isEmpty) return punches;
    final q = query.toLowerCase();
    return punches.where((p) {
      if (p.userId.toLowerCase().contains(q)) return true;
      final name = employees[p.userId]?.name.toLowerCase() ?? '';
      return name.contains(q);
    }).toList();
  }

  List<_DayGroup> _groupByDay(List<Punch> punches) {
    final map = <String, List<Punch>>{};
    for (final p in punches) {
      final key = DateFormat('yyyy-MM-dd').format(p.timestamp);
      map.putIfAbsent(key, () => <Punch>[]).add(p);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries.map((e) {
      final sorted = [...e.value]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return _DayGroup(date: DateTime.parse(e.key), punches: sorted);
    }).toList();
  }
}

class _DayGroup {
  _DayGroup({required this.date, required this.punches});
  final DateTime date;
  final List<Punch> punches;
}

class _ViewOptionsDrawer extends StatefulWidget {
  const _ViewOptionsDrawer({required this.initialShowRaw});
  final bool initialShowRaw;

  @override
  State<_ViewOptionsDrawer> createState() => _ViewOptionsDrawerState();
}

class _ViewOptionsDrawerState extends State<_ViewOptionsDrawer> {
  late bool _showRaw = widget.initialShowRaw;

  @override
  Widget build(BuildContext context) {
    return DetailDrawer(
      title: 'View options',
      subtitle: 'Choose what columns to show on each row',
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop<bool>(_showRaw),
          child: const Text('Apply'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SwitchListTile(
            title: const Text('Show raw device fields'),
            subtitle: const Text(
              'Surfaces raw_status and raw_punch on every row. '
              'Useful for debugging the sticky-key bug; off by default.',
            ),
            value: _showRaw,
            onChanged: (v) => setState(() => _showRaw = v),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.group,
    required this.employees,
    required this.showRaw,
  });

  final _DayGroup group;
  final Map<String, Employee> employees;
  final bool showRaw;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFmt = DateFormat('HH:mm');

    final byUser = <String, List<Punch>>{};
    for (final p in group.punches) {
      byUser.putIfAbsent(p.userId, () => <Punch>[]).add(p);
    }
    final firstByUser = <String, DateTime>{
      for (final e in byUser.entries) e.key: e.value.first.timestamp,
    };
    final lastByUser = <String, DateTime>{
      for (final e in byUser.entries) e.key: e.value.last.timestamp,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.4),
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: <Widget>[
              Text(
                _dayLabel(group.date),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '· ${group.punches.length} punch'
                '${group.punches.length == 1 ? "" : "es"} · '
                '${byUser.length} user${byUser.length == 1 ? "" : "s"}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
        for (int i = 0; i < group.punches.length; i++)
          _PunchRow(
            punch: group.punches[i],
            employee: employees[group.punches[i].userId],
            kind: _kindFor(
              group.punches[i],
              firstByUser[group.punches[i].userId]!,
              lastByUser[group.punches[i].userId]!,
              byUser[group.punches[i].userId]!.length,
            ),
            timeText: timeFmt.format(group.punches[i].timestamp),
            showRaw: showRaw,
            isLast: i == group.punches.length - 1,
          ),
      ],
    );
  }

  _PunchKind _kindFor(Punch p, DateTime first, DateTime last, int count) {
    if (count == 1) return _PunchKind.single;
    if (p.timestamp == first) return _PunchKind.checkIn;
    if (p.timestamp == last) return _PunchKind.checkOut;
    return _PunchKind.mid;
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dDay = DateTime(d.year, d.month, d.day);
    final diff = today.difference(dDay).inDays;
    final weekdayDate = DateFormat('EEE MMM d').format(d);
    if (diff == 0) return 'Today · $weekdayDate';
    if (diff == 1) return 'Yesterday · $weekdayDate';
    return DateFormat('EEE MMM d, y').format(d);
  }
}

enum _PunchKind { checkIn, checkOut, mid, single }

class _PunchRow extends StatelessWidget {
  const _PunchRow({
    required this.punch,
    required this.employee,
    required this.kind,
    required this.timeText,
    required this.showRaw,
    required this.isLast,
  });

  final Punch punch;
  final Employee? employee;
  final _PunchKind kind;
  final String timeText;
  final bool showRaw;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = employee?.name.isNotEmpty == true
        ? employee!.name
        : '(unknown user)';
    final initial = name.substring(0, 1).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          child: Text(initial, style: const TextStyle(fontSize: 13)),
        ),
        title: Row(
          children: <Widget>[
            Flexible(
              child: Text(name, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: AppSpacing.sm),
            _KindChip(kind: kind),
          ],
        ),
        subtitle: Text(
          showRaw
              ? 'id ${punch.userId}  •  raw_status=${punch.rawStatus}  '
                  'raw_punch=${punch.rawPunch}'
              : 'id ${punch.userId}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          timeText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
