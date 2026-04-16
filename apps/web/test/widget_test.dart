import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_web/main.dart';

void main() {
  testWidgets(
    'restores an existing manager browser session before showing login',
    (WidgetTester tester) async {
      final apiClient = _FakeManagerApiClient()
        ..restoredSession = const ManagerSession(
          accessToken: '',
          user: ManagerUser(
            id: 'manager-1',
            email: 'manager@sercesync.local',
            displayName: 'Morgan Manager',
            role: ManagerUserRole.manager,
          ),
        );

      await tester.binding.setSurfaceSize(const Size(1440, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(SerceSyncWebApp(apiClient: apiClient));
      await tester.pumpAndSettle();

      expect(find.text('Unit Overview'), findsOneWidget);
      expect(find.text('Manager workspace'), findsNothing);
      expect(apiClient.requestLog.first, 'restoreSession');
      expect(apiClient.requestLog, isNot(contains('login')));
    },
  );

  testWidgets('shows login when no manager browser session exists', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();

    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(SerceSyncWebApp(apiClient: apiClient));
    await tester.pumpAndSettle();

    expect(find.text('Manager workspace'), findsOneWidget);
    expect(find.text('Unit Overview'), findsNothing);
    expect(apiClient.requestLog.first, 'restoreSession');
  });

  testWidgets('shows a retry state when session restore fails unexpectedly', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient()
      ..restoreSessionError = const ApiException(
        'Manager session restore failed.',
        statusCode: 500,
      );

    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(SerceSyncWebApp(apiClient: apiClient));
    await tester.pumpAndSettle();

    expect(find.text('Unable to restore manager session'), findsOneWidget);
    expect(find.text('Manager session restore failed.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Manager workspace'), findsNothing);
  });

  testWidgets('workspace boot flow loads active shifts before dashboard data', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    expect(
      apiClient.requestLog.indexOf('activeShifts'),
      lessThan(apiClient.requestLog.indexOf('dashboard:shift-1')),
    );
  });

  testWidgets('dashboard renders active incidents card and incident actions', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    expect(find.text('ACTIVE INCIDENTS'), findsOneWidget);
    expect(find.text('Live Activity Feed'), findsOneWidget);
    expect(
      find.text('Morning shower support completed safely.'),
      findsOneWidget,
    );
    expect(find.text('Hallway Fall'), findsOneWidget);
    expect(find.text('Acknowledge'), findsOneWidget);
    expect(find.text('Resolve'), findsOneWidget);
  });

  testWidgets('dashboard refreshes when the live update stream emits', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    expect(
      apiClient.requestLog
          .where((entry) => entry == 'dashboard:shift-1')
          .length,
      1,
    );

    apiClient.emitDashboardUpdate('shift-1');
    await tester.pump();
    await tester.pump();

    expect(
      apiClient.requestLog
          .where((entry) => entry == 'dashboard:shift-1')
          .length,
      2,
    );
  });

  testWidgets('changing the selected shift refreshes the dashboard snapshot', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    expect(find.text('Hallway Fall'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('dashboard-shift-selector-shift-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cedar Floor • Cedar Support Shift').last);
    await tester.pumpAndSettle();

    expect(find.text('Cedar Distress Episode'), findsOneWidget);
    expect(apiClient.requestLog, contains('dashboard:shift-2'));
  });

  testWidgets(
    'ignores stale dashboard responses when a newer shift load wins',
    (WidgetTester tester) async {
      final apiClient = _FakeManagerApiClient();
      await _pumpManagerWorkspace(tester, apiClient: apiClient);

      final delayedShiftOneDashboard = Completer<ManagerDashboardSnapshot>();
      apiClient.enqueueDashboardResponse(
        'shift-1',
        () => delayedShiftOneDashboard.future,
      );

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('dashboard-shift-selector-shift-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cedar Floor • Cedar Support Shift').last);
      await tester.pumpAndSettle();

      expect(find.text('Cedar Distress Episode'), findsOneWidget);
      expect(find.text('Hallway Fall'), findsNothing);

      delayedShiftOneDashboard.complete(apiClient.snapshotForShift('shift-1'));
      await tester.pumpAndSettle();

      expect(find.text('Cedar Distress Episode'), findsOneWidget);
      expect(find.text('Hallway Fall'), findsNothing);
    },
  );

  testWidgets(
    'falls back to the remaining active shift when the selected one disappears mid-load',
    (WidgetTester tester) async {
      final apiClient = _FakeManagerApiClient();
      await _pumpManagerWorkspace(tester, apiClient: apiClient);

      apiClient.enqueueActiveShiftsResponse(
        apiClient.shiftList(const ['shift-1', 'shift-2']),
      );
      apiClient.enqueueDashboardResponse(
        'shift-1',
        () async => throw const ApiException(
          'Active shift was not found for the manager dashboard.',
        ),
      );
      apiClient.enqueueActiveShiftsResponse(
        apiClient.shiftList(const ['shift-2']),
      );
      apiClient.setActiveShifts(apiClient.shiftList(const ['shift-2']));

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Cedar Support Shift'), findsOneWidget);
      expect(find.text('Cedar Distress Episode'), findsOneWidget);
      expect(find.text('Hallway Fall'), findsNothing);
      expect(
        apiClient.requestLog,
        containsAllInOrder([
          'activeShifts',
          'dashboard:shift-1',
          'activeShifts',
          'dashboard:shift-2',
        ]),
      );
    },
  );

  testWidgets('dashboard feed shows incident rows before task rows', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    final incidentPosition = tester
        .getTopLeft(
          find.byKey(const ValueKey('exception-row-incident-open-red')),
        )
        .dy;
    final taskPosition = tester
        .getTopLeft(find.byKey(const ValueKey('exception-row-task-overdue')))
        .dy;

    expect(incidentPosition, lessThan(taskPosition));
  });

  testWidgets('incident action buttons render only for valid statuses', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    expect(find.text('Acknowledge'), findsOneWidget);
    expect(find.text('Resolve'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('exception-row-task-overdue')),
      findsOneWidget,
    );
  });

  testWidgets('dashboard shows an empty state when no active shifts exist', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient(activeShifts: const []);
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    expect(find.text('No active shifts available yet.'), findsOneWidget);
    expect(
      apiClient.requestLog.where((entry) => entry.startsWith('dashboard:')),
      isEmpty,
    );
  });

  testWidgets('residents management form sends baseline priority', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    await tester.tap(find.text('Residents'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey(
          'resident-baseline-priority-new-ManagerResidentPriorityLevel.green',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amber baseline').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Resident Name'),
      'Harriet Cole',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Room'), '12');
    await tester.enterText(find.widgetWithText(TextFormField, 'Floor'), '2');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unit Label'),
      'Maple Floor',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Clinical Summary'),
      'Requires closer wellbeing observation after an overnight decline.',
    );

    await tester.ensureVisible(find.text('Save Record'));
    await tester.tap(find.text('Save Record'));
    await tester.pumpAndSettle();

    expect(apiClient.lastSavedDraft, isNotNull);
    expect(
      apiClient.lastSavedDraft!.baselinePriority,
      ManagerResidentPriorityLevel.amber,
    );
  });

  testWidgets('resident reset restores the baseline priority selection', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    await tester.tap(find.text('Residents'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey(
          'resident-baseline-priority-new-ManagerResidentPriorityLevel.green',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amber baseline').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey(
          'resident-baseline-priority-new-ManagerResidentPriorityLevel.amber',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey(
          'resident-baseline-priority-new-ManagerResidentPriorityLevel.green',
        ),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Resident Name'),
      'Reset Resident',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Room'), '14');
    await tester.enterText(find.widgetWithText(TextFormField, 'Floor'), '2');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unit Label'),
      'Maple Floor',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Clinical Summary'),
      'Created after reset to verify the visible baseline matches the saved value.',
    );

    await tester.ensureVisible(find.text('Save Record'));
    await tester.tap(find.text('Save Record'));
    await tester.pumpAndSettle();

    expect(apiClient.lastSavedDraft, isNotNull);
    expect(
      apiClient.lastSavedDraft!.baselinePriority,
      ManagerResidentPriorityLevel.green,
    );
  });

  testWidgets('resident rows render priority and incident count pills', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    await tester.tap(find.text('Residents'));
    await tester.pumpAndSettle();

    expect(find.text('Priority RED'), findsOneWidget);
    expect(find.text('1 active incident'), findsOneWidget);
    expect(find.text('Incident override'), findsOneWidget);
  });
}

Future<void> _pumpManagerWorkspace(
  WidgetTester tester, {
  required _FakeManagerApiClient apiClient,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(SerceSyncWebApp(apiClient: apiClient));
  await tester.pumpAndSettle();

  expect(find.text('Manager workspace'), findsOneWidget);

  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email address'),
    'manager@sercesync.local',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    'Password123!',
  );
  await tester.tap(find.text('Open manager dashboard'));
  await tester.pumpAndSettle();

  expect(find.text('Unit Overview'), findsOneWidget);
}

class _FakeManagerApiClient extends SerceSyncManagerApiClient {
  _FakeManagerApiClient({List<ManagerShiftSummary>? activeShifts})
    : _availableShifts = {
        for (final shift in [
          ManagerShiftSummary(
            id: 'shift-1',
            name: 'Morning Shift',
            status: ManagerShiftStatus.active,
            unitLabel: 'Willow Floor',
            floorNumber: 1,
            startsAt: DateTime(2026, 4, 13, 7),
            endsAt: DateTime(2026, 4, 13, 14),
          ),
          ManagerShiftSummary(
            id: 'shift-2',
            name: 'Cedar Support Shift',
            status: ManagerShiftStatus.active,
            unitLabel: 'Cedar Floor',
            floorNumber: 1,
            startsAt: DateTime(2026, 4, 13, 8),
            endsAt: DateTime(2026, 4, 13, 15),
          ),
        ])
          shift.id: shift,
      },
      _activeShifts = List<ManagerShiftSummary>.from(
        activeShifts ??
            [
              ManagerShiftSummary(
                id: 'shift-1',
                name: 'Morning Shift',
                status: ManagerShiftStatus.active,
                unitLabel: 'Willow Floor',
                floorNumber: 1,
                startsAt: DateTime(2026, 4, 13, 7),
                endsAt: DateTime(2026, 4, 13, 14),
              ),
              ManagerShiftSummary(
                id: 'shift-2',
                name: 'Cedar Support Shift',
                status: ManagerShiftStatus.active,
                unitLabel: 'Cedar Floor',
                floorNumber: 1,
                startsAt: DateTime(2026, 4, 13, 8),
                endsAt: DateTime(2026, 4, 13, 15),
              ),
            ],
      ),
      super(baseUrl: 'http://localhost:3000');

  final List<String> requestLog = <String>[];
  final Map<String, ManagerShiftSummary> _availableShifts;
  final List<Future<List<ManagerShiftSummary>> Function()>
  _queuedActiveShiftResponses = [];
  final Map<String, List<Future<ManagerDashboardSnapshot> Function()>>
  _queuedDashboardResponses = {};
  final Map<String, StreamController<ManagerDashboardLiveUpdate>>
  _dashboardUpdateControllers = {};
  List<ManagerShiftSummary> _activeShifts;
  ManagerSession? restoredSession;
  ApiException? restoreSessionError;
  ManagerResidentDraft? lastSavedDraft;

  void enqueueActiveShiftsResponse(List<ManagerShiftSummary> activeShifts) {
    _queuedActiveShiftResponses.add(
      () async => List<ManagerShiftSummary>.from(activeShifts),
    );
  }

  void emitDashboardUpdate(
    String shiftId, {
    String reason = 'timeline-entry-created',
  }) {
    final controller = _dashboardUpdateControllers.putIfAbsent(
      shiftId,
      () => StreamController<ManagerDashboardLiveUpdate>.broadcast(),
    );
    controller.add(
      ManagerDashboardLiveUpdate(
        type: ManagerDashboardLiveUpdateType.updated,
        shiftId: shiftId,
        eventId: 'event-$shiftId-${requestLog.length}',
        occurredAt: DateTime(2026, 4, 13, 10, 50),
        reason: reason,
      ),
    );
  }

  void enqueueDashboardResponse(
    String shiftId,
    Future<ManagerDashboardSnapshot> Function() response,
  ) {
    _queuedDashboardResponses.putIfAbsent(shiftId, () => []).add(response);
  }

  void setActiveShifts(List<ManagerShiftSummary> activeShifts) {
    _activeShifts = List<ManagerShiftSummary>.from(activeShifts);
  }

  List<ManagerShiftSummary> shiftList(List<String> shiftIds) {
    return shiftIds.map(shiftSummary).toList(growable: false);
  }

  ManagerShiftSummary shiftSummary(String shiftId) {
    final shift = _availableShifts[shiftId];
    if (shift == null) {
      throw StateError('Unknown shift id $shiftId');
    }
    return shift;
  }

  ManagerDashboardSnapshot snapshotForShift(String shiftId) {
    switch (shiftId) {
      case 'shift-2':
        return ManagerDashboardSnapshot(
          activeShift: shiftSummary('shift-2'),
          metrics: const ManagerDashboardMetrics(
            overdueTasks: 0,
            escalatedItems: 0,
            unreadHandovers: 0,
            shiftCompletionPercent: 62,
            activeIncidents: 1,
          ),
          activityFeed: [
            ManagerActivityFeedItem(
              id: 'note-cedar-1',
              kind: ManagerActivityKind.note,
              title: 'Observation',
              residentName: 'Caroline Reed',
              roomLabel: 'Room 12',
              description:
                  'Settled after reassurance and a short corridor walk.',
              actorName: 'Alex Carer',
              occurredAt: DateTime(2026, 4, 13, 9, 35),
              badge: 'OBSERVATION',
              badgeTone: 'info',
            ),
          ],
          exceptionFeed: [
            ManagerExceptionFeedItem(
              id: 'incident-cedar-red',
              kind: ManagerExceptionKind.incident,
              title: 'Cedar Distress Episode',
              residentName: 'Caroline Reed',
              roomLabel: 'Room 12',
              description:
                  'Resident became distressed in the corridor and needs continued follow-up.',
              status: ManagerExceptionStatus.open,
              severity: ManagerIncidentSeverity.red,
              badge: 'RED INCIDENT',
              badgeTone: 'critical',
              canAcknowledge: true,
              canResolve: false,
              occurredAt: DateTime(2026, 4, 13, 9, 20),
              dueAt: null,
            ),
          ],
          complianceSeries: [
            ManagerCompliancePoint(
              timestamp: DateTime(2026, 4, 13, 9),
              value: 92,
            ),
            ManagerCompliancePoint(
              timestamp: DateTime(2026, 4, 13, 11),
              value: 88,
            ),
            ManagerCompliancePoint(
              timestamp: DateTime(2026, 4, 13, 13),
              value: 90,
            ),
          ],
        );
      case 'shift-1':
      default:
        return ManagerDashboardSnapshot(
          activeShift: shiftSummary('shift-1'),
          metrics: const ManagerDashboardMetrics(
            overdueTasks: 1,
            escalatedItems: 0,
            unreadHandovers: 0,
            shiftCompletionPercent: 74,
            activeIncidents: 2,
          ),
          activityFeed: [
            ManagerActivityFeedItem(
              id: 'note-willow-1',
              kind: ManagerActivityKind.note,
              title: 'Personal Care · Shower',
              residentName: 'Margaret Evans',
              roomLabel: 'Room 1',
              description: 'Morning shower support completed safely.',
              actorName: 'Alex Carer',
              occurredAt: DateTime(2026, 4, 13, 10, 46),
              badge: 'PERSONAL CARE',
              badgeTone: 'info',
            ),
            ManagerActivityFeedItem(
              id: 'task-willow-1',
              kind: ManagerActivityKind.task,
              title: 'Hydration Round',
              residentName: 'Margaret Evans',
              roomLabel: 'Room 1',
              description: 'Hydration round signed off and fluids encouraged.',
              actorName: 'Alex Carer',
              occurredAt: DateTime(2026, 4, 13, 10, 38),
              badge: 'COMPLETED',
              badgeTone: 'success',
            ),
          ],
          exceptionFeed: [
            ManagerExceptionFeedItem(
              id: 'incident-open-red',
              kind: ManagerExceptionKind.incident,
              title: 'Hallway Fall',
              residentName: 'Margaret Evans',
              roomLabel: 'Room 1',
              description:
                  'Resident slipped near the bathroom doorway and needs review.',
              status: ManagerExceptionStatus.open,
              severity: ManagerIncidentSeverity.red,
              badge: 'RED INCIDENT',
              badgeTone: 'critical',
              canAcknowledge: true,
              canResolve: false,
              occurredAt: DateTime(2026, 4, 13, 9, 10),
              dueAt: null,
            ),
            ManagerExceptionFeedItem(
              id: 'incident-ack-amber',
              kind: ManagerExceptionKind.incident,
              title: 'Medication Refusal',
              residentName: 'Leonard Price',
              roomLabel: 'Room 4',
              description:
                  'Morning tablets were refused and need manager follow-up.',
              status: ManagerExceptionStatus.acknowledged,
              severity: ManagerIncidentSeverity.amber,
              badge: 'AMBER INCIDENT',
              badgeTone: 'warning',
              canAcknowledge: false,
              canResolve: true,
              occurredAt: DateTime(2026, 4, 13, 8, 40),
              dueAt: null,
            ),
            ManagerExceptionFeedItem(
              id: 'task-overdue',
              kind: ManagerExceptionKind.task,
              title: 'Hydration Round',
              residentName: 'Margaret Evans',
              roomLabel: 'Room 1',
              description:
                  'Missed scheduled drink support during the late morning block.',
              status: ManagerExceptionStatus.overdue,
              severity: null,
              badge: 'MISSED',
              badgeTone: 'critical',
              canAcknowledge: false,
              canResolve: false,
              occurredAt: null,
              dueAt: DateTime(2026, 4, 13, 10, 30),
            ),
          ],
          complianceSeries: [
            ManagerCompliancePoint(
              timestamp: DateTime(2026, 4, 13, 9),
              value: 94,
            ),
            ManagerCompliancePoint(
              timestamp: DateTime(2026, 4, 13, 11),
              value: 86,
            ),
            ManagerCompliancePoint(
              timestamp: DateTime(2026, 4, 13, 13),
              value: 95,
            ),
          ],
        );
    }
  }

  final List<ManagerResidentRecord> _residents = [
    const ManagerResidentRecord(
      id: 'resident-1',
      fullName: 'Margaret Evans',
      roomNumber: 1,
      roomLabel: 'Room 1',
      floorNumber: 1,
      unitLabel: 'Willow Floor',
      recognitionImageKey: 'resident-a',
      careSummary: 'Hydration encouragement remains the main focus today.',
      isActive: true,
      baselinePriority: ManagerResidentPriorityLevel.green,
      effectivePriority: ManagerResidentPriorityLevel.red,
      prioritySource: ManagerResidentPrioritySource.incidentOverride,
      activeIncidentCount: 1,
    ),
    const ManagerResidentRecord(
      id: 'resident-2',
      fullName: 'Leonard Price',
      roomNumber: 4,
      roomLabel: 'Room 4',
      floorNumber: 1,
      unitLabel: 'Willow Floor',
      recognitionImageKey: 'resident-b',
      careSummary: 'Continence support and morning wash routine are stable.',
      isActive: true,
      baselinePriority: ManagerResidentPriorityLevel.amber,
      effectivePriority: ManagerResidentPriorityLevel.amber,
      prioritySource: ManagerResidentPrioritySource.baseline,
      activeIncidentCount: 0,
    ),
  ];

  @override
  Future<ManagerSession> login({
    required String email,
    required String password,
  }) async {
    requestLog.add('login');
    return const ManagerSession(
      accessToken: 'token',
      user: ManagerUser(
        id: 'manager-1',
        email: 'manager@sercesync.local',
        displayName: 'Morgan Manager',
        role: ManagerUserRole.manager,
      ),
    );
  }

  @override
  Future<ManagerSession> restoreSession() async {
    requestLog.add('restoreSession');
    final restoreError = restoreSessionError;
    if (restoreError != null) {
      throw restoreError;
    }
    final session = restoredSession;
    if (session == null) {
      throw const ApiException(
        'No active manager browser session.',
        statusCode: 401,
      );
    }
    return session;
  }

  @override
  Future<void> logout() async {
    requestLog.add('logout');
    restoredSession = null;
  }

  @override
  Future<List<ManagerShiftSummary>> getActiveShifts({
    required String accessToken,
  }) async {
    requestLog.add('activeShifts');
    if (_queuedActiveShiftResponses.isNotEmpty) {
      return _queuedActiveShiftResponses.removeAt(0)();
    }
    return List<ManagerShiftSummary>.from(_activeShifts);
  }

  @override
  Future<ManagerDashboardSnapshot> getDashboard({
    required String accessToken,
    required String shiftId,
  }) async {
    requestLog.add('dashboard:$shiftId');
    final queuedResponses = _queuedDashboardResponses[shiftId];
    if (queuedResponses != null && queuedResponses.isNotEmpty) {
      return queuedResponses.removeAt(0)();
    }
    if (_activeShifts.isEmpty) {
      throw StateError(
        'Dashboard should not be requested without active shifts.',
      );
    }

    return snapshotForShift(shiftId);
  }

  @override
  Stream<ManagerDashboardLiveUpdate> watchDashboard({
    required String accessToken,
    required String shiftId,
  }) {
    requestLog.add('watch:$shiftId');
    final controller = _dashboardUpdateControllers.putIfAbsent(
      shiftId,
      () => StreamController<ManagerDashboardLiveUpdate>.broadcast(),
    );
    return controller.stream;
  }

  @override
  Future<List<ManagerResidentRecord>> getResidents({
    required String accessToken,
  }) async {
    requestLog.add('residents');
    return List<ManagerResidentRecord>.from(_residents);
  }

  @override
  Future<ManagerResidentRecord> createResident({
    required String accessToken,
    required ManagerResidentDraft draft,
  }) async {
    lastSavedDraft = draft;
    final resident = ManagerResidentRecord(
      id: 'resident-${_residents.length + 1}',
      fullName: draft.fullName,
      roomNumber: draft.roomNumber,
      roomLabel: 'Room ${draft.roomNumber}',
      floorNumber: draft.floorNumber,
      unitLabel: draft.unitLabel,
      recognitionImageKey: draft.recognitionImageKey,
      careSummary: draft.careSummary,
      isActive: draft.isActive,
      baselinePriority: draft.baselinePriority,
      effectivePriority: draft.baselinePriority,
      prioritySource: ManagerResidentPrioritySource.baseline,
      activeIncidentCount: 0,
    );
    _residents.add(resident);
    return resident;
  }

  @override
  Future<ManagerResidentRecord> updateResident({
    required String accessToken,
    required String residentId,
    required ManagerResidentDraft draft,
  }) async {
    lastSavedDraft = draft;
    final index = _residents.indexWhere(
      (resident) => resident.id == residentId,
    );
    final resident = ManagerResidentRecord(
      id: residentId,
      fullName: draft.fullName,
      roomNumber: draft.roomNumber,
      roomLabel: 'Room ${draft.roomNumber}',
      floorNumber: draft.floorNumber,
      unitLabel: draft.unitLabel,
      recognitionImageKey: draft.recognitionImageKey,
      careSummary: draft.careSummary,
      isActive: draft.isActive,
      baselinePriority: draft.baselinePriority,
      effectivePriority: draft.baselinePriority,
      prioritySource: ManagerResidentPrioritySource.baseline,
      activeIncidentCount: 0,
    );
    if (index >= 0) {
      _residents[index] = resident;
    }
    return resident;
  }

  @override
  Future<void> acknowledgeIncident({
    required String accessToken,
    required String incidentId,
    required String shiftId,
  }) async {
    requestLog.add('acknowledge:$incidentId:$shiftId');
  }

  @override
  Future<void> resolveIncident({
    required String accessToken,
    required String incidentId,
    required String shiftId,
  }) async {
    requestLog.add('resolve:$incidentId:$shiftId');
  }
}
