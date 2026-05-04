import '../models/leave_type.dart';

/// Default Labour Law leaves library, per the redesign doc §4.10:
/// "Annual / Casual / Sick / Medical / Maternity (Female) / Paternity
/// (Male) / Parental / Bereavement / Personal / Study / Compassionate
/// / Unpaid. Each is toggleable on/off and gender-aware."
///
/// Day defaults are sensible Bangladesh-friendly starting points; HR
/// edits per their actual policy in Settings → Leave Types.
class LeaveTypeSeed {
  static List<LeaveType> defaults() => const <LeaveType>[
        LeaveType(
          id: 'lt_annual',
          name: 'Annual',
          code: 'AL',
          defaultDaysPerYear: 14,
        ),
        LeaveType(
          id: 'lt_casual',
          name: 'Casual',
          code: 'CL',
          defaultDaysPerYear: 10,
        ),
        LeaveType(
          id: 'lt_sick',
          name: 'Sick',
          code: 'SL',
          defaultDaysPerYear: 14,
        ),
        LeaveType(
          id: 'lt_medical',
          name: 'Medical',
          code: 'ML',
          defaultDaysPerYear: 0,
          isPaid: true,
        ),
        LeaveType(
          id: 'lt_maternity',
          name: 'Maternity',
          code: 'MAT',
          defaultDaysPerYear: 112,
          genderConstraint: LeaveGenderConstraint.femaleOnly,
        ),
        LeaveType(
          id: 'lt_paternity',
          name: 'Paternity',
          code: 'PAT',
          defaultDaysPerYear: 14,
          genderConstraint: LeaveGenderConstraint.maleOnly,
        ),
        LeaveType(
          id: 'lt_parental',
          name: 'Parental',
          code: 'PRL',
          defaultDaysPerYear: 0,
        ),
        LeaveType(
          id: 'lt_bereavement',
          name: 'Bereavement',
          code: 'BRV',
          defaultDaysPerYear: 5,
        ),
        LeaveType(
          id: 'lt_personal',
          name: 'Personal',
          code: 'PL',
          defaultDaysPerYear: 5,
        ),
        LeaveType(
          id: 'lt_study',
          name: 'Study',
          code: 'STD',
          defaultDaysPerYear: 5,
        ),
        LeaveType(
          id: 'lt_compassionate',
          name: 'Compassionate',
          code: 'CMP',
          defaultDaysPerYear: 3,
        ),
        LeaveType(
          id: 'lt_unpaid',
          name: 'Unpaid',
          code: 'UPL',
          defaultDaysPerYear: 0,
          isPaid: false,
        ),
      ];
}
