import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/employee.dart';
import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/detail_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_row.dart';
import '../widgets/profile_completeness_meter.dart';
import '../widgets/status_pill.dart';
import 'employee_detail_screen.dart';

enum _AdminFilter { all, admins, nonAdmins }

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  _AdminFilter _adminFilter = _AdminFilter.all;
  Employee? _selected;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<AppState>().employees;
    if (employees.isEmpty) {
      return const EmptyState(
        icon: Icons.person_outline,
        title: 'No employees yet',
        message: 'Run a sync to pull employees from the device.',
      );
    }

    if (_selected != null) {
      return EmployeeDetailScreen(
        employee: _selected!,
        onBack: () => setState(() => _selected = null),
      );
    }

    final filtered = _filter(employees);
    final activeFilters =
        _adminFilter == _AdminFilter.all ? 0 : 1;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            searchController: _searchCtrl,
            onSearchChanged: (v) => setState(() => _query = v.trim()),
            searchHint: 'Search by name or user id…',
            onShowFilters: () => _openFilters(context),
            activeFilterCount: activeFilters,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _query.isEmpty && activeFilters == 0
                ? '${employees.length} employee'
                    '${employees.length == 1 ? "" : "s"}'
                : '${filtered.length} of ${employees.length} '
                    'shown',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'No employees match',
                    message: 'Try a different search or clear the filters.',
                  )
                : Card(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) => _EmployeeTile(
                        employee: filtered[i],
                        onTap: () =>
                            setState(() => _selected = filtered[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Employee> _filter(List<Employee> employees) {
    final q = _query.toLowerCase();
    return employees.where((e) {
      switch (_adminFilter) {
        case _AdminFilter.all:
          break;
        case _AdminFilter.admins:
          if (!e.isAdmin) return false;
          break;
        case _AdminFilter.nonAdmins:
          if (e.isAdmin) return false;
          break;
      }
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q) ||
          e.userId.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openFilters(BuildContext context) async {
    final result = await showDetailDrawer<_AdminFilter>(
      context,
      child: _EmployeesFiltersDrawer(initial: _adminFilter),
    );
    if (result != null && mounted) {
      setState(() => _adminFilter = result);
    }
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({required this.employee, required this.onTap});
  final Employee employee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profileFor(employee.userId);
    final initial =
        employee.userId.isNotEmpty ? employee.userId.substring(0, 1) : '?';

    final fullName = <String>[
      if ((profile.firstName ?? '').trim().isNotEmpty) profile.firstName!.trim(),
      if ((profile.lastName ?? '').trim().isNotEmpty) profile.lastName!.trim(),
    ].join(' ');
    final displayName =
        fullName.isNotEmpty ? fullName : (employee.name.isNotEmpty ? employee.name : '(no name)');

    return ListTile(
      onTap: onTap,
      leading: ProfileCompletenessMeter(
        completeness: profile.completeness,
        initial: initial,
        size: 44,
      ),
      title: Row(
        children: <Widget>[
          Flexible(child: Text(displayName)),
          if (employee.isAdmin) ...<Widget>[
            const SizedBox(width: 8),
            const StatusPill(
              label: 'Admin',
              tone: StatusTone.warning,
              dense: true,
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${profile.designation ?? "user_id ${employee.userId}"}'
        '${profile.department == null ? "" : "  •  ${profile.department}"}',
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _EmployeesFiltersDrawer extends StatefulWidget {
  const _EmployeesFiltersDrawer({required this.initial});
  final _AdminFilter initial;

  @override
  State<_EmployeesFiltersDrawer> createState() =>
      _EmployeesFiltersDrawerState();
}

class _EmployeesFiltersDrawerState extends State<_EmployeesFiltersDrawer> {
  late _AdminFilter _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return DetailDrawer(
      title: 'Filters',
      subtitle: 'Narrow the employee list',
      actions: <Widget>[
        TextButton(
          onPressed: () =>
              setState(() => _value = _AdminFilter.all),
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop<_AdminFilter>(_value),
          child: const Text('Apply'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Privilege',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          RadioGroup<_AdminFilter>(
            groupValue: _value,
            onChanged: (v) => setState(() => _value = v!),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                RadioListTile<_AdminFilter>(
                  value: _AdminFilter.all,
                  title: Text('All employees'),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<_AdminFilter>(
                  value: _AdminFilter.admins,
                  title: Text('Admins only'),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<_AdminFilter>(
                  value: _AdminFilter.nonAdmins,
                  title: Text('Non-admins only'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
