import '../models/holiday.dart';

/// Example public-holiday seed for the current calendar year. Bangladesh
/// dates are an HR-edit-able starting point — the year flips
/// automatically on first launch but the user is expected to maintain
/// the exact dates per their official calendar.
class HolidaySeed {
  static List<Holiday> defaults() {
    final year = DateTime.now().year;
    return <Holiday>[
      Holiday(
        id: 'hol_intl_mother_language_$year',
        name: 'International Mother Language Day',
        date: DateTime(year, 2, 21),
      ),
      Holiday(
        id: 'hol_independence_$year',
        name: 'Independence Day',
        date: DateTime(year, 3, 26),
      ),
      Holiday(
        id: 'hol_pohela_boishakh_$year',
        name: 'Pohela Boishakh (Bengali New Year)',
        date: DateTime(year, 4, 14),
      ),
      Holiday(
        id: 'hol_may_day_$year',
        name: 'May Day',
        date: DateTime(year, 5, 1),
      ),
      Holiday(
        id: 'hol_victory_$year',
        name: 'Victory Day',
        date: DateTime(year, 12, 16),
      ),
    ];
  }
}
