import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/employee.dart';
import '../models/leave_type.dart';
import '../models/request.dart';
import '../models/shift.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

class RequestEditorDrawer extends StatefulWidget {
  const RequestEditorDrawer({
    super.key,
    required this.type,
    required this.allEmployees,
    required this.shifts,
    this.leaveTypes = const <LeaveType>[],
  });

  final RequestType type;
  final List<Employee> allEmployees;
  final List<Shift> shifts;
  final List<LeaveType> leaveTypes;

  @override
  State<RequestEditorDrawer> createState() => _RequestEditorDrawerState();
}

class _RequestEditorDrawerState extends State<RequestEditorDrawer> {
  Employee? _employee;
  late DateTime _fromDate;
  DateTime? _toDate;
  final TextEditingController _reasonCtrl = TextEditingController();

  // Type-specific
  String? _leaveType;
  String? _shiftId;
  TimeOfDay? _checkIn;
  TimeOfDay? _checkOut;

  @override
  void initState() {
    super.initState();
    _fromDate = DateUtils.dateOnly(DateTime.now());
    _shiftId = widget.shifts.isNotEmpty ? widget.shifts.first.id : null;
    _leaveType =
        widget.leaveTypes.isNotEmpty ? widget.leaveTypes.first.id : null;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_employee == null) return false;
    if (_reasonCtrl.text.trim().isEmpty) return false;
    if (widget.type == RequestType.leave && _leaveType == null) return false;
    return true;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _fromDate : (_toDate ?? _fromDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      final d = DateUtils.dateOnly(picked);
      if (isFrom) {
        _fromDate = d;
        if (_toDate != null && _toDate!.isBefore(_fromDate)) _toDate = null;
      } else {
        _toDate = d;
      }
    });
  }

  Future<void> _pickTime({required bool isCheckIn}) async {
    final initial = (isCheckIn ? _checkIn : _checkOut) ??
        const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
      } else {
        _checkOut = picked;
      }
    });
  }

  void _save() {
    DateTime? combineWithDate(TimeOfDay? t) {
      if (t == null) return null;
      return DateTime(
        _fromDate.year,
        _fromDate.month,
        _fromDate.day,
        t.hour,
        t.minute,
      );
    }

    final r = Request(
      id: 'req_${DateTime.now().microsecondsSinceEpoch}',
      type: widget.type,
      requesterUserId: _employee!.userId,
      fromDate: _fromDate,
      toDate: _toDate,
      reason: _reasonCtrl.text.trim(),
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      leaveType:
          widget.type == RequestType.leave ? _leaveType : null,
      shiftId:
          widget.type == RequestType.attendance ? _shiftId : null,
      checkIn: widget.type == RequestType.attendance
          ? combineWithDate(_checkIn)
          : null,
      checkOut: widget.type == RequestType.attendance
          ? combineWithDate(_checkOut)
          : null,
    );
    Navigator.of(context).pop(r);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, y');
    final showRange = widget.type == RequestType.leave ||
        widget.type == RequestType.separation;

    return DetailDrawer(
      title: 'New ${widget.type.label.toLowerCase()} request',
      subtitle: 'Submit a ${widget.type.label.toLowerCase()} request '
          'on behalf of an employee',
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSave ? _save : null,
          child: const Text('Submit'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _SectionLabel('Employee'),
          DropdownButtonFormField<Employee>(
            initialValue: _employee,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Pick an employee',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            items: <DropdownMenuItem<Employee>>[
              for (final e in widget.allEmployees)
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
            onChanged: (e) => setState(() => _employee = e),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (showRange) ...<Widget>[
            const _SectionLabel('Dates'),
            Row(
              children: <Widget>[
                Expanded(
                  child: _DateTile(
                    label: 'From',
                    value: dateFmt.format(_fromDate),
                    onTap: () => _pickDate(isFrom: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _DateTile(
                    label: 'To',
                    value: _toDate == null
                        ? '— same day —'
                        : dateFmt.format(_toDate!),
                    onTap: () => _pickDate(isFrom: false),
                    trailing: _toDate == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            tooltip: 'Clear',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _toDate = null),
                          ),
                  ),
                ),
              ],
            ),
          ] else ...<Widget>[
            const _SectionLabel('Date'),
            _DateTile(
              label: widget.type == RequestType.payslip ? 'Pay period' : 'Date',
              value: dateFmt.format(_fromDate),
              onTap: () => _pickDate(isFrom: true),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (widget.type == RequestType.attendance) ...<Widget>[
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
            const SizedBox(height: AppSpacing.md),
            const _SectionLabel('Proposed times (optional)'),
            Row(
              children: <Widget>[
                Expanded(
                  child: _TimeTile(
                    label: 'Check-in',
                    value: _checkIn == null ? '— optional —' : _formatTod(_checkIn!),
                    onTap: () => _pickTime(isCheckIn: true),
                    onClear: _checkIn == null
                        ? null
                        : () => setState(() => _checkIn = null),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TimeTile(
                    label: 'Check-out',
                    value: _checkOut == null ? '— optional —' : _formatTod(_checkOut!),
                    onTap: () => _pickTime(isCheckIn: false),
                    onClear: _checkOut == null
                        ? null
                        : () => setState(() => _checkOut = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (widget.type == RequestType.leave) ...<Widget>[
            const _SectionLabel('Leave type'),
            DropdownButtonFormField<String>(
              initialValue: _leaveType,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                hintText: widget.leaveTypes.isEmpty
                    ? 'No leave types — set them up in Settings → Leave Types'
                    : null,
              ),
              items: <DropdownMenuItem<String>>[
                for (final t in widget.leaveTypes)
                  DropdownMenuItem(
                    value: t.id,
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.shiftColorFor(t.id),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            '${t.name}'
                            '${t.defaultDaysPerYear > 0 ? "  ·  ${t.defaultDaysPerYear} d/yr" : ""}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _leaveType = v),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          const _SectionLabel('Reason'),
          TextField(
            controller: _reasonCtrl,
            onChanged: (_) => setState(() {}),
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'Why is this request being made?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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

class _DateTile extends StatelessWidget {
  const _DateTile({
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
                  Text(label,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
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

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

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
                  Text(label,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      )),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 16),
                tooltip: 'Clear',
                visualDensity: VisualDensity.compact,
                onPressed: onClear,
              )
            else
              Icon(Icons.access_time, size: 16, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
