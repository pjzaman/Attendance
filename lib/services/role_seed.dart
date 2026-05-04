import '../models/permission.dart';
import '../models/role.dart';

/// Default roles seeded on first launch — covers the line-manager /
/// HR lead / accountant distinctions called out in the doc's gap
/// analysis. All four are marked built-in so they can't be deleted
/// (only edited).
class RoleSeed {
  static List<Role> defaults() => <Role>[
        Role(
          id: 'role_admin',
          name: 'Admin',
          description: 'Full access to every surface.',
          isBuiltIn: true,
          permissions: Permissions.allKeys(),
        ),
        const Role(
          id: 'role_hr_lead',
          name: 'HR Lead',
          description:
              'Owns employee data, leave policies, schedules and approvals.',
          isBuiltIn: true,
          permissions: <String>[
            Permissions.viewDashboard,
            Permissions.viewReports,
            Permissions.viewAttendance,
            Permissions.manageEmployees,
            Permissions.manageSchedules,
            Permissions.manageShifts,
            Permissions.submitRequests,
            Permissions.approveRequests,
            Permissions.manageLeavePolicies,
            Permissions.manageApprovalPolicies,
            Permissions.manageSessions,
          ],
        ),
        const Role(
          id: 'role_line_manager',
          name: 'Line Manager',
          description:
              'Approves attendance / leave requests for the team they manage.',
          isBuiltIn: true,
          permissions: <String>[
            Permissions.viewDashboard,
            Permissions.viewReports,
            Permissions.viewAttendance,
            Permissions.submitRequests,
            Permissions.approveRequests,
          ],
        ),
        const Role(
          id: 'role_accountant',
          name: 'Accountant',
          description:
              'Read-only access to attendance + reports for payroll work.',
          isBuiltIn: true,
          permissions: <String>[
            Permissions.viewDashboard,
            Permissions.viewReports,
            Permissions.viewAttendance,
          ],
        ),
        const Role(
          id: 'role_employee',
          name: 'Employee',
          description: 'Can view their own dashboard and submit requests.',
          isBuiltIn: true,
          permissions: <String>[
            Permissions.viewDashboard,
            Permissions.submitRequests,
          ],
        ),
      ];
}
