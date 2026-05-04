import 'package:flutter/material.dart';

import '../shared/app_theme.dart';

/// Standard list-screen header per the redesign doc:
///   [search] [extra filters…] [date nav]   [Filters] [View] [+ New]
///
/// All slots optional. Wraps on narrow widths.
class FilterRow extends StatelessWidget {
  const FilterRow({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.searchHint = 'Search…',
    this.showSearch = true,
    this.filters = const <Widget>[],
    this.trailing,
    this.onShowFilters,
    this.activeFilterCount = 0,
    this.onShowView,
    this.onNew,
    this.newLabel = 'New',
    this.newIcon = Icons.add,
  });

  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final bool showSearch;

  /// Dropdowns / chips placed to the right of the search box.
  final List<Widget> filters;

  /// Right-side widget (typically a [DateNavigator]).
  final Widget? trailing;

  /// Opens the AdvanceFilterDrawer (right-side panel).
  final VoidCallback? onShowFilters;

  /// Number rendered in a small badge on the Filters button.
  final int activeFilterCount;

  /// Opens the column-picker drawer.
  final VoidCallback? onShowView;

  /// Primary +New action. Null = no button rendered.
  final VoidCallback? onNew;
  final String newLabel;
  final IconData newIcon;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        if (showSearch)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ...filters,
        if (trailing != null) trailing!,
        // spacer pushes right-side actions to the end on wide layouts
        if (onShowFilters != null || onShowView != null || onNew != null)
          const _RightSpacer(),
        if (onShowFilters != null)
          _ActionButton(
            icon: Icons.tune,
            label: 'Filters',
            badge: activeFilterCount > 0 ? '$activeFilterCount' : null,
            onPressed: onShowFilters!,
          ),
        if (onShowView != null)
          _ActionButton(
            icon: Icons.view_column_outlined,
            label: 'View',
            onPressed: onShowView!,
          ),
        if (onNew != null)
          FilledButton.icon(
            onPressed: onNew,
            icon: Icon(newIcon, size: 18),
            label: Text(newLabel),
          ),
      ],
    );
  }
}

class _RightSpacer extends StatelessWidget {
  const _RightSpacer();

  @override
  Widget build(BuildContext context) {
    // Wrap doesn't honor Spacer; this nudges right-side actions to the
    // end on wide rows by claiming a flexible-ish width.
    return const SizedBox(width: 1);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (badge != null) ...<Widget>[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
