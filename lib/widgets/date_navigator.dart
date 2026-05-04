import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../shared/app_theme.dart';

/// `◀ DD MMM YYYY ▶  Today` — used on every list/period-aware screen.
class DateNavigator extends StatelessWidget {
  const DateNavigator({
    super.key,
    required this.date,
    required this.onChanged,
    this.formatPattern = 'EEE, MMM d, y',
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final String formatPattern;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            tooltip: 'Previous day',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(date.subtract(const Duration(days: 1))),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              DateFormat(formatPattern).format(date),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 18),
            tooltip: 'Next day',
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(date.add(const Duration(days: 1))),
          ),
          Container(
            width: 1,
            height: 24,
            color: theme.dividerColor,
          ),
          TextButton(
            onPressed:
                isToday ? null : () => onChanged(DateUtils.dateOnly(DateTime.now())),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: const Text('Today',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
