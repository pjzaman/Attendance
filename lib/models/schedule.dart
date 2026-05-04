enum ScheduleStatus { draft, published }

/// Named, reusable schedule that assigns a shift to a set of employees on
/// a weekly pattern. Per the redesign doc, schedules — not raw shifts —
/// are the primary unit users interact with.
class Schedule {
  const Schedule({
    required this.id,
    required this.name,
    required this.shiftId,
    required this.workDays,
    required this.startDate,
    this.endDate,
    this.includeHolidays = false,
    this.assignedUserIds = const <String>[],
    this.status = ScheduleStatus.published,
  });

  final String id;
  final String name;
  final String shiftId;

  /// Weekdays this schedule is active. 1=Mon … 7=Sun, matching
  /// [DateTime.weekday]. Bangladesh default is `{1,2,3,4,6,7}`
  /// (Friday off).
  final Set<int> workDays;

  final DateTime startDate;
  final DateTime? endDate;
  final bool includeHolidays;
  final List<String> assignedUserIds;
  final ScheduleStatus status;

  bool get isPublished => status == ScheduleStatus.published;
  bool get isDraft => status == ScheduleStatus.draft;

  /// Whether this schedule covers the given calendar date and the
  /// pattern says the day is a working day.
  bool worksOn(DateTime date) {
    if (date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;
    return workDays.contains(date.weekday);
  }

  Schedule copyWith({
    String? id,
    String? name,
    String? shiftId,
    Set<int>? workDays,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? includeHolidays,
    List<String>? assignedUserIds,
    ScheduleStatus? status,
  }) =>
      Schedule(
        id: id ?? this.id,
        name: name ?? this.name,
        shiftId: shiftId ?? this.shiftId,
        workDays: workDays ?? this.workDays,
        startDate: startDate ?? this.startDate,
        endDate: clearEndDate ? null : (endDate ?? this.endDate),
        includeHolidays: includeHolidays ?? this.includeHolidays,
        assignedUserIds: assignedUserIds ?? this.assignedUserIds,
        status: status ?? this.status,
      );

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'shift_id': shiftId,
        'work_days': (workDays.toList()..sort()).join(','),
        'start_date': _dateOnly(startDate),
        'end_date': endDate == null ? null : _dateOnly(endDate!),
        'include_holidays': includeHolidays ? 1 : 0,
        'status': status.name,
      };

  /// Build a [Schedule] from a row. [assignedUserIds] is loaded
  /// separately from `schedule_assignments` and passed in.
  factory Schedule.fromMap(
    Map<String, Object?> m, {
    List<String> assignedUserIds = const <String>[],
  }) =>
      Schedule(
        id: m['id']! as String,
        name: m['name']! as String,
        shiftId: m['shift_id']! as String,
        workDays: (m['work_days']! as String)
            .split(',')
            .where((s) => s.isNotEmpty)
            .map(int.parse)
            .toSet(),
        startDate: DateTime.parse(m['start_date']! as String),
        endDate: m['end_date'] == null
            ? null
            : DateTime.parse(m['end_date']! as String),
        includeHolidays: ((m['include_holidays'] as int?) ?? 0) == 1,
        status: ScheduleStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => ScheduleStatus.draft,
        ),
        assignedUserIds: assignedUserIds,
      );

  /// Firestore form: includes assignedUserIds inline (Firestore arrays
  /// replace the schedule_assignments junction table).
  Map<String, Object?> toFirestore() => <String, Object?>{
        ...toMap(),
        'assigned_user_ids': assignedUserIds,
      };

  factory Schedule.fromFirestore(String docId, Map<String, Object?> m) {
    final ids = (m['assigned_user_ids'] as List?)?.cast<String>() ??
        const <String>[];
    return Schedule.fromMap(
      <String, Object?>{...m, 'id': docId},
      assignedUserIds: ids,
    );
  }
}
