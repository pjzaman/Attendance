import 'package:flutter/material.dart';

import '../shared/app_theme.dart';

/// A reusable named shift with start/end times and break.
class Shift {
  const Shift({
    required this.id,
    required this.name,
    required this.code,
    required this.start,
    required this.end,
    this.breakMinutes = 0,
  });

  final String id;
  final String name;

  /// Short label used in the Duty Roster grid (e.g. `M`, `E`, `N`).
  final String code;
  final TimeOfDay start;
  final TimeOfDay end;
  final int breakMinutes;

  /// Stable color band — the same shift renders the same color in the
  /// schedule list, dashboard, attendance log, and duty roster.
  Color get color => AppColors.shiftColorFor(id);

  /// Net minutes per shift (handles overnight shifts).
  int get workMinutes {
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    final raw = e <= s ? (e + 24 * 60 - s) : (e - s);
    return raw - breakMinutes;
  }

  String formatRange() {
    String t(TimeOfDay tod) =>
        '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
    return '${t(start)} – ${t(end)}';
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'code': code,
        'start_minutes': start.hour * 60 + start.minute,
        'end_minutes': end.hour * 60 + end.minute,
        'break_minutes': breakMinutes,
      };

  factory Shift.fromMap(Map<String, Object?> m) {
    TimeOfDay todFromMin(int total) =>
        TimeOfDay(hour: total ~/ 60, minute: total % 60);
    return Shift(
      id: m['id']! as String,
      name: m['name']! as String,
      code: m['code']! as String,
      start: todFromMin(m['start_minutes']! as int),
      end: todFromMin(m['end_minutes']! as int),
      breakMinutes: (m['break_minutes'] as int?) ?? 0,
    );
  }
}
