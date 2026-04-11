import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_mobile/api/api_client.dart';
import 'package:sercesync_mobile/models/handover.dart';
import 'package:sercesync_mobile/models/task.dart';
import 'package:sercesync_mobile/models/user.dart';
import 'package:sercesync_mobile/screens/shift_workspace_screen.dart';
import 'package:sercesync_mobile/main.dart';

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
      ),
      handover: HandoverSummary(
        id: 'handover-1',
        summary:
            'Mrs Evans needs a medication reminder. Mr Patel needs an observation follow-up.',
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
    expect(find.text('Mrs Evans'), findsOneWidget);

    await tester.tap(find.text('My Shift').last);
    await tester.pumpAndSettle();
    expect(find.text('Current Shift'), findsOneWidget);
    expect(find.text('Rota'), findsOneWidget);
  });
}

class _FakeApiClient extends SerceSyncApiClient {
  _FakeApiClient() : super(baseUrl: 'http://localhost:3000');

  @override
  Future<List<ShiftTask>> getCurrentTasks({required String accessToken}) async {
    return [
      ShiftTask(
        id: 'task-1',
        title: 'Hydration round for Mrs Evans',
        description: 'Offer fluids and record intake after breakfast.',
        dueAt: DateTime.now().add(const Duration(minutes: 30)),
        status: 'PENDING',
        residentName: 'Mrs Evans',
        room: 'Room 12A',
      ),
      ShiftTask(
        id: 'task-2',
        title: 'Escalate mobility concern review',
        description: 'Re-check transfer risk before lunch round.',
        dueAt: DateTime.now().subtract(const Duration(minutes: 10)),
        status: 'OVERDUE',
        residentName: 'Mr Patel',
        room: 'Room 7B',
      ),
    ];
  }
}
