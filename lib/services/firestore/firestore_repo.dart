import 'package:firedart/firedart.dart' as fs;

import '../../models/app_user.dart';
import '../../models/approval_decision.dart';
import '../../models/approval_policy.dart';
import '../../models/device.dart';
import '../../models/employee.dart';
import '../../models/employee_child_records.dart';
import '../../models/employee_document.dart';
import '../../models/employee_group.dart';
import '../../models/employee_profile.dart';
import '../../models/employee_salary.dart';
import '../../models/holiday.dart';
import '../../models/leave_type.dart';
import '../../models/office_location.dart';
import '../../models/payslip.dart';
import '../../models/punch.dart';
import '../../models/request.dart';
import '../../models/role.dart';
import '../../models/salary_history_entry.dart';
import '../../models/schedule.dart';
import '../../models/session.dart';
import '../../models/shift.dart';
import '../../models/team.dart';
import '../../models/tracking_method.dart';

/// All Firestore reads and writes flow through this class so the
/// rest of the app never imports firedart directly.
///
/// Schema convention (Phase B-2):
///   - Field names use the existing snake_case from each model's
///     `toMap`/`fromMap`. Reusing those serializers means migrating
///     a collection is just adding ~3 methods here, no model
///     surgery — except for models with nested children (Schedule,
///     ApprovalPolicy) which expose a richer `toFirestore`.
///   - Doc IDs match the model's `id` field (or `userId` for the
///     handful of records keyed by employee).
///   - Booleans are still 0/1 ints to match sqflite. We can clean
///     this up in a future pass without breaking existing data.
///
/// Bridge-owned collections (`punches`, `bridges`, `bridge_commands`)
/// are written by the Python service in camelCase and only *read*
/// here.
class FirestoreRepo {
  FirestoreRepo._();

  static FirestoreRepo? _instance;

  static FirestoreRepo get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'FirestoreRepo not initialized — call FirestoreRepo.initialize() '
        'before reading from it.',
      );
    }
    return i;
  }

  static void initialize(String projectId) {
    fs.Firestore.initialize(projectId);
    _instance = FirestoreRepo._();
  }

  fs.Firestore get _db => fs.Firestore.instance;

  // ─── Employees ────────────────────────────────────────────────

  fs.CollectionReference get _employees => _db.collection('employees');

  Stream<List<Employee>> watchEmployees() => _employees.stream.map(
        (docs) =>
            docs.map((d) => Employee.fromFirestore(d.id, d.map)).toList(),
      );

  Future<void> upsertEmployee(Employee e) =>
      _employees.document(e.userId).set(e.toFirestore());

  Future<void> deleteEmployee(String userId) =>
      _employees.document(userId).delete();

  // ─── Shifts ───────────────────────────────────────────────────

  fs.CollectionReference get _shifts => _db.collection('shifts');

  Stream<List<Shift>> watchShifts() => _shifts.stream.map(
        (docs) => docs.map((d) => Shift.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertShift(Shift s) => _shifts.document(s.id).set(s.toMap());

  Future<void> deleteShift(String id) => _shifts.document(id).delete();

  // ─── Schedules ────────────────────────────────────────────────

  fs.CollectionReference get _schedules => _db.collection('schedules');

  Stream<List<Schedule>> watchSchedules() => _schedules.stream.map(
        (docs) =>
            docs.map((d) => Schedule.fromFirestore(d.id, d.map)).toList(),
      );

  Future<void> upsertSchedule(Schedule s) =>
      _schedules.document(s.id).set(s.toFirestore());

  Future<void> deleteSchedule(String id) => _schedules.document(id).delete();

  // ─── Requests ─────────────────────────────────────────────────

  fs.CollectionReference get _requests => _db.collection('requests');

  Stream<List<Request>> watchRequests() => _requests.stream.map(
        (docs) => docs.map((d) => Request.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertRequest(Request r) =>
      _requests.document(r.id).set(r.toMap());

  Future<void> deleteRequest(String id) => _requests.document(id).delete();

  // ─── Approval policies ────────────────────────────────────────

  fs.CollectionReference get _approvalPolicies =>
      _db.collection('approval_policies');

  Stream<List<ApprovalPolicy>> watchApprovalPolicies() =>
      _approvalPolicies.stream.map(
        (docs) => docs
            .map((d) => ApprovalPolicy.fromFirestore(d.id, d.map))
            .toList(),
      );

  Future<void> upsertApprovalPolicy(ApprovalPolicy p) =>
      _approvalPolicies.document(p.id).set(p.toFirestore());

  Future<void> deleteApprovalPolicy(String id) =>
      _approvalPolicies.document(id).delete();

  // ─── Approval decisions ───────────────────────────────────────

  fs.CollectionReference get _approvalDecisions =>
      _db.collection('approval_decisions');

  Stream<List<ApprovalDecision>> watchApprovalDecisions() =>
      _approvalDecisions.stream.map(
        (docs) =>
            docs.map((d) => ApprovalDecision.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertApprovalDecision(ApprovalDecision d) =>
      _approvalDecisions.document(d.id).set(d.toMap());

  // ─── Leave types ──────────────────────────────────────────────

  fs.CollectionReference get _leaveTypes => _db.collection('leave_types');

  Stream<List<LeaveType>> watchLeaveTypes() => _leaveTypes.stream.map(
        (docs) => docs.map((d) => LeaveType.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertLeaveType(LeaveType t) =>
      _leaveTypes.document(t.id).set(t.toMap());

  Future<void> deleteLeaveType(String id) => _leaveTypes.document(id).delete();

  // ─── Employee profiles ────────────────────────────────────────

  fs.CollectionReference get _employeeProfiles =>
      _db.collection('employee_profiles');

  Stream<List<EmployeeProfile>> watchEmployeeProfiles() =>
      _employeeProfiles.stream.map(
        (docs) =>
            docs.map((d) => EmployeeProfile.fromMap(_withId(d, 'user_id'))).toList(),
      );

  Future<void> upsertEmployeeProfile(EmployeeProfile p) =>
      _employeeProfiles.document(p.userId).set(p.toMap());

  Future<void> deleteEmployeeProfile(String userId) =>
      _employeeProfiles.document(userId).delete();

  // ─── Employee documents ───────────────────────────────────────

  fs.CollectionReference get _employeeDocuments =>
      _db.collection('employee_documents');

  Stream<List<EmployeeDocument>> watchEmployeeDocuments() =>
      _employeeDocuments.stream.map(
        (docs) =>
            docs.map((d) => EmployeeDocument.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertEmployeeDocument(EmployeeDocument d) =>
      _employeeDocuments.document(d.id).set(d.toMap());

  Future<void> deleteEmployeeDocument(String id) =>
      _employeeDocuments.document(id).delete();

  // ─── Sessions ─────────────────────────────────────────────────

  fs.CollectionReference get _sessions => _db.collection('sessions');

  Stream<List<Session>> watchSessions() => _sessions.stream.map(
        (docs) => docs.map((d) => Session.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertSession(Session s) =>
      _sessions.document(s.id).set(s.toMap());

  Future<void> deleteSession(String id) => _sessions.document(id).delete();

  // ─── Roles ────────────────────────────────────────────────────

  fs.CollectionReference get _roles => _db.collection('roles');

  Stream<List<Role>> watchRoles() => _roles.stream.map(
        (docs) => docs.map((d) => Role.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertRole(Role r) => _roles.document(r.id).set(r.toMap());

  Future<void> deleteRole(String id) => _roles.document(id).delete();

  // ─── App users ────────────────────────────────────────────────

  fs.CollectionReference get _appUsers => _db.collection('app_users');

  Stream<List<AppUser>> watchAppUsers() => _appUsers.stream.map(
        (docs) => docs.map((d) => AppUser.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertAppUser(AppUser u) =>
      _appUsers.document(u.id).set(u.toMap());

  Future<void> deleteAppUser(String id) => _appUsers.document(id).delete();

  // ─── Devices ──────────────────────────────────────────────────

  fs.CollectionReference get _devices => _db.collection('devices');

  Stream<List<Device>> watchDevices() => _devices.stream.map(
        (docs) => docs.map((d) => Device.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertDevice(Device d) =>
      _devices.document(d.id).set(d.toMap());

  Future<void> deleteDevice(String id) => _devices.document(id).delete();

  // ─── Holidays ─────────────────────────────────────────────────

  fs.CollectionReference get _holidays => _db.collection('holidays');

  Stream<List<Holiday>> watchHolidays() => _holidays.stream.map(
        (docs) => docs.map((d) => Holiday.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertHoliday(Holiday h) =>
      _holidays.document(h.id).set(h.toMap());

  Future<void> deleteHoliday(String id) => _holidays.document(id).delete();

  // ─── Office locations ─────────────────────────────────────────

  fs.CollectionReference get _officeLocations =>
      _db.collection('office_locations');

  Stream<List<OfficeLocation>> watchOfficeLocations() =>
      _officeLocations.stream.map(
        (docs) =>
            docs.map((d) => OfficeLocation.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertOfficeLocation(OfficeLocation l) =>
      _officeLocations.document(l.id).set(l.toMap());

  Future<void> deleteOfficeLocation(String id) =>
      _officeLocations.document(id).delete();

  // ─── Teams ────────────────────────────────────────────────────

  fs.CollectionReference get _teams => _db.collection('teams');

  Stream<List<Team>> watchTeams() => _teams.stream.map(
        (docs) => docs.map((d) => Team.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertTeam(Team t) => _teams.document(t.id).set(t.toMap());

  Future<void> deleteTeam(String id) => _teams.document(id).delete();

  // ─── Employee groups ──────────────────────────────────────────

  fs.CollectionReference get _employeeGroups =>
      _db.collection('employee_groups');

  Stream<List<EmployeeGroup>> watchEmployeeGroups() =>
      _employeeGroups.stream.map(
        (docs) => docs.map((d) => EmployeeGroup.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertEmployeeGroup(EmployeeGroup g) =>
      _employeeGroups.document(g.id).set(g.toMap());

  Future<void> deleteEmployeeGroup(String id) =>
      _employeeGroups.document(id).delete();

  // ─── Tracking methods ─────────────────────────────────────────

  fs.CollectionReference get _trackingMethods =>
      _db.collection('tracking_methods');

  Stream<List<TrackingMethod>> watchTrackingMethods() =>
      _trackingMethods.stream.map(
        (docs) =>
            docs.map((d) => TrackingMethod.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertTrackingMethod(TrackingMethod m) =>
      _trackingMethods.document(m.id).set(m.toMap());

  Future<void> deleteTrackingMethod(String id) =>
      _trackingMethods.document(id).delete();

  // ─── Employee salaries ────────────────────────────────────────

  fs.CollectionReference get _employeeSalaries =>
      _db.collection('employee_salaries');

  Stream<List<EmployeeSalary>> watchEmployeeSalaries() =>
      _employeeSalaries.stream.map(
        (docs) =>
            docs.map((d) => EmployeeSalary.fromMap(_withId(d, 'user_id'))).toList(),
      );

  Future<void> upsertEmployeeSalary(EmployeeSalary s) =>
      _employeeSalaries.document(s.userId).set(s.toMap());

  Future<void> deleteEmployeeSalary(String userId) =>
      _employeeSalaries.document(userId).delete();

  // ─── Payslips ─────────────────────────────────────────────────

  fs.CollectionReference get _payslips => _db.collection('payslips');

  Stream<List<Payslip>> watchPayslips() => _payslips.stream.map(
        (docs) => docs.map((d) => Payslip.fromMap(_withId(d))).toList(),
      );

  Future<void> upsertPayslip(Payslip p) =>
      _payslips.document(p.id).set(p.toMap());

  Future<void> deletePayslip(String id) => _payslips.document(id).delete();

  // ─── Salary history ───────────────────────────────────────────

  fs.CollectionReference get _salaryHistory =>
      _db.collection('salary_history');

  Future<List<SalaryHistoryEntry>> listSalaryHistory(String userId) async {
    final docs = await _salaryHistory.where('user_id', isEqualTo: userId).get();
    final entries =
        docs.map((d) => SalaryHistoryEntry.fromMap(_withId(d))).toList();
    entries.sort((a, b) => b.changedAt.compareTo(a.changedAt));
    return entries;
  }

  Future<void> upsertSalaryHistory(SalaryHistoryEntry e) =>
      _salaryHistory.document(e.id).set(e.toMap());

  // ─── Punches (read-only on the Flutter side; bridge writes) ──
  //
  // Bridge writes camelCase fields. We translate to the snake_case
  // shape the existing Punch.fromMap expects.

  fs.CollectionReference get _punches => _db.collection('punches');

  Stream<List<Punch>> watchPunches({int limit = 500}) =>
      _punches.stream.map((docs) {
        final list = docs.map(_punchFromDoc).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        if (list.length > limit) return list.sublist(0, limit);
        return list;
      });

  /// One-shot fetch of every punch in a calendar month, optionally
  /// filtered to a single employee. Used by the monthly exporter and
  /// the per-employee attendance screen — the live `watchPunches`
  /// stream's 500-row cap may not cover the period.
  Future<List<Punch>> fetchPunchesForMonth(
    DateTime month, {
    String? userId,
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final List<fs.Document> docs = userId == null
        ? await _punches.get()
        : await _punches.where('userId', isEqualTo: userId).get();
    return docs
        .map(_punchFromDoc)
        .where((p) =>
            !p.timestamp.isBefore(start) && p.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static Punch _punchFromDoc(fs.Document d) =>
      Punch.fromMap(<String, Object?>{
        'user_id': d.map['userId'],
        'timestamp': d.map['timestamp'] is String
            ? d.map['timestamp']
            : (d.map['timestamp'] as DateTime?)?.toIso8601String(),
        'raw_status': d.map['rawStatus'],
        'raw_punch': d.map['rawPunch'],
      });

  // ─── Bridges (heartbeat) ──────────────────────────────────────

  fs.CollectionReference get _bridges => _db.collection('bridges');

  Stream<List<Map<String, Object?>>> watchBridges() =>
      _bridges.stream.map((docs) => docs
          .map((d) => <String, Object?>{...d.map, 'bridgeId': d.id})
          .toList());

  // ─── Bridge commands (Flutter writes; bridge consumes) ───────

  fs.CollectionReference get _bridgeCommands =>
      _db.collection('bridge_commands');

  /// Drops a command into the queue. The bridge subscribes with
  /// where('status', '==', 'pending'), executes, and writes back the
  /// result. Returns the doc id so callers can poll status if they
  /// want.
  Future<String> queueBridgeCommand({
    required String bridgeId,
    required String action,
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    final id = 'cmd_${DateTime.now().microsecondsSinceEpoch}';
    await _bridgeCommands.document(id).set(<String, Object?>{
      'bridgeId': bridgeId,
      'action': action,
      'params': params,
      'status': 'pending',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    return id;
  }

  // ─── User prefs (per Firebase Auth uid) ──────────────────────

  fs.CollectionReference get _userPrefs => _db.collection('user_prefs');

  Stream<Map<String, Object?>> watchUserPrefs(String firebaseUid) =>
      _userPrefs.document(firebaseUid).stream
          .map((d) => d == null ? const <String, Object?>{} : d.map);

  Future<void> setUserPrefs(
    String firebaseUid,
    Map<String, Object?> prefs,
  ) =>
      _userPrefs.document(firebaseUid).set(prefs);

  // ─── Employee child records ───────────────────────────────────
  //
  // Stored as top-level collections (not subcollections) with a
  // user_id field, matching how SalaryHistory works. Queried
  // per-employee on demand.

  Future<List<FamilyMember>> listFamilyMembers(String userId) =>
      _listChildRecords('family_members', userId, FamilyMember.fromMap);
  Future<void> upsertFamilyMember(FamilyMember m) =>
      _db.collection('family_members').document(m.id).set(m.toMap());
  Future<void> deleteFamilyMember(String id) =>
      _db.collection('family_members').document(id).delete();

  Future<List<EducationEntry>> listEducationEntries(String userId) =>
      _listChildRecords(
        'education_entries',
        userId,
        EducationEntry.fromMap,
      );
  Future<void> upsertEducationEntry(EducationEntry e) =>
      _db.collection('education_entries').document(e.id).set(e.toMap());
  Future<void> deleteEducationEntry(String id) =>
      _db.collection('education_entries').document(id).delete();

  Future<List<TrainingEntry>> listTrainingEntries(String userId) =>
      _listChildRecords(
        'training_entries',
        userId,
        TrainingEntry.fromMap,
      );
  Future<void> upsertTrainingEntry(TrainingEntry e) =>
      _db.collection('training_entries').document(e.id).set(e.toMap());
  Future<void> deleteTrainingEntry(String id) =>
      _db.collection('training_entries').document(id).delete();

  Future<List<EmploymentHistoryEntry>> listEmploymentHistory(String userId) =>
      _listChildRecords(
        'employment_histories',
        userId,
        EmploymentHistoryEntry.fromMap,
      );
  Future<void> upsertEmploymentHistoryEntry(EmploymentHistoryEntry e) => _db
      .collection('employment_histories')
      .document(e.id)
      .set(e.toMap());
  Future<void> deleteEmploymentHistoryEntry(String id) =>
      _db.collection('employment_histories').document(id).delete();

  Future<List<DisciplinaryAction>> listDisciplinaryActions(String userId) =>
      _listChildRecords(
        'disciplinary_actions',
        userId,
        DisciplinaryAction.fromMap,
      );
  Future<void> upsertDisciplinaryAction(DisciplinaryAction a) => _db
      .collection('disciplinary_actions')
      .document(a.id)
      .set(a.toMap());
  Future<void> deleteDisciplinaryAction(String id) =>
      _db.collection('disciplinary_actions').document(id).delete();

  Future<List<Achievement>> listAchievements(String userId) =>
      _listChildRecords('achievements', userId, Achievement.fromMap);
  Future<void> upsertAchievement(Achievement a) =>
      _db.collection('achievements').document(a.id).set(a.toMap());
  Future<void> deleteAchievement(String id) =>
      _db.collection('achievements').document(id).delete();

  Future<List<EmployeeAddress>> listEmployeeAddresses(String userId) =>
      _listChildRecords(
        'employee_addresses',
        userId,
        EmployeeAddress.fromMap,
      );
  Future<void> upsertEmployeeAddress(EmployeeAddress a) =>
      _db.collection('employee_addresses').document(a.id).set(a.toMap());
  Future<void> deleteEmployeeAddress(String id) =>
      _db.collection('employee_addresses').document(id).delete();

  Future<List<T>> _listChildRecords<T>(
    String collection,
    String userId,
    T Function(Map<String, Object?>) fromMap,
  ) async {
    final docs = await _db
        .collection(collection)
        .where('user_id', isEqualTo: userId)
        .get();
    return docs.map((d) => fromMap(_withId(d))).toList();
  }

  // ─── Helpers ──────────────────────────────────────────────────

  /// Firestore docs don't carry `id` inside the data map; the
  /// existing fromMap implementations expect it under the field name
  /// they used in sqflite. This shim merges the doc id into the map.
  Map<String, Object?> _withId(fs.Document d, [String key = 'id']) =>
      <String, Object?>{...d.map, key: d.id};
}
