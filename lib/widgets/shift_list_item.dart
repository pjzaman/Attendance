import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../shared/app_theme.dart';

/// A row in the Shifts library: leading color band, code badge, name,
/// time range, break + working hours, and the count of schedules
/// currently using this shift.
class ShiftListItem extends StatelessWidget {
  const ShiftListItem({
    super.key,
    required this.shift,
    this.scheduleCount = 0,
    this.onTap,
  });

  final Shift shift;

  /// How many schedules reference this shift. Surfaced in the row so the
  /// user knows the blast radius of editing or deleting.
  final int scheduleCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = shift.workMinutes / 60;

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
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: shift.color.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        border: Border.all(color: shift.color),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        shift.code,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            shift.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shift.formatRange(),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Working',
                        value: '${hours.toStringAsFixed(2)} h',
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Break',
                        value: shift.breakMinutes == 0
                            ? '—'
                            : '${shift.breakMinutes} min',
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Schedules',
                        value: '$scheduleCount',
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.hintColor,
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
