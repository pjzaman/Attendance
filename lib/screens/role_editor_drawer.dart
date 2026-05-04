import 'package:flutter/material.dart';

import '../models/permission.dart';
import '../models/role.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';
import '../widgets/status_pill.dart';

class RoleEditorResult {
  RoleEditorResult({this.saved, this.deletedId});
  final Role? saved;
  final String? deletedId;
}

class RoleEditorDrawer extends StatefulWidget {
  const RoleEditorDrawer({super.key, this.initial});

  /// `null` = create mode.
  final Role? initial;

  @override
  State<RoleEditorDrawer> createState() => _RoleEditorDrawerState();
}

class _RoleEditorDrawerState extends State<RoleEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late Set<String> _permissions;

  bool get _isEdit => widget.initial != null;
  bool get _isBuiltIn => widget.initial?.isBuiltIn == true;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _permissions = <String>{...?r?.permissions};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty && _permissions.isNotEmpty;

  void _save() {
    final base = widget.initial;
    final role = Role(
      id: base?.id ?? 'role_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      permissions: _permissions.toList()..sort(),
      isBuiltIn: base?.isBuiltIn ?? false,
    );
    Navigator.of(context).pop(RoleEditorResult(saved: role));
  }

  Future<void> _confirmDelete() async {
    final r = widget.initial;
    if (r == null) return;
    if (r.isBuiltIn) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete role?'),
        content: Text(
          'Removing "${r.name}" cannot be undone. Users who currently '
          'have this role will need to be reassigned manually.',
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
      Navigator.of(context).pop(RoleEditorResult(deletedId: r.id));
    }
  }

  void _toggleAll(String group, bool select) {
    setState(() {
      for (final p in Permissions.all) {
        if (p.group != group) continue;
        if (select) {
          _permissions.add(p.key);
        } else {
          _permissions.remove(p.key);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final byGroup = <String, List<PermissionMeta>>{};
    for (final p in Permissions.all) {
      byGroup.putIfAbsent(p.group, () => <PermissionMeta>[]).add(p);
    }

    return DetailDrawer(
      title: _isEdit ? 'Edit role' : 'New role',
      subtitle: _isBuiltIn
          ? 'Built-in role — name and permissions can be edited but the role can\'t be deleted.'
          : 'Roles are referenced by app users for permission checks.',
      actions: <Widget>[
        if (_isEdit && !_isBuiltIn)
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
          if (_isBuiltIn) ...<Widget>[
            const StatusPill(
              label: 'Built-in',
              tone: StatusTone.info,
              dense: true,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const _SectionLabel('Name'),
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. HR Lead',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Description'),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Short description for the Roles list.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: _SectionLabel(
                    'Permissions · ${_permissions.length} of ${Permissions.all.length}'),
              ),
            ],
          ),
          for (final entry in byGroup.entries) ...<Widget>[
            _PermissionGroup(
              group: entry.key,
              permissions: entry.value,
              selected: _permissions,
              onToggle: (key, v) => setState(() {
                if (v) {
                  _permissions.add(key);
                } else {
                  _permissions.remove(key);
                }
              }),
              onToggleAll: (v) => _toggleAll(entry.key, v),
              theme: theme,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _PermissionGroup extends StatelessWidget {
  const _PermissionGroup({
    required this.group,
    required this.permissions,
    required this.selected,
    required this.onToggle,
    required this.onToggleAll,
    required this.theme,
  });

  final String group;
  final List<PermissionMeta> permissions;
  final Set<String> selected;
  final void Function(String key, bool selected) onToggle;
  final ValueChanged<bool> onToggleAll;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final allSelected = permissions.every((p) => selected.contains(p.key));
    final noneSelected = permissions.every((p) => !selected.contains(p.key));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                group,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => onToggleAll(!allSelected),
                child: Text(
                  allSelected
                      ? 'Clear all'
                      : noneSelected
                          ? 'Select all'
                          : 'Select all',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          for (final p in permissions)
            CheckboxListTile(
              value: selected.contains(p.key),
              onChanged: (v) => onToggle(p.key, v == true),
              title: Text(p.label),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
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
