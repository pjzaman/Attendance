import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

class SessionEditorResult {
  SessionEditorResult({this.saved, this.deletedId});
  final Session? saved;
  final String? deletedId;
}

class SessionEditorDrawer extends StatefulWidget {
  const SessionEditorDrawer({
    super.key,
    this.initial,
    this.fixedType,
  });

  final Session? initial;
  final SessionType? fixedType;

  @override
  State<SessionEditorDrawer> createState() => _SessionEditorDrawerState();
}

class _SessionEditorDrawerState extends State<SessionEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late SessionType _type;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isActive;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _type = s?.type ?? widget.fixedType ?? SessionType.leave;
    final now = DateTime.now();
    _startDate = s?.startDate ?? DateTime(now.year, 1, 1);
    _endDate = s?.endDate ?? DateTime(now.year, 12, 31);
    _isActive = s?.isActive ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      !_endDate.isBefore(_startDate);

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      final d = DateUtils.dateOnly(picked);
      if (isStart) {
        _startDate = d;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = d;
      }
    });
  }

  void _save() {
    final base = widget.initial;
    final session = Session(
      id: base?.id ?? 'sess_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      type: _type,
      startDate: _startDate,
      endDate: _endDate,
      isActive: _isActive,
    );
    Navigator.of(context).pop(SessionEditorResult(saved: session));
  }

  Future<void> _confirmDelete() async {
    final s = widget.initial;
    if (s == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete session?'),
        content: Text(
          'Removing "${s.name}" cannot be undone. If this is the active '
          'session, the surface using it will fall back to no-session '
          'behavior until another is activated.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.statusDanger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop(SessionEditorResult(deletedId: s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, y');

    return DetailDrawer(
      title: _isEdit ? 'Edit session' : 'New session',
      subtitle: _isEdit
          ? 'Edits apply to surfaces that read this session live.'
          : 'A session is a named period (calendar year, fiscal quarter, etc.).',
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
          const _SectionLabel('Name'),
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. Calendar Year 2026',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Type'),
          SegmentedButton<SessionType>(
            segments: const <ButtonSegment<SessionType>>[
              ButtonSegment(
                value: SessionType.leave,
                icon: Icon(Icons.beach_access_outlined, size: 16),
                label: Text('Leave'),
              ),
              ButtonSegment(
                value: SessionType.payroll,
                icon: Icon(Icons.payments_outlined, size: 16),
                label: Text('Payroll'),
              ),
            ],
            selected: <SessionType>{_type},
            onSelectionChanged: widget.fixedType != null
                ? null
                : (s) => setState(() => _type = s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Period'),
          Row(
            children: <Widget>[
              Expanded(
                child: _DateTile(
                  label: 'Start',
                  value: dateFmt.format(_startDate),
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DateTile(
                  label: 'End',
                  value: dateFmt.format(_endDate),
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          if (_endDate.isBefore(_startDate))
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'End date is before start date.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.statusDanger),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Active'),
            subtitle: const Text(
              'Activating this session will deactivate any other session '
              'of the same type. Only one active per type at a time.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
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

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

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
            Icon(Icons.calendar_today_outlined,
                size: 16, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
