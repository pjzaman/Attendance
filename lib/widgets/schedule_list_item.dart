import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule.dart';
import '../models/shift.dart';
import '../shared/app_theme.dart';
import 'status_pill.dart';

/// A row in the Schedules list: leading color band (from the shift),
/// schedule name, start date, assigned-employee count, weekly hours,
/// shift label, and a status pill (published / draft).
class ScheduleListItem extends StatelessWidget {
  const ScheduleListItem({
    super.key,
    required this.schedule,
    required this.shift,
    this.onTap,
  });

  final Schedule schedule;
  final Shift shift;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoursPerWeek =
        (schedule.workDays.length * shift.workMinutes) / 60.0;

    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Container(width: 6, color: shift.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            schedule.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Starts ${DateFormat('MMM d, y').format(schedule.startDate)}'
                            '${schedule.endDate == null ? "" : " · ends ${DateFormat('MMM d, y').format(schedule.endDate!)}"}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Employees',
                        value: '${schedule.assignedUserIds.length}',
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Hours / week',
                        value: hoursPerWeek.toStringAsFixed(1),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _ShiftBadge(shift: shift),
                    ),
                    SizedBox(
                      width: 110,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: StatusPill(
                          label: schedule.isPublished ? 'Published' : 'Draft',
                          tone: schedule.isPublished
                              ? StatusTone.success
                              : StatusTone.warning,
                          dense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.hintColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _ShiftBadge extends StatelessWidget {
  const _ShiftBadge({required this.shift});
  final Shift shift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: shift.color.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: shift.color),
          ),
          alignment: Alignment.center,
          child: Text(
            shift.code,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(shift.name, style: theme.textTheme.bodyMedium),
              Text(
                shift.formatRange(),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
