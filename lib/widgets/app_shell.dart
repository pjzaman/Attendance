import 'package:flutter/material.dart';

import '../shared/app_theme.dart';

/// One destination in the sidebar.
class NavDestinationDef {
  const NavDestinationDef({
    required this.icon,
    required this.label,
    required this.builder,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final WidgetBuilder builder;

  /// Optional trailing widget shown next to the label (e.g. count chip).
  final Widget? trailing;
}

/// A grouped section in the sidebar. Pass [title] = null for ungrouped
/// top-level destinations.
class NavSection {
  const NavSection({this.title, required this.destinations});

  final String? title;
  final List<NavDestinationDef> destinations;
}

/// Top-level shell: dark navy collapsible sidebar (Rysenova style),
/// sticky top bar with placeholder action icons, and the active
/// destination's body in the content area.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.brandTitle,
    required this.sections,
    this.brandSubtitle,
    this.initialIndex = 0,
  });

  final String brandTitle;
  final String? brandSubtitle;
  final List<NavSection> sections;
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _selected;
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialIndex;
  }

  List<NavDestinationDef> get _flat => <NavDestinationDef>[
        for (final s in widget.sections) ...s.destinations,
      ];

  @override
  Widget build(BuildContext context) {
    final destinations = _flat;
    final active = destinations[_selected.clamp(0, destinations.length - 1)];

    return Scaffold(
      body: Row(
        children: <Widget>[
          _Sidebar(
            brandTitle: widget.brandTitle,
            brandSubtitle: widget.brandSubtitle,
            sections: widget.sections,
            selectedFlat: _selected,
            collapsed: _collapsed,
            onSelect: (i) => setState(() => _selected = i),
            onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                _TopBar(title: active.label),
                Expanded(child: active.builder(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.brandTitle,
    required this.brandSubtitle,
    required this.sections,
    required this.selectedFlat,
    required this.collapsed,
    required this.onSelect,
    required this.onToggleCollapse,
  });

  final String brandTitle;
  final String? brandSubtitle;
  final List<NavSection> sections;
  final int selectedFlat;
  final bool collapsed;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggleCollapse;

  static const double _expandedWidth = 232;
  static const double _collapsedWidth = 72;

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? _collapsedWidth : _expandedWidth;

    final items = <Widget>[];
    int flatIndex = 0;
    for (final section in sections) {
      if (section.title != null && !collapsed) {
        items.add(_GroupLabel(title: section.title!));
      } else if (section.title != null && collapsed && items.isNotEmpty) {
        items.add(const SizedBox(height: AppSpacing.md));
      }
      for (final d in section.destinations) {
        final myIndex = flatIndex;
        items.add(_NavItem(
          icon: d.icon,
          label: d.label,
          trailing: d.trailing,
          active: myIndex == selectedFlat,
          collapsed: collapsed,
          onTap: () => onSelect(myIndex),
        ));
        flatIndex++;
      }
      items.add(const SizedBox(height: AppSpacing.sm));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: width,
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Brand(
            title: brandTitle,
            subtitle: brandSubtitle,
            collapsed: collapsed,
          ),
          const Divider(height: 1, color: AppColors.sidebarDivider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: items,
            ),
          ),
          const Divider(height: 1, color: AppColors.sidebarDivider),
          _CollapseToggle(
            collapsed: collapsed,
            onTap: onToggleCollapse,
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({
    required this.title,
    required this.subtitle,
    required this.collapsed,
  });

  final String title;
  final String? subtitle;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 0 : AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment:
            collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              title.isNotEmpty ? title.substring(0, 1).toUpperCase() : 'A',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          if (!collapsed) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.sidebarGroupLabel,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.sidebarGroupLabel,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.collapsed,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        active ? AppColors.sidebarItemActive : AppColors.sidebarItem;
    final textColor =
        active ? AppColors.sidebarItemActive : AppColors.sidebarItem;

    final child = Container(
      decoration: BoxDecoration(
        color: active ? AppColors.sidebarPill : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 0 : AppSpacing.sm,
        vertical: 8,
      ),
      child: collapsed
          ? Center(child: Icon(icon, color: iconColor, size: 20))
          : Row(
              children: <Widget>[
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.5,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
    );

    final tappable = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: child,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? AppSpacing.sm : AppSpacing.sm,
        vertical: 1,
      ),
      child: collapsed
          ? Tooltip(message: label, waitDuration: const Duration(milliseconds: 400), child: tappable)
          : tappable,
    );
  }
}

class _CollapseToggle extends StatelessWidget {
  const _CollapseToggle({required this.collapsed, required this.onTap});
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        child: Icon(
          collapsed ? Icons.chevron_right : Icons.chevron_left,
          color: AppColors.sidebarGroupLabel,
          size: 20,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, size: 20),
            tooltip: 'Calendar',
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            tooltip: 'Language',
            icon: const Icon(Icons.translate, size: 20),
            onSelected: (_) {},
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'bn', child: Text('বাংলা')),
              PopupMenuItem(value: 'ar', child: Text('عربي')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 20),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
          PopupMenuButton<String>(
            tooltip: 'Profile',
            position: PopupMenuPosition.under,
            onSelected: (_) {},
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
            child: Row(
              children: <Widget>[
                const CircleAvatar(
                  radius: 14,
                  child: Text('A', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                Icon(Icons.expand_more, size: 18, color: theme.hintColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
