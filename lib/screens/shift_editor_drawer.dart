import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

/// Result returned from the shift editor.
class ShiftEditorResult {
  ShiftEditorResult({this.saved, this.deletedId});
  final Shift? saved;
  final String? deletedId;
}

class ShiftEditorDrawer extends StatefulWidget {
  const ShiftEditorDrawer({
    super.key,
    this.initial,
    this.dependentScheduleCount = 0,
  });

  /// `null` = create mode.
  final Shift? initial;

  /// How many schedules currently use this shift. Surfaced in the
  /// delete confirmation so the user knows the impact.
  final int dependentScheduleCount;

  @override
  State<ShiftEditorDrawer> createState() => _ShiftEditorDrawerState();
}

class _ShiftEditorDrawerState extends State<ShiftEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _breakCtrl;
  late TimeOfDay _start;
  late TimeOfDay _end;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _codeCtrl = TextEditingController(text: s?.code ?? '');
    _breakCtrl = TextEditingController(
      text: (s?.breakMinutes ?? 0).toString(),
    );
    _start = s?.start ?? const TimeOfDay(hour: 9, minute: 0);
    _end = s?.end ?? const TimeOfDay(hour: 17, minute: 0);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _breakCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _codeCtrl.text.trim().isNotEmpty &&
      int.tryParse(_breakCtrl.text.trim()) != null;

  int get _workMinutes {
    final s = _start.hour * 60 + _start.minute;
    final e = _end.hour * 60 + _end.minute;
    final raw = e <= s ? (e + 24 * 60 - s) : (e - s);
    final breakM = int.tryParse(_breakCtrl.text.trim()) ?? 0;
    return raw - breakM;
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _start,
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _end,
    );
    if (picked != null) setState(() => _end = picked);
  }

  void _save() {
    final base = widget.initial;
    final breakM = int.tryParse(_breakCtrl.text.trim()) ?? 0;
    final newShift = Shift(
      id: base?.id ?? 'shift_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      code: _codeCtrl.text.trim().toUpperCase(),
      start: _start,
      end: _end,
      breakMinutes: breakM,
    );
    Navigator.of(context).pop(ShiftEditorResult(saved: newShift));
  }

  Future<void> _confirmDelete() async {
    final s = widget.initial;
    if (s == null) return;
    final blocked = widget.dependentScheduleCount > 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(blocked ? 'Cannot delete shift' : 'Delete shift?'),
        content: Text(
          blocked
              ? '"${s.name}" is used by ${widget.dependentScheduleCount} '
                  'schedule${widget.dependentScheduleCount == 1 ? "" : "s"}. '
                  'Reassign or delete those first.'
              : 'This will permanently remove "${s.name}". '
                  'This cannot be undone.',
        ),
        actions: <Widget>[
          if (!blocked)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          if (blocked)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('OK'),
            )
          else
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
      Navigator.of(context).pop(ShiftEditorResult(deletedId: s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = (_workMinutes / 60).toStringAsFixed(2);

    return DetailDrawer(
      title: _isEdit ? 'Edit shift' : 'New shift',
      subtitle: _isEdit
          ? 'Edits flow into every schedule using this shift'
          : 'Define the time window. Color is auto-assigned from the name.',
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
              hintText: 'e.g. Morning',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Short code'),
          TextField(
            controller: _codeCtrl,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.characters,
            maxLength: 3,
            decoration: InputDecoration(
              hintText: 'e.g. M',
              helperText: 'One to three letters; shows in the duty roster.',
              isDense: true,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Hours'),
          Row(
            children: <Widget>[
              Expanded(
                child: _TimeTile(
                  label: 'Start',
                  value: _formatTod(_start),
                  onTap: _pickStart,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _TimeTile(
                  label: 'End',
                  value: _formatTod(_end),
                  onTap: _pickEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Break (minutes)'),
          TextField(
            controller: _breakCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.statusInfo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.statusInfo.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.schedule_outlined,
                    size: 18, color: AppColors.statusInfo),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _workMinutes < 0
                        ? 'Break is longer than the shift — adjust the times.'
                        : 'Net working time: $hours h',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          if (_isEdit && widget.dependentScheduleCount > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Used by ${widget.dependentScheduleCount} schedule'
              '${widget.dependentScheduleCount == 1 ? "" : "s"}.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
          ],
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

class _TimeTile extends StatelessWidget {
  const _TimeTile({
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
                  Text(
                    label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFeatures: <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.access_time, size: 16, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
