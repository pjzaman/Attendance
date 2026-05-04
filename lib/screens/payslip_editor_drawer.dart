import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/employee.dart';
import '../models/payslip.dart';
import '../services/export_service.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';
import '../widgets/status_pill.dart';

class PayslipEditorResult {
  PayslipEditorResult({this.saved, this.deletedId});
  final Payslip? saved;
  final String? deletedId;
}

class PayslipEditorDrawer extends StatefulWidget {
  const PayslipEditorDrawer({
    super.key,
    required this.payslip,
    required this.employee,
  });

  final Payslip payslip;
  final Employee? employee;

  @override
  State<PayslipEditorDrawer> createState() => _PayslipEditorDrawerState();
}

class _PayslipEditorDrawerState extends State<PayslipEditorDrawer> {
  late final TextEditingController _basicCtrl;
  late final TextEditingController _allowancesCtrl;
  late final TextEditingController _deductionsCtrl;
  late final TextEditingController _notesCtrl;
  late PayslipStatus _status;
  late DateTime _periodStart;
  late DateTime _periodEnd;

  @override
  void initState() {
    super.initState();
    final p = widget.payslip;
    _basicCtrl = TextEditingController(text: _fmt(p.basic));
    _allowancesCtrl = TextEditingController(text: _fmt(p.totalAllowances));
    _deductionsCtrl = TextEditingController(text: _fmt(p.totalDeductions));
    _notesCtrl = TextEditingController(text: p.notes ?? '');
    _status = p.status;
    _periodStart = p.periodStart;
    _periodEnd = p.periodEnd;
  }

  String _fmt(double v) =>
      v == 0 ? '' : v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  @override
  void dispose() {
    _basicCtrl.dispose();
    _allowancesCtrl.dispose();
    _deductionsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double _parseAmount(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '')) ?? 0;

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          DateTimeRange(start: _periodStart, end: _periodEnd),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _periodStart = DateUtils.dateOnly(picked.start);
        _periodEnd = DateUtils.dateOnly(picked.end);
      });
    }
  }

  void _save() {
    final base = widget.payslip;
    final newStatus = _status;
    final p = base.copyWith(
      periodStart: _periodStart,
      periodEnd: _periodEnd,
      basic: _parseAmount(_basicCtrl),
      totalAllowances: _parseAmount(_allowancesCtrl),
      totalDeductions: _parseAmount(_deductionsCtrl),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      status: newStatus,
      processedAt: newStatus == PayslipStatus.draft
          ? null
          : (base.processedAt ?? DateTime.now()),
      disbursedAt: newStatus == PayslipStatus.disbursed
          ? (base.disbursedAt ?? DateTime.now())
          : null,
    );
    Navigator.of(context).pop(PayslipEditorResult(saved: p));
  }

  Future<void> _exportXlsx(BuildContext context, String empName) async {
    final messenger = ScaffoldMessenger.of(context);
    final svc = ExportService();
    final suggested = svc.suggestedPayslipFilename(
      widget.payslip.periodStart,
      empName,
    );
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export payslip',
      fileName: suggested,
      type: FileType.custom,
      allowedExtensions: <String>['xlsx'],
    );
    if (path == null) return;
    try {
      // Recompute the in-memory payslip so the export reflects unsaved
      // edits (basic / allowances / deductions / notes / status / period).
      final draft = widget.payslip.copyWith(
        periodStart: _periodStart,
        periodEnd: _periodEnd,
        basic: _parseAmount(_basicCtrl),
        totalAllowances: _parseAmount(_allowancesCtrl),
        totalDeductions: _parseAmount(_deductionsCtrl),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        status: _status,
      );
      final file = await svc.writePayslipXlsx(
        path,
        payslip: draft,
        employeeName: empName,
        employeeCode: widget.employee?.userId,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Exported to ${file.path}')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete payslip?'),
        content: const Text(
            'This permanently removes the payslip from history.'),
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
          .pop(PayslipEditorResult(deletedId: widget.payslip.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, y');
    final fmt = NumberFormat('#,##0.00');
    final basic = _parseAmount(_basicCtrl);
    final allowances = _parseAmount(_allowancesCtrl);
    final deductions = _parseAmount(_deductionsCtrl);
    final gross = basic + allowances;
    final net = gross - deductions;
    final empName = widget.employee?.name.isNotEmpty == true
        ? widget.employee!.name
        : widget.payslip.userId;

    return DetailDrawer(
      title: 'Payslip',
      subtitle: '$empName  ·  '
          '${dateFmt.format(widget.payslip.periodStart)} – '
          '${dateFmt.format(widget.payslip.periodEnd)}',
      actions: <Widget>[
        TextButton(
          onPressed: _confirmDelete,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.statusDanger,
          ),
          child: const Text('Delete'),
        ),
        OutlinedButton.icon(
          onPressed: () => _exportXlsx(context, empName),
          icon: const Icon(Icons.download_outlined, size: 16),
          label: const Text('Export XLSX'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              StatusPill(
                label: _status.label,
                tone: _statusTone(_status),
                dense: true,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.payslip.currency,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Sec('Period'),
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range, size: 16),
            label: Text(
                '${dateFmt.format(_periodStart)} – ${dateFmt.format(_periodEnd)}'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Sec('Compensation'),
          _Tf(
              label: 'Basic',
              ctrl: _basicCtrl,
              isAmount: true,
              onChanged: () => setState(() {})),
          _Tf(
              label: 'Total allowances',
              ctrl: _allowancesCtrl,
              isAmount: true,
              onChanged: () => setState(() {})),
          _Tf(
              label: 'Total deductions',
              ctrl: _deductionsCtrl,
              isAmount: true,
              onChanged: () => setState(() {})),
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
                _Calc(
                    label: 'Deductions', value: -deductions, fmt: fmt),
                if (widget.payslip.attendanceDeduction > 0)
                  _Calc(
                      label: 'Attendance deduction',
                      value: -widget.payslip.attendanceDeduction,
                      fmt: fmt),
                Divider(height: 16, color: theme.dividerColor),
                _Calc(
                    label: 'Net Payable',
                    value: net - widget.payslip.attendanceDeduction,
                    fmt: fmt,
                    bold: true),
              ],
            ),
          ),
          if (widget.payslip.workingDays > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            const _Sec('Attendance breakdown'),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _DayRow(
                      label: 'Working days',
                      value: widget.payslip.workingDays),
                  _DayRow(
                      label: 'Present',
                      value: widget.payslip.presentDays,
                      tone: AppColors.statusSuccess),
                  if (widget.payslip.lateDays > 0)
                    _DayRow(
                        label: 'Late',
                        value: widget.payslip.lateDays,
                        tone: AppColors.statusWarning),
                  if (widget.payslip.leaveDays > 0)
                    _DayRow(
                        label: 'On leave',
                        value: widget.payslip.leaveDays,
                        tone: AppColors.statusInfo),
                  if (widget.payslip.absentDays > 0)
                    _DayRow(
                        label: 'Absent (unaccounted)',
                        value: widget.payslip.absentDays,
                        tone: AppColors.statusDanger),
                  if (widget.payslip.attendanceDeduction > 0) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Per-day basic × ${widget.payslip.absentDays} unaccounted day(s) = ${fmt.format(widget.payslip.attendanceDeduction)} ${widget.payslip.currency}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _Sec('Status'),
          SegmentedButton<PayslipStatus>(
            segments: const <ButtonSegment<PayslipStatus>>[
              ButtonSegment(
                  value: PayslipStatus.draft,
                  icon: Icon(Icons.edit_note, size: 16),
                  label: Text('Draft')),
              ButtonSegment(
                  value: PayslipStatus.processed,
                  icon: Icon(Icons.check_circle_outline, size: 16),
                  label: Text('Processed')),
              ButtonSegment(
                  value: PayslipStatus.disbursed,
                  icon: Icon(Icons.payments_outlined, size: 16),
                  label: Text('Disbursed')),
            ],
            selected: <PayslipStatus>{_status},
            onSelectionChanged: (s) => setState(() => _status = s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _Sec('Notes'),
          _Tf(
              label: 'Adjustments / context',
              ctrl: _notesCtrl,
              maxLines: 3,
              onChanged: () => setState(() {})),
          if (widget.payslip.processedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Processed: ${DateFormat('MMM d, y · HH:mm').format(widget.payslip.processedAt!)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ),
          if (widget.payslip.disbursedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Disbursed: ${DateFormat('MMM d, y · HH:mm').format(widget.payslip.disbursedAt!)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ),
        ],
      ),
    );
  }

  StatusTone _statusTone(PayslipStatus s) {
    switch (s) {
      case PayslipStatus.draft:
        return StatusTone.muted;
      case PayslipStatus.processed:
        return StatusTone.warning;
      case PayslipStatus.disbursed:
        return StatusTone.success;
    }
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

class _DayRow extends StatelessWidget {
  const _DayRow({required this.label, required this.value, this.tone});
  final String label;
  final int value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          if (tone != null) ...<Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: tone,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            '$value',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(fmt.format(value), style: style),
        ],
      ),
    );
  }
}
