import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/daily_summary.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/app_data_table.dart';
import '../widgets/detail_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_row.dart';
import '../widgets/status_pill.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Set<AttendanceStatus> _statusFilter = AttendanceStatus.values.toSet();

  static final _dateFmt = DateFormat('yyyy-MM-dd');
  static final _timeFmt = DateFormat('HH:mm');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daily = context.watch<AppState>().daily;
    if (daily.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'No daily summaries yet',
        message: 'Run a sync to derive daily summaries from punches.',
      );
    }

    final filtered = _filter(daily);
    final activeFilters = _activeFilterCount();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            searchController: _searchCtrl,
            onSearchChanged: (v) => setState(() => _query = v.trim()),
            searchHint: 'Search by user id…',
            onShowFilters: () => _openFilters(context),
            activeFilterCount: activeFilters,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _query.isEmpty && activeFilters == 0
                ? '${daily.length} day-summar'
                    '${daily.length == 1 ? "y" : "ies"}'
                : '${filtered.length} of ${daily.length} shown',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: AppDataTable<DailySummary>(
              rows: filtered,
              initialSortColumnId: 'date',
              initialSortAscending: false,
              emptyState: const EmptyState(
                icon: Icons.search_off,
                title: 'No summaries match',
                message: 'Try a different search or clear the filters.',
              ),
              columns: <DataColumnDef<DailySummary>>[
                DataColumnDef<DailySummary>(
                  id: 'date',
                  label: 'Date',
                  sortKey: (d) => d.date.toIso8601String(),
                  cell: (_, d) => Text(_dateFmt.format(d.date)),
                  width: 120,
                ),
                DataColumnDef<DailySummary>(
                  id: 'user',
                  label: 'User',
                  sortKey: (d) => d.userId,
                  cell: (_, d) => Text(d.userId),
                  width: 110,
                ),
                DataColumnDef<DailySummary>(
                  id: 'check_in',
                  label: 'In',
                  sortKey: (d) => d.checkIn?.toIso8601String() ?? '',
                  cell: (_, d) => Text(
                    d.checkIn != null ? _timeFmt.format(d.checkIn!) : '—',
                  ),
                  width: 80,
                ),
                DataColumnDef<DailySummary>(
                  id: 'check_out',
                  label: 'Out',
                  sortKey: (d) => d.checkOut?.toIso8601String() ?? '',
                  cell: (_, d) => Text(
                    d.checkOut != null ? _timeFmt.format(d.checkOut!) : '—',
                  ),
                  width: 80,
                ),
                DataColumnDef<DailySummary>(
                  id: 'hours',
                  label: 'Hours',
                  numeric: true,
                  sortKey: (d) => d.workedMinutes,
                  cell: (_, d) =>
                      Text((d.workedMinutes / 60).toStringAsFixed(2)),
                  width: 90,
                ),
                DataColumnDef<DailySummary>(
                  id: 'status',
                  label: 'Status',
                  sortKey: (d) => d.status.wireValue,
                  cell: (_, d) => StatusPill(
                    label: _statusLabel(d.status),
                    tone: _statusTone(d.status),
                    dense: true,
                  ),
                  width: 110,
                ),
                DataColumnDef<DailySummary>(
                  id: 'notes',
                  label: 'Notes',
                  sortKey: null,
                  cell: (_, d) => Text(
                    d.notes,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<DailySummary> _filter(List<DailySummary> rows) {
    final q = _query.toLowerCase();
    return rows.where((d) {
      if (!_statusFilter.contains(d.status)) return false;
      if (q.isEmpty) return true;
      return d.userId.toLowerCase().contains(q);
    }).toList();
  }

  int _activeFilterCount() {
    return _statusFilter.length == AttendanceStatus.values.length ? 0 : 1;
  }

  Future<void> _openFilters(BuildContext context) async {
    final result = await showDetailDrawer<Set<AttendanceStatus>>(
      context,
      child: _DailyFiltersDrawer(initial: _statusFilter),
    );
    if (result != null && mounted) {
      setState(() => _statusFilter = result);
    }
  }

  static String _statusLabel(AttendanceStatus s) {
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

  static StatusTone _statusTone(AttendanceStatus s) {
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
}

class _DailyFiltersDrawer extends StatefulWidget {
  const _DailyFiltersDrawer({required this.initial});
  final Set<AttendanceStatus> initial;

  @override
  State<_DailyFiltersDrawer> createState() => _DailyFiltersDrawerState();
}

class _DailyFiltersDrawerState extends State<_DailyFiltersDrawer> {
  late Set<AttendanceStatus> _selected = <AttendanceStatus>{...widget.initial};

  @override
  Widget build(BuildContext context) {
    return DetailDrawer(
      title: 'Filters',
      subtitle: 'Show only the statuses you care about',
      actions: <Widget>[
        TextButton(
          onPressed: () => setState(
              () => _selected = AttendanceStatus.values.toSet()),
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop<Set<AttendanceStatus>>(_selected),
          child: const Text('Apply'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Status',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final s in AttendanceStatus.values)
            CheckboxListTile(
              value: _selected.contains(s),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selected.add(s);
                } else {
                  _selected.remove(s);
                }
              }),
              title: Text(_DailyScreenState._statusLabel(s)),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
    );
  }
}
