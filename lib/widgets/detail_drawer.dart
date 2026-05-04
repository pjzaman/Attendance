import 'package:flutter/material.dart';

import '../shared/app_theme.dart';

/// Right-slide overlay used for detail/edit/filter drawers throughout the
/// app. Per the redesign doc, never modal, never a route change for the
/// content underneath — it sits on top of the current page so the user
/// keeps their context.
class DetailDrawer extends StatelessWidget {
  const DetailDrawer({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const <Widget>[],
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Footer action buttons. Empty list = no footer rendered.
  final List<Widget> actions;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleMedium),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: padding,
            child: child,
          ),
        ),
        if (actions.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                for (int i = 0; i < actions.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  actions[i],
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Slides a panel in from the right edge with a dim barrier. Returns
/// whatever value the drawer pops with (Navigator.pop(value)).
Future<T?> showDetailDrawer<T>(
  BuildContext context, {
  required Widget child,
  double width = 480,
}) {
  return Navigator.of(context, rootNavigator: false).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) => Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: SizedBox(
            height: double.infinity,
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              elevation: 8,
              child: child,
            ),
          ),
        ),
      ),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: anim.drive(
          Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: child,
      ),
    ),
  );
}
