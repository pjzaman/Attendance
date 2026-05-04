import 'package:flutter/material.dart';

import '../models/employee.dart';
import '../models/schedule.dart';
import '../models/shift.dart';

/// Hardcoded shifts + schedules so the Schedules / Duty Roster screens
/// have something to render before the persistence layer is wired up.
/// Replace with real CRUD in a later phase.
class ScheduleSeed {
  static const Set<int> bangladeshWorkWeek = <int>{
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.saturday,
    DateTime.sunday,
  };

  static List<Shift> shifts() => <Shift>[
        const Shift(
          id: 'shift_morning',
          name: 'Morning',
          code: 'M',
          start: TimeOfDay(hour: 8, minute: 0),
          end: TimeOfDay(hour: 16, minute: 0),
          breakMinutes: 30,
        ),
        const Shift(
          id: 'shift_evening',
          name: 'Evening',
          code: 'E',
          start: TimeOfDay(hour: 16, minute: 0),
          end: TimeOfDay(hour: 0, minute: 0),
          breakMinutes: 30,
        ),
        const Shift(
          id: 'shift_night',
          name: 'Night',
          code: 'N',
          start: TimeOfDay(hour: 0, minute: 0),
          end: TimeOfDay(hour: 8, minute: 0),
          breakMinutes: 30,
        ),
      ];

  /// Seed three schedules from the live employee list — splits employees
  /// across Morning and Evening rosters; leaves a Night Watch as draft
  /// so the "waiting to publish" banner has something to surface.
  static List<Schedule> schedulesFor(List<Employee> employees) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final ids = employees.map((e) => e.userId).toList();
    final half = (ids.length / 2).ceil();
    final morning = ids.take(half).toList();
    final evening = ids.skip(half).toList();

    return <Schedule>[
      Schedule(
        id: 'sched_morning',
        name: 'Morning Roster',
        shiftId: 'shift_morning',
        workDays: bangladeshWorkWeek,
        startDate: monthStart,
        assignedUserIds: morning,
        status: ScheduleStatus.published,
      ),
      Schedule(
        id: 'sched_evening',
        name: 'Evening Roster',
        shiftId: 'shift_evening',
        workDays: bangladeshWorkWeek,
        startDate: monthStart,
        assignedUserIds: evening,
        status: ScheduleStatus.published,
      ),
      Schedule(
        id: 'sched_night',
        name: 'Night Watch',
        shiftId: 'shift_night',
        workDays: bangladeshWorkWeek,
        startDate: monthStart,
        assignedUserIds: const <String>[],
        status: ScheduleStatus.draft,
      ),
    ];
  }
}
