import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/daily_summary.dart';
import '../models/employee.dart';
import '../models/holiday.dart';
import '../models/schedule.dart';
import '../models/shift.dart';
import '../shared/app_theme.dart';

/// Weekly duty roster — sticky-left employee column, 7 day columns.
/// Per the doc, "the killer view for shift managers": shift code chip
/// per cell with check-in/out time or 'Off'.
class DutyRosterGrid extends StatelessWidget {
  const DutyRosterGrid({
    super.key,
    required this.employees,
    required this.schedules,
    required this.shifts,
    required this.weekStart,
    this.daily = const <DailySummary>[],
    this.holidays = const <Holiday>[],
  });

  final List<Employee> employees;
  final List<Schedule> schedules;
  final List<Shift> shifts;

  /// First day of the displayed week (Monday).
  final DateTime weekStart;

  /// Daily summaries for the displayed week — used to show actual
  /// check-in/out time inside each cell when the employee did work.
  final List<DailySummary> daily;

  /// Optional holidays — when a date matches a holiday and the
  /// schedule's `includeHolidays` flag is off, the cell renders as
  /// "Holiday" rather than the shift chip.
  final List<Holiday> holidays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = <DateTime>[
      for (int i = 0; i < 7; i++) weekStart.add(Duration(days: i)),
    ];

    final shiftById = <String, Shift>{for (final s in shifts) s.id: s};
    final schedById = <String, Schedule>{for (final s in schedules) s.id: s};
    final scheduleByUser = <String, Schedule>{};
    for (final s in schedules) {
      for (final uid in s.assignedUserIds) {
        scheduleByUser.putIfAbsent(uid, () => s);
      }
    }
    final dailyByKey = <String, DailySummary>{
      for (final d in daily) _dailyKey(d.userId, d.date): d,
    };
    final holidaysByDay = <String, Holiday>{
      for (final h in holidays)
        '${h.date.year}-${h.date.month.toString().padLeft(2, '0')}-${h.date.day.toString().padLeft(2, '0')}':
            h,
    };

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _HeaderRow(days: days),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: ListView.separated(
              itemCount: employees.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (context, i) {
                final emp = employees[i];
                final schedule = scheduleByUser[emp.userId];
                final shift = schedule == null
                    ? null
                    : shiftById[schedule.shiftId];
                return _EmployeeRow(
                  employee: emp,
                  schedule: schedule,
                  shift: shift,
                  days: days,
                  dailyByKey: dailyByKey,
                  scheduleById: schedById,
                  shiftById: shiftById,
                  holidaysByDay: holidaysByDay,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _dailyKey(String userId, DateTime date) =>
      '$userId|${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

const double _kEmployeeColWidth = 200;
const double _kDayColWidth = 116;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.days});
  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = DateUtils.dateOnly(DateTime.now());
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBg.withValues(alpha: 0.4)
            : AppColors.lightBg,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: _kEmployeeColWidth,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'Employee',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: theme.hintColor,
                ),
              ),
            ),
          ),
          for (final d in days)
            SizedBox(
              width: _kDayColWidth,
              child: _DayHeaderCell(
                date: d,
                isToday: DateUtils.isSameDay(d, today),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell({required this.date, required this.isToday});
  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.brandPrimary.withValues(alpha: 0.08)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            DateFormat('EEE').format(date),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: isToday ? AppColors.brandPrimary : theme.hintColor,
            ),
          ),
          Text(
            DateFormat('MMM d').format(date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isToday
                  ? AppColors.brandPrimary
                  : theme.textTheme.bodyMedium?.color,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({
    required this.employee,
    required this.schedule,
    required this.shift,
    required this.days,
    required this.dailyByKey,
    required this.scheduleById,
    required this.shiftById,
    required this.holidaysByDay,
  });

  final Employee employee;
  final Schedule? schedule;
  final Shift? shift;
  final List<DateTime> days;
  final Map<String, DailySummary> dailyByKey;
  final Map<String, Schedule> scheduleById;
  final Map<String, Shift> shiftById;
  final Map<String, Holiday> holidaysByDay;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          width: _kEmployeeColWidth,
          child: _EmployeeCell(employee: employee, shift: shift),
        ),
        for (final d in days)
          SizedBox(
            width: _kDayColWidth,
            child: _RosterCell(
              employee: employee,
              date: d,
              isToday: DateUtils.isSameDay(d, today),
              schedule: schedule,
              shift: shift,
              daily: dailyByKey[
                  '${employee.userId}|${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'],
              holiday: holidaysByDay[
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'],
            ),
          ),
      ],
    );
  }
}

class _EmployeeCell extends StatelessWidget {
  const _EmployeeCell({required this.employee, required this.shift});
  final Employee employee;
  final Shift? shift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = (employee.name.isNotEmpty
            ? employee.name
            : employee.userId.isNotEmpty
                ? employee.userId
                : '?')
        .substring(0, 1)
        .toUpperCase();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: <Widget>[
          CircleAvatar(radius: 14, child: Text(initial,
              style: const TextStyle(fontSize: 12))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  employee.name.isNotEmpty
                      ? employee.name
                      : '(no name)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  shift == null ? 'Unassigned' : shift!.name,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterCell extends StatelessWidget {
  const _RosterCell({
    required this.employee,
    required this.date,
    required this.isToday,
    required this.schedule,
    required this.shift,
    required this.daily,
    required this.holiday,
  });

  final Employee employee;
  final DateTime date;
  final bool isToday;
  final Schedule? schedule;
  final Shift? shift;
  final DailySummary? daily;
  final Holiday? holiday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduled = schedule != null && schedule!.worksOn(date);
    final isHolidaySkip = holiday != null &&
        schedule != null &&
        !schedule!.includeHolidays;
    final effectivelyOff = !scheduled || isHolidaySkip;
    final timeFmt = DateFormat('HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.brandPrimary.withValues(alpha: 0.05)
            : null,
        border: Border(
          left: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: effectivelyOff
          ? Center(
              child: holiday != null
                  ? Tooltip(
                      message: holiday!.name,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusWarning
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppRadius.xs),
                          border: Border.all(
                            color: AppColors.statusWarning
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Holiday',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.statusWarning,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      'Off',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _ShiftCellChip(shift: shift!),
                if (daily != null && daily!.checkIn != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    daily!.checkOut != null
                        ? '${timeFmt.format(daily!.checkIn!)}–${timeFmt.format(daily!.checkOut!)}'
                        : 'In ${timeFmt.format(daily!.checkIn!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (daily == null && _isPast(date)) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'Absent',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.statusDanger,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
    );
  }

  bool _isPast(DateTime d) {
    final today = DateUtils.dateOnly(DateTime.now());
    return d.isBefore(today);
  }
}

class _ShiftCellChip extends StatelessWidget {
  const _ShiftCellChip({required this.shift});
  final Shift shift;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: shift.color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: shift.color.withValues(alpha: 0.55)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: shift.color,
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.center,
            child: Text(
              shift.code,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              shift.formatRange(),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
