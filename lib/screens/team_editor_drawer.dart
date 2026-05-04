import 'package:flutter/material.dart';

import '../models/employee.dart';
import '../models/team.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

class TeamEditorResult {
  TeamEditorResult({this.saved, this.deletedId});
  final Team? saved;
  final String? deletedId;
}

class TeamEditorDrawer extends StatefulWidget {
  const TeamEditorDrawer({
    super.key,
    required this.employees,
    this.initial,
  });

  final List<Employee> employees;
  final Team? initial;

  @override
  State<TeamEditorDrawer> createState() => _TeamEditorDrawerState();
}

class _TeamEditorDrawerState extends State<TeamEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String? _leaderId;
  late bool _isActive;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _leaderId = t?.leaderUserId;
    _isActive = t?.isActive ?? true;
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
    final t = Team(
      id: base?.id ?? 'team_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      leaderUserId: _leaderId,
      isActive: _isActive,
    );
    Navigator.of(context).pop(TeamEditorResult(saved: t));
  }

  Future<void> _confirmDelete() async {
    final t = widget.initial;
    if (t == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete team?'),
        content: Text(
          'Removing "${t.name}" cannot be undone. Employees referencing '
          'this team in free-text profile fields keep their entry.',
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
      Navigator.of(context).pop(TeamEditorResult(deletedId: t.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailDrawer(
      title: _isEdit ? 'Edit team' : 'New team',
      subtitle: _isEdit
          ? 'Edits apply on next refresh of surfaces that filter by team.'
          : 'A named team of employees, typically led by a manager.',
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
              hintText: 'e.g. Engineering',
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
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Optional context.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Team lead'),
          DropdownButtonFormField<String>(
            initialValue: _leaderId,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: '— unassigned —',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem<String>(
                  value: null, child: Text('— unassigned —')),
              for (final e in widget.employees)
                DropdownMenuItem(
                  value: e.userId,
                  child: Text(
                    e.name.isEmpty
                        ? 'id ${e.userId}'
                        : '${e.name}  ·  ${e.userId}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _leaderId = v),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Active'),
            subtitle: const Text(
              'Inactive teams disappear from new-record dropdowns.',
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
