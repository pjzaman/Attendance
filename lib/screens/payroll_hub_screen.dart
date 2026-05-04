import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/payslip.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_pill.dart';

/// Aggregated payroll period card per the doc §4.8 — Pay Period,
/// Employees, Gross, Earning, Deduction, Net Payable, status pill,
/// Active toggle and View Details.
class _PeriodCardData {
  _PeriodCardData({
    required this.start,
    required this.end,
    required this.payslips,
  });

  final DateTime start;
  final DateTime end;
  final List<Payslip> payslips;

  int get count => payslips.length;
  double get gross =>
      payslips.fold<double>(0, (a, p) => a + p.gross);
  double get earning =>
      payslips.fold<double>(0, (a, p) => a + p.totalAllowances);
  double get deduction =>
      payslips.fold<double>(0, (a, p) => a + p.totalDeductions);
  double get attendanceDeduction =>
      payslips.fold<double>(0, (a, p) => a + p.attendanceDeduction);
  double get netPayable =>
      payslips.fold<double>(0, (a, p) => a + p.netPayable);
  int get totalAbsentDays =>
      payslips.fold<int>(0, (a, p) => a + p.absentDays);

  /// Worst status across the batch — drives the period's pill.
  PayslipStatus get rollupStatus {
    if (payslips.any((p) => p.status == PayslipStatus.draft)) {
      return PayslipStatus.draft;
    }
    if (payslips.any((p) => p.status == PayslipStatus.processed)) {
      return PayslipStatus.processed;
    }
    return PayslipStatus.disbursed;
  }
}

class PayrollHubScreen extends StatefulWidget {
  const PayrollHubScreen({super.key});

  @override
  State<PayrollHubScreen> createState() => _PayrollHubScreenState();
}

class _PayrollHubScreenState extends State<PayrollHubScreen> {
  _PeriodCardData? _expanded;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final periods = _groupByPeriod(state.payslips);

    if (periods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'No payroll periods yet',
          message:
              'Generate payslips from Payroll → Salary → Payslips to see period cards here.',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Pay periods',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '· ${periods.length}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth >= 1400
                      ? 3
                      : c.maxWidth >= 900
                          ? 2
                          : 1;
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.55,
                    children: <Widget>[
                      for (final p in periods)
                        _PeriodCard(
                          data: p,
                          onView: () =>
                              setState(() => _expanded = p),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (_expanded != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _PeriodDetail(
              data: _expanded!,
              onClose: () => setState(() => _expanded = null),
              state: state,
            ),
          ],
        ],
      ),
    );
  }

  List<_PeriodCardData> _groupByPeriod(List<Payslip> all) {
    final map = <String, List<Payslip>>{};
    for (final p in all) {
      final key = '${p.periodStart.toIso8601String()}|'
          '${p.periodEnd.toIso8601String()}';
      map.putIfAbsent(key, () => <Payslip>[]).add(p);
    }
    final entries = map.entries.toList()
      ..sort((a, b) {
        final aStart = a.value.first.periodStart;
        final bStart = b.value.first.periodStart;
        return bStart.compareTo(aStart);
      });
    return <_PeriodCardData>[
      for (final e in entries)
        _PeriodCardData(
          start: e.value.first.periodStart,
          end: e.value.first.periodEnd,
          payslips: e.value,
        ),
    ];
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.data, required this.onView});
  final _PeriodCardData data;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('MMM d, y');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${dateFmt.format(data.start)} – ${dateFmt.format(data.end)}',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.count} employee${data.count == 1 ? "" : "s"}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  label: data.rollupStatus.label,
                  tone: _statusTone(data.rollupStatus),
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _Stat(
                label: 'Gross',
                value: fmt.format(data.gross),
                tone: StatusTone.info),
            _Stat(
                label: 'Earning',
                value: fmt.format(data.earning),
                tone: StatusTone.success),
            _Stat(
                label: 'Deduction',
                value: fmt.format(data.deduction),
                tone: StatusTone.danger),
            if (data.attendanceDeduction > 0)
              _Stat(
                  label: 'Attendance',
                  value: fmt.format(data.attendanceDeduction),
                  tone: StatusTone.danger),
            Divider(height: 18, color: theme.dividerColor),
            _Stat(
                label: 'Net Payable',
                value: fmt.format(data.netPayable),
                tone: StatusTone.success,
                bold: true),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: onView,
                child: const Text('View details'),
              ),
            ),
          ],
        ),
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

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.tone,
    this.bold = false,
  });
  final String label;
  final String value;
  final StatusTone tone;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _toneColor(tone);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: bold ? color : null,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _toneColor(StatusTone t) {
    switch (t) {
      case StatusTone.info:
        return AppColors.statusInfo;
      case StatusTone.success:
        return AppColors.statusSuccess;
      case StatusTone.warning:
        return AppColors.statusWarning;
      case StatusTone.danger:
        return AppColors.statusDanger;
      case StatusTone.muted:
        return AppColors.statusMuted;
    }
  }
}

class _PeriodDetail extends StatelessWidget {
  const _PeriodDetail({
    required this.data,
    required this.onClose,
    required this.state,
  });

  final _PeriodCardData data;
  final VoidCallback onClose;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, y');
    final fmt = NumberFormat('#,##0.00');
    final empById = <String, String>{
      for (final e in state.employees)
        e.userId: e.name.isEmpty ? e.userId : e.name,
    };
    final draftCount = data.payslips
        .where((p) => p.status == PayslipStatus.draft)
        .length;
    final processedCount = data.payslips
        .where((p) => p.status == PayslipStatus.processed)
        .length;
    final disbursedCount = data.payslips
        .where((p) => p.status == PayslipStatus.disbursed)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${dateFmt.format(data.start)} – ${dateFmt.format(data.end)}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '$draftCount draft  ·  '
                        '$processedCount processed  ·  '
                        '$disbursedCount disbursed',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                      if (data.attendanceDeduction > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Attendance deductions: ${fmt.format(data.attendanceDeduction)}  ·  '
                            '${data.totalAbsentDays} absent day${data.totalAbsentDays == 1 ? "" : "s"}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.statusDanger,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: draftCount == 0
                          ? null
                          : () => _bulkUpdate(
                              context, state, PayslipStatus.processed),
                      icon: const Icon(Icons.check_circle_outline,
                          size: 16),
                      label: const Text('Mark drafts processed'),
                    ),
                    FilledButton.icon(
                      onPressed: processedCount == 0
                          ? null
                          : () => _bulkUpdate(
                              context, state, PayslipStatus.disbursed),
                      icon: const Icon(Icons.payments_outlined, size: 16),
                      label: const Text('Disburse processed'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close detail',
                      onPressed: onClose,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(height: 1, color: theme.dividerColor),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: data.payslips.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: theme.dividerColor),
                itemBuilder: (context, i) {
                  final p = data.payslips[i];
                  final attendanceLine = p.workingDays > 0
                      ? '  ·  ${p.presentDays}/${p.workingDays} present'
                          '${p.absentDays > 0 ? " · ${p.absentDays} absent" : ""}'
                      : '';
                  return ListTile(
                    dense: true,
                    title:
                        Text(empById[p.userId] ?? p.userId),
                    subtitle: Text(
                      'Gross ${fmt.format(p.gross)}  ·  '
                      'Net ${fmt.format(p.netPayable)} ${p.currency}'
                      '$attendanceLine',
                    ),
                    trailing: StatusPill(
                      label: p.status.label,
                      tone: _statusTone(p.status),
                      dense: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkUpdate(
    BuildContext context,
    AppState state,
    PayslipStatus newStatus,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    int updated = 0;
    for (final p in data.payslips) {
      // Only advance forward from one status to the next.
      if (newStatus == PayslipStatus.processed &&
          p.status == PayslipStatus.draft) {
        await state.upsertPayslip(p.copyWith(
          status: PayslipStatus.processed,
          processedAt: DateTime.now(),
        ));
        updated++;
      } else if (newStatus == PayslipStatus.disbursed &&
          p.status == PayslipStatus.processed) {
        await state.upsertPayslip(p.copyWith(
          status: PayslipStatus.disbursed,
          disbursedAt: DateTime.now(),
        ));
        updated++;
      }
    }
    messenger.showSnackBar(
      SnackBar(
          content: Text(
              'Updated $updated payslip${updated == 1 ? "" : "s"}.')),
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
