/// A named team of employees, typically with a designated lead. Per
/// the doc §4.10 HR Management, teams sit alongside groups, shifts,
/// office locations, and sessions.
class Team {
  Team({
    required this.id,
    required this.name,
    this.description,
    this.leaderUserId,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? description;

  /// `Employee.userId` of the team lead, or `null` if unassigned.
  final String? leaderUserId;
  final bool isActive;

  Team copyWith({
    String? name,
    String? description,
    String? leaderUserId,
    bool? isActive,
  }) =>
      Team(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        leaderUserId: leaderUserId ?? this.leaderUserId,
        isActive: isActive ?? this.isActive,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'description': description,
        'leader_user_id': leaderUserId,
        'is_active': isActive ? 1 : 0,
      };

  factory Team.fromMap(Map<String, Object?> m) => Team(
        id: m['id']! as String,
        name: m['name']! as String,
        description: m['description'] as String?,
        leaderUserId: m['leader_user_id'] as String?,
        isActive: ((m['is_active'] as int?) ?? 1) == 1,
      );
}
