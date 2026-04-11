import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_web/main.dart';

void main() {
  testWidgets('renders the manager residents workspace', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SerceSyncWebApp(
        apiClient: _FakeManagerApiClient(),
      ),
    );

    expect(find.text('Manager Sign In'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email Address'),
      'manager@sercesync.local',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Password123!',
    );
    await tester.tap(find.text('Open Residents Workspace'));
    await tester.pumpAndSettle();

    expect(find.text('Residents Directory'), findsOneWidget);
    expect(find.text('Margaret Evans'), findsOneWidget);
    expect(find.text('Create Resident'), findsOneWidget);
    expect(find.text('Save Resident'), findsOneWidget);
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
