import 'package:flutter/material.dart';

import '../shared/app_theme.dart';

/// Pill with a colored leading band that travels with a named shift
/// across schedules, attendance log, dashboard and the duty roster.
class ShiftChip extends StatelessWidget {
  const ShiftChip({
    super.key,
    required this.label,
    this.timeRange,
    this.color,
    this.shiftKey,
    this.dense = false,
  }) : assert(color != null || shiftKey != null,
            'Provide either color or shiftKey');

  final String label;
  final String? timeRange;
  final Color? color;
  final String? shiftKey;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? AppColors.shiftColorFor(shiftKey ?? label);
    final hPad = dense ? 6.0 : 8.0;
    final vPad = dense ? 2.0 : 4.0;
    final fontSize = dense ? 11.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(width: 4, color: c),
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (timeRange != null) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      timeRange!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: fontSize - 1,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
