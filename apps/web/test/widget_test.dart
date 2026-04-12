import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_web/main.dart';

void main() {
  testWidgets('renders the manager residents workspace', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      SerceSyncWebApp(
        apiClient: _FakeManagerApiClient(),
      ),
    );

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

    await tester.tap(find.text('Residents'));
    await tester.pumpAndSettle();

    expect(find.text('Resident Directory'), findsOneWidget);
    expect(find.text('Margaret Evans'), findsOneWidget);
    expect(find.text('New Resident'), findsOneWidget);
    expect(find.text('Save Record'), findsOneWidget);
  });
}

class _FakeManagerApiClient extends SerceSyncManagerApiClient {
  _FakeManagerApiClient() : super(baseUrl: 'http://localhost:3000');

  @override
  Future<ManagerSession> login({
    required String email,
    required String password,
  }) async {
    return const ManagerSession(
      accessToken: 'token',
      user: ManagerUser(
        id: 'manager-1',
        email: 'manager@sercesync.local',
        displayName: 'Morgan Manager',
        role: 'MANAGER',
      ),
    );
  }

  @override
  Future<ManagerDashboardSnapshot> getDashboard({
    required String accessToken,
  }) async {
    return ManagerDashboardSnapshot(
      activeShift: ManagerShiftSummary(
        id: 'shift-1',
        name: 'Morning Shift',
        unitLabel: 'Willow Floor',
        floorNumber: 1,
        startsAt: DateTime(2026, 4, 12, 7),
        endsAt: DateTime(2026, 4, 12, 14),
      ),
      metrics: const ManagerDashboardMetrics(
        overdueTasks: 1,
        escalatedItems: 1,
        unreadHandovers: 0,
        shiftCompletionPercent: 17,
      ),
      exceptionFeed: const [
        ManagerExceptionFeedItem(
          id: 'feed-1',
          title: 'Wound Dressing Change',
          residentName: 'Margaret Evans',
          roomLabel: 'Room 1',
          description: 'Dressing was loose, needed senior nurse assistance.',
          badge: 'ESCALATED',
          badgeTone: 'warning',
          dueAt: null,
        ),
      ],
      complianceSeries: [
        ManagerCompliancePoint(
          timestamp: DateTime(2026, 4, 12, 9),
          value: 94,
        ),
        ManagerCompliancePoint(
          timestamp: DateTime(2026, 4, 12, 11),
          value: 86,
        ),
        ManagerCompliancePoint(
          timestamp: DateTime(2026, 4, 12, 13),
          value: 95,
        ),
      ],
    );
  }

  @override
  Future<List<ManagerResidentRecord>> getResidents({
    required String accessToken,
  }) async {
    return const [
      ManagerResidentRecord(
        id: 'resident-1',
        fullName: 'Margaret Evans',
        roomNumber: 1,
        roomLabel: 'Room 1',
        floorNumber: 1,
        unitLabel: 'Willow Floor',
        recognitionImageKey: 'resident-a',
        careSummary: 'Hydration encouragement remains the main focus today.',
        isActive: true,
      ),
    ];
  }
}
