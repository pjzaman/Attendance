/// Static catalog of permission keys used by [Role]. Roles are
/// authored in Settings → Roles; permissions are enforced at the UI
/// layer once auth lands. v1 ships the catalog so the IA matches the
/// doc's "ACL: Users / Roles" hub.
class Permissions {
  // ── Dashboards & reading ────────────────────────────────────────
  static const String viewDashboard = 'view_dashboard';
  static const String viewReports = 'view_reports';
  static const String viewAttendance = 'view_attendance';

  // ── HR Management ───────────────────────────────────────────────
  static const String manageEmployees = 'manage_employees';
  static const String manageSchedules = 'manage_schedules';
  static const String manageShifts = 'manage_shifts';

  // ── Requests ────────────────────────────────────────────────────
  static const String submitRequests = 'submit_requests';
  static const String approveRequests = 'approve_requests';

  // ── Settings ────────────────────────────────────────────────────
  static const String manageLeavePolicies = 'manage_leave_policies';
  static const String manageApprovalPolicies = 'manage_approval_policies';
  static const String manageSessions = 'manage_sessions';
  static const String manageRoles = 'manage_roles';
  static const String manageUsers = 'manage_users';

  /// All permissions in stable display order. Used by the role editor
  /// to render the permission picker.
  static const List<PermissionMeta> all = <PermissionMeta>[
    PermissionMeta(
      key: viewDashboard,
      label: 'View dashboard',
      group: 'Read',
    ),
    PermissionMeta(
      key: viewReports,
      label: 'View reports',
      group: 'Read',
    ),
    PermissionMeta(
      key: viewAttendance,
      label: 'View attendance',
      group: 'Read',
    ),
    PermissionMeta(
      key: manageEmployees,
      label: 'Manage employees',
      group: 'HR Management',
    ),
    PermissionMeta(
      key: manageSchedules,
      label: 'Manage schedules',
      group: 'HR Management',
    ),
    PermissionMeta(
      key: manageShifts,
      label: 'Manage shifts',
      group: 'HR Management',
    ),
    PermissionMeta(
      key: submitRequests,
      label: 'Submit requests',
      group: 'Requests',
    ),
    PermissionMeta(
      key: approveRequests,
      label: 'Approve requests',
      group: 'Requests',
    ),
    PermissionMeta(
      key: manageLeavePolicies,
      label: 'Manage leave policies',
      group: 'Settings',
    ),
    PermissionMeta(
      key: manageApprovalPolicies,
      label: 'Manage approval policies',
      group: 'Settings',
    ),
    PermissionMeta(
      key: manageSessions,
      label: 'Manage sessions',
      group: 'Settings',
    ),
    PermissionMeta(
      key: manageRoles,
      label: 'Manage roles',
      group: 'Settings',
    ),
    PermissionMeta(
      key: manageUsers,
      label: 'Manage users',
      group: 'Settings',
    ),
  ];

  static PermissionMeta? lookup(String key) {
    for (final p in all) {
      if (p.key == key) return p;
    }
    return null;
  }

  static List<String> allKeys() => all.map((p) => p.key).toList();
}

class PermissionMeta {
  const PermissionMeta({
    required this.key,
    required this.label,
    required this.group,
  });

  final String key;
  final String label;
  final String group;
}
