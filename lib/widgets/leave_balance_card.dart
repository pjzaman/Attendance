import 'package:flutter/material.dart';

import '../models/leave_type.dart';
import '../shared/app_theme.dart';
import 'status_pill.dart';

/// One leave-balance row in the right pane of the Leave screen.
/// Shows code badge, name + gender constraint, used / total, and a
/// utilization bar.
class LeaveBalanceCard extends StatelessWidget {
  const LeaveBalanceCard({
    super.key,
    required this.type,
    required this.usedDays,
  });

  final LeaveType type;
  final int usedDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = type.defaultDaysPerYear;
    final remaining = (total - usedDays).clamp(-9999, total);
    final pct = total <= 0 ? 0.0 : (usedDays / total).clamp(0.0, 1.0);

    final tone = total <= 0
        ? StatusTone.muted
        : (usedDays >= total
            ? StatusTone.danger
            : (pct >= 0.75 ? StatusTone.warning : StatusTone.success));

    final color = AppColors.shiftColorFor(type.id);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: color),
                ),
                alignment: Alignment.center,
                child: Text(
                  type.code,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            type.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (type.genderConstraint !=
                            LeaveGenderConstraint.any) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          StatusPill(
                            label: type.genderConstraint.label,
                            tone: StatusTone.info,
                            dense: true,
                          ),
                        ],
                        if (!type.isPaid) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          const StatusPill(
                            label: 'Unpaid',
                            tone: StatusTone.muted,
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total <= 0
                          ? 'Used $usedDays day${usedDays == 1 ? "" : "s"} this year'
                          : 'Used $usedDays of $total day${total == 1 ? "" : "s"}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    total <= 0 ? '—' : '$remaining',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _toneColor(tone),
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  Text('remaining',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ],
              ),
            ],
          ),
          if (total > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: theme.dividerColor,
                valueColor:
                    AlwaysStoppedAnimation<Color>(_toneColor(tone)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _toneColor(StatusTone t) {
    switch (t) {
      case StatusTone.info:
        return AppColors.statusInfo;
      case StatusTone.success:
        return AppColors.statusSuccess;
      case StatusTone.warning:
        return AppColors.statusWarning;
      case StatusTone.danger:
        return AppColors.statusDanger;
      case StatusTone.muted:
        return AppColors.statusMuted;
    }
  }
}
