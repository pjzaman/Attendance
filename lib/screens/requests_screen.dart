import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/approval_policy.dart';
import '../models/employee.dart';
import '../models/leave_type.dart';
import '../models/request.dart';
import '../models/shift.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/approval_stepper.dart';
import '../widgets/detail_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_row.dart';
import '../widgets/status_pill.dart';
import 'request_editor_drawer.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: RequestType.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  int _pendingCount(List<Request> requests, RequestType type) =>
      requests.where((r) => r.type == type && r.isPending).length;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.employees.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No employees yet',
        message:
            'Requests need employees first. Run a sync to pull them from the device.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Tab>[
              for (final t in RequestType.values)
                Tab(
                  child: _TabLabel(
                    label: t.label,
                    pendingCount: _pendingCount(state.requests, t),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: <Widget>[
                for (final t in RequestType.values)
                  _RequestsList(state: state, type: t),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, required this.pendingCount});
  final String label;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label),
        if (pendingCount > 0) ...<Widget>[
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.statusWarning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$pendingCount',
              style: const TextStyle(
                color: AppColors.statusWarning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({required this.state, required this.type});

  final AppState state;
  final RequestType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requests = state.requests.where((r) => r.type == type).toList();
    final employeesById = <String, Employee>{
      for (final e in state.employees) e.userId: e,
    };
    final shiftsById = <String, Shift>{for (final s in state.shifts) s.id: s};
    final policiesById = <String, ApprovalPolicy>{
      for (final p in state.approvalPolicies) p.id: p,
    };
    final leaveTypesById = <String, LeaveType>{
      for (final t in state.leaveTypes) t.id: t,
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: () => _openEditor(context, state),
            newLabel: 'New ${type.label.toLowerCase()} request',
          ),
          const SizedBox(height: AppSpacing.md),
          if (requests.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No ${type.label.toLowerCase()} requests',
              message:
                  'New requests will land here. Click + New to submit one.',
            )
          else
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: <Widget>[
                        Text('${type.label} requests',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '· ${requests.length}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  for (int i = 0; i < requests.length; i++) ...<Widget>[
                    _RequestRow(
                      request: requests[i],
                      employee: employeesById[requests[i].requesterUserId],
                      shift: requests[i].shiftId == null
                          ? null
                          : shiftsById[requests[i].shiftId!],
                      leaveType: requests[i].leaveType == null
                          ? null
                          : leaveTypesById[requests[i].leaveType!],
                      policy: requests[i].policyId == null
                          ? null
                          : policiesById[requests[i].policyId!],
                      onApprove: () => _confirmResolve(
                        context,
                        state,
                        requests[i],
                        approve: true,
                      ),
                      onReject: () => _confirmResolve(
                        context,
                        state,
                        requests[i],
                        approve: false,
                      ),
                      onDelete: () => _confirmDelete(
                          context, state, requests[i]),
                    ),
                    if (i < requests.length - 1)
                      Divider(height: 1, color: theme.dividerColor),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    AppState state,
  ) async {
    final result = await showDetailDrawer<Request>(
      context,
      width: 520,
      child: RequestEditorDrawer(
        type: type,
        allEmployees: state.employees,
        shifts: state.shifts,
        leaveTypes: state.activeLeaveTypes,
      ),
    );
    if (result != null) {
      await state.upsertRequest(result);
    }
  }

  Future<void> _confirmResolve(
    BuildContext context,
    AppState state,
    Request request, {
    required bool approve,
  }) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? 'Approve request?' : 'Reject request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: approve
                ? null
                : FilledButton.styleFrom(
                    backgroundColor: AppColors.statusDanger,
                  ),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
      if (approve) {
        await state.approveCurrentStep(request.id, note: note);
      } else {
        await state.rejectAtCurrentStep(request.id, note: note);
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState state,
    Request request,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text(
            'This permanently removes the request from history.'),
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
    if (ok == true) {
      await state.deleteRequest(request.id);
    }
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.employee,
    required this.shift,
    required this.leaveType,
    required this.policy,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  final Request request;
  final Employee? employee;
  final Shift? shift;
  final LeaveType? leaveType;
  final ApprovalPolicy? policy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, y');
    final name = employee?.name.isNotEmpty == true
        ? employee!.name
        : 'id ${request.requesterUserId}';
    final initial = name.substring(0, 1).toUpperCase();

    String dateLabel() {
      if (request.toDate == null ||
          DateUtils.isSameDay(request.toDate!, request.fromDate)) {
        return dateFmt.format(request.fromDate);
      }
      return '${dateFmt.format(request.fromDate)} – '
          '${dateFmt.format(request.toDate!)}';
    }

    final detail = <String>[];
    if (request.type == RequestType.leave && request.leaveType != null) {
      // Prefer the resolved name from the leave-type catalog; fall back
      // to the raw stored value (e.g. when the type was deleted).
      detail.add(leaveType?.name ?? request.leaveType!);
    }
    if (request.type == RequestType.attendance && shift != null) {
      detail.add('${shift!.name} (${shift!.formatRange()})');
    }
    if (request.type == RequestType.attendance &&
        (request.checkIn != null || request.checkOut != null)) {
      final timeFmt = DateFormat('HH:mm');
      detail.add(
        '${request.checkIn != null ? "in ${timeFmt.format(request.checkIn!)}" : ""}'
        '${request.checkIn != null && request.checkOut != null ? " · " : ""}'
        '${request.checkOut != null ? "out ${timeFmt.format(request.checkOut!)}" : ""}',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 16,
            child: Text(initial, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StatusPill(
                      label: request.status.label,
                      tone: _statusTone(request.status),
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
                if (detail.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    detail.join('  ·  '),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  request.reason,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (policy != null && policy!.steps.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  ApprovalStepper(policy: policy!, request: request),
                ],
                if (request.isResolved &&
                    request.resolverNote != null &&
                    request.resolverNote!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      'Note: ${request.resolverNote}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Submitted ${DateFormat('MMM d').format(request.createdAt)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 8),
              if (request.isPending)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusDanger,
                        side: BorderSide(
                          color: AppColors.statusDanger
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(_approveLabel()),
                    ),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.hintColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  StatusTone _statusTone(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending:
        return StatusTone.warning;
      case RequestStatus.approved:
        return StatusTone.success;
      case RequestStatus.rejected:
        return StatusTone.danger;
      case RequestStatus.cancelled:
        return StatusTone.muted;
    }
  }

  String _approveLabel() {
    if (policy == null || policy!.steps.isEmpty) return 'Approve';
    final step = policy!.steps.firstWhere(
      (s) => s.order == request.currentStepOrder,
      orElse: () => policy!.steps.last,
    );
    return 'Approve · ${step.name}';
  }
}
