import 'package:flutter/material.dart';

import '../models/office_location.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

class OfficeLocationEditorResult {
  OfficeLocationEditorResult({this.saved, this.deletedId});
  final OfficeLocation? saved;
  final String? deletedId;
}

class OfficeLocationEditorDrawer extends StatefulWidget {
  const OfficeLocationEditorDrawer({super.key, this.initial});
  final OfficeLocation? initial;

  @override
  State<OfficeLocationEditorDrawer> createState() =>
      _OfficeLocationEditorDrawerState();
}

class _OfficeLocationEditorDrawerState
    extends State<OfficeLocationEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _shortCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _contactNameCtrl;
  late final TextEditingController _contactPhoneCtrl;
  late final TextEditingController _contactEmailCtrl;
  late bool _isActive;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final l = widget.initial;
    _nameCtrl = TextEditingController(text: l?.name ?? '');
    _shortCtrl = TextEditingController(text: l?.shortName ?? '');
    _addressCtrl = TextEditingController(text: l?.address ?? '');
    _cityCtrl = TextEditingController(text: l?.city ?? '');
    _countryCtrl = TextEditingController(text: l?.country ?? '');
    _contactNameCtrl = TextEditingController(text: l?.contactName ?? '');
    _contactPhoneCtrl = TextEditingController(text: l?.contactPhone ?? '');
    _contactEmailCtrl = TextEditingController(text: l?.contactEmail ?? '');
    _isActive = l?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _contactEmailCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  String? _trimOrNull(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  void _save() {
    final base = widget.initial;
    final loc = OfficeLocation(
      id: base?.id ?? 'loc_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      shortName: _trimOrNull(_shortCtrl),
      address: _trimOrNull(_addressCtrl),
      city: _trimOrNull(_cityCtrl),
      country: _trimOrNull(_countryCtrl),
      contactName: _trimOrNull(_contactNameCtrl),
      contactPhone: _trimOrNull(_contactPhoneCtrl),
      contactEmail: _trimOrNull(_contactEmailCtrl),
      isActive: _isActive,
    );
    Navigator.of(context).pop(OfficeLocationEditorResult(saved: loc));
  }

  Future<void> _confirmDelete() async {
    final l = widget.initial;
    if (l == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete location?'),
        content: Text(
          'Removing "${l.name}" cannot be undone. Devices and employees '
          'currently referencing this location will keep their text but '
          'lose the link.',
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
      Navigator.of(context).pop(OfficeLocationEditorResult(deletedId: l.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailDrawer(
      title: _isEdit ? 'Edit office location' : 'New office location',
      subtitle: _isEdit
          ? 'Edits apply on next refresh of surfaces that filter by location.'
          : 'A registered workspace where employees punch in.',
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
          const _SectionLabel('Identity'),
          _Tf(label: 'Name', ctrl: _nameCtrl, hint: 'e.g. Head Office', onChanged: () => setState(() {})),
          _Tf(label: 'Short name', ctrl: _shortCtrl, hint: 'e.g. HQ', onChanged: () => setState(() {})),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Address'),
          _Tf(label: 'Street', ctrl: _addressCtrl, maxLines: 2, onChanged: () => setState(() {})),
          Row(
            children: <Widget>[
              Expanded(child: _Tf(label: 'City', ctrl: _cityCtrl, onChanged: () => setState(() {}))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _Tf(label: 'Country', ctrl: _countryCtrl, onChanged: () => setState(() {}))),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Contact'),
          _Tf(label: 'Contact name', ctrl: _contactNameCtrl, onChanged: () => setState(() {})),
          _Tf(
            label: 'Contact phone',
            ctrl: _contactPhoneCtrl,
            keyboardType: TextInputType.phone,
            onChanged: () => setState(() {}),
          ),
          _Tf(
            label: 'Contact email',
            ctrl: _contactEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Active'),
            subtitle: const Text(
              'Inactive locations stay in history but don\'t appear in '
              'new-record dropdowns.',
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

class _Tf extends StatelessWidget {
  const _Tf({
    required this.label,
    required this.ctrl,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController ctrl;
  final VoidCallback onChanged;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: ctrl,
        onChanged: (_) => onChanged(),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }
}
