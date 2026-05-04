import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../models/employee_child_records.dart';
import '../models/employee_document.dart';
import '../models/employee_group.dart';
import '../models/employee_profile.dart';
import '../models/office_location.dart';
import '../models/schedule.dart';
import '../models/team.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/profile_completeness_meter.dart';
import '../widgets/status_pill.dart';

class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({
    super.key,
    required this.employee,
    required this.onBack,
  });

  final Employee employee;
  final VoidCallback onBack;

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late EmployeeProfile _draft;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 12, vsync: this);
    _draft = context.read<AppState>().profileFor(widget.employee.userId);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _update(EmployeeProfile updated) {
    setState(() {
      _draft = updated;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    await context.read<AppState>().upsertEmployeeProfile(_draft);
    if (mounted) setState(() => _dirty = false);
  }

  Future<bool> _confirmDiscardIfDirty() async {
    if (!_dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text(
          'You have unsaved profile changes. Going back will discard them.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.statusDanger,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Pull live profile from state so other surfaces editing the same
    // record show through; but always render through `_draft` so user
    // edits don't get clobbered mid-flight.
    final docs = state.documentsFor(widget.employee.userId);
    final schedules = state.schedules;

    return Column(
      children: <Widget>[
        _Header(
          employee: widget.employee,
          profile: _draft,
          dirty: _dirty,
          onBack: () async {
            if (await _confirmDiscardIfDirty()) widget.onBack();
          },
          onSave: _save,
        ),
        TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const <Tab>[
            Tab(text: 'General'),
            Tab(text: 'Personal'),
            Tab(text: 'Employment'),
            Tab(text: 'Bank Details'),
            Tab(text: 'Documents'),
            Tab(text: 'Family'),
            Tab(text: 'Education'),
            Tab(text: 'Trainings'),
            Tab(text: 'Histories'),
            Tab(text: 'Disciplinary'),
            Tab(text: 'Achievements'),
            Tab(text: 'Addresses'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: <Widget>[
              _GeneralTab(employee: widget.employee, profile: _draft),
              _PersonalTab(draft: _draft, onChanged: _update),
              _EmploymentTab(
                draft: _draft,
                onChanged: _update,
                schedules: schedules,
                allEmployees: state.employees,
                teams: state.activeTeams,
                employeeGroups: state.activeEmployeeGroups,
                officeLocations: state.activeOfficeLocations,
              ),
              _BankTab(draft: _draft, onChanged: _update),
              _DocumentsTab(
                userId: widget.employee.userId,
                documents: docs,
                state: state,
              ),
              _FamilyTab(userId: widget.employee.userId, state: state),
              _EducationTab(userId: widget.employee.userId, state: state),
              _TrainingsTab(userId: widget.employee.userId, state: state),
              _HistoryTab(userId: widget.employee.userId, state: state),
              _DisciplinaryTab(
                  userId: widget.employee.userId, state: state),
              _AchievementsTab(
                  userId: widget.employee.userId, state: state),
              _AddressesTab(
                  userId: widget.employee.userId, state: state),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.employee,
    required this.profile,
    required this.dirty,
    required this.onBack,
    required this.onSave,
  });

  final Employee employee;
  final EmployeeProfile profile;
  final bool dirty;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullName = _composeName(employee, profile);
    final initial = fullName.isNotEmpty
        ? fullName.substring(0, 1).toUpperCase()
        : (employee.userId.isNotEmpty
            ? employee.userId.substring(0, 1).toUpperCase()
            : '?');

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to list',
            onPressed: onBack,
          ),
          const SizedBox(width: AppSpacing.sm),
          ProfileCompletenessMeter(
            completeness: profile.completeness,
            initial: initial,
            size: 56,
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
                        fullName.isEmpty ? '(no name)' : fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (employee.isAdmin) ...<Widget>[
                      const SizedBox(width: AppSpacing.sm),
                      const StatusPill(
                        label: 'Admin',
                        tone: StatusTone.warning,
                        dense: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${profile.designation ?? '—'}'
                  '${profile.department == null ? '' : '  ·  ${profile.department}'}'
                  '  ·  user_id ${employee.userId}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (dirty) ...<Widget>[
            Text(
              'Unsaved changes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.statusWarning,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          FilledButton.icon(
            onPressed: dirty ? onSave : null,
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static String _composeName(Employee e, EmployeeProfile p) {
    final parts = <String>[];
    if ((p.firstName ?? '').trim().isNotEmpty) parts.add(p.firstName!.trim());
    if ((p.lastName ?? '').trim().isNotEmpty) parts.add(p.lastName!.trim());
    if (parts.isNotEmpty) return parts.join(' ');
    if ((p.displayName ?? '').trim().isNotEmpty) return p.displayName!.trim();
    return e.name;
  }
}

// ─── Form helpers ────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _TextFieldRow extends StatelessWidget {
  const _TextFieldRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return _Field(
      label: label,
      child: TextFormField(
        initialValue: value ?? '',
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
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

class _DateFieldRow extends StatelessWidget {
  const _DateFieldRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d, y');
    return _Field(
      label: label,
      child: Row(
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: value ?? DateTime.now(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime(2100),
                );
                if (picked != null) onChanged(DateUtils.dateOnly(picked));
              },
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
                      child: Text(
                        value == null ? '— not set —' : fmt.format(value!),
                        style: value == null
                            ? theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.hintColor)
                            : theme.textTheme.bodyMedium,
                      ),
                    ),
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: theme.hintColor),
                  ],
                ),
              ),
            ),
          ),
          if (value != null) ...<Widget>[
            IconButton(
              icon: const Icon(Icons.clear, size: 16),
              tooltip: 'Clear',
              visualDensity: VisualDensity.compact,
              onPressed: () => onChanged(null),
            ),
          ],
        ],
      ),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return _Field(
      label: label,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: hint ?? '— not set —',
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

// ─── General tab (read-only synced fields) ───────────────────────────

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({required this.employee, required this.profile});
  final Employee employee;
  final EmployeeProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
                const Icon(Icons.cloud_done_outlined,
                    size: 18, color: AppColors.statusInfo),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'These fields come from the biometric device sync '
                    'and are read-only. To enrich the profile, fill out '
                    'the Personal / Employment / Bank tabs.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ReadOnlyRow(label: 'User ID', value: employee.userId),
          _ReadOnlyRow(label: 'UID', value: '${employee.uid}'),
          _ReadOnlyRow(
              label: 'Device name', value: employee.name.isEmpty ? '—' : employee.name),
          _ReadOnlyRow(
              label: 'Privilege',
              value: employee.isAdmin
                  ? 'Admin (privilege ${employee.privilege})'
                  : 'User (privilege ${employee.privilege})'),
          _ReadOnlyRow(
              label: 'Card number',
              value: employee.cardNo.isEmpty || employee.cardNo == '0'
                  ? '—'
                  : employee.cardNo),
          _ReadOnlyRow(
              label: 'Group',
              value: employee.groupId.isEmpty ? '—' : employee.groupId),
          _ReadOnlyRow(
            label: 'Last device sync',
            value: employee.updatedAt == null
                ? '—'
                : DateFormat('MMM d, y · HH:mm').format(employee.updatedAt!),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 180,
            child: Text(
              label,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Personal tab ────────────────────────────────────────────────────

class _PersonalTab extends StatelessWidget {
  const _PersonalTab({required this.draft, required this.onChanged});
  final EmployeeProfile draft;
  final ValueChanged<EmployeeProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Section(title: 'Identity', children: <Widget>[
            _TextFieldRow(
              label: 'First name',
              value: draft.firstName,
              onChanged: (v) =>
                  onChanged(draft.copyWith(firstName: v)),
            ),
            _TextFieldRow(
              label: 'Last name',
              value: draft.lastName,
              onChanged: (v) => onChanged(draft.copyWith(lastName: v)),
            ),
            _TextFieldRow(
              label: 'Display name',
              value: draft.displayName,
              hint: 'Optional, falls back to first + last.',
              onChanged: (v) => onChanged(draft.copyWith(displayName: v)),
            ),
            _DropdownRow<Gender>(
              label: 'Gender',
              value: draft.gender,
              items: <DropdownMenuItem<Gender>>[
                for (final g in Gender.values)
                  DropdownMenuItem(value: g, child: Text(g.label)),
              ],
              onChanged: (v) => onChanged(draft.copyWith(gender: v)),
            ),
            _DateFieldRow(
              label: 'Date of birth',
              value: draft.dateOfBirth,
              onChanged: (v) => onChanged(draft.copyWith(dateOfBirth: v)),
            ),
            _DropdownRow<MaritalStatus>(
              label: 'Marital status',
              value: draft.maritalStatus,
              items: <DropdownMenuItem<MaritalStatus>>[
                for (final m in MaritalStatus.values)
                  DropdownMenuItem(value: m, child: Text(m.label)),
              ],
              onChanged: (v) => onChanged(draft.copyWith(maritalStatus: v)),
            ),
            _TextFieldRow(
              label: 'Nationality',
              value: draft.nationality,
              onChanged: (v) => onChanged(draft.copyWith(nationality: v)),
            ),
          ]),
          _Section(title: 'Contact', children: <Widget>[
            _TextFieldRow(
              label: 'Phone',
              value: draft.phone,
              keyboardType: TextInputType.phone,
              onChanged: (v) => onChanged(draft.copyWith(phone: v)),
            ),
            _TextFieldRow(
              label: 'Email',
              value: draft.email,
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => onChanged(draft.copyWith(email: v)),
            ),
            _TextFieldRow(
              label: 'Address',
              value: draft.address,
              maxLines: 3,
              onChanged: (v) => onChanged(draft.copyWith(address: v)),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─── Employment tab ──────────────────────────────────────────────────

/// If [stored] matches one of the [validIds], return it. Otherwise
/// return null so the dropdown shows "— none —" instead of crashing
/// on a stale free-text value left over from before these fields
/// became foreign keys.
String? _resolveDropdownValue(String? stored, Iterable<String> validIds) {
  if (stored == null) return null;
  return validIds.contains(stored) ? stored : null;
}

class _EmploymentTab extends StatelessWidget {
  const _EmploymentTab({
    required this.draft,
    required this.onChanged,
    required this.schedules,
    required this.allEmployees,
    required this.teams,
    required this.employeeGroups,
    required this.officeLocations,
  });

  final EmployeeProfile draft;
  final ValueChanged<EmployeeProfile> onChanged;
  final List<Schedule> schedules;
  final List<Employee> allEmployees;
  final List<Team> teams;
  final List<EmployeeGroup> employeeGroups;
  final List<OfficeLocation> officeLocations;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Section(title: 'Employment', children: <Widget>[
            _DateFieldRow(
              label: 'Joining date',
              value: draft.joiningDate,
              onChanged: (v) => onChanged(draft.copyWith(joiningDate: v)),
            ),
            _DropdownRow<EmploymentType>(
              label: 'Employment type',
              value: draft.employmentType,
              items: <DropdownMenuItem<EmploymentType>>[
                for (final e in EmploymentType.values)
                  DropdownMenuItem(value: e, child: Text(e.label)),
              ],
              onChanged: (v) =>
                  onChanged(draft.copyWith(employmentType: v)),
            ),
            _TextFieldRow(
              label: 'Division',
              value: draft.division,
              onChanged: (v) => onChanged(draft.copyWith(division: v)),
            ),
            _TextFieldRow(
              label: 'Department',
              value: draft.department,
              onChanged: (v) => onChanged(draft.copyWith(department: v)),
            ),
            _TextFieldRow(
              label: 'Grade',
              value: draft.grade,
              onChanged: (v) => onChanged(draft.copyWith(grade: v)),
            ),
            _TextFieldRow(
              label: 'Designation',
              value: draft.designation,
              onChanged: (v) => onChanged(draft.copyWith(designation: v)),
            ),
            _DropdownRow<String>(
              label: 'Group',
              value: _resolveDropdownValue(
                  draft.groupLabel, employeeGroups.map((g) => g.id)),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                    value: null, child: Text('— none —')),
                for (final g in employeeGroups)
                  DropdownMenuItem(
                    value: g.id,
                    child:
                        Text(g.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => onChanged(draft.copyWith(groupLabel: v)),
            ),
            _DropdownRow<String>(
              label: 'Team',
              value: _resolveDropdownValue(
                  draft.team, teams.map((t) => t.id)),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                    value: null, child: Text('— none —')),
                for (final t in teams)
                  DropdownMenuItem(
                    value: t.id,
                    child:
                        Text(t.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => onChanged(draft.copyWith(team: v)),
            ),
            _TextFieldRow(
              label: 'Employment role',
              value: draft.employmentRole,
              onChanged: (v) =>
                  onChanged(draft.copyWith(employmentRole: v)),
            ),
          ]),
          _Section(title: 'Location', children: <Widget>[
            _DropdownRow<String>(
              label: 'Office location',
              value: _resolveDropdownValue(
                  draft.officeLocationId,
                  officeLocations.map((l) => l.id)),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                    value: null, child: Text('— none —')),
                for (final l in officeLocations)
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
              onChanged: (v) =>
                  onChanged(draft.copyWith(officeLocationId: v)),
            ),
            if (draft.officeLocationId != null &&
                !officeLocations
                    .any((l) => l.id == draft.officeLocationId))
              Padding(
                padding: const EdgeInsets.only(left: 180, top: 4),
                child: Text(
                  'Stored value "${draft.officeLocationId}" no longer matches a registered location.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.statusWarning,
                      ),
                ),
              ),
          ]),
          _Section(title: 'Reporting & Schedule', children: <Widget>[
            _DropdownRow<String>(
              label: 'Line manager',
              value: draft.lineManagerUserId,
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                    value: null, child: Text('— none —')),
                for (final e in allEmployees)
                  DropdownMenuItem(
                    value: e.userId,
                    child: Text(
                      e.name.isEmpty ? 'id ${e.userId}' : e.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) =>
                  onChanged(draft.copyWith(lineManagerUserId: v)),
            ),
            _DropdownRow<String>(
              label: 'Schedule',
              value: draft.scheduleId,
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                    value: null, child: Text('— none —')),
                for (final s in schedules)
                  DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => onChanged(draft.copyWith(scheduleId: v)),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─── Bank tab ────────────────────────────────────────────────────────

class _BankTab extends StatelessWidget {
  const _BankTab({required this.draft, required this.onChanged});
  final EmployeeProfile draft;
  final ValueChanged<EmployeeProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Section(title: 'Salary deposit', children: <Widget>[
            _TextFieldRow(
              label: 'Bank name',
              value: draft.bankName,
              onChanged: (v) => onChanged(draft.copyWith(bankName: v)),
            ),
            _TextFieldRow(
              label: 'Branch',
              value: draft.bankBranch,
              onChanged: (v) => onChanged(draft.copyWith(bankBranch: v)),
            ),
            _TextFieldRow(
              label: 'Account number',
              value: draft.bankAccountNo,
              onChanged: (v) =>
                  onChanged(draft.copyWith(bankAccountNo: v)),
            ),
            _TextFieldRow(
              label: 'Routing number',
              value: draft.bankRouting,
              onChanged: (v) =>
                  onChanged(draft.copyWith(bankRouting: v)),
            ),
            _TextFieldRow(
              label: 'SWIFT / BIC',
              value: draft.bankSwift,
              onChanged: (v) => onChanged(draft.copyWith(bankSwift: v)),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─── Documents tab ───────────────────────────────────────────────────

class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab({
    required this.userId,
    required this.documents,
    required this.state,
  });

  final String userId;
  final List<EmployeeDocument> documents;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('${documents.length} document'
                  '${documents.length == 1 ? "" : "s"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _addDocument(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add document'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: documents.isEmpty
                ? const EmptyState(
                    icon: Icons.description_outlined,
                    title: 'No documents',
                    message:
                        'Track contract scans, ID copies, certificates, etc. '
                        'v1 stores metadata only — actual file upload is coming.',
                  )
                : Card(
                    child: ListView.separated(
                      itemCount: documents.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: theme.dividerColor),
                      itemBuilder: (context, i) {
                        final d = documents[i];
                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file_outlined),
                          title: Text(d.title),
                          subtitle: Text(
                            '${d.filename}'
                            '${d.notes == null || d.notes!.isEmpty ? "" : "\n${d.notes}"}'
                            '\nUploaded ${DateFormat('MMM d, y').format(d.uploadedAt)}',
                          ),
                          isThreeLine: d.notes?.isNotEmpty == true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            tooltip: 'Remove',
                            onPressed: () => _confirmDelete(context, d),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addDocument(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final filenameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add document'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: filenameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Filename',
                  helperText:
                      'v1 only stores the name — no file is uploaded.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (saved == true &&
        titleCtrl.text.trim().isNotEmpty &&
        filenameCtrl.text.trim().isNotEmpty) {
      await state.upsertEmployeeDocument(
        EmployeeDocument(
          id: 'doc_${DateTime.now().microsecondsSinceEpoch}',
          userId: userId,
          title: titleCtrl.text.trim(),
          filename: filenameCtrl.text.trim(),
          uploadedAt: DateTime.now(),
          notes:
              notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, EmployeeDocument doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove document?'),
        content: Text('Remove "${doc.title}" from this employee?'),
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
    if (ok == true) {
      await state.deleteEmployeeDocument(doc.id);
    }
  }
}

// ─── Child-collection tabs ───────────────────────────────────────────
// All 7 tabs follow the same pattern: load via FutureBuilder, render
// rows through `_ChildRow`, "+ Add" opens a typed AlertDialog form,
// trailing delete on each row. Each holds an internal version counter
// to force a refresh after writes.

const _childCardPadding = EdgeInsets.symmetric(
  horizontal: AppSpacing.md,
  vertical: AppSpacing.md,
);

class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onTap,
    required this.onDelete,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: _childCardPadding,
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor)),
                  ],
                ],
              ),
            ),
            if (meta != null) ...<Widget>[
              const SizedBox(width: AppSpacing.md),
              Text(meta!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Remove',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/// Reused for every child tab. Wraps `loader` (returns the list) and
/// renders an empty state, header with count + "+ Add" button, and the
/// list itself rendered by [itemBuilder].
class _ChildListShell<T> extends StatefulWidget {
  const _ChildListShell({
    super.key,
    required this.title,
    required this.icon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.loader,
    required this.itemBuilder,
    required this.onAdd,
  });

  final String title;
  final IconData icon;
  final String emptyTitle;
  final String emptyMessage;
  final Future<List<T>> Function() loader;
  final Widget Function(T item, VoidCallback refresh) itemBuilder;
  final Future<bool> Function() onAdd;

  @override
  State<_ChildListShell<T>> createState() => _ChildListShellState<T>();
}

class _ChildListShellState<T> extends State<_ChildListShell<T>> {
  int _version = 0;

  void _refresh() => setState(() => _version++);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<T>>(
      key: ValueKey<int>(_version),
      future: widget.loader(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? <T>[];
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text('${items.length} ${widget.title.toLowerCase()}'
                      '${items.length == 1 ? "" : "s"}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      final saved = await widget.onAdd();
                      if (saved) _refresh();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: Text('Add ${widget.title.toLowerCase()}'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: widget.icon,
                        title: widget.emptyTitle,
                        message: widget.emptyMessage,
                      )
                    : Card(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: theme.dividerColor),
                          itemBuilder: (context, i) =>
                              widget.itemBuilder(items[i], _refresh),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<bool> _confirmRemove(
    BuildContext context, String name, Future<void> Function() onConfirm) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Remove?'),
      content: Text('Remove "$name"? This cannot be undone.'),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel')),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
              foregroundColor: AppColors.statusDanger),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await onConfirm();
    return true;
  }
  return false;
}

String _newId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

// ─── Family tab ─────────────────────────────────────────────────────

class _FamilyTab extends StatelessWidget {
  const _FamilyTab({required this.userId, required this.state});
  final String userId;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _ChildListShell<FamilyMember>(
      title: 'Family member',
      icon: Icons.family_restroom,
      emptyTitle: 'No family members yet',
      emptyMessage: 'Add next of kin or emergency contacts.',
      loader: () => state.familyMembersFor(userId),
      onAdd: () => _editFamily(context, null),
      itemBuilder: (m, refresh) {
        final dob = m.dateOfBirth == null
            ? ''
            : '  ·  born ${DateFormat('MMM d, y').format(m.dateOfBirth!)}';
        final phone = m.contactPhone == null || m.contactPhone!.isEmpty
            ? ''
            : '  ·  ${m.contactPhone}';
        return _ChildRow(
          title: m.name,
          subtitle: '${m.relationship}$dob$phone',
          meta: null,
          onTap: () async {
            if (await _editFamily(context, m)) refresh();
          },
          onDelete: () async {
            if (await _confirmRemove(context, m.name,
                () => state.deleteFamilyMember(m.id))) {
              refresh();
            }
          },
        );
      },
    );
  }

  Future<bool> _editFamily(BuildContext context, FamilyMember? initial) async {
    final nameCtrl = TextEditingController(text: initial?.name ?? '');
    final relCtrl = TextEditingController(text: initial?.relationship ?? '');
    final phoneCtrl =
        TextEditingController(text: initial?.contactPhone ?? '');
    final notesCtrl = TextEditingController(text: initial?.notes ?? '');
    DateTime? dob = initial?.dateOfBirth;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateD) {
        return AlertDialog(
          title: Text(initial == null ? 'Add family member' : 'Edit'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _DialogField(label: 'Name', ctrl: nameCtrl),
                _DialogField(
                    label: 'Relationship',
                    ctrl: relCtrl,
                    hint: 'Spouse, Parent, Child, …'),
                _DialogDate(
                  label: 'Date of birth',
                  value: dob,
                  onChanged: (v) => setStateD(() => dob = v),
                ),
                _DialogField(
                    label: 'Contact phone',
                    ctrl: phoneCtrl,
                    keyboardType: TextInputType.phone),
                _DialogField(
                    label: 'Notes', ctrl: notesCtrl, maxLines: 2),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    relCtrl.text.trim().isEmpty) {
                  return;
                }
                await state.upsertFamilyMember(FamilyMember(
                  id: initial?.id ?? _newId('fam'),
                  userId: userId,
                  name: nameCtrl.text.trim(),
                  relationship: relCtrl.text.trim(),
                  dateOfBirth: dob,
                  contactPhone:
                      phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                ));
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              child: Text(initial == null ? 'Add' : 'Save'),
            ),
          ],
        );
      }),
    );
    return saved == true;
  }
}

// ─── Education tab ──────────────────────────────────────────────────

class _EducationTab extends StatelessWidget {
  const _EducationTab({required this.userId, required this.state});
  final String userId;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _ChildListShell<EducationEntry>(
      title: 'Education entry',
      icon: Icons.school_outlined,
      emptyTitle: 'No education records yet',
      emptyMessage: 'Add degrees, certifications, courses.',
      loader: () => state.educationEntriesFor(userId),
      onAdd: () => _editEducation(context, null),
      itemBuilder: (e, refresh) {
        final years = e.startYear == null && e.endYear == null
            ? null
            : '${e.startYear ?? '?'} – ${e.endYear ?? 'present'}';
        return _ChildRow(
          title: e.degree,
          subtitle: <String>[
            if (e.institution != null && e.institution!.isNotEmpty)
              e.institution!,
            if (e.fieldOfStudy != null && e.fieldOfStudy!.isNotEmpty)
              e.fieldOfStudy!,
          ].join('  ·  '),
          meta: years,
          onTap: () async {
            if (await _editEducation(context, e)) refresh();
          },
          onDelete: () async {
            if (await _confirmRemove(context, e.degree,
                () => state.deleteEducationEntry(e.id))) {
              refresh();
            }
          },
        );
      },
    );
  }

  Future<bool> _editEducation(
      BuildContext context, EducationEntry? initial) async {
    final degCtrl = TextEditingController(text: initial?.degree ?? '');
    final instCtrl = TextEditingController(text: initial?.institution ?? '');
    final fieldCtrl =
        TextEditingController(text: initial?.fieldOfStudy ?? '');
    final startCtrl = TextEditingController(
        text: initial?.startYear == null ? '' : '${initial!.startYear}');
    final endCtrl = TextEditingController(
        text: initial?.endYear == null ? '' : '${initial!.endYear}');
    final notesCtrl = TextEditingController(text: initial?.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(initial == null ? 'Add education' : 'Edit'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _DialogField(label: 'Degree', ctrl: degCtrl),
              _DialogField(label: 'Institution', ctrl: instCtrl),
              _DialogField(label: 'Field of study', ctrl: fieldCtrl),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _DialogField(
                        label: 'Start year',
                        ctrl: startCtrl,
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DialogField(
                        label: 'End year',
                        ctrl: endCtrl,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              _DialogField(label: 'Notes', ctrl: notesCtrl, maxLines: 2),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (degCtrl.text.trim().isEmpty) return;
              await state.upsertEducationEntry(EducationEntry(
                id: initial?.id ?? _newId('edu'),
                userId: userId,
                degree: degCtrl.text.trim(),
                institution: instCtrl.text.trim().isEmpty
                    ? null
                    : instCtrl.text.trim(),
                fieldOfStudy: fieldCtrl.text.trim().isEmpty
                    ? null
                    : fieldCtrl.text.trim(),
                startYear: int.tryParse(startCtrl.text.trim()),
                endYear: int.tryParse(endCtrl.text.trim()),
                notes: notesCtrl.text.trim().isEmpty
                    ? null
                    : notesCtrl.text.trim(),
              ));
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            child: Text(initial == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
    return saved == true;
  }
}

// ─── Trainings tab ──────────────────────────────────────────────────

class _TrainingsTab extends StatelessWidget {
  const _TrainingsTab({required this.userId, required this.state});
  final String userId;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _ChildListShell<TrainingEntry>(
      title: 'Training',
      icon: Icons.cast_for_education_outlined,
      emptyTitle: 'No trainings yet',
      emptyMessage: 'Track courses, workshops, certifications.',
      loader: () => state.trainingEntriesFor(userId),
      onAdd: () => _editTraining(context, null),
      itemBuilder: (t, refresh) {
        final dateLabel = t.completedDate == null
            ? null
            : DateFormat('MMM d, y').format(t.completedDate!);
        return _ChildRow(
          title: t.title,
          subtitle: <String>[
            if (t.provider != null && t.provider!.isNotEmpty) t.provider!,
            if (t.certificateNumber != null && t.certificateNumber!.isNotEmpty)
              'Cert ${t.certificateNumber!}',
          ].join('  ·  '),
          meta: dateLabel,
          onTap: () async {
            if (await _editTraining(context, t)) refresh();
          },
          onDelete: () async {
            if (await _confirmRemove(context, t.title,
                () => state.deleteTrainingEntry(t.id))) {
              refresh();
            }
          },
        );
      },
    );
  }

  Future<bool> _editTraining(
      BuildContext context, TrainingEntry? initial) async {
    final titleCtrl = TextEditingController(text: initial?.title ?? '');
    final provCtrl = TextEditingController(text: initial?.provider ?? '');
    final certCtrl =
        TextEditingController(text: initial?.certificateNumber ?? '');
    final notesCtrl = TextEditingController(text: initial?.notes ?? '');
    DateTime? completed = initial?.completedDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateD) {
        return AlertDialog(
          title: Text(initial == null ? 'Add training' : 'Edit'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _DialogField(label: 'Title', ctrl: titleCtrl),
                _DialogField(label: 'Provider', ctrl: provCtrl),
                _DialogDate(
                  label: 'Completed',
                  value: completed,
                  onChanged: (v) => setStateD(() => completed = v),
                ),
                _DialogField(
                    label: 'Certificate number', ctrl: certCtrl),
                _DialogField(
                    label: 'Notes', ctrl: notesCtrl, maxLines: 2),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await state.upsertTrainingEntry(TrainingEntry(
                  id: initial?.id ?? _newId('trn'),
                  userId: userId,
                  title: titleCtrl.text.trim(),
                  provider: provCtrl.text.trim().isEmpty
                      ? null
                      : provCtrl.text.trim(),
                  completedDate: completed,
                  certificateNumber: certCtrl.text.trim().isEmpty
                      ? null
                      : certCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                ));
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              child: Text(initial == null ? 'Add' : 'Save'),
            ),
          ],
        );
      }),
    );
    return saved == true;
  }
}

// ─── Employment History tab ─────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.userId, required this.state});
  final String userId;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _ChildListShell<EmploymentHistoryEntry>(
      title: 'Employment history entry',
      icon: Icons.history_outlined,
      emptyTitle: 'No employment history yet',
      emptyMessage: 'Add prior employers and roles.',
      loader: () => state.employmentHistoryFor(userId),
      onAdd: () => _editHistory(context, null),
      itemBuilder: (h, refresh) {
        final fmt = DateFormat('MMM y');
        final span = h.startDate == null && h.endDate == null
            ? null
            : '${h.startDate == null ? '?' : fmt.format(h.startDate!)} – '
                '${h.endDate == null ? 'present' : fmt.format(h.endDate!)}';
        return _ChildRow(
          title: h.position,
          subtitle: h.employer,
          meta: span,
          onTap: () async {
            if (await _editHistory(context, h)) refresh();
          },
          onDelete: () async {
            if (await _confirmRemove(context, '${h.position} @ ${h.employer}',
                () => state.deleteEmploymentHistoryEntry(h.id))) {
              refresh();
            }
          },
        );
      },
    );
  }

  Future<bool> _editHistory(
      BuildContext context, EmploymentHistoryEntry? initial) async {
    final empCtrl = TextEditingController(text: initial?.employer ?? '');
    final posCtrl = TextEditingController(text: initial?.position ?? '');
    final reasonCtrl =
        TextEditingController(text: initial?.reasonForLeaving ?? '');
    final notesCtrl = TextEditingController(text: initial?.notes ?? '');
    DateTime? start = initial?.startDate;
    DateTime? end = initial?.endDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateD) {
        return AlertDialog(
          title: Text(initial == null ? 'Add employment history' : 'Edit'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _DialogField(label: 'Employer', ctrl: empCtrl),
                _DialogField(label: 'Position', ctrl: posCtrl),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _DialogDate(
                        label: 'Start',
                        value: start,
                        onChanged: (v) => setStateD(() => start = v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _DialogDate(
                        label: 'End',
                        value: end,
                        onChanged: (v) => setStateD(() => end = v),
                      ),
                    ),
                  ],
                ),
                _DialogField(
                    label: 'Reason for leaving', ctrl: reasonCtrl),
                _DialogField(
                    label: 'Notes', ctrl: notesCtrl, maxLines: 2),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (empCtrl.text.trim().isEmpty ||
                    posCtrl.text.trim().isEmpty) {
                  return;
                }
                await state.upsertEmploymentHistoryEntry(EmploymentHistoryEntry(
                  id: initial?.id ?? _newId('hist'),
                  userId: userId,
                  employer: empCtrl.text.trim(),
                  position: posCtrl.text.trim(),
                  startDate: start,
                  endDate: end,
                  reasonForLeaving: reasonCtrl.text.trim().isEmpty
                      ? null
                      : reasonCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                ));
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              child: Text(initial == null ? 'Add' : 'Save'),
            ),
          ],
        );
      }),
    );
    return saved == true;
  }
}

// ─── Disciplinary tab ───────────────────────────────────────────────

class _DisciplinaryTab extends StatelessWidget {
  const _DisciplinaryTab({required this.userId, required this.state});
  final String userId;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _ChildListShell<DisciplinaryAction>(
      title: 'Disciplinary action',
      icon: Icons.gavel_outlined,
      emptyTitle: 'No disciplinary actions',
      emptyMessage: 'Track warnings, suspensions, and resolutions.',
      loader: () => state.disciplinaryActionsFor(userId),
      onAdd: () => _editAction(context, null),
      itemBuilder: (a, refresh) {
        return _ChildRow(
          title: a.type,
          subtitle: a.description,
          meta: DateFormat('MMM d, y').format(a.date),
          onTap: () async {
            if (await _editAction(context, a)) refresh();
          },
          onDelete: () async {
            if (await _confirmRemove(context, a.type,
                () => state.deleteDisciplinaryAction(a.id))) {
              refresh();
            }
          },
        );
      },
    );
  }

  Future<bool> _editAction(
      BuildContext context, DisciplinaryAction? initial) async {
    final typeCtrl = TextEditingController(text: initial?.type ?? '');
    final descCtrl =
        TextEditingController(text: initial?.description ?? '');
    final actionCtrl = TextEditingController(text: initial?.action ?? '');
    final notesCtrl = TextEditingController(text: initial?.notes ?? '');
    DateTime date = initial?.date ?? DateUtils.dateOnly(DateTime.now());

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateD) {
        return AlertDialog(
          title: Text(
              initial == null ? 'Add disciplinary action' : 'Edit'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _DialogDate(
                  label: 'Date',
                  value: date,
                  onChanged: (v) {
                    if (v != null) setStateD(() => date = v);
                  },
                ),
                _DialogField(
                    label: 'Type',
                    ctrl: typeCtrl,
                    hint: 'Verbal warning, Written warning, …'),
                _DialogField(
                    label: 'Description', ctrl: descCtrl, maxLines: 3),
                _DialogField(label: 'Action taken', ctrl: actionCtrl),
                _DialogField(
                    label: 'Notes', ctrl: notesCtrl, maxLines: 2),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (typeCtrl.text.trim().isEmpty ||
                    descCtrl.text.trim().isEmpty) {
                  return;
                }
                await state.upsertDisciplinaryAction(DisciplinaryAction(
                  id: initial?.id ?? _newId('disc'),
                  userId: userId,
                  date: date,
                  type: typeCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  action: actionCtrl.text.trim().isEmpty
                      ? null
                      : actionCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                ));
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              child: Text(initial == null ? 'Add' : 'Save'),
            ),
          ],
        );
      }),
    );
    return saved == true;
  }
}

// ─── Achievements tab ───────────────────────────────────────────────

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab({required this.userId, required this.state});
  final String userId;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _ChildListShell<Achievement>(
      title: 'Achievement',
      icon: Icons.emoji_events_outlined,
      emptyTitle: 'No achievements yet',
      emptyMessage: 'Recognitions, awards, milestones.',
      loader: () => state.achievementsFor(userId),
      onAdd: () => _editAchievement(context, null),
      itemBuilder: (a, refresh) {
        return _ChildRow(
          title: a.title,
          subtitle: a.description,
          meta: a.date == null ? null : DateFormat('MMM y').format(a.date!),
          onTap: () async {
            if (await _editAchievement(context, a)) refresh();
          },
          onDelete: () async {
            if (await _confirmRemove(context, a.title,
                () => state.deleteAchievement(a.id))) {
              refresh();
            }
          },
        );
      },
    );
  }

  Future<bool> _editAchievement(
      BuildContext context, Achievement? initial) async {
    final titleCtrl = TextEditingController(text: initial?.title ?? '');
    final descCtrl = TextEditingController(text: initial?.description ?? '');
    final notesCtrl = TextEditingController(text: initial?.notes ?? '');
    DateTime? date = initial?.date;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateD) {
        return AlertDialog(
          title: Text(initial == null ? 'Add achievement' : 'Edit'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _DialogField(label: 'Title', ctrl: titleCtrl),
                _DialogDate(
                  label: 'Date',
                  value: date,
                  onChanged: (v) => setStateD(() => date = v),
                ),
                _DialogField(
                    label: 'Description', ctrl: descCtrl, maxLines: 3),
                _DialogField(
                    label: 'Notes', ctrl: notesCtrl, maxLines: 2),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await state.upsertAchievement(Achievement(
                  id: initial?.id ?? _newId('ach'),
                  userId: userId,
                  title: titleCtrl.text.trim(),
                  date: date,
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                ));
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              child: Text(initial == null ? 'Add' : 'Save'),
            ),
          ],
        );
      }),
    );
    return saved == true;
  }
}

// ─── Addresses tab ──────────────────────────────────────────────────

class _AddressesTab extends StatelessWidget {
  const _AddressesTab({required this.userId, required this.state});
  final String userId;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return _ChildListShell<EmployeeAddress>(
      title: 'Address',
      icon: Icons.location_on_outlined,
      emptyTitle: 'No addresses yet',
      emptyMessage: 'Add Home / Permanent / Mailing / Emergency addresses.',
      loader: () => state.addressesFor(userId),
      onAdd: () => _editAddress(context, null),
      itemBuilder: (a, refresh) {
        final loc = <String>[
          if (a.city != null && a.city!.isNotEmpty) a.city!,
          if (a.country != null && a.country!.isNotEmpty) a.country!,
        ].join(', ');
        return _ChildRow(
          title: '${a.type.label}'
              '${a.isPrimary ? ' · Primary' : ''}',
          subtitle: <String>[
            a.addressLine,
            if (loc.isNotEmpty) loc,
          ].join('  ·  '),
          meta: null,
          leading: Icon(
            a.isPrimary ? Icons.location_on : Icons.location_on_outlined,
            color: a.isPrimary ? AppColors.brandPrimary : null,
          ),
          onTap: () async {
            if (await _editAddress(context, a)) refresh();
          },
          onDelete: () async {
            if (await _confirmRemove(context, a.type.label,
                () => state.deleteEmployeeAddress(a.id))) {
              refresh();
            }
          },
        );
      },
    );
  }

  Future<bool> _editAddress(
      BuildContext context, EmployeeAddress? initial) async {
    final lineCtrl = TextEditingController(text: initial?.addressLine ?? '');
    final cityCtrl = TextEditingController(text: initial?.city ?? '');
    final countryCtrl = TextEditingController(text: initial?.country ?? '');
    final notesCtrl = TextEditingController(text: initial?.notes ?? '');
    EmployeeAddressType type = initial?.type ?? EmployeeAddressType.home;
    bool isPrimary = initial?.isPrimary ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateD) {
        return AlertDialog(
          title: Text(initial == null ? 'Add address' : 'Edit'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: DropdownButtonFormField<EmployeeAddressType>(
                    initialValue: type,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: <DropdownMenuItem<EmployeeAddressType>>[
                      for (final t in EmployeeAddressType.values)
                        DropdownMenuItem(value: t, child: Text(t.label)),
                    ],
                    onChanged: (v) =>
                        setStateD(() => type = v ?? type),
                  ),
                ),
                _DialogField(
                    label: 'Address line', ctrl: lineCtrl, maxLines: 2),
                Row(
                  children: <Widget>[
                    Expanded(
                        child:
                            _DialogField(label: 'City', ctrl: cityCtrl)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: _DialogField(
                            label: 'Country', ctrl: countryCtrl)),
                  ],
                ),
                CheckboxListTile(
                  value: isPrimary,
                  onChanged: (v) => setStateD(() => isPrimary = v == true),
                  title: const Text('Primary address'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                _DialogField(
                    label: 'Notes', ctrl: notesCtrl, maxLines: 2),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (lineCtrl.text.trim().isEmpty) return;
                await state.upsertEmployeeAddress(EmployeeAddress(
                  id: initial?.id ?? _newId('addr'),
                  userId: userId,
                  type: type,
                  addressLine: lineCtrl.text.trim(),
                  city: cityCtrl.text.trim().isEmpty
                      ? null
                      : cityCtrl.text.trim(),
                  country: countryCtrl.text.trim().isEmpty
                      ? null
                      : countryCtrl.text.trim(),
                  isPrimary: isPrimary,
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                ));
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              child: Text(initial == null ? 'Add' : 'Save'),
            ),
          ],
        );
      }),
    );
    return saved == true;
  }
}

// ─── Dialog helper widgets ──────────────────────────────────────────

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.ctrl,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final TextEditingController ctrl;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _DialogDate extends StatelessWidget {
  const _DialogDate({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d, y');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
          );
          if (picked != null) onChanged(DateUtils.dateOnly(picked));
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: value == null
                ? const Icon(Icons.calendar_today_outlined, size: 16)
                : IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onChanged(null),
                  ),
          ),
          child: Text(
            value == null ? '— not set —' : fmt.format(value!),
            style: value == null
                ? theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor)
                : null,
          ),
        ),
      ),
    );
  }
}
