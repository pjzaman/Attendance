import 'request.dart';

/// A single approve/reject event recorded against a step in a pipeline.
/// Multiple decisions can exist per request — one per pipeline step the
/// request has progressed through, plus a final reject if any step
/// rejected.
class ApprovalDecision {
  ApprovalDecision({
    required this.id,
    required this.requestId,
    required this.stepOrder,
    required this.decision,
    required this.decidedAt,
    this.decidedByUserId,
    this.note,
  });

  final String id;
  final String requestId;

  /// Which step in the pipeline this decision was made at.
  final int stepOrder;

  /// Either [RequestStatus.approved] or [RequestStatus.rejected].
  final RequestStatus decision;
  final DateTime decidedAt;
  final String? decidedByUserId;
  final String? note;

  bool get isApproval => decision == RequestStatus.approved;
  bool get isRejection => decision == RequestStatus.rejected;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'request_id': requestId,
        'step_order': stepOrder,
        'decision': decision.name,
        'decided_at': decidedAt.toUtc().toIso8601String(),
        'decided_by_user_id': decidedByUserId,
        'note': note,
      };

  factory ApprovalDecision.fromMap(Map<String, Object?> m) => ApprovalDecision(
        id: m['id']! as String,
        requestId: m['request_id']! as String,
        stepOrder: (m['step_order'] as int?) ?? 0,
        decision: RequestStatus.values.firstWhere(
          (s) => s.name == m['decision'],
          orElse: () => RequestStatus.approved,
        ),
        decidedAt: DateTime.parse(m['decided_at']! as String).toLocal(),
        decidedByUserId: m['decided_by_user_id'] as String?,
        note: m['note'] as String?,
      );
}
