import 'package:flutter/material.dart';

import '../shared/app_theme.dart';
import 'empty_state.dart';

/// One column in [AppDataTable].
class DataColumnDef<T> {
  const DataColumnDef({
    required this.id,
    required this.label,
    required this.cell,
    this.sortKey,
    this.numeric = false,
    this.width,
    this.exportValue,
  });

  /// Stable identifier for column visibility / sort state. Use a slug
  /// like `'check_in'`, not the human label (which can change).
  final String id;

  /// Header label.
  final String label;

  /// Render the cell for a given row.
  final Widget Function(BuildContext context, T row) cell;

  /// Returns a sortable value for this row. `null` = not sortable.
  final Comparable<Object>? Function(T row)? sortKey;

  /// Right-align the column (numeric data convention).
  final bool numeric;

  /// Optional fixed width. `null` = flex.
  final double? width;

  /// Returns a string representation of the cell for CSV / XLSX
  /// export. `null` = column is omitted from exports (defensive
  /// default — every column the runner offers in the picker should
  /// also have one).
  final String Function(T row)? exportValue;
}

/// Sortable, paginated table used for every list screen per the doc.
/// Caller passes typed rows and column definitions; the table manages
/// its own sort + page state internally.
class AppDataTable<T> extends StatefulWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.hiddenColumnIds = const <String>{},
    this.pageSize = 25,
    this.initialSortColumnId,
    this.initialSortAscending = true,
    this.emptyState,
  });

  final List<DataColumnDef<T>> columns;
  final List<T> rows;

  /// Column ids to hide. Useful for the View column-picker drawer.
  final Set<String> hiddenColumnIds;

  final int pageSize;
  final String? initialSortColumnId;
  final bool initialSortAscending;

  /// Shown when [rows] is empty. Defaults to a generic EmptyState.
  final Widget? emptyState;

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

class _AppDataTableState<T> extends State<AppDataTable<T>> {
  String? _sortColId;
  bool _sortAsc = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _sortColId = widget.initialSortColumnId;
    _sortAsc = widget.initialSortAscending;
  }

  @override
  void didUpdateWidget(AppDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to first page when row set changes shape.
    if (oldWidget.rows.length != widget.rows.length) {
      _page = 0;
    }
  }

  List<DataColumnDef<T>> get _visibleColumns => <DataColumnDef<T>>[
        for (final c in widget.columns)
          if (!widget.hiddenColumnIds.contains(c.id)) c,
      ];

  List<T> _sorted(List<T> rows) {
    if (_sortColId == null) return rows;
    final col = widget.columns.firstWhere(
      (c) => c.id == _sortColId,
      orElse: () => widget.columns.first,
    );
    if (col.sortKey == null) return rows;
    final out = <T>[...rows];
    out.sort((a, b) {
      final av = col.sortKey!(a);
      final bv = col.sortKey!(b);
      if (av == null && bv == null) return 0;
      if (av == null) return 1;
      if (bv == null) return -1;
      final cmp = av.compareTo(bv);
      return _sortAsc ? cmp : -cmp;
    });
    return out;
  }

  void _toggleSort(DataColumnDef<T> col) {
    if (col.sortKey == null) return;
    setState(() {
      if (_sortColId == col.id) {
        _sortAsc = !_sortAsc;
      } else {
        _sortColId = col.id;
        _sortAsc = true;
      }
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return widget.emptyState ??
          const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No data',
            message: 'Nothing to show here yet.',
          );
    }

    final cols = _visibleColumns;
    final total = widget.rows.length;
    final pageSize = widget.pageSize;
    final pageCount = (total / pageSize).ceil();
    final clampedPage = _page.clamp(0, pageCount - 1);
    final start = clampedPage * pageSize;
    final end = (start + pageSize).clamp(0, total);

    final sorted = _sorted(widget.rows);
    final pageRows = sorted.sublist(start, end);

    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 320,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _Header<T>(
                      columns: cols,
                      sortColId: _sortColId,
                      sortAsc: _sortAsc,
                      onSort: _toggleSort,
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    Expanded(
                      child: ListView.separated(
                        itemCount: pageRows.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: theme.dividerColor),
                        itemBuilder: (context, i) => _Row<T>(
                          row: pageRows[i],
                          columns: cols,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          _Footer(
            start: start + 1,
            end: end,
            total: total,
            page: clampedPage,
            pageCount: pageCount,
            onPrev: clampedPage > 0
                ? () => setState(() => _page = clampedPage - 1)
                : null,
            onNext: clampedPage < pageCount - 1
                ? () => setState(() => _page = clampedPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _Header<T> extends StatelessWidget {
  const _Header({
    required this.columns,
    required this.sortColId,
    required this.sortAsc,
    required this.onSort,
  });

  final List<DataColumnDef<T>> columns;
  final String? sortColId;
  final bool sortAsc;
  final void Function(DataColumnDef<T>) onSort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBg.withValues(alpha: 0.4)
            : AppColors.lightBg,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          for (final c in columns)
            _HeaderCell<T>(
              column: c,
              sorted: sortColId == c.id,
              ascending: sortAsc,
              onTap: () => onSort(c),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell<T> extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.sorted,
    required this.ascending,
    required this.onTap,
  });

  final DataColumnDef<T> column;
  final bool sorted;
  final bool ascending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSort = column.sortKey != null;
    final label = Text(
      column.label,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: theme.hintColor,
      ),
    );
    final indicator = !canSort
        ? const SizedBox.shrink()
        : Icon(
            sorted
                ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 12,
            color: sorted ? AppColors.brandPrimary : theme.hintColor,
          );

    final content = Row(
      mainAxisAlignment: column.numeric
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: <Widget>[
        if (column.numeric) ...<Widget>[
          indicator,
          const SizedBox(width: 4),
          label,
        ] else ...<Widget>[
          label,
          const SizedBox(width: 4),
          indicator,
        ],
      ],
    );

    final inner = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: canSort
          ? InkWell(onTap: onTap, child: content)
          : content,
    );

    return column.width == null
        ? Expanded(child: inner)
        : SizedBox(width: column.width, child: inner);
  }
}

class _Row<T> extends StatelessWidget {
  const _Row({required this.row, required this.columns});
  final T row;
  final List<DataColumnDef<T>> columns;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          for (final c in columns)
            _Cell<T>(column: c, row: row),
        ],
      ),
    );
  }
}

class _Cell<T> extends StatelessWidget {
  const _Cell({required this.column, required this.row});
  final DataColumnDef<T> column;
  final T row;

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Align(
        alignment: column.numeric
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: column.cell(context, row),
      ),
    );
    return column.width == null
        ? Expanded(child: inner)
        : SizedBox(width: column.width, child: inner);
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.start,
    required this.end,
    required this.total,
    required this.page,
    required this.pageCount,
    required this.onPrev,
    required this.onNext,
  });

  final int start;
  final int end;
  final int total;
  final int page;
  final int pageCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Showing $start to $end of $total Results',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            tooltip: 'Previous page',
            visualDensity: VisualDensity.compact,
            onPressed: onPrev,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '${page + 1} / $pageCount',
              style: theme.textTheme.bodySmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 18),
            tooltip: 'Next page',
            visualDensity: VisualDensity.compact,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
