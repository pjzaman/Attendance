import 'package:flutter/material.dart';

import '../shared/app_theme.dart';

/// Avatar with a circular progress ring + percent label, per the
/// redesign doc §3.7. "Encourages HR to actually fill in the data."
class ProfileCompletenessMeter extends StatelessWidget {
  const ProfileCompletenessMeter({
    super.key,
    required this.completeness,
    required this.initial,
    this.size = 64,
  });

  /// 0.0 – 1.0
  final double completeness;
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pct = (completeness * 100).round();
    final color = _toneColor(completeness);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: completeness.clamp(0.0, 1.0),
              strokeWidth: 3,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          CircleAvatar(
            radius: size / 2 - 6,
            child: Text(
              initial.toUpperCase(),
              style: TextStyle(fontSize: size * 0.32),
            ),
          ),
          Positioned(
            bottom: -2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Theme.of(context).cardColor,
                  width: 2,
                ),
              ),
              child: Text(
                '$pct%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _toneColor(double c) {
    if (c >= 0.75) return AppColors.statusSuccess;
    if (c >= 0.5) return AppColors.statusWarning;
    return AppColors.statusDanger;
  }
}
