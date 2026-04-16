import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_mobile/api/api_client.dart';
import 'package:sercesync_mobile/main.dart';
import 'package:sercesync_mobile/models/handover.dart';
import 'package:sercesync_mobile/models/task.dart';
import 'package:sercesync_mobile/models/user.dart';
import 'package:sercesync_mobile/models/workspace_models.dart';
import 'package:sercesync_mobile/screens/resident_detail_screen.dart';
import 'package:sercesync_mobile/screens/residents_screen.dart';
import 'package:sercesync_mobile/screens/shift_workspace_screen.dart';

void main() {
  testWidgets('renders the login shell', (WidgetTester tester) async {
    await tester.pumpWidget(const SerceSyncMobileApp());

    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('shift workspace switches between real destinations', (
    WidgetTester tester,
  ) async {
    final client = _FakeApiClient();
    final snapshot = HandoverSnapshot(
      shift: ShiftSummary(
        id: 'shift-1',
        name: 'Morning Care Shift',
        startsAt: DateTime(2026, 4, 11, 7),
        endsAt: DateTime(2026, 4, 11, 15, 30),
        status: ShiftStatus.active,
        floorNumber: 1,
        unitLabel: 'Willow Floor',
      ),
      handover: HandoverSummary(
        id: 'handover-1',
        summary:
            'Margaret Evans needs a medication reminder. Raj Patel needs an observation follow-up.',
        createdAt: DateTime(2026, 4, 11, 6, 30),
        updatedAt: DateTime(2026, 4, 11, 6, 45),
      ),
      currentUser: const LoginUser(
        id: 'user-1',
        email: 'carer@sercesync.local',
        displayName: 'Alex Carer',
        role: AppUserRole.carer,
      ),
      acknowledged: true,
      acknowledgedAt: DateTime(2026, 4, 11, 6, 55),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ShiftWorkspaceScreen(
          apiClient: client,
          accessToken: 'token',
          user: snapshot.currentUser,
          snapshot: snapshot,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Priorities'), findsWidgets);
    expect(find.text('Residents'), findsOneWidget);
    expect(find.text('My Shift'), findsOneWidget);

    await tester.tap(find.text('Residents').last);
    await tester.pumpAndSettle();
    expect(find.text('Margaret Evans'), findsOneWidget);

    await tester.tap(find.text('My Shift').last);
    await tester.pumpAndSettle();
    expect(find.text('Current Shift'), findsOneWidget);
    expect(find.text('Upcoming shifts'), findsOneWidget);
    expect(find.text('Willow Floor · Floor 1'), findsOneWidget);
    expect(find.text('Tomorrow Care Shift'), findsOneWidget);
    expect(find.text('Evening Relief Shift'), findsOneWidget);
  });

  testWidgets('resident list renders priority cue', (
    WidgetTester tester,
  ) async {
    final client = _FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ResidentsScreen(
          apiClient: client,
          accessToken: 'token',
          currentCarerName: 'Alex Carer',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Red priority'), findsOneWidget);
    expect(find.text('1 active incident'), findsOneWidget);
    expect(find.text('Amber priority'), findsOneWidget);
  });

  testWidgets(
    'resident detail renders incident summary and timeline evidence',
    (WidgetTester tester) async {
      final client = _FakeApiClient();

      await tester.pumpWidget(
        MaterialApp(
          home: ResidentDetailScreen(
            residentId: 'resident-1',
            apiClient: client,
            accessToken: 'token',
            currentCarerName: 'Alex Carer',
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Active incident summary'), findsOneWidget);
      expect(find.text('1 active incident'), findsWidgets);
      expect(find.text('Bathroom fall during morning checks'), findsOneWidget);
      expect(find.text('Red priority'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Skin integrity review completed.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Skin integrity review completed.'), findsOneWidget);
      expect(find.text('1 attachment'), findsOneWidget);
      expect(find.text('skin-check.jpg'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
    },
  );

  testWidgets('incident bottom sheet validates required fields', (
    WidgetTester tester,
  ) async {
    final client = _FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ResidentDetailScreen(
          residentId: 'resident-1',
          apiClient: client,
          accessToken: 'token',
          currentCarerName: 'Alex Carer',
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Report incident'));
    await tester.pumpAndSettle();
    final submitIncidentButton = find.text('Submit incident');
    await tester.ensureVisible(submitIncidentButton);
    await tester.tap(submitIncidentButton);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Add a short title and the incident details before submitting.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'personal-care note sheet requires subtype only for personal-care entries',
    (WidgetTester tester) async {
      final client = _FakeApiClient();

      await tester.pumpWidget(
        MaterialApp(
          home: ResidentDetailScreen(
            residentId: 'resident-1',
            apiClient: client,
            accessToken: 'token',
            currentCarerName: 'Alex Carer',
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Add note'));
      await tester.pumpAndSettle();

      expect(find.text('Personal Care'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).first,
        'Morning care update',
      );
      final saveNoteButton = find.text('Save note');
      await tester.ensureVisible(saveNoteButton);
      await tester.tap(saveNoteButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Choose the personal care subtype before saving this note.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('note submission refreshes resident detail correctly', (
    WidgetTester tester,
  ) async {
    final client = _FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ResidentDetailScreen(
          residentId: 'resident-1',
          apiClient: client,
          accessToken: 'token',
          currentCarerName: 'Alex Carer',
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personal care subtype').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shower').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'Morning shower support completed safely.',
    );
    final saveNoteButton = find.text('Save note');
    await tester.ensureVisible(saveNoteButton);
    await tester.tap(saveNoteButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.scrollUntilVisible(
      find.text('Morning shower support completed safely.'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Morning shower support completed safely.'),
      findsOneWidget,
    );
    expect(find.text('Shower'), findsWidgets);
  });

  testWidgets('add-note sheet hides legacy care-given option for new notes', (
    WidgetTester tester,
  ) async {
    final client = _FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ResidentDetailScreen(
          residentId: 'resident-1',
          apiClient: client,
          accessToken: 'token',
          currentCarerName: 'Alex Carer',
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personal Care').last);
    await tester.pumpAndSettle();

    expect(find.text('Care Given'), findsNothing);
  });

  testWidgets('incident submission refreshes resident detail correctly', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final client = _FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ResidentDetailScreen(
          residentId: 'resident-1',
          apiClient: client,
          accessToken: 'token',
          currentCarerName: 'Alex Carer',
        ),
      ),
    );

    await tester.pumpAndSettle();

    final reportIncidentFab = find.byWidgetPredicate(
      (widget) =>
          widget is FloatingActionButton && widget.heroTag == 'report-incident',
    );
    await tester.tap(reportIncidentFab);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.enterText(find.byType(TextField).at(1), 'Medication concern');
    await tester.enterText(
      find.byType(TextField).at(2),
      'Resident reported dizziness after lunch medications.',
    );
    final submitIncidentButton = find.widgetWithText(
      FilledButton,
      'Submit incident',
    );
    final incidentButton = tester.widget<FilledButton>(submitIncidentButton);
    incidentButton.onPressed?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Medication concern'), findsOneWidget);
    expect(find.text('2 active incidents'), findsOneWidget);
  });

  testWidgets('resident detail completes an active priority in context', (
    WidgetTester tester,
  ) async {
    final client = _FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ResidentDetailScreen(
          residentId: 'resident-1',
          apiClient: client,
          accessToken: 'token',
          currentCarerName: 'Alex Carer',
          highlightTaskId: 'task-1',
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Complete'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(
      find.byType(TextField).first,
      'Completed with resident comfortable after breakfast.',
    );
    final completeButton = find.widgetWithText(FilledButton, 'Complete');
    await tester.ensureVisible(completeButton);
    await tester.tap(completeButton);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Priority completed.'), findsOneWidget);
    expect(find.text('Hydration round for Margaret Evans'), findsNothing);
  });
}

class _FakeApiClient extends SerceSyncApiClient {
  _FakeApiClient() : super(baseUrl: 'http://localhost:3000') {
    _timelinesByResident['resident-1'] = [
      ResidentTimelineEntry(
        id: 'timeline-1',
        type: ResidentEntryType.observation,
        title: 'Observation',
        details: 'Skin integrity review completed.',
        authorName: 'Alex Carer',
        timestamp: DateTime(2026, 4, 11, 9),
        media: [
          ResidentTimelineMediaItem(
            id: 'media-1',
            originalFileName: 'skin-check.jpg',
            mediaType: 'image/jpeg',
            byteSize: 1280,
            downloadPath: '/resident-media/media-1',
            createdAt: DateTime(2026, 4, 11, 9),
          ),
        ],
      ),
    ];
    _timelinesByResident['resident-2'] = const [];

    _incidentsByResident['resident-1'] = [
      ResidentIncident(
        id: 'incident-1',
        severity: IncidentSeverity.red,
        status: IncidentStatus.open,
        category: IncidentCategory.fall,
        categoryLabel: 'Fall',
        title: 'Bathroom fall during morning checks',
        details: 'Resident slipped while transferring and needs monitoring.',
        occurredAt: DateTime(2026, 4, 11, 8, 45),
        createdAt: DateTime(2026, 4, 11, 8, 46),
        createdByName: 'Alex Carer',
        evidence: const [],
      ),
    ];
    _incidentsByResident['resident-2'] = const [];
  }

  bool _residentTaskCompleted = false;
  final Map<String, List<ResidentTimelineEntry>> _timelinesByResident = {};
  final Map<String, List<ResidentIncident>> _incidentsByResident = {};

  @override
  Future<List<ShiftTask>> getCurrentTasks({required String accessToken}) async {
    return [
      ShiftTask(
        id: 'task-1',
        title: 'Hydration round for Margaret Evans',
        description: 'Offer fluids and record intake after breakfast.',
        dueAt: DateTime.now().add(const Duration(minutes: 30)),
        status: TaskStatus.pending,
        residentId: 'resident-1',
        residentName: 'Margaret Evans',
        room: 'Room 1',
      ),
      ShiftTask(
        id: 'task-2',
        title: 'Repositioning check for Raj Patel',
        description: 'Re-check transfer risk before lunch round.',
        dueAt: DateTime.now().subtract(const Duration(minutes: 10)),
        status: TaskStatus.overdue,
        residentId: 'resident-2',
        residentName: 'Raj Patel',
        room: 'Room 2',
      ),
    ];
  }

  @override
  Future<List<ResidentListItem>> getResidents({
    required String accessToken,
  }) async {
    return [
      ResidentListItem(
        id: 'resident-1',
        fullName: 'Margaret Evans',
        roomLabel: 'Room 1',
        floorNumber: 1,
        unitLabel: 'Willow Floor',
        recognitionImageKey: 'resident-a',
        todaySummary: 'Monitor mobility after morning fall.',
        assignmentContext: 'Assigned to Willow Floor for this shift',
        contextLine: 'Follow-up observations and safety checks remain active.',
        alerts: const ['Open incident'],
        baselinePriority: ResidentPriorityLevel.green,
        effectivePriority: _effectivePriorityFor('resident-1'),
        prioritySource: _prioritySourceFor('resident-1'),
        activeIncidentCount: _activeIncidentCountFor('resident-1'),
      ),
      ResidentListItem(
        id: 'resident-2',
        fullName: 'Raj Patel',
        roomLabel: 'Room 2',
        floorNumber: 1,
        unitLabel: 'Willow Floor',
        recognitionImageKey: 'resident-b',
        todaySummary: 'Baseline amber due to ongoing mobility support.',
        assignmentContext: 'Assigned to Willow Floor for this shift',
        contextLine: 'Routine mobility support scheduled later in the shift.',
        alerts: const ['Due this shift'],
        baselinePriority: ResidentPriorityLevel.amber,
        effectivePriority: _effectivePriorityFor('resident-2'),
        prioritySource: _prioritySourceFor('resident-2'),
        activeIncidentCount: _activeIncidentCountFor('resident-2'),
      ),
    ];
  }

  @override
  Future<ResidentDetail> getResidentById({
    required String accessToken,
    required String residentId,
  }) async {
    final baselinePriority = residentId == 'resident-2'
        ? ResidentPriorityLevel.amber
        : ResidentPriorityLevel.green;

    return ResidentDetail(
      id: residentId,
      fullName: residentId == 'resident-1' ? 'Margaret Evans' : 'Raj Patel',
      roomLabel: residentId == 'resident-1' ? 'Room 1' : 'Room 2',
      floorNumber: 1,
      unitLabel: 'Willow Floor',
      recognitionImageKey: residentId == 'resident-1'
          ? 'resident-a'
          : 'resident-b',
      todaySummary: residentId == 'resident-1'
          ? 'Monitor mobility, hydration, and incident follow-up.'
          : 'Continue baseline amber support for mobility and reassurance.',
      assignmentContext: 'Assigned to Willow Floor for this shift',
      contextLine: 'Linked priority visible for this resident',
      alerts: residentId == 'resident-1'
          ? const ['Open incident', 'Due this shift']
          : const ['Due this shift'],
      baselinePriority: baselinePriority,
      effectivePriority: _effectivePriorityFor(residentId),
      prioritySource: _prioritySourceFor(residentId),
      activeIncidentCount: _activeIncidentCountFor(residentId),
      activeIncidents: List<ResidentIncident>.from(
        _activeIncidentsFor(residentId),
      ),
      currentTasks: residentId == 'resident-1' && !_residentTaskCompleted
          ? [
              ResidentTaskSummary(
                id: 'task-1',
                title: 'Hydration round for Margaret Evans',
                description: 'Offer fluids and record intake after breakfast.',
                status: TaskStatus.pending,
                dueAt: DateTime(2026, 4, 11, 9, 30),
                residentId: residentId,
                residentName: 'Margaret Evans',
                room: 'Room 1',
              ),
            ]
          : const [],
      timeline: List<ResidentTimelineEntry>.from(
        _timelinesByResident[residentId] ?? const [],
      ),
    );
  }

  @override
  Future<ResidentTimelineEntry> createResidentTimelineEntry({
    required String accessToken,
    required String residentId,
    required ResidentTimelineEntryDraft draft,
  }) async {
    final entry = ResidentTimelineEntry(
      id: 'timeline-${(_timelinesByResident[residentId]?.length ?? 0) + 1}',
      type: draft.type,
      title: draft.personalCareSubtype?.label ?? draft.type.label,
      details: draft.details,
      personalCareSubtype: draft.personalCareSubtype,
      authorName: 'Alex Carer',
      timestamp: DateTime(2026, 4, 11, 10, 15),
      media: const [],
    );
    _timelinesByResident.putIfAbsent(residentId, () => []).insert(0, entry);
    return entry;
  }

  @override
  Future<ResidentIncident> createResidentIncident({
    required String accessToken,
    required String residentId,
    required ResidentIncidentDraft draft,
  }) async {
    final incident = ResidentIncident(
      id: 'incident-${(_incidentsByResident[residentId]?.length ?? 0) + 1}',
      severity: draft.severity,
      status: IncidentStatus.open,
      category: draft.category,
      categoryLabel: draft.category.label,
      title: draft.title,
      details: draft.details,
      occurredAt: DateTime(2026, 4, 11, 10, 30),
      createdAt: DateTime(2026, 4, 11, 10, 31),
      createdByName: 'Alex Carer',
      evidence: const [],
    );
    _incidentsByResident.putIfAbsent(residentId, () => []).insert(0, incident);
    return incident;
  }

  @override
  Future<ShiftTask> completeTask({
    required String accessToken,
    required String taskId,
    String? note,
  }) async {
    _residentTaskCompleted = true;
    return ShiftTask(
      id: taskId,
      title: 'Hydration round for Margaret Evans',
      description: 'Offer fluids and record intake after breakfast.',
      dueAt: DateTime(2026, 4, 11, 9, 30),
      status: TaskStatus.completed,
      statusNote: note,
      residentId: 'resident-1',
      residentName: 'Margaret Evans',
      room: 'Room 1',
    );
  }

  @override
  Future<ShiftOverview> getShiftOverview({required String accessToken}) async {
    return ShiftOverview(
      currentShift: ShiftAssignment(
        id: 'shift-1',
        name: 'Morning Care Shift',
        startsAt: DateTime(2026, 4, 11, 7),
        endsAt: DateTime(2026, 4, 11, 15, 30),
        status: ShiftStatus.active,
        floorNumber: 1,
        unitLabel: 'Willow Floor',
        handoverAcknowledged: true,
        handoverAcknowledgedAt: DateTime(2026, 4, 11, 6, 55),
      ),
      assignments: [
        ShiftAssignment(
          id: 'shift-1',
          name: 'Morning Care Shift',
          startsAt: DateTime(2026, 4, 11, 7),
          endsAt: DateTime(2026, 4, 11, 15, 30),
          status: ShiftStatus.active,
          floorNumber: 1,
          unitLabel: 'Willow Floor',
          handoverAcknowledged: true,
          handoverAcknowledgedAt: DateTime(2026, 4, 11, 6, 55),
        ),
        ShiftAssignment(
          id: 'shift-2',
          name: 'Tomorrow Care Shift',
          startsAt: DateTime(2026, 4, 12, 7),
          endsAt: DateTime(2026, 4, 12, 15, 0),
          status: ShiftStatus.planned,
          floorNumber: 1,
          unitLabel: 'Willow Floor',
        ),
        ShiftAssignment(
          id: 'shift-3',
          name: 'Evening Relief Shift',
          startsAt: DateTime(2026, 4, 13, 13),
          endsAt: DateTime(2026, 4, 13, 21),
          status: ShiftStatus.planned,
          floorNumber: 2,
          unitLabel: 'Maple Floor',
        ),
      ],
    );
  }

  ResidentPriorityLevel _effectivePriorityFor(String residentId) {
    final activeIncidents = _activeIncidentsFor(residentId);
    if (activeIncidents.any(
      (incident) => incident.severity == IncidentSeverity.red,
    )) {
      return ResidentPriorityLevel.red;
    }
    if (activeIncidents.isNotEmpty) {
      return ResidentPriorityLevel.amber;
    }
    return residentId == 'resident-2'
        ? ResidentPriorityLevel.amber
        : ResidentPriorityLevel.green;
  }

  ResidentPrioritySource _prioritySourceFor(String residentId) {
    return _activeIncidentsFor(residentId).isNotEmpty
        ? ResidentPrioritySource.incidentOverride
        : ResidentPrioritySource.baseline;
  }

  int _activeIncidentCountFor(String residentId) {
    return _activeIncidentsFor(residentId).length;
  }

  List<ResidentIncident> _activeIncidentsFor(String residentId) {
    return (_incidentsByResident[residentId] ?? const [])
        .where(
          (incident) =>
              incident.status == IncidentStatus.open ||
              incident.status == IncidentStatus.acknowledged,
        )
        .toList();
  }
}
