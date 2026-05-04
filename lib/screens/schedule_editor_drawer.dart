import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/employee.dart';
import '../models/schedule.dart';
import '../models/shift.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

/// Result returned from the editor: caller picks the action and updates
/// state accordingly. Null = drawer dismissed without saving.
class ScheduleEditorResult {
  ScheduleEditorResult({this.saved, this.deletedId});
  final Schedule? saved;
  final String? deletedId;
}

class ScheduleEditorDrawer extends StatefulWidget {
  const ScheduleEditorDrawer({
    super.key,
    required this.shifts,
    required this.allEmployees,
    this.initial,
  });

  /// `null` = create mode.
  final Schedule? initial;
  final List<Shift> shifts;
  final List<Employee> allEmployees;

  @override
  State<ScheduleEditorDrawer> createState() => _ScheduleEditorDrawerState();
}

class _ScheduleEditorDrawerState extends State<ScheduleEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late String? _shiftId;
  late Set<int> _workDays;
  late DateTime _startDate;
  late DateTime? _endDate;
  late bool _includeHolidays;
  late Set<String> _assigned;
  late ScheduleStatus _status;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _shiftId = s?.shiftId ??
        (widget.shifts.isNotEmpty ? widget.shifts.first.id : null);
    _workDays = <int>{
      ...(s?.workDays ?? const <int>{1, 2, 3, 4, 6, 7}),
    };
    _startDate = s?.startDate ?? DateUtils.dateOnly(DateTime.now());
    _endDate = s?.endDate;
    _includeHolidays = s?.includeHolidays ?? false;
    _assigned = <String>{...?s?.assignedUserIds};
    _status = s?.status ?? ScheduleStatus.draft;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _shiftId != null &&
      _workDays.isNotEmpty;

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateUtils.dateOnly(picked);
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = DateUtils.dateOnly(picked));
    }
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final base = widget.initial;
    final newSchedule = Schedule(
      id: base?.id ?? 'sched_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      shiftId: _shiftId!,
      workDays: <int>{..._workDays},
      startDate: _startDate,
      endDate: _endDate,
      includeHolidays: _includeHolidays,
      assignedUserIds: _assigned.toList()..sort(),
      status: _status,
    );
    Navigator.of(context).pop(ScheduleEditorResult(saved: newSchedule));
  }

  Future<void> _confirmDelete() async {
    final id = widget.initial?.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: Text(
          'This will remove "${widget.initial!.name}" and unassign all '
          '${widget.initial!.assignedUserIds.length} employee(s). '
          'This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.statusDanger,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop(ScheduleEditorResult(deletedId: id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, y');

    return DetailDrawer(
      title: _isEdit ? 'Edit schedule' : 'New schedule',
      subtitle: _isEdit
          ? 'Changes save immediately when you click Save'
          : 'Drafts can be published later from the Schedules tab',
      actions: <Widget>[
        if (_isEdit)
          TextButton(
            onPressed: _confirmDelete,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.statusDanger,
            ),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _SectionLabel('Schedule name'),
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. Morning Roster',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Shift'),
          DropdownButtonFormField<String>(
            initialValue: _shiftId,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            items: <DropdownMenuItem<String>>[
              for (final s in widget.shifts)
                DropdownMenuItem(
                  value: s.id,
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('${s.name}  ·  ${s.formatRange()}'),
                    ],
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _shiftId = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Working days'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (int wd = 1; wd <= 7; wd++)
                FilterChip(
                  label: Text(_weekdayShort(wd)),
                  selected: _workDays.contains(wd),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _workDays.add(wd);
                    } else {
                      _workDays.remove(wd);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Effective dates'),
          Row(
            children: <Widget>[
              Expanded(
                child: _DatePickerTile(
                  label: 'Start',
                  value: dateFmt.format(_startDate),
                  onTap: _pickStart,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DatePickerTile(
                  label: 'End',
                  value: _endDate == null ? '— optional —' : dateFmt.format(_endDate!),
                  onTap: _pickEnd,
                  trailing: _endDate == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          tooltip: 'Clear end date',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => _endDate = null),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            value: _includeHolidays,
            onChanged: (v) => setState(() => _includeHolidays = v),
            title: const Text('Include public holidays'),
            subtitle: const Text(
              'Otherwise public holidays are skipped on assigned days.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Status'),
          SegmentedButton<ScheduleStatus>(
            segments: const <ButtonSegment<ScheduleStatus>>[
              ButtonSegment(
                value: ScheduleStatus.draft,
                icon: Icon(Icons.edit_note, size: 16),
                label: Text('Draft'),
              ),
              ButtonSegment(
                value: ScheduleStatus.published,
                icon: Icon(Icons.check_circle_outline, size: 16),
                label: Text('Published'),
              ),
            ],
            selected: <ScheduleStatus>{_status},
            onSelectionChanged: (s) => setState(() => _status = s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(
              'Assigned employees · ${_assigned.length} of ${widget.allEmployees.length}'),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.allEmployees.length,
              itemBuilder: (context, i) {
                final e = widget.allEmployees[i];
                final selected = _assigned.contains(e.userId);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _assigned.add(e.userId);
                    } else {
                      _assigned.remove(e.userId);
                    }
                  }),
                  title: Text(
                    e.name.isNotEmpty
                        ? '${e.name}  (id ${e.userId})'
                        : 'id ${e.userId}',
                  ),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayShort(int wd) {
    const labels = <int, String>{
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return labels[wd] ?? '?';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 2),
                  Text(value),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(Icons.calendar_today_outlined,
                  size: 16, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
