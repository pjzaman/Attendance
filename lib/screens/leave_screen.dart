import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';

import '../models/employee.dart';
import '../models/leave_type.dart';
import '../models/request.dart';
import '../models/session.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/leave_balance_card.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  Employee? _selected;
  String? _viewingSessionId;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.employees.isEmpty) {
      return const EmptyState(
        icon: Icons.beach_access_outlined,
        title: 'No employees yet',
        message:
            'Leave balances need employees first. Run a sync to pull them.',
      );
    }

    final theme = Theme.of(context);
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? state.employees
        : state.employees
            .where((e) =>
                e.name.toLowerCase().contains(q) ||
                e.userId.toLowerCase().contains(q))
            .toList();

    // Auto-pick the first employee on first frame so the right pane
    // doesn't open empty.
    final selected = _selected ??
        (filtered.isNotEmpty ? filtered.first : null);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ─── Left pane ──────────────────────────────────────────────
          SizedBox(
            width: 320,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) =>
                          setState(() => _query = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search employees…',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  Expanded(
                    child: filtered.isEmpty
                        ? const EmptyState(
                            icon: Icons.search_off,
                            title: 'No matches',
                            message: 'Try a different search term.',
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: theme.dividerColor),
                            itemBuilder: (context, i) {
                              final e = filtered[i];
                              final isSelected = selected?.userId == e.userId;
                              return _EmployeeListTile(
                                employee: e,
                                isSelected: isSelected,
                                onTap: () =>
                                    setState(() => _selected = e),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // ─── Right pane ─────────────────────────────────────────────
          Expanded(
            child: selected == null
                ? const EmptyState(
                    icon: Icons.beach_access_outlined,
                    title: 'Select an employee',
                    message: 'Pick an employee on the left to see their balance.',
                  )
                : _BalancePane(
                    state: state,
                    employee: selected,
                    sessionId: _viewingSessionId,
                    onSessionChanged: (id) =>
                        setState(() => _viewingSessionId = id),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeListTile extends StatelessWidget {
  const _EmployeeListTile({
    required this.employee,
    required this.isSelected,
    required this.onTap,
  });

  final Employee employee;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.brandPrimary.withValues(alpha: 0.08)
            : null,
        border: Border(
          left: BorderSide(
            color: isSelected ? AppColors.brandPrimary : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 16,
          child: Text(
            employee.userId.isNotEmpty
                ? employee.userId.substring(0, 1).toUpperCase()
                : '?',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        title: Text(
          employee.name.isNotEmpty ? employee.name : '(no name)',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text('user_id: ${employee.userId}'),
        dense: true,
      ),
    );
  }
}

class _BalancePane extends StatelessWidget {
  const _BalancePane({
    required this.state,
    required this.employee,
    required this.sessionId,
    required this.onSessionChanged,
  });

  final AppState state;
  final Employee employee;

  /// The session id the user is currently viewing. Null = active.
  final String? sessionId;
  final ValueChanged<String?> onSessionChanged;

  Session? _resolveSession() {
    final leaveSessions = state.sessionsOf(SessionType.leave);
    if (sessionId != null) {
      for (final s in leaveSessions) {
        if (s.id == sessionId) return s;
      }
    }
    return state.activeSessionOf(SessionType.leave);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = _resolveSession();
    final activeTypes = state.activeLeaveTypes;
    final usage = _LeaveUsage.compute(
      state.requests,
      employee.userId,
      session,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 24,
                child: Text(
                  employee.name.isNotEmpty
                      ? employee.name.substring(0, 1).toUpperCase()
                      : (employee.userId.isNotEmpty
                          ? employee.userId.substring(0, 1).toUpperCase()
                          : '?'),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      employee.name.isNotEmpty
                          ? employee.name
                          : '(no name)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'user_id: ${employee.userId}'
                      '${employee.isAdmin ? "  •  ADMIN" : ""}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              _SessionPicker(
                sessions: state.sessionsOf(SessionType.leave),
                selected: session,
                onSelected: (id) => onSessionChanged(id),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        Expanded(
          child: activeTypes.isEmpty
              ? const EmptyState(
                  icon: Icons.beach_access_outlined,
                  title: 'No active leave types',
                  message:
                      'Activate at least one leave type in Settings → Leave Types.',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _Summary(
                        types: activeTypes,
                        usage: usage,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final t in activeTypes) ...<Widget>[
                        LeaveBalanceCard(
                          type: t,
                          usedDays: usage.byTypeId[t.id] ?? 0,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (usage.pendingByTypeId.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        _PendingNote(usage: usage, types: activeTypes),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.types, required this.usage});
  final List<LeaveType> types;
  final _LeaveUsage usage;

  @override
  Widget build(BuildContext context) {
    final totalEntitled = types
        .map((t) => t.defaultDaysPerYear)
        .fold<int>(0, (a, b) => a + b);
    final totalUsed = usage.byTypeId.values.fold<int>(0, (a, b) => a + b);
    final totalPending =
        usage.pendingByTypeId.values.fold<int>(0, (a, b) => a + b);

    return Row(
      children: <Widget>[
        Expanded(
            child:
                _SummaryStat(label: 'Entitled', value: '$totalEntitled')),
        Expanded(
            child:
                _SummaryStat(label: 'Used', value: '$totalUsed')),
        Expanded(
            child: _SummaryStat(
                label: 'Pending', value: '$totalPending')),
        Expanded(
          child: _SummaryStat(
            label: 'Remaining',
            value: '${(totalEntitled - totalUsed).clamp(0, totalEntitled)}',
            highlight: true,
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.hintColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color:
                  highlight ? AppColors.brandPrimary : null,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingNote extends StatelessWidget {
  const _PendingNote({required this.usage, required this.types});
  final _LeaveUsage usage;
  final List<LeaveType> types;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typesById = <String, LeaveType>{for (final t in types) t.id: t};
    final entries = usage.pendingByTypeId.entries.toList();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusWarning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.statusWarning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.hourglass_top_outlined,
              color: AppColors.statusWarning, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Pending requests not yet counted: '
              '${entries.map((e) => '${e.value} d ${typesById[e.key]?.name ?? "?"}').join(', ')}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aggregated leave usage for a given employee + session, computed
/// from the requests list. Approved requests count as used; pending
/// requests are tracked separately. When [session] is null, falls back
/// to the current calendar year so the screen still works before any
/// session is configured.
class _LeaveUsage {
  _LeaveUsage({
    required this.byTypeId,
    required this.pendingByTypeId,
  });

  /// `leaveTypeId → days used` (approved only).
  final Map<String, int> byTypeId;

  /// `leaveTypeId → days pending`.
  final Map<String, int> pendingByTypeId;

  static _LeaveUsage compute(
    List<Request> all,
    String userId,
    Session? session,
  ) {
    final used = <String, int>{};
    final pending = <String, int>{};
    for (final r in all) {
      if (r.type != RequestType.leave) continue;
      if (r.requesterUserId != userId) continue;
      if (r.leaveType == null) continue;
      final key = r.leaveType!;
      if (!_inPeriod(r.fromDate, r.toDate, session)) continue;
      final days = _dayCount(r.fromDate, r.toDate);
      if (r.status == RequestStatus.approved) {
        used.update(key, (n) => n + days, ifAbsent: () => days);
      } else if (r.status == RequestStatus.pending) {
        pending.update(key, (n) => n + days, ifAbsent: () => days);
      }
    }
    return _LeaveUsage(byTypeId: used, pendingByTypeId: pending);
  }

  static bool _inPeriod(DateTime from, DateTime? to, Session? session) {
    if (session == null) {
      // Fallback: current calendar year — the previous behavior.
      final year = DateTime.now().year;
      return from.year == year || (to?.year ?? year) == year;
    }
    return session.contains(from) || (to != null && session.contains(to));
  }

  static int _dayCount(DateTime from, DateTime? to) {
    if (to == null) return 1;
    return to.difference(from).inDays + 1;
  }
}

class _SessionPicker extends StatelessWidget {
  const _SessionPicker({
    required this.sessions,
    required this.selected,
    required this.onSelected,
  });

  final List<Session> sessions;
  final Session? selected;

  /// `null` value means "fall back to the active session".
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d');
    final yearFmt = DateFormat('y');

    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          'No leave sessions',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.hintColor),
        ),
      );
    }

    return PopupMenuButton<String?>(
      tooltip: 'Switch session',
      onSelected: onSelected,
      itemBuilder: (_) => <PopupMenuEntry<String?>>[
        for (final s in sessions)
          PopupMenuItem<String?>(
            value: s.id,
            child: Row(
              children: <Widget>[
                Icon(
                  s.isActive ? Icons.check_circle : Icons.circle_outlined,
                  size: 14,
                  color: s.isActive
                      ? AppColors.statusSuccess
                      : theme.hintColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${s.name}  ·  ${fmt.format(s.startDate)} – '
                    '${fmt.format(s.endDate)}, ${yearFmt.format(s.endDate)}',
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.event_outlined, size: 16, color: theme.hintColor),
            const SizedBox(width: 6),
            Text(
              selected?.name ?? 'No session',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
