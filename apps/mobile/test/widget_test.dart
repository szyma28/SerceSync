import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_mobile/api/api_client.dart';
import 'package:sercesync_mobile/main.dart';
import 'package:sercesync_mobile/models/handover.dart';
import 'package:sercesync_mobile/models/task.dart';
import 'package:sercesync_mobile/models/user.dart';
import 'package:sercesync_mobile/screens/resident_detail_screen.dart';
import 'package:sercesync_mobile/models/workspace_models.dart';
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
        status: 'ACTIVE',
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
        role: 'Carer',
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

  testWidgets('resident detail shows uploaded evidence on timeline entries', (
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
    await tester.scrollUntilVisible(
      find.text('Skin integrity review completed.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Skin integrity review completed.'), findsOneWidget);
    expect(find.text('1 attachment'), findsOneWidget);
    expect(find.text('skin-check.jpg'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
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
  _FakeApiClient() : super(baseUrl: 'http://localhost:3000');

  bool _residentTaskCompleted = false;

  @override
  Future<List<ShiftTask>> getCurrentTasks({required String accessToken}) async {
    return [
      ShiftTask(
        id: 'task-1',
        title: 'Hydration round for Margaret Evans',
        description: 'Offer fluids and record intake after breakfast.',
        dueAt: DateTime.now().add(const Duration(minutes: 30)),
        status: 'PENDING',
        residentId: 'resident-1',
        residentName: 'Margaret Evans',
        room: 'Room 1',
      ),
      ShiftTask(
        id: 'task-2',
        title: 'Repositioning check for Raj Patel',
        description: 'Re-check transfer risk before lunch round.',
        dueAt: DateTime.now().subtract(const Duration(minutes: 10)),
        status: 'OVERDUE',
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
    const names = [
      'Margaret Evans',
      'Raj Patel',
      'Edith Turner',
      'Thomas Green',
      'Amina Hussain',
      'Sheila Morgan',
      'Brian Foster',
      'Joan Clarke',
      'Peter Wallace',
      'Lily Bennett',
    ];

    return List<ResidentListItem>.generate(names.length, (index) {
      final roomNumber = index + 1;
      return ResidentListItem(
        id: 'resident-$roomNumber',
        fullName: names[index],
        roomLabel: 'Room $roomNumber',
        floorNumber: 1,
        unitLabel: 'Willow Floor',
        recognitionImageKey: 'resident-a',
        todaySummary: 'Assigned resident summary for room $roomNumber.',
        assignmentContext: 'Assigned to Willow Floor for this shift',
        contextLine: 'Room $roomNumber follow-up remains visible this shift',
        alerts: [roomNumber == 2 ? 'Overdue follow-up' : 'Due this shift'],
      );
    });
  }

  @override
  Future<ResidentDetail> getResidentById({
    required String accessToken,
    required String residentId,
  }) async {
    return ResidentDetail(
      id: residentId,
      fullName: residentId == 'resident-1' ? 'Margaret Evans' : 'Raj Patel',
      roomLabel: residentId == 'resident-1' ? 'Room 1' : 'Room 2',
      floorNumber: 1,
      unitLabel: 'Willow Floor',
      recognitionImageKey: 'resident-a',
      todaySummary: 'Seeded resident detail for widget testing.',
      assignmentContext: 'Assigned to Willow Floor for this shift',
      contextLine: 'Linked priority visible for this resident',
      alerts: const ['Due this shift'],
      currentTasks: _residentTaskCompleted
          ? const []
          : [
              ResidentTaskSummary(
                id: 'task-1',
                title: 'Hydration round for Margaret Evans',
                description: 'Offer fluids and record intake after breakfast.',
                status: 'PENDING',
                dueAt: DateTime(2026, 4, 11, 9, 30),
                residentId: residentId,
                residentName: 'Margaret Evans',
                room: 'Room 1',
              ),
            ],
      timeline: [
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
      ],
    );
  }

  @override
  Future<ResidentTimelineEntry> createResidentTimelineEntry({
    required String accessToken,
    required String residentId,
    required ResidentTimelineEntryDraft draft,
  }) async {
    return ResidentTimelineEntry(
      id: 'timeline-1',
      type: draft.type,
      title: draft.type.label,
      details: draft.details,
      authorName: 'Alex Carer',
      timestamp: DateTime(2026, 4, 11, 9),
      media: const [],
    );
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
      status: 'COMPLETED',
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
        status: 'ACTIVE',
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
          status: 'ACTIVE',
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
          status: 'PLANNED',
          floorNumber: 1,
          unitLabel: 'Willow Floor',
        ),
        ShiftAssignment(
          id: 'shift-3',
          name: 'Evening Relief Shift',
          startsAt: DateTime(2026, 4, 13, 13),
          endsAt: DateTime(2026, 4, 13, 21),
          status: 'PLANNED',
          floorNumber: 2,
          unitLabel: 'Maple Floor',
        ),
      ],
    );
  }
}
