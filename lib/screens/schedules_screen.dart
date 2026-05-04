import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/schedule.dart';
import '../models/shift.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';
import '../widgets/duty_roster_grid.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_row.dart';
import '../widgets/schedule_list_item.dart';
import '../widgets/shift_list_item.dart';
import '../widgets/status_pill.dart';
import 'schedule_editor_drawer.dart';
import 'shift_editor_drawer.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen>
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
        icon: Icons.schedule_outlined,
        title: 'No employees yet',
        message:
            'Schedules need employees first. Run a sync to pull them from the device.',
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
              Tab(text: 'Schedules'),
              Tab(text: 'Duty Roster'),
              Tab(text: 'Shifts'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: <Widget>[
                _SchedulesList(state: state),
                _DutyRoster(state: state),
                _ShiftsList(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Schedules tab ───────────────────────────────────────────────────

class _SchedulesList extends StatelessWidget {
  const _SchedulesList({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shifts = state.shifts;
    final schedules = state.schedules;
    final shiftById = <String, Shift>{for (final s in shifts) s.id: s};
    final drafts = schedules.where((s) => s.isDraft).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: shifts.isEmpty
                ? null
                : () => _openEditor(context, state, null),
            newLabel: 'New schedule',
          ),
          const SizedBox(height: AppSpacing.md),
          if (drafts.isNotEmpty) ...<Widget>[
            _PublishBanner(
              count: drafts.length,
              onPublishAll: () => state.publishAllDrafts(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (schedules.isEmpty)
            const EmptyState(
              icon: Icons.event_note_outlined,
              title: 'No schedules yet',
              message:
                  'Create one to assign a shift to a group of employees.',
            )
          else
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: <Widget>[
                        Text('All schedules',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '· ${schedules.length}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  for (int i = 0; i < schedules.length; i++) ...<Widget>[
                    ScheduleListItem(
                      schedule: schedules[i],
                      shift: shiftById[schedules[i].shiftId] ??
                          (shifts.isNotEmpty
                              ? shifts.first
                              : _placeholderShift(schedules[i].shiftId)),
                      onTap: () =>
                          _openEditor(context, state, schedules[i]),
                    ),
                    if (i < schedules.length - 1)
                      Divider(height: 1, color: theme.dividerColor),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Shift _placeholderShift(String id) => Shift(
        id: id,
        name: '(missing shift)',
        code: '?',
        start: const TimeOfDay(hour: 0, minute: 0),
        end: const TimeOfDay(hour: 0, minute: 0),
      );

  Future<void> _openEditor(
    BuildContext context,
    AppState state,
    Schedule? initial,
  ) async {
    final result = await showDetailDrawer<ScheduleEditorResult>(
      context,
      width: 560,
      child: ScheduleEditorDrawer(
        shifts: state.shifts,
        allEmployees: state.employees,
        initial: initial,
      ),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteSchedule(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertSchedule(result.saved!);
    }
  }
}

class _PublishBanner extends StatelessWidget {
  const _PublishBanner({required this.count, required this.onPublishAll});
  final int count;
  final VoidCallback onPublishAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusWarning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.statusWarning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.schedule_send_outlined,
              color: AppColors.statusWarning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$count schedule${count == 1 ? "" : "s"} waiting to be published',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const StatusPill(
              label: 'Draft', tone: StatusTone.warning, dense: true),
          const SizedBox(width: AppSpacing.md),
          FilledButton.icon(
            onPressed: onPublishAll,
            icon: const Icon(Icons.publish_outlined, size: 16),
            label: Text('Publish all ($count)'),
          ),
        ],
      ),
    );
  }
}

// ─── Duty Roster tab ─────────────────────────────────────────────────

class _DutyRoster extends StatefulWidget {
  const _DutyRoster({required this.state});
  final AppState state;

  @override
  State<_DutyRoster> createState() => _DutyRosterState();
}

class _DutyRosterState extends State<_DutyRoster> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  static DateTime _mondayOf(DateTime d) {
    final base = DateUtils.dateOnly(d);
    return base.subtract(Duration(days: base.weekday - DateTime.monday));
  }

  void _shiftWeek(int days) {
    setState(() => _weekStart = _weekStart.add(Duration(days: days)));
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final isThisWeek =
        DateUtils.isSameDay(_weekStart, _mondayOf(DateTime.now()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _WeekNav(
          weekStart: _weekStart,
          weekEnd: weekEnd,
          isThisWeek: isThisWeek,
          onPrev: () => _shiftWeek(-7),
          onNext: () => _shiftWeek(7),
          onThisWeek: () =>
              setState(() => _weekStart = _mondayOf(DateTime.now())),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 200 + 7 * 116,
              child: DutyRosterGrid(
                employees: widget.state.employees,
                schedules: widget.state.schedules,
                shifts: widget.state.shifts,
                weekStart: _weekStart,
                daily: widget.state.daily,
                holidays: widget.state.holidays,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekNav extends StatelessWidget {
  const _WeekNav({
    required this.weekStart,
    required this.weekEnd,
    required this.isThisWeek,
    required this.onPrev,
    required this.onNext,
    required this.onThisWeek,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final bool isThisWeek;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onThisWeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d');
    final yearFmt = DateFormat('y');
    final spans = weekStart.year == weekEnd.year
        ? '${fmt.format(weekStart)} – ${fmt.format(weekEnd)}, ${yearFmt.format(weekStart)}'
        : '${fmt.format(weekStart)}, ${yearFmt.format(weekStart)} – ${fmt.format(weekEnd)}, ${yearFmt.format(weekEnd)}';

    return Row(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                tooltip: 'Previous week',
                visualDensity: VisualDensity.compact,
                onPressed: onPrev,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  spans,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                tooltip: 'Next week',
                visualDensity: VisualDensity.compact,
                onPressed: onNext,
              ),
              Container(
                width: 1,
                height: 24,
                color: theme.dividerColor,
              ),
              TextButton(
                onPressed: isThisWeek ? null : onThisWeek,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
                child: const Text('This week',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shifts tab ──────────────────────────────────────────────────────

class _ShiftsList extends StatelessWidget {
  const _ShiftsList({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shifts = state.shifts;
    final usageByShiftId = <String, int>{};
    for (final s in state.schedules) {
      usageByShiftId.update(s.shiftId, (n) => n + 1, ifAbsent: () => 1);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: () => _openEditor(context, state, null),
            newLabel: 'New shift',
          ),
          const SizedBox(height: AppSpacing.md),
          if (shifts.isEmpty)
            const EmptyState(
              icon: Icons.schedule_outlined,
              title: 'No shifts yet',
              message:
                  'Create a shift to define a working time window. '
                  'Schedules use shifts to assign hours to employees.',
            )
          else
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: <Widget>[
                        Text('All shifts',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '· ${shifts.length}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  for (int i = 0; i < shifts.length; i++) ...<Widget>[
                    ShiftListItem(
                      shift: shifts[i],
                      scheduleCount: usageByShiftId[shifts[i].id] ?? 0,
                      onTap: () => _openEditor(context, state, shifts[i]),
                    ),
                    if (i < shifts.length - 1)
                      Divider(height: 1, color: theme.dividerColor),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    AppState state,
    Shift? initial,
  ) async {
    final usage = initial == null
        ? 0
        : state.schedules
            .where((s) => s.shiftId == initial.id)
            .length;
    final result = await showDetailDrawer<ShiftEditorResult>(
      context,
      width: 520,
      child: ShiftEditorDrawer(
        initial: initial,
        dependentScheduleCount: usage,
      ),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteShift(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertShift(result.saved!);
    }
  }
}
