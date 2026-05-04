import '../models/approval_policy.dart';
import '../models/request.dart';

/// Default approval policies seeded on first launch — one per request
/// type. The Settings → Approvals screen lets users edit / replace them
/// later.
class ApprovalSeed {
  static List<ApprovalPolicy> defaultPolicies() => <ApprovalPolicy>[
        const ApprovalPolicy(
          id: 'pol_default_attendance',
          name: 'Default Attendance Policy',
          type: RequestType.attendance,
          steps: <ApprovalStep>[
            ApprovalStep(order: 1, name: 'Line Manager'),
            ApprovalStep(order: 2, name: 'HR'),
          ],
        ),
        const ApprovalPolicy(
          id: 'pol_default_leave',
          name: 'Default Leave Policy',
          type: RequestType.leave,
          steps: <ApprovalStep>[
            ApprovalStep(order: 1, name: 'Line Manager'),
            ApprovalStep(order: 2, name: 'HR'),
          ],
        ),
        const ApprovalPolicy(
          id: 'pol_default_payslip',
          name: 'Default Payslip Policy',
          type: RequestType.payslip,
          steps: <ApprovalStep>[
            ApprovalStep(order: 1, name: 'Accounting'),
          ],
        ),
        const ApprovalPolicy(
          id: 'pol_default_separation',
          name: 'Default Separation Policy',
          type: RequestType.separation,
          steps: <ApprovalStep>[
            ApprovalStep(order: 1, name: 'Line Manager'),
            ApprovalStep(order: 2, name: 'HR'),
            ApprovalStep(order: 3, name: 'Director'),
          ],
        ),
      ];
}
