import 'package:flutter/material.dart';

import '../models/leave_type.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

class LeaveTypeEditorResult {
  LeaveTypeEditorResult({this.saved, this.deletedId});
  final LeaveType? saved;
  final String? deletedId;
}

class LeaveTypeEditorDrawer extends StatefulWidget {
  const LeaveTypeEditorDrawer({super.key, this.initial});

  /// `null` = create mode.
  final LeaveType? initial;

  @override
  State<LeaveTypeEditorDrawer> createState() => _LeaveTypeEditorDrawerState();
}

class _LeaveTypeEditorDrawerState extends State<LeaveTypeEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _daysCtrl;
  late LeaveGenderConstraint _gender;
  late bool _isPaid;
  late bool _isActive;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _codeCtrl = TextEditingController(text: t?.code ?? '');
    _daysCtrl = TextEditingController(
      text: (t?.defaultDaysPerYear ?? 0).toString(),
    );
    _gender = t?.genderConstraint ?? LeaveGenderConstraint.any;
    _isPaid = t?.isPaid ?? true;
    _isActive = t?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _codeCtrl.text.trim().isNotEmpty &&
      int.tryParse(_daysCtrl.text.trim()) != null;

  void _save() {
    final base = widget.initial;
    final updated = LeaveType(
      id: base?.id ?? 'lt_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      code: _codeCtrl.text.trim().toUpperCase(),
      defaultDaysPerYear: int.tryParse(_daysCtrl.text.trim()) ?? 0,
      genderConstraint: _gender,
      isPaid: _isPaid,
      isActive: _isActive,
    );
    Navigator.of(context).pop(LeaveTypeEditorResult(saved: updated));
  }

  Future<void> _confirmDelete() async {
    final t = widget.initial;
    if (t == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete leave type?'),
        content: Text(
          'This permanently removes "${t.name}" from the catalog. '
          'Existing requests using this type keep working — only new '
          'request creation no longer offers it.',
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
      Navigator.of(context).pop(LeaveTypeEditorResult(deletedId: t.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailDrawer(
      title: _isEdit ? 'Edit leave type' : 'New leave type',
      subtitle: _isEdit
          ? 'Edits apply to new requests; existing balances re-derive from this on next view.'
          : 'Add an entry to the Labour Law leaves catalog.',
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
              hintText: 'e.g. Annual',
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
            maxLength: 4,
            decoration: InputDecoration(
              hintText: 'e.g. AL',
              counterText: '',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Default days per year'),
          TextField(
            controller: _daysCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0',
              helperText: '0 = no preset cap (e.g. Unpaid).',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Gender constraint'),
          SegmentedButton<LeaveGenderConstraint>(
            segments: const <ButtonSegment<LeaveGenderConstraint>>[
              ButtonSegment(
                  value: LeaveGenderConstraint.any, label: Text('Any')),
              ButtonSegment(
                  value: LeaveGenderConstraint.femaleOnly,
                  label: Text('Female')),
              ButtonSegment(
                  value: LeaveGenderConstraint.maleOnly,
                  label: Text('Male')),
            ],
            selected: <LeaveGenderConstraint>{_gender},
            onSelectionChanged: (s) => setState(() => _gender = s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile(
            value: _isPaid,
            onChanged: (v) => setState(() => _isPaid = v),
            title: const Text('Paid'),
            subtitle: const Text(
              'Off = the leave is unpaid (e.g. extended absence).',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Active'),
            subtitle: const Text(
              'Inactive types stay in history but disappear from the new-request dropdown.',
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
