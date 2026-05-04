import '../models/employee_group.dart';

/// Seed a single placeholder employee group on first launch.
class EmployeeGroupSeed {
  static List<EmployeeGroup> defaults() => <EmployeeGroup>[
        EmployeeGroup(
          id: 'grp_default',
          name: 'All Employees',
          description: 'Default group — replace with project / cohort groups.',
        ),
      ];
}
