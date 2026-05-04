import 'package:flutter/material.dart';

import '../models/device.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

class DeviceEditorResult {
  DeviceEditorResult({this.saved, this.deletedId});
  final Device? saved;
  final String? deletedId;
}

class DeviceEditorDrawer extends StatefulWidget {
  const DeviceEditorDrawer({super.key, this.initial});

  /// `null` = create mode.
  final Device? initial;

  @override
  State<DeviceEditorDrawer> createState() => _DeviceEditorDrawerState();
}

class _DeviceEditorDrawerState extends State<DeviceEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _ipCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _serialCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _commKeyCtrl;
  late final TextEditingController _connectTimeoutCtrl;
  late final TextEditingController _recvTimeoutCtrl;
  late bool _isActive;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _brandCtrl = TextEditingController(text: d?.brand ?? 'ZKTeco');
    _modelCtrl = TextEditingController(text: d?.model ?? 'UFACE-800');
    _ipCtrl = TextEditingController(text: d?.ipAddress ?? '');
    _portCtrl =
        TextEditingController(text: d?.port.toString() ?? '4370');
    _serialCtrl = TextEditingController(text: d?.serialNumber ?? '');
    _locationCtrl = TextEditingController(text: d?.officeLocation ?? '');
    _notesCtrl = TextEditingController(text: d?.notes ?? '');
    _commKeyCtrl =
        TextEditingController(text: (d?.commKey ?? 0).toString());
    _connectTimeoutCtrl = TextEditingController(
        text: (d?.connectTimeoutMs ?? 5000).toString());
    _recvTimeoutCtrl = TextEditingController(
        text: (d?.recvTimeoutMs ?? 10000).toString());
    _isActive = d?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _serialCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    _commKeyCtrl.dispose();
    _connectTimeoutCtrl.dispose();
    _recvTimeoutCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _ipCtrl.text.trim().isNotEmpty &&
      int.tryParse(_portCtrl.text.trim()) != null &&
      int.tryParse(_commKeyCtrl.text.trim()) != null &&
      int.tryParse(_connectTimeoutCtrl.text.trim()) != null &&
      int.tryParse(_recvTimeoutCtrl.text.trim()) != null;

  void _save() {
    final base = widget.initial;
    final device = Device(
      id: base?.id ?? 'dev_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      ipAddress: _ipCtrl.text.trim(),
      port: int.tryParse(_portCtrl.text.trim()) ?? 4370,
      serialNumber: _serialCtrl.text.trim().isEmpty
          ? null
          : _serialCtrl.text.trim(),
      officeLocation: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      isActive: _isActive,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      lastConnectedAt: base?.lastConnectedAt,
      lastSyncAt: base?.lastSyncAt,
      commKey: int.tryParse(_commKeyCtrl.text.trim()) ?? 0,
      connectTimeoutMs:
          int.tryParse(_connectTimeoutCtrl.text.trim()) ?? 5000,
      recvTimeoutMs:
          int.tryParse(_recvTimeoutCtrl.text.trim()) ?? 10000,
    );
    Navigator.of(context).pop(DeviceEditorResult(saved: device));
  }

  Future<void> _confirmDelete() async {
    final d = widget.initial;
    if (d == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove device?'),
        content: Text(
          'Removing "${d.name}" stops surfacing it in the registry. '
          'Existing sync history is preserved; only the metadata is removed.',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop(DeviceEditorResult(deletedId: d.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailDrawer(
      title: _isEdit ? 'Edit device' : 'New device',
      subtitle: _isEdit
          ? 'Edits update the registry; the active sync still uses '
              'the IP / port from .env until that\'s wired up here.'
          : 'Register a biometric / time-tracking device.',
      actions: <Widget>[
        if (_isEdit)
          TextButton(
            onPressed: _confirmDelete,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.statusDanger,
            ),
            child: const Text('Remove'),
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
          _Tf(label: 'Name', ctrl: _nameCtrl, hint: 'e.g. Main Gate', onChanged: () => setState(() {})),
          Row(
            children: <Widget>[
              Expanded(child: _Tf(label: 'Brand', ctrl: _brandCtrl, onChanged: () => setState(() {}))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _Tf(label: 'Model', ctrl: _modelCtrl, onChanged: () => setState(() {}))),
            ],
          ),
          _Tf(
            label: 'Serial number',
            ctrl: _serialCtrl,
            hint: 'Optional',
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Connection'),
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: _Tf(
                  label: 'IP address',
                  ctrl: _ipCtrl,
                  hint: '192.168.0.150',
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Tf(
                  label: 'Port',
                  ctrl: _portCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: () => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Placement'),
          _Tf(
            label: 'Office location',
            ctrl: _locationCtrl,
            hint: 'e.g. Factory A',
            onChanged: () => setState(() {}),
          ),
          _Tf(
            label: 'Notes',
            ctrl: _notesCtrl,
            maxLines: 3,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Active'),
            subtitle: const Text(
              'Inactive devices stay in the registry but aren\'t expected to sync.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Advanced'),
          _Tf(
            label: 'Comm key',
            ctrl: _commKeyCtrl,
            keyboardType: TextInputType.number,
            hint: '0 = no auth (default for stock ZKTeco devices)',
            onChanged: () => setState(() {}),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _Tf(
                  label: 'Connect timeout (ms)',
                  ctrl: _connectTimeoutCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Tf(
                  label: 'Recv timeout (ms)',
                  ctrl: _recvTimeoutCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: () => setState(() {}),
                ),
              ),
            ],
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
