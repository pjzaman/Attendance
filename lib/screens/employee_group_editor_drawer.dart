import 'package:flutter/material.dart';

import '../models/employee_group.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

class EmployeeGroupEditorResult {
  EmployeeGroupEditorResult({this.saved, this.deletedId});
  final EmployeeGroup? saved;
  final String? deletedId;
}

class EmployeeGroupEditorDrawer extends StatefulWidget {
  const EmployeeGroupEditorDrawer({super.key, this.initial});
  final EmployeeGroup? initial;

  @override
  State<EmployeeGroupEditorDrawer> createState() =>
      _EmployeeGroupEditorDrawerState();
}

class _EmployeeGroupEditorDrawerState
    extends State<EmployeeGroupEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late bool _isActive;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final g = widget.initial;
    _nameCtrl = TextEditingController(text: g?.name ?? '');
    _descCtrl = TextEditingController(text: g?.description ?? '');
    _isActive = g?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  void _save() {
    final base = widget.initial;
    final g = EmployeeGroup(
      id: base?.id ?? 'grp_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      isActive: _isActive,
    );
    Navigator.of(context).pop(EmployeeGroupEditorResult(saved: g));
  }

  Future<void> _confirmDelete() async {
    final g = widget.initial;
    if (g == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete group?'),
        content: Text(
          'Removing "${g.name}" cannot be undone. Employees referencing '
          'this group in free-text profile fields keep their entry.',
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
      Navigator.of(context).pop(EmployeeGroupEditorResult(deletedId: g.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailDrawer(
      title: _isEdit ? 'Edit group' : 'New group',
      subtitle: _isEdit
          ? 'Edits apply on next refresh.'
          : 'A looser cohort than a team — projects, training rounds, etc.',
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
              hintText: 'e.g. Project Atlas',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Description'),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Optional.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Active'),
            subtitle: const Text(
              'Inactive groups disappear from new-record dropdowns.',
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
