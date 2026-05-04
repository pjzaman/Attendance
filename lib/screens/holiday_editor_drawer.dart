import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/holiday.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

class HolidayEditorResult {
  HolidayEditorResult({this.saved, this.deletedId});
  final Holiday? saved;
  final String? deletedId;
}

class HolidayEditorDrawer extends StatefulWidget {
  const HolidayEditorDrawer({super.key, this.initial});
  final Holiday? initial;

  @override
  State<HolidayEditorDrawer> createState() => _HolidayEditorDrawerState();
}

class _HolidayEditorDrawerState extends State<HolidayEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _date;
  late HolidayType _type;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final h = widget.initial;
    _nameCtrl = TextEditingController(text: h?.name ?? '');
    _notesCtrl = TextEditingController(text: h?.notes ?? '');
    _date = h?.date ?? DateUtils.dateOnly(DateTime.now());
    _type = h?.type ?? HolidayType.public;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
  }

  void _save() {
    final base = widget.initial;
    final h = Holiday(
      id: base?.id ?? 'hol_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      date: _date,
      type: _type,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    Navigator.of(context).pop(HolidayEditorResult(saved: h));
  }

  Future<void> _confirmDelete() async {
    final h = widget.initial;
    if (h == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete holiday?'),
        content: Text(
          'Removing "${h.name}" cannot be undone. Schedules with '
          '"Include public holidays" off will start treating that '
          'date as a working day again.',
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
      Navigator.of(context).pop(HolidayEditorResult(deletedId: h.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('EEE, MMM d, y');

    return DetailDrawer(
      title: _isEdit ? 'Edit holiday' : 'New holiday',
      subtitle: _isEdit
          ? 'Edits apply to the duty roster + schedule rendering.'
          : 'Adds a calendar entry; schedules can opt in or out via "Include public holidays".',
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
              hintText: 'e.g. Independence Day',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Date'),
          InkWell(
            onTap: _pickDate,
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
                  Expanded(child: Text(fmt.format(_date))),
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: theme.hintColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Type'),
          SegmentedButton<HolidayType>(
            segments: const <ButtonSegment<HolidayType>>[
              ButtonSegment(
                  value: HolidayType.public, label: Text('Public')),
              ButtonSegment(
                  value: HolidayType.optional, label: Text('Optional')),
              ButtonSegment(
                  value: HolidayType.company, label: Text('Company')),
            ],
            selected: <HolidayType>{_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Notes'),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Optional context.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
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
