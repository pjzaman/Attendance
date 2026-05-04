import 'package:flutter/material.dart';

import '../shared/app_theme.dart';
import 'status_pill.dart';

/// Single KPI tile: small label, big number, optional delta vs prior period.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaSuffix = '%',
    this.subLabel,
    this.tone = StatusTone.info,
    this.icon,
  });

  final String label;
  final String value;

  /// Signed percent (or whatever unit) vs prior period. Null = no delta shown.
  /// Positive renders ▲ green, negative renders ▼ red. The semantics of
  /// "good" vs "bad" are tone-agnostic — pass a negated value for KPIs
  /// where lower is better (e.g. Absent).
  final double? delta;
  final String deltaSuffix;
  final String? subLabel;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _toneColor(tone);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: accent, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (delta != null) _DeltaChip(delta: delta!, suffix: deltaSuffix),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
            if (subLabel != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                subLabel!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
          ],
        ),
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

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta, required this.suffix});
  final double delta;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final positive = delta >= 0;
    final color =
        positive ? AppColors.statusSuccess : AppColors.statusDanger;
    final arrow = positive ? '▲' : '▼';
    final text = '${delta.abs().toStringAsFixed(delta.abs() >= 10 ? 0 : 1)}$suffix';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        '$arrow $text',
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
