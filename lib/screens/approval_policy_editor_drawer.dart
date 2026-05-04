import 'package:flutter/material.dart';

import '../models/approval_policy.dart';
import '../models/request.dart';
import '../shared/app_theme.dart';
import '../widgets/approval_stepper.dart';
import '../widgets/detail_drawer.dart';

class ApprovalPolicyEditorResult {
  ApprovalPolicyEditorResult({this.saved, this.deletedId});
  final ApprovalPolicy? saved;
  final String? deletedId;
}

class ApprovalPolicyEditorDrawer extends StatefulWidget {
  const ApprovalPolicyEditorDrawer({
    super.key,
    this.initial,
    this.fixedType,
  });

  /// `null` = create mode.
  final ApprovalPolicy? initial;

  /// In create mode, optionally lock the type so the user can't pick a
  /// type that already has multiple active policies.
  final RequestType? fixedType;

  @override
  State<ApprovalPolicyEditorDrawer> createState() =>
      _ApprovalPolicyEditorDrawerState();
}

class _ApprovalPolicyEditorDrawerState
    extends State<ApprovalPolicyEditorDrawer> {
  late final TextEditingController _nameCtrl;
  late RequestType _type;
  late bool _isActive;
  late List<TextEditingController> _stepCtrls;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _type = p?.type ?? widget.fixedType ?? RequestType.attendance;
    _isActive = p?.isActive ?? true;
    _stepCtrls = (p?.steps ?? const <ApprovalStep>[])
        .map((s) => TextEditingController(text: s.name))
        .toList();
    if (_stepCtrls.isEmpty) {
      _stepCtrls.add(TextEditingController(text: 'Line Manager'));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _stepCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _stepCtrls.isNotEmpty &&
      _stepCtrls.every((c) => c.text.trim().isNotEmpty);

  void _addStep() {
    setState(() => _stepCtrls.add(TextEditingController()));
  }

  void _removeStep(int index) {
    if (_stepCtrls.length <= 1) return;
    setState(() {
      _stepCtrls[index].dispose();
      _stepCtrls.removeAt(index);
    });
  }

  void _moveStep(int from, int to) {
    if (to < 0 || to >= _stepCtrls.length) return;
    setState(() {
      final c = _stepCtrls.removeAt(from);
      _stepCtrls.insert(to, c);
    });
  }

  void _save() {
    final base = widget.initial;
    final policy = ApprovalPolicy(
      id: base?.id ?? 'pol_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      type: _type,
      isActive: _isActive,
      steps: <ApprovalStep>[
        for (int i = 0; i < _stepCtrls.length; i++)
          ApprovalStep(
            order: i + 1,
            name: _stepCtrls[i].text.trim(),
          ),
      ],
    );
    Navigator.of(context).pop(
      ApprovalPolicyEditorResult(saved: policy),
    );
  }

  Future<void> _confirmDelete() async {
    final p = widget.initial;
    if (p == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete policy?'),
        content: Text(
          'New "${p.type.label.toLowerCase()}" requests will fall back to '
          'single-click approval until another policy is set active. '
          'Existing in-flight requests keep their pipeline.',
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
      Navigator.of(context).pop(
        ApprovalPolicyEditorResult(deletedId: p.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final previewPolicy = ApprovalPolicy(
      id: 'preview',
      name: _nameCtrl.text.trim().isEmpty ? 'Preview' : _nameCtrl.text.trim(),
      type: _type,
      steps: <ApprovalStep>[
        for (int i = 0; i < _stepCtrls.length; i++)
          ApprovalStep(
            order: i + 1,
            name: _stepCtrls[i].text.trim().isEmpty
                ? 'Step ${i + 1}'
                : _stepCtrls[i].text.trim(),
          ),
      ],
    );
    final previewRequest = Request(
      id: 'preview',
      type: _type,
      requesterUserId: '',
      fromDate: DateTime.now(),
      reason: '',
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      currentStepOrder: 1,
      policyId: 'preview',
    );

    return DetailDrawer(
      title: _isEdit ? 'Edit approval policy' : 'New approval policy',
      subtitle: _isEdit
          ? 'Edits apply to new requests; in-flight requests keep '
              'their existing pipeline.'
          : 'Pipelines run sequentially. Any reject ends the pipeline.',
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
          const _SectionLabel('Policy name'),
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. Default Leave Policy',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Applies to'),
          DropdownButtonFormField<RequestType>(
            initialValue: _type,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            items: <DropdownMenuItem<RequestType>>[
              for (final t in RequestType.values)
                DropdownMenuItem(value: t, child: Text(t.label)),
            ],
            onChanged: widget.fixedType != null
                ? null
                : (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            title: const Text('Active'),
            subtitle: const Text(
              'Inactive policies aren\'t auto-attached to new requests.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              const Expanded(child: _SectionLabel('Pipeline steps')),
              TextButton.icon(
                onPressed: _addStep,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add step'),
              ),
            ],
          ),
          for (int i = 0; i < _stepCtrls.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.brandPrimary,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _stepCtrls[i],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Step name (e.g. Line Manager)',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 16),
                    tooltip: 'Move up',
                    visualDensity: VisualDensity.compact,
                    onPressed: i == 0 ? null : () => _moveStep(i, i - 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 16),
                    tooltip: 'Move down',
                    visualDensity: VisualDensity.compact,
                    onPressed: i == _stepCtrls.length - 1
                        ? null
                        : () => _moveStep(i, i + 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    tooltip: 'Remove step',
                    visualDensity: VisualDensity.compact,
                    onPressed: _stepCtrls.length <= 1
                        ? null
                        : () => _removeStep(i),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('Preview'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: ApprovalStepper(
              policy: previewPolicy,
              request: previewRequest,
              compact: false,
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
