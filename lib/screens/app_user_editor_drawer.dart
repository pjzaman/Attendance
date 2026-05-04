import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/employee.dart';
import '../models/role.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

class AppUserEditorResult {
  AppUserEditorResult({this.saved, this.deletedId});
  final AppUser? saved;
  final String? deletedId;
}

class AppUserEditorDrawer extends StatefulWidget {
  const AppUserEditorDrawer({
    super.key,
    required this.roles,
    required this.employees,
    this.initial,
  });

  final List<Role> roles;
  final List<Employee> employees;

  /// `null` = create mode.
  final AppUser? initial;

  @override
  State<AppUserEditorDrawer> createState() => _AppUserEditorDrawerState();
}

class _AppUserEditorDrawerState extends State<AppUserEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late String? _roleId;
  late String? _employeeUserId;
  late bool _isVerified;
  late bool _isActive;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final u = widget.initial;
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _roleId = u?.roleId ??
        (widget.roles.isNotEmpty ? widget.roles.first.id : null);
    _employeeUserId = u?.employeeUserId;
    _isVerified = u?.isVerified ?? false;
    _isActive = u?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _emailValid {
    final e = _emailCtrl.text.trim();
    return e.contains('@') && e.contains('.');
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _emailValid &&
      _roleId != null;

  void _save() {
    final base = widget.initial;
    final user = AppUser(
      id: base?.id ?? 'usr_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().toLowerCase(),
      roleId: _roleId!,
      isVerified: _isVerified,
      isActive: _isActive,
      employeeUserId: _employeeUserId,
      lastSignInAt: base?.lastSignInAt,
      createdAt: base?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(AppUserEditorResult(saved: user));
  }

  Future<void> _confirmDelete() async {
    final u = widget.initial;
    if (u == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'Removing "${u.name}" cannot be undone. They will lose access on '
          'next sign-in.',
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
      Navigator.of(context).pop(AppUserEditorResult(deletedId: u.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailDrawer(
      title: _isEdit ? 'Edit user' : 'New user',
      subtitle: _isEdit
          ? 'Edits apply on next sign-in.'
          : 'A user is someone who logs into the management app.',
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
              hintText: 'e.g. Sagor Mia',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Email'),
          TextField(
            controller: _emailCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'name@example.com',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Role'),
          DropdownButtonFormField<String>(
            initialValue: _roleId,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            items: <DropdownMenuItem<String>>[
              for (final r in widget.roles)
                DropdownMenuItem(
                  value: r.id,
                  child: Text(
                    '${r.name}'
                    '${r.permissions.isEmpty ? "" : "  ·  ${r.permissions.length} permission${r.permissions.length == 1 ? "" : "s"}"}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _roleId = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Linked employee (optional)'),
          DropdownButtonFormField<String>(
            initialValue: _employeeUserId,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: '— not linked —',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem<String>(
                  value: null, child: Text('— not linked —')),
              for (final e in widget.employees)
                DropdownMenuItem(
                  value: e.userId,
                  child: Text(
                    '${e.name.isEmpty ? "id ${e.userId}" : e.name}'
                    '  ·  ${e.userId}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _employeeUserId = v),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            value: _isVerified,
            onChanged: (v) => setState(() => _isVerified = v),
            title: const Text('Email verified'),
            subtitle: const Text(
              'Mark as verified once the user has confirmed their email.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Active'),
            subtitle: const Text(
              'Inactive users can\'t sign in. Useful for offboarding without deleting history.',
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
