class Punch {
  Punch({
    required this.userId,
    required this.timestamp,
    this.rawStatus = 0,
    this.rawPunch = 0,
  });

  final String userId;
  final DateTime timestamp;
  final int rawStatus;
  final int rawPunch;

  factory Punch.fromMap(Map<String, Object?> m) => Punch(
        userId: m['user_id']! as String,
        timestamp: DateTime.parse(m['timestamp']! as String).toLocal(),
        rawStatus: (m['raw_status'] as int?) ?? 0,
        rawPunch: (m['raw_punch'] as int?) ?? 0,
      );
}
