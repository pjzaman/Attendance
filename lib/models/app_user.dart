/// A user who can sign into the management app. Distinct from
/// [Employee] (which represents a biometric-device user). May
/// optionally link to an Employee via [employeeUserId] so a manager
/// or HR lead can be associated with their punch record.
class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roleId,
    this.isVerified = false,
    this.isActive = true,
    this.employeeUserId,
    this.lastSignInAt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String roleId;
  final bool isVerified;
  final bool isActive;

  /// `Employee.userId` if this app user is also enrolled on the device.
  final String? employeeUserId;

  final DateTime? lastSignInAt;
  final DateTime? createdAt;

  AppUser copyWith({
    String? name,
    String? email,
    String? roleId,
    bool? isVerified,
    bool? isActive,
    String? employeeUserId,
    DateTime? lastSignInAt,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        roleId: roleId ?? this.roleId,
        isVerified: isVerified ?? this.isVerified,
        isActive: isActive ?? this.isActive,
        employeeUserId: employeeUserId ?? this.employeeUserId,
        lastSignInAt: lastSignInAt ?? this.lastSignInAt,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'email': email,
        'role_id': roleId,
        'is_verified': isVerified ? 1 : 0,
        'is_active': isActive ? 1 : 0,
        'employee_user_id': employeeUserId,
        'last_sign_in_at': lastSignInAt?.toUtc().toIso8601String(),
        'created_at': createdAt?.toUtc().toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
        id: m['id']! as String,
        name: m['name']! as String,
        email: m['email']! as String,
        roleId: m['role_id']! as String,
        isVerified: ((m['is_verified'] as int?) ?? 0) == 1,
        isActive: ((m['is_active'] as int?) ?? 1) == 1,
        employeeUserId: m['employee_user_id'] as String?,
        lastSignInAt: m['last_sign_in_at'] == null
            ? null
            : DateTime.parse(m['last_sign_in_at']! as String).toLocal(),
        createdAt: m['created_at'] == null
            ? null
            : DateTime.parse(m['created_at']! as String).toLocal(),
      );
}
