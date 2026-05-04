enum RequestType { attendance, leave, payslip, separation }

extension RequestTypeX on RequestType {
  String get label {
    switch (this) {
      case RequestType.attendance:
        return 'Attendance';
      case RequestType.leave:
        return 'Leave';
      case RequestType.payslip:
        return 'Payslip';
      case RequestType.separation:
        return 'Separation';
    }
  }
}

enum RequestStatus { pending, approved, rejected, cancelled }

extension RequestStatusX on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Single request type covering attendance / leave / payslip / separation.
/// Type-specific fields are all nullable; the screens read what's relevant
/// per type. Per the redesign doc, the four types share a common inbox so
/// approvers don't need to chase across screens.
class Request {
  Request({
    required this.id,
    required this.type,
    required this.requesterUserId,
    required this.fromDate,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.toDate,
    this.resolvedAt,
    this.resolverUserId,
    this.resolverNote,
    this.leaveType,
    this.shiftId,
    this.checkIn,
    this.checkOut,
    this.policyId,
    this.currentStepOrder = 0,
  });

  final String id;
  final RequestType type;
  final String requesterUserId;
  final DateTime fromDate;

  /// Inclusive end date for multi-day requests. Null = single day.
  final DateTime? toDate;
  final String reason;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolverUserId;
  final String? resolverNote;

  // ─── Type-specific (all nullable) ────────────────────────────────

  /// For [RequestType.leave].
  final String? leaveType;

  /// For [RequestType.attendance] — the shift the user wants the
  /// attendance correction applied to.
  final String? shiftId;

  /// For [RequestType.attendance] — proposed check-in / check-out
  /// timestamps (date portion equals [fromDate]).
  final DateTime? checkIn;
  final DateTime? checkOut;

  /// Approval pipeline assigned at creation time. `null` = legacy
  /// single-click approve / reject.
  final String? policyId;

  /// 1-based current step in the pipeline. `0` = not in any pipeline.
  /// Approving advances this; the request resolves when it exceeds the
  /// pipeline's last step.
  final int currentStepOrder;

  bool get isPending => status == RequestStatus.pending;
  bool get isResolved =>
      status == RequestStatus.approved || status == RequestStatus.rejected;

  Request copyWith({
    RequestStatus? status,
    DateTime? resolvedAt,
    String? resolverUserId,
    String? resolverNote,
    String? policyId,
    int? currentStepOrder,
  }) =>
      Request(
        id: id,
        type: type,
        requesterUserId: requesterUserId,
        fromDate: fromDate,
        toDate: toDate,
        reason: reason,
        status: status ?? this.status,
        createdAt: createdAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        resolverUserId: resolverUserId ?? this.resolverUserId,
        resolverNote: resolverNote ?? this.resolverNote,
        leaveType: leaveType,
        shiftId: shiftId,
        checkIn: checkIn,
        checkOut: checkOut,
        policyId: policyId ?? this.policyId,
        currentStepOrder: currentStepOrder ?? this.currentStepOrder,
      );

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'type': type.name,
        'requester_user_id': requesterUserId,
        'from_date': _dateOnly(fromDate),
        'to_date': toDate == null ? null : _dateOnly(toDate!),
        'reason': reason,
        'status': status.name,
        'created_at': createdAt.toUtc().toIso8601String(),
        'resolved_at': resolvedAt?.toUtc().toIso8601String(),
        'resolver_user_id': resolverUserId,
        'resolver_note': resolverNote,
        'leave_type': leaveType,
        'shift_id': shiftId,
        'check_in': checkIn?.toUtc().toIso8601String(),
        'check_out': checkOut?.toUtc().toIso8601String(),
        'policy_id': policyId,
        'current_step_order': currentStepOrder,
      };

  factory Request.fromMap(Map<String, Object?> m) => Request(
        id: m['id']! as String,
        type: RequestType.values.firstWhere(
          (t) => t.name == m['type'],
          orElse: () => RequestType.attendance,
        ),
        requesterUserId: m['requester_user_id']! as String,
        fromDate: DateTime.parse(m['from_date']! as String),
        toDate: m['to_date'] == null
            ? null
            : DateTime.parse(m['to_date']! as String),
        reason: (m['reason'] as String?) ?? '',
        status: RequestStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => RequestStatus.pending,
        ),
        createdAt: DateTime.parse(m['created_at']! as String).toLocal(),
        resolvedAt: m['resolved_at'] == null
            ? null
            : DateTime.parse(m['resolved_at']! as String).toLocal(),
        resolverUserId: m['resolver_user_id'] as String?,
        resolverNote: m['resolver_note'] as String?,
        leaveType: m['leave_type'] as String?,
        shiftId: m['shift_id'] as String?,
        checkIn: m['check_in'] == null
            ? null
            : DateTime.parse(m['check_in']! as String).toLocal(),
        checkOut: m['check_out'] == null
            ? null
            : DateTime.parse(m['check_out']! as String).toLocal(),
        policyId: m['policy_id'] as String?,
        currentStepOrder: (m['current_step_order'] as int?) ?? 0,
      );
}
