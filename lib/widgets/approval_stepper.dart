import 'package:flutter/material.dart';

import '../models/approval_policy.dart';
import '../models/request.dart';
import '../shared/app_theme.dart';

/// Compact horizontal stepper showing where a request sits in its
/// approval pipeline. Per the doc, "View Pipeline visual editor" maps
/// to the editor drawer; this widget is the read-only progress view
/// embedded in each request row.
class ApprovalStepper extends StatelessWidget {
  const ApprovalStepper({
    super.key,
    required this.policy,
    required this.request,
    this.compact = true,
  });

  final ApprovalPolicy policy;
  final Request request;

  /// `true` = single line with smaller dots (default). `false` = larger
  /// dots with two-line labels for the editor preview.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotSize = compact ? 14.0 : 22.0;
    final fontSize = compact ? 11.0 : 12.5;

    final isRejected = request.status == RequestStatus.rejected;
    final isApproved = request.status == RequestStatus.approved;

    final children = <Widget>[];
    for (int i = 0; i < policy.steps.length; i++) {
      final step = policy.steps[i];
      final state = _stateFor(step.order, isApproved, isRejected);
      if (i > 0) {
        children.add(Expanded(
          child: Container(
            height: 1,
            color: _connectorColor(state, theme),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ));
      }
      children.add(_StepDot(
        size: dotSize,
        state: state,
        index: step.order,
      ));
      children.add(const SizedBox(width: 4));
      children.add(Flexible(
        child: Text(
          step.name,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: fontSize,
            fontWeight: state == _StepState.current
                ? FontWeight.w700
                : FontWeight.w500,
            color: state == _StepState.upcoming
                ? theme.hintColor
                : theme.textTheme.bodyMedium?.color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  _StepState _stateFor(int stepOrder, bool isApproved, bool isRejected) {
    if (isApproved) return _StepState.done;
    if (isRejected) {
      if (stepOrder < request.currentStepOrder) return _StepState.done;
      if (stepOrder == request.currentStepOrder) return _StepState.rejected;
      return _StepState.upcoming;
    }
    if (stepOrder < request.currentStepOrder) return _StepState.done;
    if (stepOrder == request.currentStepOrder) return _StepState.current;
    return _StepState.upcoming;
  }

  Color _connectorColor(_StepState state, ThemeData theme) {
    switch (state) {
      case _StepState.done:
        return AppColors.statusSuccess.withValues(alpha: 0.5);
      case _StepState.current:
        return AppColors.brandPrimary.withValues(alpha: 0.5);
      case _StepState.rejected:
        return AppColors.statusDanger.withValues(alpha: 0.5);
      case _StepState.upcoming:
        return theme.dividerColor;
    }
  }
}

enum _StepState { done, current, rejected, upcoming }

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.size,
    required this.state,
    required this.index,
  });

  final double size;
  final _StepState state;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    late final Color bg;
    late final Color border;
    late final Widget child;

    switch (state) {
      case _StepState.done:
        bg = AppColors.statusSuccess;
        border = AppColors.statusSuccess;
        child = Icon(Icons.check, size: size * 0.65, color: Colors.white);
        break;
      case _StepState.current:
        bg = AppColors.brandPrimary;
        border = AppColors.brandPrimary;
        child = Text(
          '$index',
          style: TextStyle(
            fontSize: size * 0.55,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        );
        break;
      case _StepState.rejected:
        bg = AppColors.statusDanger;
        border = AppColors.statusDanger;
        child = Icon(Icons.close, size: size * 0.65, color: Colors.white);
        break;
      case _StepState.upcoming:
        bg = Colors.transparent;
        border = theme.dividerColor;
        child = Text(
          '$index',
          style: TextStyle(
            fontSize: size * 0.55,
            fontWeight: FontWeight.w600,
            color: theme.hintColor,
          ),
        );
        break;
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
      ),
      child: child,
    );
  }
}
