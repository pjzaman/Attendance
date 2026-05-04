import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/office_location.dart';
import '../models/tracking_method.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

class TrackingMethodEditorResult {
  TrackingMethodEditorResult({this.saved, this.deletedId});
  final TrackingMethod? saved;
  final String? deletedId;
}

class TrackingMethodEditorDrawer extends StatefulWidget {
  const TrackingMethodEditorDrawer({
    super.key,
    required this.officeLocations,
    this.initial,
  });

  final List<OfficeLocation> officeLocations;
  final TrackingMethod? initial;

  @override
  State<TrackingMethodEditorDrawer> createState() =>
      _TrackingMethodEditorDrawerState();
}

class _TrackingMethodEditorDrawerState
    extends State<TrackingMethodEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  late String? _officeLocationId;
  late DateTime _effectiveDate;
  late bool _allowMobileApp;
  late bool _allowWeb;
  late bool _allowDevice;
  late bool _isActive;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _notesCtrl = TextEditingController(text: m?.notes ?? '');
    _officeLocationId = m?.officeLocationId;
    _effectiveDate = m?.effectiveDate ?? DateUtils.dateOnly(DateTime.now());
    _allowMobileApp = m?.allowMobileApp ?? false;
    _allowWeb = m?.allowWeb ?? false;
    _allowDevice = m?.allowDevice ?? true;
    _isActive = m?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      (_allowMobileApp || _allowWeb || _allowDevice);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _effectiveDate = DateUtils.dateOnly(picked));
    }
  }

  void _save() {
    final base = widget.initial;
    final m = TrackingMethod(
      id: base?.id ?? 'tm_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      officeLocationId: _officeLocationId,
      effectiveDate: _effectiveDate,
      allowMobileApp: _allowMobileApp,
      allowWeb: _allowWeb,
      allowDevice: _allowDevice,
      isActive: _isActive,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    Navigator.of(context).pop(TrackingMethodEditorResult(saved: m));
  }

  Future<void> _confirmDelete() async {
    final m = widget.initial;
    if (m == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete tracking method?'),
        content: Text(
          'Removing "${m.name}" cannot be undone. Employees at the '
          'affected location will fall back to whichever method covers '
          'their date next.',
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
      Navigator.of(context)
          .pop(TrackingMethodEditorResult(deletedId: m.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('EEE, MMM d, y');

    return DetailDrawer(
      title: _isEdit ? 'Edit tracking method' : 'New tracking method',
      subtitle: _isEdit
          ? 'Edits apply on the next clock-in.'
          : 'Bundle the channels (mobile app / web / device) employees can use to clock in.',
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
              hintText: 'e.g. HQ — Mobile + Device',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Office location'),
          DropdownButtonFormField<String>(
            initialValue: _officeLocationId,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: '— org-wide fallback —',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem<String>(
                  value: null, child: Text('— org-wide fallback —')),
              for (final l in widget.officeLocations)
                DropdownMenuItem(
                  value: l.id,
                  child: Text(
                    l.shortName == null || l.shortName!.isEmpty
                        ? l.name
                        : '${l.name}  ·  ${l.shortName!}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _officeLocationId = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Effective from'),
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
                  Expanded(child: Text(fmt.format(_effectiveDate))),
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: theme.hintColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Channels'),
          if (!_canSave && !_isEdit)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Enable at least one channel.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.statusDanger),
              ),
            ),
          SwitchListTile(
            value: _allowMobileApp,
            onChanged: (v) => setState(() => _allowMobileApp = v),
            secondary: const Icon(Icons.phone_iphone),
            title: const Text('Mobile app'),
            subtitle: const Text('Clock in from a mobile companion app.'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _allowWeb,
            onChanged: (v) => setState(() => _allowWeb = v),
            secondary: const Icon(Icons.public),
            title: const Text('Web'),
            subtitle: const Text('Clock in from a browser.'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _allowDevice,
            onChanged: (v) => setState(() => _allowDevice = v),
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Attendance device'),
            subtitle: const Text(
                'Biometric / RFID device (the existing ZKTeco sync).'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Active'),
            subtitle: const Text(
              'Inactive methods are kept for history but ignored when '
              'resolving the current method for a location + date.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Notes'),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Optional context — rollout plan, exceptions, etc.',
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
