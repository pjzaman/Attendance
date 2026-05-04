import 'package:flutter/material.dart';

import '../shared/app_theme.dart';

enum StatusTone { info, success, warning, danger, muted }

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = StatusTone.info,
    this.dense = false,
  });

  final String label;
  final StatusTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = _color(tone);
    final hPad = dense ? 6.0 : 8.0;
    final vPad = dense ? 1.0 : 2.0;
    final dot = dense ? 5.0 : 6.0;
    final fontSize = dense ? 10.5 : 11.5;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: dense ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static Color _color(StatusTone t) {
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
