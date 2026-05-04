class Employee {
  Employee({
    required this.userId,
    required this.uid,
    required this.name,
    required this.privilege,
    this.cardNo = '',
    this.groupId = '',
    this.updatedAt,
  });

  final String userId;
  final int uid;
  final String name;
  final int privilege;
  final String cardNo;
  final String groupId;
  final DateTime? updatedAt;

  bool get isAdmin => privilege == 14;

  factory Employee.fromMap(Map<String, Object?> m) => Employee(
        userId: m['user_id']! as String,
        uid: (m['uid'] as int?) ?? 0,
        name: (m['name'] as String?) ?? '',
        privilege: (m['privilege'] as int?) ?? 0,
        cardNo: (m['card_no'] as String?) ?? '',
        groupId: (m['group_id'] as String?) ?? '',
        updatedAt: m['updated_at'] != null
            ? DateTime.tryParse(m['updated_at']! as String)
            : null,
      );

  /// Firestore representation. Field names are camelCase (idiomatic
  /// for Firestore documents), not snake_case (which we use for
  /// sqflite). Doc ID = userId, so userId is omitted from the map.
  Map<String, Object?> toFirestore() => <String, Object?>{
        'uid': uid,
        'name': name,
        'privilege': privilege,
        'cardNo': cardNo,
        'groupId': groupId,
        'updatedAt': (updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
      };

  factory Employee.fromFirestore(String docId, Map<String, Object?> m) =>
      Employee(
        userId: docId,
        uid: (m['uid'] as int?) ?? 0,
        name: (m['name'] as String?) ?? '',
        privilege: (m['privilege'] as int?) ?? 0,
        cardNo: (m['cardNo'] as String?) ?? '',
        groupId: (m['groupId'] as String?) ?? '',
        updatedAt: m['updatedAt'] != null
            ? DateTime.tryParse(m['updatedAt'] as String)
            : null,
      );
}
