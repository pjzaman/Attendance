/// A named group of employees — looser than a [Team], typically used
/// for project / function / training cohorts. Named `EmployeeGroup`
/// rather than `Group` to avoid colliding with Dart's collection
/// terminology in screens.
class EmployeeGroup {
  EmployeeGroup({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? description;
  final bool isActive;

  EmployeeGroup copyWith({
    String? name,
    String? description,
    bool? isActive,
  }) =>
      EmployeeGroup(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        isActive: isActive ?? this.isActive,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'description': description,
        'is_active': isActive ? 1 : 0,
      };

  factory EmployeeGroup.fromMap(Map<String, Object?> m) => EmployeeGroup(
        id: m['id']! as String,
        name: m['name']! as String,
        description: m['description'] as String?,
        isActive: ((m['is_active'] as int?) ?? 1) == 1,
      );
}
