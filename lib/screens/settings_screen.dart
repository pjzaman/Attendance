import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/approval_policy.dart';
import '../models/device.dart';
import '../models/employee_group.dart';
import '../models/holiday.dart';
import '../models/leave_type.dart';
import '../models/office_location.dart';
import '../models/request.dart';
import '../models/role.dart';
import '../models/session.dart';
import '../models/team.dart';
import '../models/tracking_method.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/approval_stepper.dart';
import '../widgets/detail_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_row.dart';
import '../widgets/status_pill.dart';
import 'app_user_editor_drawer.dart';
import 'approval_policy_editor_drawer.dart';
import 'device_editor_drawer.dart';
import 'employee_group_editor_drawer.dart';
import 'holiday_editor_drawer.dart';
import 'leave_type_editor_drawer.dart';
import 'office_location_editor_drawer.dart';
import 'role_editor_drawer.dart';
import 'session_editor_drawer.dart';
import 'team_editor_drawer.dart';
import 'tracking_method_editor_drawer.dart';

/// Settings hub organized into the doc's nested IA. The left rail
/// groups settings pages by section (HR Management / Approvals / Leave
/// / ACL / Integrations); the right pane shows the selected page.
/// Replaces the previous flat 11-tab layout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum _Page {
  hrTeams,
  hrGroups,
  hrLocations,
  hrSessions,
  hrHolidays,
  hrTracking,
  approvalPolicies,
  leaveTypes,
  aclRoles,
  aclUsers,
  integrationsDevices,
  adminSystem,
}

class _PageDef {
  const _PageDef({
    required this.page,
    required this.label,
    required this.icon,
    required this.body,
  });
  final _Page page;
  final String label;
  final IconData icon;
  final Widget body;
}

class _Section {
  const _Section({required this.title, required this.pages});
  final String title;
  final List<_PageDef> pages;
}

class _SettingsScreenState extends State<SettingsScreen> {
  _Page _selected = _Page.hrTeams;

  static const List<_Section> _sections = <_Section>[
    _Section(
      title: 'HR Management',
      pages: <_PageDef>[
        _PageDef(
          page: _Page.hrTeams,
          label: 'Teams',
          icon: Icons.groups_outlined,
          body: _TeamsTab(),
        ),
        _PageDef(
          page: _Page.hrGroups,
          label: 'Groups',
          icon: Icons.workspaces_outline,
          body: _EmployeeGroupsTab(),
        ),
        _PageDef(
          page: _Page.hrLocations,
          label: 'Office Locations',
          icon: Icons.business_outlined,
          body: _OfficeLocationsTab(),
        ),
        _PageDef(
          page: _Page.hrSessions,
          label: 'Sessions',
          icon: Icons.event_outlined,
          body: _SessionsTab(),
        ),
        _PageDef(
          page: _Page.hrHolidays,
          label: 'Holidays',
          icon: Icons.celebration_outlined,
          body: _HolidaysTab(),
        ),
        _PageDef(
          page: _Page.hrTracking,
          label: 'Tracking Methods',
          icon: Icons.swap_calls,
          body: _TrackingMethodsTab(),
        ),
      ],
    ),
    _Section(
      title: 'Approvals',
      pages: <_PageDef>[
        _PageDef(
          page: _Page.approvalPolicies,
          label: 'Approval Policies',
          icon: Icons.account_tree_outlined,
          body: _ApprovalsTab(),
        ),
      ],
    ),
    _Section(
      title: 'Leave',
      pages: <_PageDef>[
        _PageDef(
          page: _Page.leaveTypes,
          label: 'Leave Types',
          icon: Icons.beach_access_outlined,
          body: _LeaveTypesTab(),
        ),
      ],
    ),
    _Section(
      title: 'ACL',
      pages: <_PageDef>[
        _PageDef(
          page: _Page.aclRoles,
          label: 'Roles',
          icon: Icons.shield_outlined,
          body: _RolesTab(),
        ),
        _PageDef(
          page: _Page.aclUsers,
          label: 'Users',
          icon: Icons.person_outline,
          body: _UsersTab(),
        ),
      ],
    ),
    _Section(
      title: 'Integrations',
      pages: <_PageDef>[
        _PageDef(
          page: _Page.integrationsDevices,
          label: 'Devices',
          icon: Icons.developer_board,
          body: _DevicesTab(),
        ),
      ],
    ),
    _Section(
      title: 'Admin',
      pages: <_PageDef>[
        _PageDef(
          page: _Page.adminSystem,
          label: 'System',
          icon: Icons.settings_suggest_outlined,
          body: _SystemTab(),
        ),
      ],
    ),
  ];

  _PageDef _activePage() {
    for (final s in _sections) {
      for (final p in s.pages) {
        if (p.page == _selected) return p;
      }
    }
    return _sections.first.pages.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _activePage();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ─── Left rail ──────────────────────────────────────────────
          SizedBox(
            width: 240,
            child: Card(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: <Widget>[
                  for (final section in _sections) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xs,
                      ),
                      child: Text(
                        section.title.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    for (final p in section.pages)
                      _RailItem(
                        page: p,
                        selected: _selected == p.page,
                        onTap: () => setState(() => _selected = p.page),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // ─── Right pane ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(active.icon, size: 22),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        active.label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: active.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final _PageDef page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg =
        selected ? AppColors.brandPrimary : theme.textTheme.bodyMedium?.color;
    final bg = selected
        ? AppColors.brandPrimary.withValues(alpha: 0.10)
        : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 8),
          child: Row(
            children: <Widget>[
              Icon(page.icon, size: 18, color: fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  page.label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalsTab extends StatelessWidget {
  const _ApprovalsTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final policies = state.approvalPolicies;
    final theme = Theme.of(context);

    final policiesByType = <RequestType, List<ApprovalPolicy>>{};
    for (final p in policies) {
      policiesByType.putIfAbsent(p.type, () => <ApprovalPolicy>[]).add(p);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: () => _openEditor(context, state, null),
            newLabel: 'New policy',
          ),
          const SizedBox(height: AppSpacing.md),
          if (policies.isEmpty)
            const EmptyState(
              icon: Icons.account_tree_outlined,
              title: 'No approval policies yet',
              message:
                  'Create one to define a multi-step approval pipeline '
                  'per request type.',
            )
          else
            for (final t in RequestType.values) ...<Widget>[
              _TypeSection(
                type: t,
                policies: policiesByType[t] ?? const <ApprovalPolicy>[],
                onEdit: (p) => _openEditor(context, state, p),
                onCreateForType: () =>
                    _openEditor(context, state, null, fixedType: t),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
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
            child: Row(
              children: <Widget>[
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.statusInfo),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'New requests automatically attach to the active '
                    'policy for their type. In-flight requests keep '
                    'their existing pipeline even if the policy changes.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
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
    ApprovalPolicy? initial, {
    RequestType? fixedType,
  }) async {
    final result = await showDetailDrawer<ApprovalPolicyEditorResult>(
      context,
      width: 560,
      child: ApprovalPolicyEditorDrawer(
        initial: initial,
        fixedType: fixedType,
      ),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteApprovalPolicy(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertApprovalPolicy(result.saved!);
    }
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection({
    required this.type,
    required this.policies,
    required this.onEdit,
    required this.onCreateForType,
  });

  final RequestType type;
  final List<ApprovalPolicy> policies;
  final void Function(ApprovalPolicy) onEdit;
  final VoidCallback onCreateForType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Text(type.label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '· ${policies.length} polic${policies.length == 1 ? "y" : "ies"}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onCreateForType,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('New for ${type.label.toLowerCase()}'),
                ),
              ],
            ),
          ),
          if (policies.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Text(
                'No policy yet — ${type.label.toLowerCase()} requests fall '
                'back to single-click approval.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            )
          else ...<Widget>[
            Divider(height: 1, color: theme.dividerColor),
            for (int i = 0; i < policies.length; i++) ...<Widget>[
              _PolicyRow(
                policy: policies[i],
                onTap: () => onEdit(policies[i]),
              ),
              if (i < policies.length - 1)
                Divider(height: 1, color: theme.dividerColor),
            ],
          ],
        ],
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({required this.policy, required this.onTap});
  final ApprovalPolicy policy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = Request(
      id: 'preview',
      type: policy.type,
      requesterUserId: '',
      fromDate: DateTime.now(),
      reason: '',
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      currentStepOrder: 1,
      policyId: policy.id,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          policy.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusPill(
                        label: policy.isActive ? 'Active' : 'Inactive',
                        tone: policy.isActive
                            ? StatusTone.success
                            : StatusTone.muted,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${policy.steps.length} step'
                    '${policy.steps.length == 1 ? "" : "s"}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 3,
              child: ApprovalStepper(policy: policy, request: preview),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

// ─── Leave Types tab ─────────────────────────────────────────────────

class _LeaveTypesTab extends StatelessWidget {
  const _LeaveTypesTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final types = state.leaveTypes;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: () => _openEditor(context, state, null),
            newLabel: 'New leave type',
          ),
          const SizedBox(height: AppSpacing.md),
          if (types.isEmpty)
            const EmptyState(
              icon: Icons.beach_access_outlined,
              title: 'No leave types yet',
              message:
                  'Create leave types to populate the new-request dropdown.',
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
                        Text('Labour Law leaves',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '· ${types.length}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  for (int i = 0; i < types.length; i++) ...<Widget>[
                    _LeaveTypeRow(
                      type: types[i],
                      onTap: () => _openEditor(context, state, types[i]),
                      onToggleActive: (v) async {
                        await state.upsertLeaveType(
                          types[i].copyWith(isActive: v),
                        );
                      },
                    ),
                    if (i < types.length - 1)
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
    LeaveType? initial,
  ) async {
    final result = await showDetailDrawer<LeaveTypeEditorResult>(
      context,
      width: 480,
      child: LeaveTypeEditorDrawer(initial: initial),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteLeaveType(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertLeaveType(result.saved!);
    }
  }
}

class _LeaveTypeRow extends StatelessWidget {
  const _LeaveTypeRow({
    required this.type,
    required this.onTap,
    required this.onToggleActive,
  });

  final LeaveType type;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.shiftColorFor(type.id);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(color: color),
              ),
              alignment: Alignment.center,
              child: Text(
                type.code,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          type.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (type.genderConstraint !=
                          LeaveGenderConstraint.any) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        StatusPill(
                          label: type.genderConstraint.label,
                          tone: StatusTone.info,
                          dense: true,
                        ),
                      ],
                      if (!type.isPaid) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        const StatusPill(
                          label: 'Unpaid',
                          tone: StatusTone.muted,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.defaultDaysPerYear == 0
                        ? 'No preset cap'
                        : '${type.defaultDaysPerYear} day'
                            '${type.defaultDaysPerYear == 1 ? "" : "s"} / year',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Switch(
              value: type.isActive,
              onChanged: onToggleActive,
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

// ─── Sessions tab ────────────────────────────────────────────────────

class _SessionsTab extends StatelessWidget {
  const _SessionsTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sessions = state.sessions;
    final theme = Theme.of(context);

    final byType = <SessionType, List<Session>>{};
    for (final s in sessions) {
      byType.putIfAbsent(s.type, () => <Session>[]).add(s);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: () => _openSessionEditor(context, state, null),
            newLabel: 'New session',
          ),
          const SizedBox(height: AppSpacing.md),
          if (sessions.isEmpty)
            const EmptyState(
              icon: Icons.event_outlined,
              title: 'No sessions yet',
              message:
                  'Create a leave or payroll session to scope balances and reports.',
            )
          else
            for (final t in SessionType.values) ...<Widget>[
              _SessionTypeSection(
                type: t,
                sessions: byType[t] ?? const <Session>[],
                onEdit: (s) => _openSessionEditor(context, state, s),
                onActivate: (s) => state.activateSession(s.id),
                onCreateForType: () =>
                    _openSessionEditor(context, state, null, fixedType: t),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
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
            child: Row(
              children: <Widget>[
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.statusInfo),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'The Leave screen reads the active leave session. '
                    'Only one session per type can be active at a time.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSessionEditor(
    BuildContext context,
    AppState state,
    Session? initial, {
    SessionType? fixedType,
  }) async {
    final result = await showDetailDrawer<SessionEditorResult>(
      context,
      width: 520,
      child: SessionEditorDrawer(
        initial: initial,
        fixedType: fixedType,
      ),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteSession(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertSession(result.saved!);
    }
  }
}

class _SessionTypeSection extends StatelessWidget {
  const _SessionTypeSection({
    required this.type,
    required this.sessions,
    required this.onEdit,
    required this.onActivate,
    required this.onCreateForType,
  });

  final SessionType type;
  final List<Session> sessions;
  final void Function(Session) onEdit;
  final void Function(Session) onActivate;
  final VoidCallback onCreateForType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Text(type.label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '· ${sessions.length} session'
                  '${sessions.length == 1 ? "" : "s"}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onCreateForType,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('New ${type.label.toLowerCase()} session'),
                ),
              ],
            ),
          ),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Text(
                'No ${type.label.toLowerCase()} session — create one.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            )
          else ...<Widget>[
            Divider(height: 1, color: theme.dividerColor),
            for (int i = 0; i < sessions.length; i++) ...<Widget>[
              _SessionRow(
                session: sessions[i],
                onTap: () => onEdit(sessions[i]),
                onActivate: sessions[i].isActive
                    ? null
                    : () => onActivate(sessions[i]),
              ),
              if (i < sessions.length - 1)
                Divider(height: 1, color: theme.dividerColor),
            ],
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.onTap,
    required this.onActivate,
  });

  final Session session;
  final VoidCallback onTap;
  final VoidCallback? onActivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d, y');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          session.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusPill(
                        label: session.isActive ? 'Active' : 'Inactive',
                        tone: session.isActive
                            ? StatusTone.success
                            : StatusTone.muted,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${fmt.format(session.startDate)} – '
                    '${fmt.format(session.endDate)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            if (onActivate != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                onPressed: onActivate,
                child: const Text('Make active'),
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

// ─── Roles tab ───────────────────────────────────────────────────────

class _RolesTab extends StatelessWidget {
  const _RolesTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final roles = state.roles;
    final theme = Theme.of(context);
    final usersByRole = <String, int>{};
    for (final u in state.appUsers) {
      usersByRole.update(u.roleId, (n) => n + 1, ifAbsent: () => 1);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: () => _openRoleEditor(context, state, null),
            newLabel: 'New role',
          ),
          const SizedBox(height: AppSpacing.md),
          if (roles.isEmpty)
            const EmptyState(
              icon: Icons.shield_outlined,
              title: 'No roles yet',
              message:
                  'Create roles to give users granular access to the app.',
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
                        Text('All roles',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '· ${roles.length}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  for (int i = 0; i < roles.length; i++) ...<Widget>[
                    _RoleRow(
                      role: roles[i],
                      userCount: usersByRole[roles[i].id] ?? 0,
                      onTap: () =>
                          _openRoleEditor(context, state, roles[i]),
                    ),
                    if (i < roles.length - 1)
                      Divider(height: 1, color: theme.dividerColor),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openRoleEditor(
    BuildContext context,
    AppState state,
    Role? initial,
  ) async {
    final result = await showDetailDrawer<RoleEditorResult>(
      context,
      width: 560,
      child: RoleEditorDrawer(initial: initial),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteRole(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertRole(result.saved!);
    }
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.role,
    required this.userCount,
    required this.onTap,
  });

  final Role role;
  final int userCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          role.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (role.isBuiltIn) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        const StatusPill(
                          label: 'Built-in',
                          tone: StatusTone.info,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  if (role.description.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      role.description,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                  '${role.permissions.length} permission'
                  '${role.permissions.length == 1 ? "" : "s"}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
                Text(
                  '$userCount user${userCount == 1 ? "" : "s"}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

// ─── Users tab ───────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
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
    final theme = Theme.of(context);
    final q = _query.toLowerCase();
    final users = q.isEmpty
        ? state.appUsers
        : state.appUsers
            .where((u) =>
                u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q))
            .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            searchController: _searchCtrl,
            onSearchChanged: (v) => setState(() => _query = v.trim()),
            searchHint: 'Search by name or email…',
            onNew: state.roles.isEmpty
                ? null
                : () => _openUserEditor(context, state, null),
            newLabel: 'New user',
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.appUsers.isEmpty)
            const EmptyState(
              icon: Icons.person_outline,
              title: 'No app users yet',
              message:
                  'Create users to grant sign-in access. Roles control what '
                  'they can see and do.',
            )
          else if (users.isEmpty)
            const EmptyState(
              icon: Icons.search_off,
              title: 'No users match',
              message: 'Try a different search.',
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
                        Text('App users',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '· ${users.length}'
                          '${q.isEmpty ? "" : " of ${state.appUsers.length}"}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  for (int i = 0; i < users.length; i++) ...<Widget>[
                    _AppUserRow(
                      user: users[i],
                      role: state.roleById(users[i].roleId),
                      onTap: () =>
                          _openUserEditor(context, state, users[i]),
                    ),
                    if (i < users.length - 1)
                      Divider(height: 1, color: theme.dividerColor),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openUserEditor(
    BuildContext context,
    AppState state,
    AppUser? initial,
  ) async {
    final result = await showDetailDrawer<AppUserEditorResult>(
      context,
      width: 520,
      child: AppUserEditorDrawer(
        initial: initial,
        roles: state.roles,
        employees: state.employees,
      ),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteAppUser(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertAppUser(result.saved!);
    }
  }
}

class _AppUserRow extends StatelessWidget {
  const _AppUserRow({
    required this.user,
    required this.role,
    required this.onTap,
  });

  final AppUser user;
  final Role? role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = user.name.isNotEmpty
        ? user.name.substring(0, 1).toUpperCase()
        : '?';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 18,
              child: Text(initial, style: const TextStyle(fontSize: 14)),
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
                          user.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusPill(
                        label: user.isVerified ? 'Verified' : 'Unverified',
                        tone: user.isVerified
                            ? StatusTone.success
                            : StatusTone.warning,
                        dense: true,
                      ),
                      if (!user.isActive) ...<Widget>[
                        const SizedBox(width: 6),
                        const StatusPill(
                          label: 'Inactive',
                          tone: StatusTone.muted,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  role?.name ?? '— missing role —',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (user.employeeUserId != null)
                  Text(
                    'Linked to ${user.employeeUserId}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

// ─── Devices tab ─────────────────────────────────────────────────────

class _DevicesTab extends StatelessWidget {
  const _DevicesTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final devices = state.devices;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: () => _openEditor(context, state, null),
            newLabel: 'New device',
          ),
          const SizedBox(height: AppSpacing.md),
          const _BridgeStatusPanel(),
          const SizedBox(height: AppSpacing.md),
          if (devices.isEmpty)
            const EmptyState(
              icon: Icons.developer_board,
              title: 'No devices yet',
              message:
                  'Register a biometric device to track its connection and sync status here.',
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
                        Text('Connected devices',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '· ${devices.length}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  for (int i = 0; i < devices.length; i++) ...<Widget>[
                    _DeviceRow(
                      device: devices[i],
                      onTap: () => _openEditor(context, state, devices[i]),
                    ),
                    if (i < devices.length - 1)
                      Divider(height: 1, color: theme.dividerColor),
                  ],
                ],
              ),
            ),
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
            child: Row(
              children: <Widget>[
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.statusInfo),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Sync targets the active device\'s IP / port / commKey / '
                    'timeouts. .env is only used as a fallback when no device '
                    'is registered. Use Test to verify a device without running '
                    'a full sync.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
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
    Device? initial,
  ) async {
    final result = await showDetailDrawer<DeviceEditorResult>(
      context,
      width: 560,
      child: DeviceEditorDrawer(initial: initial),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteDevice(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertDevice(result.saved!);
    }
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.onTap,
  });
  final Device device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d, y · HH:mm');
    final connected = device.lastSyncAt != null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.developer_board,
                  color: AppColors.brandPrimary, size: 20),
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
                          device.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusPill(
                        label:
                            connected ? 'Connected' : 'Not yet synced',
                        tone: connected
                            ? StatusTone.success
                            : StatusTone.muted,
                        dense: true,
                      ),
                      if (!device.isActive) ...<Widget>[
                        const SizedBox(width: 6),
                        const StatusPill(
                          label: 'Inactive',
                          tone: StatusTone.muted,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (device.brand.isNotEmpty || device.model.isNotEmpty)
                        '${device.brand}'
                            '${device.brand.isNotEmpty && device.model.isNotEmpty ? " " : ""}'
                            '${device.model}',
                      device.connectionLabel,
                      if (device.officeLocation != null)
                        device.officeLocation!,
                    ].where((s) => s.isNotEmpty).join('  ·  '),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  device.lastSyncAt == null
                      ? '— never —'
                      : fmt.format(device.lastSyncAt!),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Last sync',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

// ─── Holidays tab ────────────────────────────────────────────────────

class _HolidaysTab extends StatelessWidget {
  const _HolidaysTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final holidays = state.holidays;
    final upcoming = holidays
        .where((h) => !DateUtils.dateOnly(h.date).isBefore(today))
        .toList();
    final past = holidays
        .where((h) => DateUtils.dateOnly(h.date).isBefore(today))
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: () => _openHolidayEditor(context, state, null),
            newLabel: 'New holiday',
          ),
          const SizedBox(height: AppSpacing.md),
          if (holidays.isEmpty)
            const EmptyState(
              icon: Icons.celebration_outlined,
              title: 'No holidays yet',
              message:
                  'Create holidays so schedules can opt to skip them via "Include public holidays".',
            )
          else ...<Widget>[
            _HolidayGroup(
              title: 'Upcoming',
              entries: upcoming,
              onTap: (h) => _openHolidayEditor(context, state, h),
              emptyMessage: 'No upcoming holidays.',
              theme: theme,
            ),
            if (past.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _HolidayGroup(
                title: 'Past',
                entries: past,
                onTap: (h) => _openHolidayEditor(context, state, h),
                emptyMessage: '',
                theme: theme,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _openHolidayEditor(
    BuildContext context,
    AppState state,
    Holiday? initial,
  ) async {
    final result = await showDetailDrawer<HolidayEditorResult>(
      context,
      width: 480,
      child: HolidayEditorDrawer(initial: initial),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteHoliday(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertHoliday(result.saved!);
    }
  }
}

class _HolidayGroup extends StatelessWidget {
  const _HolidayGroup({
    required this.title,
    required this.entries,
    required this.onTap,
    required this.emptyMessage,
    required this.theme,
  });

  final String title;
  final List<Holiday> entries;
  final ValueChanged<Holiday> onTap;
  final String emptyMessage;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '· ${entries.length}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
              ),
              child: Text(
                emptyMessage,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            )
          else ...<Widget>[
            Divider(height: 1, color: theme.dividerColor),
            for (int i = 0; i < entries.length; i++) ...<Widget>[
              _HolidayRow(
                holiday: entries[i],
                onTap: () => onTap(entries[i]),
              ),
              if (i < entries.length - 1)
                Divider(height: 1, color: theme.dividerColor),
            ],
          ],
        ],
      ),
    );
  }
}

class _HolidayRow extends StatelessWidget {
  const _HolidayRow({required this.holiday, required this.onTap});
  final Holiday holiday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d, y');
    final weekdayFmt = DateFormat('EEEE');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusWarning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.statusWarning.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    DateFormat('MMM').format(holiday.date).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusWarning,
                    ),
                  ),
                  Text(
                    '${holiday.date.day}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
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
                          holiday.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatusPill(
                        label: holiday.type.label,
                        tone: holiday.type == HolidayType.public
                            ? StatusTone.warning
                            : holiday.type == HolidayType.optional
                                ? StatusTone.info
                                : StatusTone.muted,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${weekdayFmt.format(holiday.date)}, '
                    '${dateFmt.format(holiday.date)}'
                    '${holiday.notes == null || holiday.notes!.isEmpty ? "" : "  ·  ${holiday.notes}"}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

// ─── Office Locations tab ────────────────────────────────────────────

class _OfficeLocationsTab extends StatelessWidget {
  const _OfficeLocationsTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final locations = state.officeLocations;
    final deviceCounts = <String, int>{};
    for (final d in state.devices) {
      final loc = d.officeLocation;
      if (loc == null || loc.isEmpty) continue;
      deviceCounts.update(loc, (n) => n + 1, ifAbsent: () => 1);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: () => _openLocationEditor(context, state, null),
            newLabel: 'New location',
          ),
          const SizedBox(height: AppSpacing.md),
          if (locations.isEmpty)
            const EmptyState(
              icon: Icons.business_outlined,
              title: 'No office locations yet',
              message:
                  'Register the workspaces where employees punch in. Used by Devices and (future) employee filters.',
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
                        Text('All locations',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '· ${locations.length}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  for (int i = 0; i < locations.length; i++) ...<Widget>[
                    _LocationRow(
                      location: locations[i],
                      // Match either name or short_name against the
                      // free-text Device.officeLocation field.
                      deviceCount: (deviceCounts[locations[i].name] ?? 0) +
                          (locations[i].shortName == null
                              ? 0
                              : (deviceCounts[locations[i].shortName!] ?? 0)),
                      onTap: () =>
                          _openLocationEditor(context, state, locations[i]),
                    ),
                    if (i < locations.length - 1)
                      Divider(height: 1, color: theme.dividerColor),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openLocationEditor(
    BuildContext context,
    AppState state,
    OfficeLocation? initial,
  ) async {
    final result = await showDetailDrawer<OfficeLocationEditorResult>(
      context,
      width: 520,
      child: OfficeLocationEditorDrawer(initial: initial),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteOfficeLocation(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertOfficeLocation(result.saved!);
    }
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.location,
    required this.deviceCount,
    required this.onTap,
  });

  final OfficeLocation location;
  final int deviceCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cityCountry =
        <String>[
          if (location.city != null && location.city!.isNotEmpty)
            location.city!,
          if (location.country != null && location.country!.isNotEmpty)
            location.country!,
        ].join(', ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.business_outlined,
                  color: AppColors.brandPrimary, size: 20),
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
                          location.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (location.shortName != null &&
                          location.shortName!.isNotEmpty) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            location.shortName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                      if (!location.isActive) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        const StatusPill(
                          label: 'Inactive',
                          tone: StatusTone.muted,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  if (cityCountry.isNotEmpty ||
                      (location.address?.isNotEmpty ?? false)) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      <String>[
                        if (location.address != null &&
                            location.address!.isNotEmpty)
                          location.address!,
                        if (cityCountry.isNotEmpty) cityCountry,
                      ].join('  ·  '),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                  '$deviceCount device${deviceCount == 1 ? "" : "s"}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

// ─── Teams tab ───────────────────────────────────────────────────────

class _TeamsTab extends StatelessWidget {
  const _TeamsTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final teams = state.teams;
    final empById = <String, dynamic>{
      for (final e in state.employees) e.userId: e,
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: () => _openTeamEditor(context, state, null),
            newLabel: 'New team',
          ),
          const SizedBox(height: AppSpacing.md),
          if (teams.isEmpty)
            const EmptyState(
              icon: Icons.groups_outlined,
              title: 'No teams yet',
              message:
                  'Create teams to organize employees by reporting line / function.',
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
                        Text('All teams',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '· ${teams.length}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  for (int i = 0; i < teams.length; i++) ...<Widget>[
                    _TeamRow(
                      team: teams[i],
                      leaderName: _resolveLeaderName(
                          empById, teams[i].leaderUserId),
                      onTap: () =>
                          _openTeamEditor(context, state, teams[i]),
                    ),
                    if (i < teams.length - 1)
                      Divider(height: 1, color: theme.dividerColor),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String? _resolveLeaderName(
      Map<String, dynamic> empById, String? leaderId) {
    if (leaderId == null) return null;
    final e = empById[leaderId];
    if (e == null) return 'id $leaderId';
    final name = (e.name as String?) ?? '';
    return name.trim().isEmpty ? 'id $leaderId' : name;
  }

  Future<void> _openTeamEditor(
    BuildContext context,
    AppState state,
    Team? initial,
  ) async {
    final result = await showDetailDrawer<TeamEditorResult>(
      context,
      width: 500,
      child: TeamEditorDrawer(
        initial: initial,
        employees: state.employees,
      ),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteTeam(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertTeam(result.saved!);
    }
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.team,
    required this.leaderName,
    required this.onTap,
  });

  final Team team;
  final String? leaderName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.groups_outlined,
                  color: AppColors.brandPrimary, size: 20),
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
                          team.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!team.isActive) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        const StatusPill(
                          label: 'Inactive',
                          tone: StatusTone.muted,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  if (team.description != null &&
                      team.description!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      team.description!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                  leaderName ?? 'Unassigned',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('Lead',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

// ─── Groups tab ──────────────────────────────────────────────────────

class _EmployeeGroupsTab extends StatelessWidget {
  const _EmployeeGroupsTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final groups = state.employeeGroups;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: () => _openGroupEditor(context, state, null),
            newLabel: 'New group',
          ),
          const SizedBox(height: AppSpacing.md),
          if (groups.isEmpty)
            const EmptyState(
              icon: Icons.workspaces_outline,
              title: 'No groups yet',
              message:
                  'Groups are looser than teams — projects, training cohorts, etc.',
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
                        Text('All groups',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '· ${groups.length}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  for (int i = 0; i < groups.length; i++) ...<Widget>[
                    _GroupRow(
                      group: groups[i],
                      onTap: () =>
                          _openGroupEditor(context, state, groups[i]),
                    ),
                    if (i < groups.length - 1)
                      Divider(height: 1, color: theme.dividerColor),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openGroupEditor(
    BuildContext context,
    AppState state,
    EmployeeGroup? initial,
  ) async {
    final result = await showDetailDrawer<EmployeeGroupEditorResult>(
      context,
      width: 480,
      child: EmployeeGroupEditorDrawer(initial: initial),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteEmployeeGroup(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertEmployeeGroup(result.saved!);
    }
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.group, required this.onTap});
  final EmployeeGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.workspaces_outline,
                  color: AppColors.brandAccent, size: 20),
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
                          group.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!group.isActive) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        const StatusPill(
                          label: 'Inactive',
                          tone: StatusTone.muted,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  if (group.description != null &&
                      group.description!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      group.description!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

// ─── Tracking Methods tab ────────────────────────────────────────────

class _TrackingMethodsTab extends StatelessWidget {
  const _TrackingMethodsTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final methods = state.trackingMethods;
    final locById = <String, OfficeLocation>{
      for (final l in state.officeLocations) l.id: l,
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            showSearch: false,
            onNew: () => _openTrackingMethodEditor(context, state, null),
            newLabel: 'New tracking method',
          ),
          const SizedBox(height: AppSpacing.md),
          if (methods.isEmpty)
            const EmptyState(
              icon: Icons.swap_calls,
              title: 'No tracking methods yet',
              message:
                  'Bundle the channels (mobile / web / device) employees can use to clock in.',
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
                        Text('All tracking methods',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '· ${methods.length}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),
                  for (int i = 0; i < methods.length; i++) ...<Widget>[
                    _TrackingMethodRow(
                      method: methods[i],
                      location: methods[i].officeLocationId == null
                          ? null
                          : locById[methods[i].officeLocationId!],
                      onTap: () => _openTrackingMethodEditor(
                          context, state, methods[i]),
                    ),
                    if (i < methods.length - 1)
                      Divider(height: 1, color: theme.dividerColor),
                  ],
                ],
              ),
            ),
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
            child: Row(
              children: <Widget>[
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.statusInfo),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'v1 only the Attendance Device channel actually syncs '
                    'data. Mobile App / Web flags are for IA + future '
                    'rollout — toggling them surfaces them in employee '
                    '"how to clock in" copy.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTrackingMethodEditor(
    BuildContext context,
    AppState state,
    TrackingMethod? initial,
  ) async {
    final result = await showDetailDrawer<TrackingMethodEditorResult>(
      context,
      width: 540,
      child: TrackingMethodEditorDrawer(
        initial: initial,
        officeLocations: state.officeLocations,
      ),
    );
    if (result == null) return;
    if (result.deletedId != null) {
      await state.deleteTrackingMethod(result.deletedId!);
    } else if (result.saved != null) {
      await state.upsertTrackingMethod(result.saved!);
    }
  }
}

class _TrackingMethodRow extends StatelessWidget {
  const _TrackingMethodRow({
    required this.method,
    required this.location,
    required this.onTap,
  });

  final TrackingMethod method;
  final OfficeLocation? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d, y');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.swap_calls,
                  color: AppColors.brandPrimary, size: 20),
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
                          method.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!method.isActive) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        const StatusPill(
                          label: 'Inactive',
                          tone: StatusTone.muted,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${location?.name ?? "Org-wide fallback"}'
                    '  ·  effective ${fmt.format(method.effectiveDate)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: <Widget>[
                      _ChannelChip(
                        icon: Icons.phone_iphone,
                        label: 'Mobile',
                        enabled: method.allowMobileApp,
                      ),
                      _ChannelChip(
                        icon: Icons.public,
                        label: 'Web',
                        enabled: method.allowWeb,
                      ),
                      _ChannelChip(
                        icon: Icons.fingerprint,
                        label: 'Device',
                        enabled: method.allowDevice,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({
    required this.icon,
    required this.label,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled ? AppColors.statusSuccess : theme.hintColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.statusSuccess.withValues(alpha: 0.13)
            : theme.dividerColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(
          color: enabled
              ? AppColors.statusSuccess.withValues(alpha: 0.4)
              : theme.dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: enabled ? color : theme.hintColor,
              decoration: enabled ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bridge status panel (lives at top of Devices tab) ──────────────

class _BridgeStatusPanel extends StatelessWidget {
  const _BridgeStatusPanel();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final bridges = state.bridges;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.cable, size: 18, color: theme.hintColor),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Bridge services',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '· ${bridges.length}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (bridges.isEmpty)
              Text(
                'No bridge has reported in yet. Install apon-bridge.exe '
                'on the PC wired to the device — the Devices status '
                'panel updates as soon as it sends its first heartbeat.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              )
            else
              for (int i = 0; i < bridges.length; i++) ...<Widget>[
                _BridgeRow(data: bridges[i]),
                if (i < bridges.length - 1)
                  Divider(height: 16, color: theme.dividerColor),
              ],
          ],
        ),
      ),
    );
  }
}

class _BridgeRow extends StatefulWidget {
  const _BridgeRow({required this.data});
  final Map<String, Object?> data;

  @override
  State<_BridgeRow> createState() => _BridgeRowState();
}

class _BridgeRowState extends State<_BridgeRow> {
  String? _runningAction;

  Future<void> _send(String action, {Map<String, Object?>? params}) async {
    final id = (widget.data['bridgeId'] as String?) ?? '';
    if (id.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final state = context.read<AppState>();
    setState(() => _runningAction = action);
    try {
      final cmdId = await state.queueBridgeCommand(
        bridgeId: id,
        action: action,
        params: params ?? const <String, Object?>{},
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('Queued $action for $id (${cmdId.substring(0, 12)}…)'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusDanger,
          content: Text('Failed to queue $action: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _runningAction = null);
    }
  }

  Future<void> _confirmThenSend({
    required String action,
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (ok == true) await _send(action);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final theme = Theme.of(context);
    final id = (data['bridgeId'] as String?) ?? 'unknown';
    final deviceId = (data['deviceId'] as String?) ?? '';
    final status = (data['status'] as String?) ?? 'unknown';
    final connected = (data['deviceConnected'] as bool?) ?? false;
    final lastError = data['lastError'] as String?;
    final lastSyncAt = _BridgeRowState._parseTs(data['lastSyncAt']);
    final updatedAt = _BridgeRowState._parseTs(data['updatedAt']);

    final tone = _BridgeRowState._toneFor(status);
    final stale = updatedAt != null &&
        DateTime.now().difference(updatedAt).inMinutes > 2;
    final effectiveTone = stale ? StatusTone.warning : tone;
    final effectiveLabel = stale ? 'Stale' : _BridgeRowState._statusLabel(status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    id,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (deviceId.isNotEmpty) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '· $deviceId',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        connected ? Icons.link : Icons.link_off,
                        size: 14,
                        color: connected
                            ? AppColors.statusSuccess
                            : AppColors.statusDanger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        connected ? 'Device linked' : 'Device dropped',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (lastSyncAt != null)
                    Text(
                      'Last sync ${_relative(lastSyncAt)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  if (updatedAt != null)
                    Text(
                      'Heartbeat ${_relative(updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: stale
                            ? AppColors.statusWarning
                            : theme.hintColor,
                      ),
                    ),
                ],
              ),
              if (lastError != null && lastError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    lastError,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.statusDanger,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  _BridgeActionButton(
                    icon: Icons.sync,
                    label: 'Sync now',
                    busy: _runningAction == 'manual_sync',
                    enabled: !stale && _runningAction == null,
                    onPressed: () => _send('manual_sync'),
                  ),
                  _BridgeActionButton(
                    icon: Icons.access_time,
                    label: 'Sync time',
                    busy: _runningAction == 'sync_time',
                    enabled: !stale && _runningAction == null,
                    onPressed: () => _send('sync_time'),
                  ),
                  _BridgeActionButton(
                    icon: Icons.delete_sweep_outlined,
                    label: 'Clear log',
                    danger: true,
                    busy: _runningAction == 'clear_log',
                    enabled: !stale && _runningAction == null,
                    onPressed: () => _confirmThenSend(
                      action: 'clear_log',
                      title: 'Clear device attendance log?',
                      body:
                          'Wipes every punch record stored on the device. '
                          'Punches already pushed to Firestore stay intact, '
                          'but anything not yet synced will be lost. This '
                          'is what you do once a year to keep the device '
                          'from filling up.',
                      confirmLabel: 'Clear log',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusPill(
          label: effectiveLabel,
          tone: effectiveTone,
          dense: true,
        ),
      ],
    );
  }

  static StatusTone _toneFor(String status) {
    switch (status) {
      case 'online':
        return StatusTone.success;
      case 'degraded':
        return StatusTone.warning;
      case 'error':
        return StatusTone.danger;
      case 'offline':
        return StatusTone.muted;
      default:
        return StatusTone.muted;
    }
  }

  static String _statusLabel(String s) =>
      s.isEmpty ? 'Unknown' : (s[0].toUpperCase() + s.substring(1));

  static DateTime? _parseTs(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v.toLocal();
    if (v is String) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  static String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class _BridgeActionButton extends StatelessWidget {
  const _BridgeActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.enabled = true,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool busy;
  final bool enabled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: danger ? AppColors.statusDanger : null,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
    return OutlinedButton.icon(
      onPressed: enabled && !busy ? onPressed : null,
      style: style,
      icon: busy
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

// ─── Admin → System tab ─────────────────────────────────────────────

class _SystemTab extends StatelessWidget {
  const _SystemTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.cloud_done_outlined,
                          size: 18, color: theme.hintColor),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Cloud workspace',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _Kv('Firebase project', 'attendance-app-apon'),
                  _Kv('Signed-in UID', state.firebaseUid ?? '—'),
                  _Kv(
                    'Connected bridges',
                    state.bridges.isEmpty
                        ? 'none'
                        : state.bridges
                            .map((b) => b['bridgeId'])
                            .whereType<String>()
                            .join(', '),
                  ),
                  _Kv(
                    'Last bridge sync',
                    state.lastBridgeSync == null
                        ? 'never'
                        : state.lastBridgeSync!.toLocal().toString(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv(this.k, this.v);
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 160,
            child: Text(
              k,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
