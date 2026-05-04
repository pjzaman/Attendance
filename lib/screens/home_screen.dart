import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../shared/app_theme.dart';
import '../widgets/app_shell.dart';
import 'attendance_screen.dart';
import 'daily_screen.dart';
import 'dashboard_screen.dart';
import 'employees_screen.dart';
import 'export_screen.dart';
import 'leave_screen.dart';
import 'payroll_hub_screen.dart';
import 'payroll_salary_screen.dart';
import 'punches_screen.dart';
import 'reports_screen.dart';
import 'requests_screen.dart';
import 'schedules_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return AppShell(
      brandTitle: 'Apon Attendance',
      brandSubtitle: 'UFace800',
      sections: <NavSection>[
        NavSection(
          destinations: <NavDestinationDef>[
            NavDestinationDef(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              builder: (_) => const DashboardScreen(),
            ),
            NavDestinationDef(
              icon: Icons.assessment_outlined,
              label: 'Reports',
              trailing: _CountChip(state.starredReports.length),
              builder: (_) => const ReportsScreen(),
            ),
            NavDestinationDef(
              icon: Icons.inbox_outlined,
              label: 'Requests',
              trailing: _CountChip(
                state.requests.where((r) => r.isPending).length,
              ),
              builder: (_) => const RequestsScreen(),
            ),
          ],
        ),
        NavSection(
          title: 'HR Management',
          destinations: <NavDestinationDef>[
            NavDestinationDef(
              icon: Icons.person_outline,
              label: 'Employees',
              trailing: _CountChip(state.employees.length),
              builder: (_) => const EmployeesScreen(),
            ),
            NavDestinationDef(
              icon: Icons.event_available_outlined,
              label: 'Attendance',
              builder: (_) => const AttendanceScreen(),
            ),
            NavDestinationDef(
              icon: Icons.schedule_outlined,
              label: 'Schedules',
              builder: (_) => const SchedulesScreen(),
            ),
            NavDestinationDef(
              icon: Icons.beach_access_outlined,
              label: 'Leave',
              builder: (_) => const LeaveScreen(),
            ),
            NavDestinationDef(
              icon: Icons.fingerprint,
              label: 'Punches',
              trailing: _CountChip(state.totalPunches),
              builder: (_) => const PunchesScreen(),
            ),
            NavDestinationDef(
              icon: Icons.calendar_today_outlined,
              label: 'Daily',
              trailing: _CountChip(state.daily.length),
              builder: (_) => const DailyScreen(),
            ),
          ],
        ),
        NavSection(
          title: 'Payroll (Beta)',
          destinations: <NavDestinationDef>[
            NavDestinationDef(
              icon: Icons.payments_outlined,
              label: 'Salary',
              trailing: const _BetaChip(),
              builder: (_) => const PayrollSalaryScreen(),
            ),
            NavDestinationDef(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Payroll Hub',
              trailing: const _BetaChip(),
              builder: (_) => const PayrollHubScreen(),
            ),
          ],
        ),
        NavSection(
          title: 'Tools',
          destinations: <NavDestinationDef>[
            NavDestinationDef(
              icon: Icons.file_download_outlined,
              label: 'Export',
              builder: (_) => const ExportScreen(),
            ),
          ],
        ),
        NavSection(
          destinations: <NavDestinationDef>[
            NavDestinationDef(
              icon: Icons.settings_outlined,
              label: 'Settings',
              builder: (_) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

class _BetaChip extends StatelessWidget {
  const _BetaChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.statusWarning.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: const Text(
        'BETA',
        style: TextStyle(
          color: AppColors.statusWarning,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip(this.count);
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.sidebarPill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.sidebarItem,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
