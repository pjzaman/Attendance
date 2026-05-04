import '../models/team.dart';

/// Seed a single placeholder team on first launch so other surfaces
/// (Employee profile, Duty Roster filters) have something to reference.
class TeamSeed {
  static List<Team> defaults() => <Team>[
        Team(
          id: 'team_default',
          name: 'General',
          description:
              'Default team — rename or replace once HR maps the org chart.',
        ),
      ];
}
