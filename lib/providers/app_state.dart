// Single source of truth for the UI. Reads come from Firestore via
// snapshot subscriptions; writes go directly to Firestore. The
// listener fires on every write and notifyListeners() rebuilds
// dependent screens — no manual cache invalidation, no local DB.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;

import '../models/app_user.dart';
import '../models/approval_decision.dart';
import '../models/approval_policy.dart';
import '../models/daily_summary.dart';
import '../models/device.dart';
import '../models/employee.dart';
import '../models/employee_child_records.dart';
import '../models/employee_document.dart';
import '../models/employee_group.dart';
import '../models/employee_profile.dart';
import '../models/employee_salary.dart';
import '../models/holiday.dart';
import '../models/leave_type.dart';
import '../models/office_location.dart';
import '../models/payslip.dart';
import '../models/punch.dart';
import '../models/request.dart';
import '../models/role.dart';
import '../models/salary_history_entry.dart';
import '../models/schedule.dart';
import '../models/session.dart';
import '../models/shift.dart';
import '../models/team.dart';
import '../models/tracking_method.dart';
import '../services/approval_seed.dart';
import '../services/device_seed.dart';
import '../services/employee_group_seed.dart';
import '../services/export_service.dart';
import '../services/firestore/firestore_repo.dart';
import '../services/holiday_seed.dart';
import '../services/leave_type_seed.dart';
import '../services/office_location_seed.dart';
import '../services/role_seed.dart';
import '../services/schedule_seed.dart';
import '../services/session_seed.dart';
import '../services/team_seed.dart';
import '../services/tracking_method_seed.dart';

class AppState extends ChangeNotifier {
  AppState({FirestoreRepo? repo})
      : _repo = repo ?? FirestoreRepo.instance;

  final FirestoreRepo _repo;
  final ExportService _export = ExportService();

  // ─── Live Firestore subscriptions ──────────────────────────────
  StreamSubscription<List<Employee>>? _employeesSub;
  StreamSubscription<List<Shift>>? _shiftsSub;
  StreamSubscription<List<Schedule>>? _schedulesSub;
  StreamSubscription<List<Request>>? _requestsSub;
  StreamSubscription<List<ApprovalPolicy>>? _approvalPoliciesSub;
  StreamSubscription<List<ApprovalDecision>>? _approvalDecisionsSub;
  StreamSubscription<List<LeaveType>>? _leaveTypesSub;
  StreamSubscription<List<EmployeeProfile>>? _profilesSub;
  StreamSubscription<List<EmployeeDocument>>? _employeeDocumentsSub;
  StreamSubscription<List<Session>>? _sessionsSub;
  StreamSubscription<List<Role>>? _rolesSub;
  StreamSubscription<List<AppUser>>? _appUsersSub;
  StreamSubscription<List<Device>>? _devicesSub;
  StreamSubscription<List<Holiday>>? _holidaysSub;
  StreamSubscription<List<OfficeLocation>>? _officeLocationsSub;
  StreamSubscription<List<Team>>? _teamsSub;
  StreamSubscription<List<EmployeeGroup>>? _employeeGroupsSub;
  StreamSubscription<List<TrackingMethod>>? _trackingMethodsSub;
  StreamSubscription<List<EmployeeSalary>>? _employeeSalariesSub;
  StreamSubscription<List<Payslip>>? _payslipsSub;
  StreamSubscription<List<Punch>>? _punchesSub;
  StreamSubscription<List<Map<String, Object?>>>? _bridgesSub;
  StreamSubscription<Map<String, Object?>>? _userPrefsSub;

  // ─── Cached snapshots of Firestore data ───────────────────────
  List<Employee> _employees = <Employee>[];
  List<Punch> _recentPunches = <Punch>[];
  List<DailySummary> _daily = <DailySummary>[];
  List<Shift> _shifts = <Shift>[];
  List<Schedule> _schedules = <Schedule>[];
  List<Request> _requests = <Request>[];
  List<ApprovalPolicy> _approvalPolicies = <ApprovalPolicy>[];
  List<ApprovalDecision> _approvalDecisions = <ApprovalDecision>[];
  List<LeaveType> _leaveTypes = <LeaveType>[];
  Map<String, EmployeeProfile> _profiles = <String, EmployeeProfile>{};
  List<EmployeeDocument> _employeeDocuments = <EmployeeDocument>[];
  List<Session> _sessions = <Session>[];
  List<Role> _roles = <Role>[];
  List<AppUser> _appUsers = <AppUser>[];
  List<Device> _devices = <Device>[];
  List<Holiday> _holidays = <Holiday>[];
  List<OfficeLocation> _officeLocations = <OfficeLocation>[];
  List<Team> _teams = <Team>[];
  List<EmployeeGroup> _employeeGroups = <EmployeeGroup>[];
  List<TrackingMethod> _trackingMethods = <TrackingMethod>[];
  Set<String> _starredReports = <String>{};
  Map<String, Set<String>> _reportHiddenColumns = <String, Set<String>>{};
  Map<String, EmployeeSalary> _salaries = <String, EmployeeSalary>{};
  List<Payslip> _payslips = <Payslip>[];
  List<Map<String, Object?>> _bridges = <Map<String, Object?>>[];

  /// Firebase Auth UID of the signed-in user. Set by AuthGate so
  /// AppState can subscribe to user_prefs/{uid}.
  String? _firebaseUid;
  void setFirebaseUid(String? uid) {
    _firebaseUid = uid;
  }

  // ─── Public getters ───────────────────────────────────────────
  List<Employee> get employees => _employees;
  List<Punch> get recentPunches => _recentPunches;
  int get totalPunches => _recentPunches.length;
  List<DailySummary> get daily => _daily;
  List<Shift> get shifts => _shifts;
  List<Schedule> get schedules => _schedules;
  List<Request> get requests => _requests;
  List<ApprovalPolicy> get approvalPolicies => _approvalPolicies;
  List<ApprovalDecision> get approvalDecisions => _approvalDecisions;
  List<LeaveType> get leaveTypes => _leaveTypes;
  List<LeaveType> get activeLeaveTypes =>
      _leaveTypes.where((t) => t.isActive).toList();
  Map<String, EmployeeProfile> get employeeProfiles => _profiles;
  List<EmployeeDocument> get employeeDocuments => _employeeDocuments;
  List<Session> get sessions => _sessions;
  List<Role> get roles => _roles;
  List<AppUser> get appUsers => _appUsers;
  List<Device> get devices => _devices;
  List<Holiday> get holidays => _holidays;
  List<OfficeLocation> get officeLocations => _officeLocations;
  List<OfficeLocation> get activeOfficeLocations =>
      _officeLocations.where((l) => l.isActive).toList();
  List<Team> get teams => _teams;
  List<Team> get activeTeams => _teams.where((t) => t.isActive).toList();
  List<EmployeeGroup> get employeeGroups => _employeeGroups;
  List<EmployeeGroup> get activeEmployeeGroups =>
      _employeeGroups.where((g) => g.isActive).toList();
  List<TrackingMethod> get trackingMethods => _trackingMethods;
  Set<String> get starredReports => _starredReports;
  Map<String, Set<String>> get reportHiddenColumns => _reportHiddenColumns;
  Map<String, EmployeeSalary> get employeeSalaries => _salaries;
  List<Payslip> get payslips => _payslips;
  List<Map<String, Object?>> get bridges => _bridges;
  String? get firebaseUid => _firebaseUid;
  ExportService get exportService => _export;

  /// The first active device. UI uses this for "primary" labels.
  Device? get primaryDevice {
    for (final d in _devices) {
      if (d.isActive) return d;
    }
    return _devices.isEmpty ? null : _devices.first;
  }

  /// The "primary" bridge — the first one we know about. Convenience
  /// for screens that just want a single bridge to talk to (most
  /// installations only run one).
  Map<String, Object?>? get primaryBridge =>
      _bridges.isEmpty ? null : _bridges.first;

  /// Most recent successful sync time across all bridges (max of
  /// `lastSyncAt`). Replaces the old SyncService-driven `lastSync`.
  DateTime? get lastBridgeSync {
    DateTime? best;
    for (final b in _bridges) {
      final t = b['lastSyncAt'];
      DateTime? parsed;
      if (t is DateTime) {
        parsed = t.toLocal();
      } else if (t is String) {
        parsed = DateTime.tryParse(t)?.toLocal();
      }
      if (parsed != null && (best == null || parsed.isAfter(best))) {
        best = parsed;
      }
    }
    return best;
  }

  EmployeeSalary salaryFor(String userId) =>
      _salaries[userId] ?? EmployeeSalary.empty(userId);

  List<Payslip> payslipsFor(String userId) =>
      _payslips.where((p) => p.userId == userId).toList();

  Set<String> hiddenColumnsFor(String reportId) =>
      _reportHiddenColumns[reportId] ?? const <String>{};

  Holiday? upcomingHoliday({DateTime? from}) {
    final start = DateUtils.dateOnly(from ?? DateTime.now());
    Holiday? best;
    for (final h in _holidays) {
      final d = DateUtils.dateOnly(h.date);
      if (d.isBefore(start)) continue;
      if (best == null || d.isBefore(DateUtils.dateOnly(best.date))) {
        best = h;
      }
    }
    return best;
  }

  Role? roleById(String id) {
    for (final r in _roles) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<Session> sessionsOf(SessionType type) =>
      _sessions.where((s) => s.type == type).toList();

  Session? activeSessionOf(SessionType type) {
    for (final s in _sessions) {
      if (s.type == type && s.isActive) return s;
    }
    return null;
  }

  EmployeeProfile profileFor(String userId) =>
      _profiles[userId] ?? EmployeeProfile.empty(userId);

  List<EmployeeDocument> documentsFor(String userId) =>
      _employeeDocuments.where((d) => d.userId == userId).toList();

  ApprovalPolicy? activePolicyFor(RequestType type) {
    for (final p in _approvalPolicies) {
      if (p.type == type && p.isActive) return p;
    }
    return null;
  }

  List<ApprovalDecision> decisionsFor(String requestId) =>
      _approvalDecisions.where((d) => d.requestId == requestId).toList();

  /// Drop a command into bridge_commands/{id}. The bridge picks it
  /// up via its snapshot listener and writes back the result.
  Future<String> queueBridgeCommand({
    required String bridgeId,
    required String action,
    Map<String, Object?> params = const <String, Object?>{},
  }) =>
      _repo.queueBridgeCommand(
        bridgeId: bridgeId,
        action: action,
        params: params,
      );

  // ─── Bootstrap ───────────────────────────────────────────────

  Future<void> bootstrap() async {
    await _attachFirestoreListeners();
    await _seedDevicesIfEmpty();
    await _seedRolesIfEmpty();
    await _seedSessionsIfEmpty();
    await _seedApprovalPoliciesIfEmpty();
    await _seedLeaveTypesIfEmpty();
    await _seedHolidaysIfEmpty();
    await _seedOfficeLocationsIfEmpty();
    await _seedTeamsIfEmpty();
    await _seedEmployeeGroupsIfEmpty();
    await _seedTrackingMethodsIfEmpty();
    await _seedSchedulesIfEmpty();
    notifyListeners();
  }

  Future<void> _attachFirestoreListeners() async {
    final waiters = <Future<void>>[];

    waiters.add(_subscribe<Employee>(
      stream: _repo.watchEmployees(),
      assign: (list) => _employees = list,
      attachTo: (sub) => _employeesSub = sub,
    ));
    waiters.add(_subscribe<Shift>(
      stream: _repo.watchShifts(),
      assign: (list) => _shifts = list,
      attachTo: (sub) => _shiftsSub = sub,
    ));
    waiters.add(_subscribe<Schedule>(
      stream: _repo.watchSchedules(),
      assign: (list) => _schedules = list,
      attachTo: (sub) => _schedulesSub = sub,
    ));
    waiters.add(_subscribe<Request>(
      stream: _repo.watchRequests(),
      assign: (list) => _requests = list,
      attachTo: (sub) => _requestsSub = sub,
    ));
    waiters.add(_subscribe<ApprovalPolicy>(
      stream: _repo.watchApprovalPolicies(),
      assign: (list) => _approvalPolicies = list,
      attachTo: (sub) => _approvalPoliciesSub = sub,
    ));
    waiters.add(_subscribe<ApprovalDecision>(
      stream: _repo.watchApprovalDecisions(),
      assign: (list) => _approvalDecisions = list,
      attachTo: (sub) => _approvalDecisionsSub = sub,
    ));
    waiters.add(_subscribe<LeaveType>(
      stream: _repo.watchLeaveTypes(),
      assign: (list) => _leaveTypes = list,
      attachTo: (sub) => _leaveTypesSub = sub,
    ));
    waiters.add(_subscribe<EmployeeProfile>(
      stream: _repo.watchEmployeeProfiles(),
      assign: (list) => _profiles = <String, EmployeeProfile>{
        for (final p in list) p.userId: p,
      },
      attachTo: (sub) => _profilesSub = sub,
    ));
    waiters.add(_subscribe<EmployeeDocument>(
      stream: _repo.watchEmployeeDocuments(),
      assign: (list) => _employeeDocuments = list,
      attachTo: (sub) => _employeeDocumentsSub = sub,
    ));
    waiters.add(_subscribe<Session>(
      stream: _repo.watchSessions(),
      assign: (list) => _sessions = list,
      attachTo: (sub) => _sessionsSub = sub,
    ));
    waiters.add(_subscribe<Role>(
      stream: _repo.watchRoles(),
      assign: (list) => _roles = list,
      attachTo: (sub) => _rolesSub = sub,
    ));
    waiters.add(_subscribe<AppUser>(
      stream: _repo.watchAppUsers(),
      assign: (list) => _appUsers = list,
      attachTo: (sub) => _appUsersSub = sub,
    ));
    waiters.add(_subscribe<Device>(
      stream: _repo.watchDevices(),
      assign: (list) => _devices = list,
      attachTo: (sub) => _devicesSub = sub,
    ));
    waiters.add(_subscribe<Holiday>(
      stream: _repo.watchHolidays(),
      assign: (list) => _holidays = list,
      attachTo: (sub) => _holidaysSub = sub,
    ));
    waiters.add(_subscribe<OfficeLocation>(
      stream: _repo.watchOfficeLocations(),
      assign: (list) => _officeLocations = list,
      attachTo: (sub) => _officeLocationsSub = sub,
    ));
    waiters.add(_subscribe<Team>(
      stream: _repo.watchTeams(),
      assign: (list) => _teams = list,
      attachTo: (sub) => _teamsSub = sub,
    ));
    waiters.add(_subscribe<EmployeeGroup>(
      stream: _repo.watchEmployeeGroups(),
      assign: (list) => _employeeGroups = list,
      attachTo: (sub) => _employeeGroupsSub = sub,
    ));
    waiters.add(_subscribe<TrackingMethod>(
      stream: _repo.watchTrackingMethods(),
      assign: (list) => _trackingMethods = list,
      attachTo: (sub) => _trackingMethodsSub = sub,
    ));
    waiters.add(_subscribe<EmployeeSalary>(
      stream: _repo.watchEmployeeSalaries(),
      assign: (list) => _salaries = <String, EmployeeSalary>{
        for (final s in list) s.userId: s,
      },
      attachTo: (sub) => _employeeSalariesSub = sub,
    ));
    waiters.add(_subscribe<Payslip>(
      stream: _repo.watchPayslips(),
      assign: (list) => _payslips = list,
      attachTo: (sub) => _payslipsSub = sub,
    ));
    waiters.add(_subscribe<Punch>(
      stream: _repo.watchPunches(),
      assign: (list) {
        _recentPunches = list;
        _daily = _deriveDailyFromPunches(list);
      },
      attachTo: (sub) => _punchesSub = sub,
    ));
    waiters.add(_subscribe<Map<String, Object?>>(
      stream: _repo.watchBridges(),
      assign: (list) => _bridges = list,
      attachTo: (sub) => _bridgesSub = sub,
    ));

    final uid = _firebaseUid;
    if (uid != null) {
      final firstPrefs = Completer<void>();
      _userPrefsSub = _repo.watchUserPrefs(uid).listen(
        (m) {
          final stars = (m['starred_reports'] as List?)?.cast<String>() ??
              const <String>[];
          _starredReports = stars.toSet();
          final hidden = m['report_hidden_columns'];
          if (hidden is Map) {
            _reportHiddenColumns = <String, Set<String>>{
              for (final e in hidden.entries)
                e.key as String: (e.value as List).cast<String>().toSet(),
            };
          } else {
            _reportHiddenColumns = <String, Set<String>>{};
          }
          if (!firstPrefs.isCompleted) firstPrefs.complete();
          notifyListeners();
        },
        onError: (Object e, StackTrace st) {
          if (!firstPrefs.isCompleted) firstPrefs.completeError(e, st);
        },
      );
      waiters.add(firstPrefs.future);
    }

    try {
      await Future.wait(waiters).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('AppState: Firestore did not deliver all initial '
          'snapshots in time. Listeners stay attached. $e');
    }
  }

  Future<void> _subscribe<T>({
    required Stream<List<T>> stream,
    required void Function(List<T>) assign,
    required void Function(StreamSubscription<List<T>>) attachTo,
  }) {
    final firstSnap = Completer<void>();
    final sub = stream.listen(
      (list) {
        assign(list);
        if (!firstSnap.isCompleted) firstSnap.complete();
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        if (!firstSnap.isCompleted) firstSnap.completeError(e, st);
      },
    );
    attachTo(sub);
    return firstSnap.future;
  }

  @override
  void dispose() {
    _employeesSub?.cancel();
    _shiftsSub?.cancel();
    _schedulesSub?.cancel();
    _requestsSub?.cancel();
    _approvalPoliciesSub?.cancel();
    _approvalDecisionsSub?.cancel();
    _leaveTypesSub?.cancel();
    _profilesSub?.cancel();
    _employeeDocumentsSub?.cancel();
    _sessionsSub?.cancel();
    _rolesSub?.cancel();
    _appUsersSub?.cancel();
    _devicesSub?.cancel();
    _holidaysSub?.cancel();
    _officeLocationsSub?.cancel();
    _teamsSub?.cancel();
    _employeeGroupsSub?.cancel();
    _trackingMethodsSub?.cancel();
    _employeeSalariesSub?.cancel();
    _payslipsSub?.cancel();
    _punchesSub?.cancel();
    _bridgesSub?.cancel();
    _userPrefsSub?.cancel();
    super.dispose();
  }

  // ─── Seeders (first-launch defaults) ─────────────────────────
  // Each seeder runs once per Firestore project: it bails if the
  // corresponding collection already has entries (locally cached
  // by the Firestore subscription, which has just delivered its
  // first snapshot).

  Future<void> _seedTrackingMethodsIfEmpty() async {
    if (_trackingMethods.isNotEmpty) return;
    for (final m in TrackingMethodSeed.defaults()) {
      await _repo.upsertTrackingMethod(m);
    }
  }

  Future<void> _seedOfficeLocationsIfEmpty() async {
    if (_officeLocations.isNotEmpty) return;
    for (final l in OfficeLocationSeed.defaults()) {
      await _repo.upsertOfficeLocation(l);
    }
  }

  Future<void> _seedTeamsIfEmpty() async {
    if (_teams.isNotEmpty) return;
    for (final t in TeamSeed.defaults()) {
      await _repo.upsertTeam(t);
    }
  }

  Future<void> _seedEmployeeGroupsIfEmpty() async {
    if (_employeeGroups.isNotEmpty) return;
    for (final g in EmployeeGroupSeed.defaults()) {
      await _repo.upsertEmployeeGroup(g);
    }
  }

  Future<void> _seedDevicesIfEmpty() async {
    if (_devices.isNotEmpty) return;
    await _repo.upsertDevice(DeviceSeed.defaultDevice());
  }

  Future<void> _seedHolidaysIfEmpty() async {
    if (_holidays.isNotEmpty) return;
    for (final h in HolidaySeed.defaults()) {
      await _repo.upsertHoliday(h);
    }
  }

  Future<void> _seedRolesIfEmpty() async {
    if (_roles.isNotEmpty) return;
    for (final r in RoleSeed.defaults()) {
      await _repo.upsertRole(r);
    }
  }

  Future<void> _seedSessionsIfEmpty() async {
    if (_sessions.isNotEmpty) return;
    for (final s in SessionSeed.defaults()) {
      await _repo.upsertSession(s);
    }
  }

  Future<void> _seedApprovalPoliciesIfEmpty() async {
    if (_approvalPolicies.isNotEmpty) return;
    for (final p in ApprovalSeed.defaultPolicies()) {
      await _repo.upsertApprovalPolicy(p);
    }
  }

  Future<void> _seedLeaveTypesIfEmpty() async {
    if (_leaveTypes.isNotEmpty) return;
    for (final t in LeaveTypeSeed.defaults()) {
      await _repo.upsertLeaveType(t);
    }
  }

  Future<void> _seedSchedulesIfEmpty() async {
    if (_employees.isEmpty) return;
    if (_shifts.isNotEmpty) return;
    for (final s in ScheduleSeed.shifts()) {
      await _repo.upsertShift(s);
    }
    for (final s in ScheduleSeed.schedulesFor(_employees)) {
      await _repo.upsertSchedule(s);
    }
  }

  // ─── Writes (Firestore-only) ──────────────────────────────────
  // No local refresh needed — the snapshot listener reassigns local
  // state and calls notifyListeners() within ~100ms.

  Future<void> upsertShift(Shift shift) => _repo.upsertShift(shift);
  Future<void> deleteShift(String id) => _repo.deleteShift(id);

  Future<void> upsertSchedule(Schedule schedule) =>
      _repo.upsertSchedule(schedule);
  Future<void> deleteSchedule(String id) => _repo.deleteSchedule(id);

  Future<void> publishAllDrafts() async {
    for (final s in _schedules.where((s) => s.isDraft)) {
      await _repo.upsertSchedule(s.copyWith(status: ScheduleStatus.published));
    }
  }

  /// Persist a request. Auto-attaches the active policy for its type
  /// and starts the pipeline at step 1 if none was set.
  Future<void> upsertRequest(Request request) async {
    Request toSave = request;
    if (toSave.policyId == null) {
      final policy = activePolicyFor(toSave.type);
      if (policy != null && policy.steps.isNotEmpty) {
        toSave = toSave.copyWith(
          policyId: policy.id,
          currentStepOrder: 1,
        );
      }
    }
    await _repo.upsertRequest(toSave);
  }

  Future<void> approveCurrentStep(
    String requestId, {
    String? note,
    String? userId,
  }) async {
    final req = _requests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => throw StateError('Request $requestId not found'),
    );
    if (!req.isPending) return;

    final policy = req.policyId == null
        ? null
        : _approvalPolicies.firstWhere(
            (p) => p.id == req.policyId,
            orElse: () =>
                throw StateError('Policy ${req.policyId} not found'),
          );

    if (policy == null || policy.steps.isEmpty) {
      await _repo.upsertRequest(req.copyWith(
        status: RequestStatus.approved,
        resolvedAt: DateTime.now(),
        resolverUserId: userId,
        resolverNote: note,
      ));
      return;
    }

    await _repo.upsertApprovalDecision(ApprovalDecision(
      id: 'dec_${DateTime.now().microsecondsSinceEpoch}',
      requestId: req.id,
      stepOrder: req.currentStepOrder,
      decision: RequestStatus.approved,
      decidedAt: DateTime.now(),
      decidedByUserId: userId,
      note: note,
    ));

    final isLast = req.currentStepOrder >= policy.steps.length;
    await _repo.upsertRequest(isLast
        ? req.copyWith(
            status: RequestStatus.approved,
            resolvedAt: DateTime.now(),
            resolverUserId: userId,
            resolverNote: note,
          )
        : req.copyWith(currentStepOrder: req.currentStepOrder + 1));
  }

  Future<void> rejectAtCurrentStep(
    String requestId, {
    String? note,
    String? userId,
  }) async {
    final req = _requests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => throw StateError('Request $requestId not found'),
    );
    if (!req.isPending) return;

    if (req.policyId != null) {
      await _repo.upsertApprovalDecision(ApprovalDecision(
        id: 'dec_${DateTime.now().microsecondsSinceEpoch}',
        requestId: req.id,
        stepOrder: req.currentStepOrder,
        decision: RequestStatus.rejected,
        decidedAt: DateTime.now(),
        decidedByUserId: userId,
        note: note,
      ));
    }

    await _repo.upsertRequest(req.copyWith(
      status: RequestStatus.rejected,
      resolvedAt: DateTime.now(),
      resolverUserId: userId,
      resolverNote: note,
    ));
  }

  Future<void> deleteRequest(String id) => _repo.deleteRequest(id);

  Future<void> upsertApprovalPolicy(ApprovalPolicy policy) =>
      _repo.upsertApprovalPolicy(policy);
  Future<void> deleteApprovalPolicy(String id) =>
      _repo.deleteApprovalPolicy(id);

  Future<void> upsertLeaveType(LeaveType type) =>
      _repo.upsertLeaveType(type);
  Future<void> deleteLeaveType(String id) => _repo.deleteLeaveType(id);

  Future<void> upsertEmployeeProfile(EmployeeProfile profile) =>
      _repo.upsertEmployeeProfile(profile.copyWith(updatedAt: DateTime.now()));

  Future<void> upsertEmployeeDocument(EmployeeDocument doc) =>
      _repo.upsertEmployeeDocument(doc);
  Future<void> deleteEmployeeDocument(String id) =>
      _repo.deleteEmployeeDocument(id);

  Future<void> toggleStarredReport(String reportId) async {
    if (_starredReports.contains(reportId)) {
      _starredReports.remove(reportId);
    } else {
      _starredReports.add(reportId);
    }
    await _persistUserPrefs();
    notifyListeners();
  }

  Future<void> setReportHiddenColumns(
    String reportId,
    Set<String> hidden,
  ) async {
    if (hidden.isEmpty) {
      _reportHiddenColumns.remove(reportId);
    } else {
      _reportHiddenColumns[reportId] = <String>{...hidden};
    }
    await _persistUserPrefs();
    notifyListeners();
  }

  Future<void> upsertSession(Session session) =>
      _repo.upsertSession(session);
  Future<void> deleteSession(String id) => _repo.deleteSession(id);
  Future<void> activateSession(String id) async {
    final s = _sessions.firstWhere(
      (s) => s.id == id,
      orElse: () => throw StateError('Session $id not found'),
    );
    await _repo.upsertSession(s.copyWith(isActive: true));
  }

  Future<void> upsertRole(Role role) => _repo.upsertRole(role);
  Future<void> deleteRole(String id) => _repo.deleteRole(id);

  Future<void> upsertAppUser(AppUser user) => _repo.upsertAppUser(user);
  Future<void> deleteAppUser(String id) => _repo.deleteAppUser(id);

  Future<void> upsertDevice(Device device) => _repo.upsertDevice(device);
  Future<void> deleteDevice(String id) => _repo.deleteDevice(id);

  Future<void> upsertHoliday(Holiday holiday) =>
      _repo.upsertHoliday(holiday);
  Future<void> deleteHoliday(String id) => _repo.deleteHoliday(id);

  Future<void> upsertOfficeLocation(OfficeLocation loc) =>
      _repo.upsertOfficeLocation(loc);
  Future<void> deleteOfficeLocation(String id) =>
      _repo.deleteOfficeLocation(id);

  Future<void> upsertTeam(Team team) => _repo.upsertTeam(team);
  Future<void> deleteTeam(String id) => _repo.deleteTeam(id);

  Future<void> upsertEmployeeGroup(EmployeeGroup g) =>
      _repo.upsertEmployeeGroup(g);
  Future<void> deleteEmployeeGroup(String id) =>
      _repo.deleteEmployeeGroup(id);

  Future<void> upsertTrackingMethod(TrackingMethod m) =>
      _repo.upsertTrackingMethod(m);
  Future<void> deleteTrackingMethod(String id) =>
      _repo.deleteTrackingMethod(id);

  Future<void> upsertEmployeeSalary(EmployeeSalary s) async {
    final now = DateTime.now();
    final stamped = s.copyWith(updatedAt: now);
    await _repo.upsertEmployeeSalary(stamped);
    // Audit: every change writes a new history row.
    await _repo.upsertSalaryHistory(SalaryHistoryEntry(
      id: 'sh_${now.microsecondsSinceEpoch}',
      userId: stamped.userId,
      changedAt: now,
      basic: stamped.basic,
      totalAllowances: stamped.totalAllowances,
      totalDeductions: stamped.totalDeductions,
      grade: stamped.grade,
      structure: stamped.structure,
      currency: stamped.currency,
      notes: stamped.notes,
    ));
  }

  Future<List<SalaryHistoryEntry>> salaryHistoryFor(String userId) =>
      _repo.listSalaryHistory(userId);

  Future<void> deleteEmployeeSalary(String userId) =>
      _repo.deleteEmployeeSalary(userId);

  Future<void> upsertPayslip(Payslip p) => _repo.upsertPayslip(p);
  Future<void> deletePayslip(String id) => _repo.deletePayslip(id);

  // ─── Child records ───────────────────────────────────────────

  Future<List<FamilyMember>> familyMembersFor(String userId) =>
      _repo.listFamilyMembers(userId);
  Future<void> upsertFamilyMember(FamilyMember m) =>
      _repo.upsertFamilyMember(m);
  Future<void> deleteFamilyMember(String id) => _repo.deleteFamilyMember(id);

  Future<List<EducationEntry>> educationEntriesFor(String userId) =>
      _repo.listEducationEntries(userId);
  Future<void> upsertEducationEntry(EducationEntry e) =>
      _repo.upsertEducationEntry(e);
  Future<void> deleteEducationEntry(String id) =>
      _repo.deleteEducationEntry(id);

  Future<List<TrainingEntry>> trainingEntriesFor(String userId) =>
      _repo.listTrainingEntries(userId);
  Future<void> upsertTrainingEntry(TrainingEntry e) =>
      _repo.upsertTrainingEntry(e);
  Future<void> deleteTrainingEntry(String id) =>
      _repo.deleteTrainingEntry(id);

  Future<List<EmploymentHistoryEntry>> employmentHistoryFor(String userId) =>
      _repo.listEmploymentHistory(userId);
  Future<void> upsertEmploymentHistoryEntry(EmploymentHistoryEntry e) =>
      _repo.upsertEmploymentHistoryEntry(e);
  Future<void> deleteEmploymentHistoryEntry(String id) =>
      _repo.deleteEmploymentHistoryEntry(id);

  Future<List<DisciplinaryAction>> disciplinaryActionsFor(String userId) =>
      _repo.listDisciplinaryActions(userId);
  Future<void> upsertDisciplinaryAction(DisciplinaryAction a) =>
      _repo.upsertDisciplinaryAction(a);
  Future<void> deleteDisciplinaryAction(String id) =>
      _repo.deleteDisciplinaryAction(id);

  Future<List<Achievement>> achievementsFor(String userId) =>
      _repo.listAchievements(userId);
  Future<void> upsertAchievement(Achievement a) =>
      _repo.upsertAchievement(a);
  Future<void> deleteAchievement(String id) => _repo.deleteAchievement(id);

  Future<List<EmployeeAddress>> addressesFor(String userId) =>
      _repo.listEmployeeAddresses(userId);
  Future<void> upsertEmployeeAddress(EmployeeAddress a) =>
      _repo.upsertEmployeeAddress(a);
  Future<void> deleteEmployeeAddress(String id) =>
      _repo.deleteEmployeeAddress(id);

  // ─── User prefs ──────────────────────────────────────────────

  Future<void> _persistUserPrefs() async {
    final uid = _firebaseUid;
    if (uid == null) return;
    await _repo.setUserPrefs(uid, <String, Object?>{
      'starred_reports': _starredReports.toList(),
      'report_hidden_columns': <String, List<String>>{
        for (final e in _reportHiddenColumns.entries)
          e.key: e.value.toList(),
      },
    });
  }

  /// Fetches every punch in [month] from Firestore, optionally
  /// filtered to a single employee. Used by the monthly export and
  /// the per-employee attendance screen — the live subscription's
  /// 500-row cap may not cover a full period.
  Future<List<Punch>> fetchPunchesForMonth(
    DateTime month, {
    String? userId,
  }) =>
      _repo.fetchPunchesForMonth(month, userId: userId);

  /// Public alias of the daily-summary derivation so screens like the
  /// monthly exporter can derive from a custom punch list (not just
  /// the live `_recentPunches`).
  static List<DailySummary> deriveDailyFromPunches(List<Punch> punches) =>
      _deriveDailyImpl(punches);

  // ─── Daily summaries (derived from punches) ──────────────────

  List<DailySummary> _deriveDailyFromPunches(List<Punch> punches) =>
      _deriveDailyImpl(punches);

  static List<DailySummary> _deriveDailyImpl(List<Punch> punches) {
    if (punches.isEmpty) return const <DailySummary>[];
    final byKey = <String, List<Punch>>{};
    for (final p in punches) {
      final d = DateUtils.dateOnly(p.timestamp);
      final key = '${p.userId}|${d.toIso8601String()}';
      byKey.putIfAbsent(key, () => <Punch>[]).add(p);
    }
    final out = <DailySummary>[];
    for (final entry in byKey.entries) {
      final list = entry.value
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final first = list.first;
      final last = list.last;
      final worked = list.length > 1
          ? last.timestamp.difference(first.timestamp).inMinutes
          : 0;
      out.add(DailySummary(
        userId: first.userId,
        date: DateUtils.dateOnly(first.timestamp),
        checkIn: first.timestamp,
        checkOut: list.length > 1 ? last.timestamp : null,
        workedMinutes: worked,
        status: AttendanceStatus.present,
        notes: '',
      ));
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  // ─── Payroll ─────────────────────────────────────────────────

  AttendanceBreakdown attendanceBreakdownFor(
    String userId, {
    required DateTime periodStart,
    required DateTime periodEnd,
    EmployeeSalary? salary,
  }) {
    final s = salary ?? salaryFor(userId);

    final assignedScheduleId = profileFor(userId).scheduleId;
    Schedule? schedule;
    if (assignedScheduleId != null) {
      for (final sc in _schedules) {
        if (sc.id == assignedScheduleId) {
          schedule = sc;
          break;
        }
      }
    }
    schedule ??= _schedules.firstWhere(
      (sc) => sc.assignedUserIds.contains(userId),
      orElse: () => Schedule(
        id: 'fallback',
        name: 'Fallback',
        shiftId: '',
        workDays: const <int>{1, 2, 3, 4, 6, 7},
        startDate: periodStart,
      ),
    );

    final holidayKeys = <String>{
      for (final h in _holidays)
        if (!schedule.includeHolidays)
          '${h.date.year}-${h.date.month}-${h.date.day}',
    };

    int workingDays = 0;
    for (var d = DateUtils.dateOnly(periodStart);
        !d.isAfter(periodEnd);
        d = d.add(const Duration(days: 1))) {
      if (!schedule.workDays.contains(d.weekday)) continue;
      if (holidayKeys.contains('${d.year}-${d.month}-${d.day}')) continue;
      workingDays++;
    }

    int presentDays = 0;
    int lateDays = 0;
    final presentDates = <String>{};
    for (final ds in _daily) {
      if (ds.userId != userId) continue;
      if (ds.date.isBefore(periodStart) || ds.date.isAfter(periodEnd)) {
        continue;
      }
      if (ds.checkIn == null) continue;
      presentDays++;
      presentDates.add('${ds.date.year}-${ds.date.month}-${ds.date.day}');
      if (ds.status == AttendanceStatus.late) lateDays++;
    }

    int leaveDays = 0;
    for (final r in _requests) {
      if (r.type != RequestType.leave) continue;
      if (r.requesterUserId != userId) continue;
      if (r.status != RequestStatus.approved) continue;
      final leaveEnd = r.toDate ?? r.fromDate;
      for (var d = DateUtils.dateOnly(r.fromDate);
          !d.isAfter(leaveEnd);
          d = d.add(const Duration(days: 1))) {
        if (d.isBefore(periodStart) || d.isAfter(periodEnd)) continue;
        if (presentDates.contains('${d.year}-${d.month}-${d.day}')) continue;
        leaveDays++;
      }
    }

    final unaccounted =
        (workingDays - presentDays - leaveDays).clamp(0, workingDays);
    final perDayBasic = workingDays == 0 ? 0.0 : s.basic / workingDays;
    final attendanceDeduction = perDayBasic * unaccounted;

    return AttendanceBreakdown(
      workingDays: workingDays,
      presentDays: presentDays,
      absentDays: unaccounted,
      lateDays: lateDays,
      leaveDays: leaveDays,
      attendanceDeduction: attendanceDeduction,
    );
  }

  Future<Payslip> generatePayslip(
    String userId, {
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final salary = salaryFor(userId);
    final att = attendanceBreakdownFor(
      userId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      salary: salary,
    );
    final p = Payslip(
      id: 'pay_${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      basic: salary.basic,
      totalAllowances: salary.totalAllowances,
      totalDeductions: salary.totalDeductions,
      currency: salary.currency,
      status: PayslipStatus.draft,
      createdAt: DateTime.now(),
      workingDays: att.workingDays,
      presentDays: att.presentDays,
      absentDays: att.absentDays,
      lateDays: att.lateDays,
      leaveDays: att.leaveDays,
      attendanceDeduction: att.attendanceDeduction,
    );
    await upsertPayslip(p);
    return p;
  }

  Future<int> generatePayslipsForPeriod({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    int created = 0;
    for (final userId in _salaries.keys) {
      final exists = _payslips.any((p) =>
          p.userId == userId &&
          p.periodStart == periodStart &&
          p.periodEnd == periodEnd);
      if (exists) continue;
      await generatePayslip(
        userId,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      created++;
    }
    return created;
  }
}

class AttendanceBreakdown {
  AttendanceBreakdown({
    required this.workingDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.leaveDays,
    required this.attendanceDeduction,
  });
  final int workingDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int leaveDays;
  final double attendanceDeduction;
}
