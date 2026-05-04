import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../models/employee_salary.dart';
import '../models/salary_history_entry.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';

class EmployeeSalaryEditorResult {
  EmployeeSalaryEditorResult({this.saved, this.deletedUserId});
  final EmployeeSalary? saved;
  final String? deletedUserId;
}

class EmployeeSalaryEditorDrawer extends StatefulWidget {
  const EmployeeSalaryEditorDrawer({
    super.key,
    required this.employee,
    required this.initial,
  });

  final Employee employee;
  final EmployeeSalary initial;

  @override
  State<EmployeeSalaryEditorDrawer> createState() =>
      _EmployeeSalaryEditorDrawerState();
}

class _EmployeeSalaryEditorDrawerState
    extends State<EmployeeSalaryEditorDrawer> {
  late final TextEditingController _basicCtrl;
  late final TextEditingController _allowancesCtrl;
  late final TextEditingController _deductionsCtrl;
  late final TextEditingController _gradeCtrl;
  late final TextEditingController _structureCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _notesCtrl;
  DateTime? _effectiveFrom;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _basicCtrl = TextEditingController(text: _fmt(s.basic));
    _allowancesCtrl = TextEditingController(text: _fmt(s.totalAllowances));
    _deductionsCtrl = TextEditingController(text: _fmt(s.totalDeductions));
    _gradeCtrl = TextEditingController(text: s.grade ?? '');
    _structureCtrl = TextEditingController(text: s.structure ?? '');
    _currencyCtrl = TextEditingController(text: s.currency);
    _notesCtrl = TextEditingController(text: s.notes ?? '');
    _effectiveFrom = s.effectiveFrom;
  }

  String _fmt(double v) =>
      v == 0 ? '' : v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  @override
  void dispose() {
    _basicCtrl.dispose();
    _allowancesCtrl.dispose();
    _deductionsCtrl.dispose();
    _gradeCtrl.dispose();
    _structureCtrl.dispose();
    _currencyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double _parseAmount(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '')) ?? 0;

  bool get _canSave =>
      double.tryParse(_basicCtrl.text.trim().replaceAll(',', '')) != null &&
      _currencyCtrl.text.trim().isNotEmpty;

  void _save() {
    final s = widget.initial.copyWith(
      basic: _parseAmount(_basicCtrl),
      totalAllowances: _parseAmount(_allowancesCtrl),
      totalDeductions: _parseAmount(_deductionsCtrl),
      grade: _gradeCtrl.text.trim().isEmpty ? null : _gradeCtrl.text.trim(),
      structure: _structureCtrl.text.trim().isEmpty
          ? null
          : _structureCtrl.text.trim(),
      currency: _currencyCtrl.text.trim().toUpperCase(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      effectiveFrom: _effectiveFrom,
    );
    Navigator.of(context).pop(EmployeeSalaryEditorResult(saved: s));
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove salary?'),
        content: Text(
          'Removing the salary record for ${widget.employee.name.isEmpty ? widget.employee.userId : widget.employee.name} '
          'doesn\'t affect already-issued payslips. Future payslip generation will skip this employee.',
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
      Navigator.of(context).pop(EmployeeSalaryEditorResult(
        deletedUserId: widget.employee.userId,
      ));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _effectiveFrom = DateUtils.dateOnly(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final basic = _parseAmount(_basicCtrl);
    final allowances = _parseAmount(_allowancesCtrl);
    final deductions = _parseAmount(_deductionsCtrl);
    final gross = basic + allowances;
    final net = gross - deductions;
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, y');

    return DetailDrawer(
      title: 'Salary',
      subtitle:
          'Current salary for ${widget.employee.name.isEmpty ? widget.employee.userId : widget.employee.name}',
      actions: <Widget>[
        if (widget.initial.basic > 0 ||
            widget.initial.totalAllowances > 0 ||
            widget.initial.totalDeductions > 0)
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
          child: const Text('Save'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _Sec('Compensation'),
          _Tf(label: 'Basic', ctrl: _basicCtrl, isAmount: true,
              onChanged: () => setState(() {})),
          _Tf(label: 'Total allowances', ctrl: _allowancesCtrl,
              isAmount: true, onChanged: () => setState(() {})),
          _Tf(label: 'Total deductions', ctrl: _deductionsCtrl,
              isAmount: true, onChanged: () => setState(() {})),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.statusInfo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.statusInfo.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Calc(label: 'Gross', value: gross, fmt: fmt),
                const SizedBox(height: 4),
                _Calc(
                    label: 'Deductions',
                    value: -deductions,
                    fmt: fmt),
                Divider(height: 16, color: theme.dividerColor),
                _Calc(label: 'Net Payable', value: net, fmt: fmt, bold: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Sec('Classification'),
          Row(
            children: <Widget>[
              Expanded(
                child: _Tf(
                    label: 'Grade',
                    ctrl: _gradeCtrl,
                    onChanged: () => setState(() {})),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Tf(
                    label: 'Structure',
                    ctrl: _structureCtrl,
                    onChanged: () => setState(() {})),
              ),
            ],
          ),
          _Tf(
              label: 'Currency',
              ctrl: _currencyCtrl,
              onChanged: () => setState(() {})),
          const SizedBox(height: AppSpacing.md),
          const _Sec('Effective from (optional)'),
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
                  Expanded(
                    child: Text(_effectiveFrom == null
                        ? '— not set —'
                        : dateFmt.format(_effectiveFrom!)),
                  ),
                  if (_effectiveFrom != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      tooltip: 'Clear',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          setState(() => _effectiveFrom = null),
                    )
                  else
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: theme.hintColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Sec('Notes'),
          _Tf(
              label: 'Breakdown / context',
              ctrl: _notesCtrl,
              maxLines: 3,
              onChanged: () => setState(() {})),
          const SizedBox(height: AppSpacing.lg),
          _SalaryHistorySection(userId: widget.employee.userId, fmt: fmt),
        ],
      ),
    );
  }
}

class _SalaryHistorySection extends StatefulWidget {
  const _SalaryHistorySection({required this.userId, required this.fmt});
  final String userId;
  final NumberFormat fmt;

  @override
  State<_SalaryHistorySection> createState() => _SalaryHistorySectionState();
}

class _SalaryHistorySectionState extends State<_SalaryHistorySection> {
  late Future<List<SalaryHistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().salaryHistoryFor(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, y');

    return FutureBuilder<List<SalaryHistoryEntry>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Sec('Salary history'),
              SizedBox(
                height: 32,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],
          );
        }
        final history = snap.data!;
        if (history.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _Sec('Salary history'),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'No prior changes recorded. Saving here will start the audit trail.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _Sec('Salary history'),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < history.length; i++)
                    _HistoryRow(
                      entry: history[i],
                      isLast: i == history.length - 1,
                      dateFmt: dateFmt,
                      fmt: widget.fmt,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.isLast,
    required this.dateFmt,
    required this.fmt,
  });
  final SalaryHistoryEntry entry;
  final bool isLast;
  final DateFormat dateFmt;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  dateFmt.format(entry.changedAt),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${fmt.format(entry.netPayable)} ${entry.currency}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures()
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Basic ${fmt.format(entry.basic)} · '
            'Allow ${fmt.format(entry.totalAllowances)} · '
            'Deduct ${fmt.format(entry.totalDeductions)}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          if (entry.grade != null || entry.structure != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                <String>[
                  if (entry.grade != null) 'Grade ${entry.grade}',
                  if (entry.structure != null) entry.structure!,
                ].join(' · '),
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ),
          if (entry.notes != null && entry.notes!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                entry.notes!,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _Sec extends StatelessWidget {
  const _Sec(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600)),
      );
}

class _Tf extends StatelessWidget {
  const _Tf({
    required this.label,
    required this.ctrl,
    required this.onChanged,
    this.maxLines = 1,
    this.isAmount = false,
  });

  final String label;
  final TextEditingController ctrl;
  final VoidCallback onChanged;
  final int maxLines;
  final bool isAmount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isAmount ? TextInputType.number : null,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }
}

class _Calc extends StatelessWidget {
  const _Calc({
    required this.label,
    required this.value,
    required this.fmt,
    this.bold = false,
  });
  final String label;
  final double value;
  final NumberFormat fmt;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: style)),
        Text(fmt.format(value), style: style),
      ],
    );
  }
}
