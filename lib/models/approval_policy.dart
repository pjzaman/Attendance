import 'request.dart';

/// One step in an approval pipeline. v1 stores just the step name —
/// approver identity is enforced at the UI layer once auth lands.
class ApprovalStep {
  const ApprovalStep({required this.order, required this.name});

  /// 1-based step ordering. Steps run sequentially.
  final int order;
  final String name;

  Map<String, Object?> toMap(String policyId) => <String, Object?>{
        'policy_id': policyId,
        'step_order': order,
        'name': name,
      };

  factory ApprovalStep.fromMap(Map<String, Object?> m) => ApprovalStep(
        order: (m['step_order'] as int?) ?? 0,
        name: m['name']! as String,
      );
}

/// Named multi-step approval pipeline tied to one [RequestType]. Per the
/// redesign doc, "named multi-step pipelines per request type, assigned
/// to a session, with a 'View Pipeline' visual editor."
class ApprovalPolicy {
  const ApprovalPolicy({
    required this.id,
    required this.name,
    required this.type,
    required this.steps,
    this.isActive = true,
  });

  final String id;
  final String name;
  final RequestType type;

  /// Ordered list of pipeline steps. Index 0 == step 1.
  final List<ApprovalStep> steps;

  /// Whether this policy is the active one for [type]. New requests of
  /// that type get this policy assigned automatically.
  final bool isActive;

  ApprovalPolicy copyWith({
    String? name,
    List<ApprovalStep>? steps,
    bool? isActive,
  }) =>
      ApprovalPolicy(
        id: id,
        name: name ?? this.name,
        type: type,
        steps: steps ?? this.steps,
        isActive: isActive ?? this.isActive,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'type': type.name,
        'is_active': isActive ? 1 : 0,
      };

  factory ApprovalPolicy.fromMap(
    Map<String, Object?> m, {
    List<ApprovalStep> steps = const <ApprovalStep>[],
  }) =>
      ApprovalPolicy(
        id: m['id']! as String,
        name: m['name']! as String,
        type: RequestType.values.firstWhere(
          (t) => t.name == m['type'],
          orElse: () => RequestType.attendance,
        ),
        steps: steps,
        isActive: ((m['is_active'] as int?) ?? 1) == 1,
      );

  /// Firestore form: steps are stored inline as an array (replaces the
  /// approval_steps child table from sqflite).
  Map<String, Object?> toFirestore() => <String, Object?>{
        ...toMap(),
        'steps': steps
            .map((s) => <String, Object?>{
                  'step_order': s.order,
                  'name': s.name,
                })
            .toList(),
      };

  factory ApprovalPolicy.fromFirestore(String docId, Map<String, Object?> m) {
    final raw = (m['steps'] as List?) ?? const <dynamic>[];
    final steps = raw
        .map((e) => ApprovalStep.fromMap(
              Map<String, Object?>.from(e as Map),
            ))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return ApprovalPolicy.fromMap(
      <String, Object?>{...m, 'id': docId},
      steps: steps,
    );
  }
}
