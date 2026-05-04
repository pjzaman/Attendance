import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/report_def.dart';
import '../providers/app_state.dart';
import '../services/reports_catalog.dart';
import '../shared/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_row.dart';
import '../widgets/status_pill.dart';
import 'report_runner_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _starredOnly = false;
  ReportDef? _opened;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (_opened != null) {
      return ReportRunnerScreen(
        report: _opened!,
        onBack: () => setState(() => _opened = null),
      );
    }

    final all = ReportsCatalog.all();
    final q = _query.toLowerCase();
    final filtered = all.where((r) {
      if (_starredOnly && !state.starredReports.contains(r.id)) return false;
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.category.label.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FilterRow(
            searchController: _searchCtrl,
            onSearchChanged: (v) => setState(() => _query = v.trim()),
            searchHint: 'Search reports…',
            filters: <Widget>[
              FilterChip(
                avatar: Icon(
                  _starredOnly ? Icons.star : Icons.star_border,
                  size: 16,
                  color: _starredOnly
                      ? AppColors.statusWarning
                      : Theme.of(context).hintColor,
                ),
                label: Text('Starred'
                    '${state.starredReports.isEmpty ? "" : " (${state.starredReports.length})"}'),
                selected: _starredOnly,
                onSelected: (v) => setState(() => _starredOnly = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: _starredOnly && _query.isEmpty
                        ? 'No starred reports yet'
                        : 'No reports match',
                    message: _starredOnly && _query.isEmpty
                        ? 'Tap the star on a report card to pin it here.'
                        : 'Try a different search or clear the filters.',
                  )
                : SingleChildScrollView(
                    child: _CategoryGrid(
                      reports: filtered,
                      starredIds: state.starredReports,
                      onToggleStar: (r) =>
                          state.toggleStarredReport(r.id),
                      onOpen: (r) => setState(() => _opened = r),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.reports,
    required this.starredIds,
    required this.onToggleStar,
    required this.onOpen,
  });

  final List<ReportDef> reports;
  final Set<String> starredIds;
  final ValueChanged<ReportDef> onToggleStar;
  final ValueChanged<ReportDef> onOpen;

  @override
  Widget build(BuildContext context) {
    final byCategory = <ReportCategory, List<ReportDef>>{};
    for (final r in reports) {
      byCategory.putIfAbsent(r.category, () => <ReportDef>[]).add(r);
    }

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final cols = w >= 1200
          ? 4
          : w >= 900
              ? 3
              : w >= 600
                  ? 2
                  : 1;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.3,
        children: <Widget>[
          for (final cat in ReportCategory.values)
            if (byCategory[cat] != null)
              _CategoryColumn(
                category: cat,
                reports: byCategory[cat]!,
                starredIds: starredIds,
                onToggleStar: onToggleStar,
                onOpen: onOpen,
              ),
        ],
      );
    });
  }
}

class _CategoryColumn extends StatelessWidget {
  const _CategoryColumn({
    required this.category,
    required this.reports,
    required this.starredIds,
    required this.onToggleStar,
    required this.onOpen,
  });

  final ReportCategory category;
  final List<ReportDef> reports;
  final Set<String> starredIds;
  final ValueChanged<ReportDef> onToggleStar;
  final ValueChanged<ReportDef> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.10),
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(category.icon, size: 18, color: category.color),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  category.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: category.color,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '· ${reports.length}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: reports.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (context, i) => _ReportRow(
                report: reports[i],
                starred: starredIds.contains(reports[i].id),
                onToggleStar: () => onToggleStar(reports[i]),
                onOpen: () => onOpen(reports[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.report,
    required this.starred,
    required this.onToggleStar,
    required this.onOpen,
  });

  final ReportDef report;
  final bool starred;
  final VoidCallback onToggleStar;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          report.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!report.available) ...<Widget>[
                        const SizedBox(width: 6),
                        const StatusPill(
                          label: 'Soon',
                          tone: StatusTone.muted,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.description,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                starred ? Icons.star : Icons.star_border,
                color: starred ? AppColors.statusWarning : theme.hintColor,
                size: 20,
              ),
              tooltip: starred ? 'Unstar' : 'Star',
              visualDensity: VisualDensity.compact,
              onPressed: onToggleStar,
            ),
          ],
        ),
      ),
    );
  }
}
