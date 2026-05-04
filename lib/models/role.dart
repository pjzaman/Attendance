/// User-creatable role per the doc §4.10 ACL section. Built-in roles
/// are seeded on first launch and can't be deleted (only edited).
class Role {
  const Role({
    required this.id,
    required this.name,
    required this.permissions,
    this.description = '',
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final String description;

  /// Permission keys from [Permissions]. Treated as a set; UI never
  /// shows duplicates.
  final List<String> permissions;

  /// Built-in roles can be edited (name/permissions) but not deleted.
  final bool isBuiltIn;

  bool has(String permissionKey) => permissions.contains(permissionKey);

  Role copyWith({
    String? name,
    String? description,
    List<String>? permissions,
  }) =>
      Role(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        permissions: permissions ?? this.permissions,
        isBuiltIn: isBuiltIn,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'description': description,
        'is_built_in': isBuiltIn ? 1 : 0,
      };

  factory Role.fromMap(
    Map<String, Object?> m, {
    List<String> permissions = const <String>[],
  }) =>
      Role(
        id: m['id']! as String,
        name: m['name']! as String,
        description: (m['description'] as String?) ?? '',
        isBuiltIn: ((m['is_built_in'] as int?) ?? 0) == 1,
        permissions: permissions,
      );
}
