import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_mobile/api/api_client.dart';
import 'package:sercesync_mobile/main.dart';
import 'package:sercesync_mobile/models/handover.dart';
import 'package:sercesync_mobile/models/medication_models.dart';
import 'package:sercesync_mobile/models/task.dart';
import 'package:sercesync_mobile/models/user.dart';
import 'package:sercesync_mobile/models/workspace_models.dart';
import 'package:sercesync_mobile/screens/medication_round_screen.dart';
import 'package:sercesync_mobile/screens/resident_detail_screen.dart';
import 'package:sercesync_mobile/screens/residents_screen.dart';
import 'package:sercesync_mobile/screens/shift_workspace_screen.dart';
import 'package:sercesync_mobile/screens/task_board_screen.dart';

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
    expect(find.text('Medication Safety'), findsNothing);
    expect(find.text('1 medication due within the next hour'), findsNothing);
    expect(find.text('Willow Floor · Floor 1'), findsWidgets);
    expect(find.text('Tomorrow Care Shift'), findsNothing);
    expect(find.text('Evening Relief Shift'), findsNothing);
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
          currentUserRole: AppUserRole.carer,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('resident-card-resident-1-RED')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('resident-card-resident-2-AMBER')),
      findsOneWidget,
    );
    expect(find.text('1 active incident'), findsOneWidget);
    expect(find.text('Red priority'), findsNothing);
    expect(find.text('Amber priority'), findsNothing);
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
            currentUserRole: AppUserRole.carer,
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Active incident summary'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Active incident summary'), findsOneWidget);
      expect(find.text('1 active incident'), findsWidgets);
      expect(find.text('Bathroom fall during morning checks'), findsOneWidget);
      expect(find.text('Red priority'), findsNothing);
      expect(find.text('Medication safety'), findsNothing);
      expect(find.text('About me'), findsOneWidget);
      expect(find.text('Baseline Green'), findsNothing);
      expect(
        find.textContaining('Enjoys a calm start to the day'),
        findsOneWidget,
      );
      expect(find.text('Shift summary'), findsNothing);
      expect(find.text('Care focus'), findsNothing);
      expect(
        find.text('Assigned to Willow Floor for this shift'),
        findsNothing,
      );
      expect(find.text('Due this shift'), findsNothing);
      expect(find.text('1 medication due soon'), findsNothing);
      expect(find.text('Only nurses can administer medication.'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Skin integrity review completed.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Skin integrity review completed.'), findsOneWidget);
      expect(find.text('1 attachment'), findsOneWidget);
      expect(find.text('skin-check.jpg'), findsOneWidget);
    },
  );

  testWidgets('resident detail hides routine green status in the top card', (
    WidgetTester tester,
  ) async {
    final client = _RoutineResidentApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ResidentDetailScreen(
          residentId: 'resident-routine',
          apiClient: client,
          accessToken: 'token',
          currentCarerName: 'Alex Carer',
          currentUserRole: AppUserRole.carer,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('About me'), findsOneWidget);
    expect(find.text('Room 8'), findsOneWidget);
    expect(find.text('Green priority'), findsNothing);
    expect(find.text('Baseline Green'), findsNothing);
    expect(find.text('Shift summary'), findsNothing);
    expect(find.text('Care focus'), findsNothing);
    expect(find.text('Assigned to Willow Floor for this shift'), findsNothing);
    expect(find.text('Due this shift'), findsNothing);
    expect(find.textContaining('Enjoys a familiar routine'), findsOneWidget);
  });

  testWidgets('resident detail keeps medication tools visible for nurses', (
    WidgetTester tester,
  ) async {
    final client = _FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ResidentDetailScreen(
          residentId: 'resident-1',
          apiClient: client,
          accessToken: 'token',
          currentCarerName: 'Nora Nurse',
          currentUserRole: AppUserRole.nurse,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Medication safety'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Scheduled medication'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Scheduled medication'), findsOneWidget);
    expect(find.text('PRN medication'), findsOneWidget);
    expect(find.text('Open shift medication round'), findsOneWidget);
    expect(find.text('Record PRN event'), findsOneWidget);
    final openRoundButton = find.widgetWithText(
      FilledButton,
      'Open shift medication round',
    );
    final openRoundAction = tester.widget<FilledButton>(openRoundButton);
    expect(openRoundAction.onPressed, isNotNull);
    openRoundAction.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('Round details'), findsOneWidget);
  });

  testWidgets('task board hides medication tasks for carers', (
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
        home: TaskBoardScreen(
          apiClient: client,
          accessToken: 'token',
          user: snapshot.currentUser,
          snapshot: snapshot,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hydration round for Margaret Evans'), findsOneWidget);
    expect(find.text('Medication round for Margaret Evans'), findsNothing);
    expect(find.text('Medication follow-up for Raj Patel'), findsNothing);
  });

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
          currentUserRole: AppUserRole.carer,
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
            currentUserRole: AppUserRole.carer,
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
          currentUserRole: AppUserRole.carer,
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

  testWidgets('nutrition note sheet supports structured meal intake logging', (
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
          currentUserRole: AppUserRole.carer,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Personal Care').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nutrition / Hydration').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meal type').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lunch').last);
    await tester.pumpAndSettle();

    final saveNoteButton = find.text('Save note');
    await tester.ensureVisible(saveNoteButton);
    await tester.tap(saveNoteButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Choose both meal type and amount eaten, or leave both blank.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Amount eaten').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Half eaten').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(saveNoteButton);
    await tester.tap(saveNoteButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.scrollUntilVisible(
      find.text('Lunch intake'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Lunch intake'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Half eaten'), findsOneWidget);
    expect(find.text('No additional concerns noted.'), findsOneWidget);
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
          currentUserRole: AppUserRole.carer,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Add note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personal Care').last);
    await tester.pumpAndSettle();

    expect(find.text('Care Given'), findsNothing);
    expect(find.text('Medication Note'), findsNothing);
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
          currentUserRole: AppUserRole.carer,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final reportIncidentButton = find.widgetWithText(
      OutlinedButton,
      'Report incident',
    );
    await tester.ensureVisible(reportIncidentButton);
    await tester.tap(reportIncidentButton);
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
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.scrollUntilVisible(
      find.text('Medication concern'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Medication concern'), findsOneWidget);
  });

  testWidgets('medication round screen shows due medications after handover', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final client = _FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: MedicationRoundScreen(
          apiClient: client,
          accessToken: 'token',
          shiftId: 'shift-1',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Medication Round'), findsOneWidget);
    expect(find.text('Medication recording'), findsOneWidget);
    expect(find.text('Round details'), findsOneWidget);
    expect(
      find.text(
        'Check medication label, resident identity and prescribed instructions before recording.',
      ),
      findsWidgets,
    );
    final medicationTitle = find.textContaining('Amoxicillin');
    await tester.scrollUntilVisible(
      medicationTitle,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(medicationTitle, findsOneWidget);
    expect(find.text('Administer'), findsOneWidget);
    expect(find.text('Record outcome'), findsOneWidget);
    expect(find.text('Refuse'), findsNothing);
    expect(find.text('Not available'), findsNothing);
  });

  testWidgets('PRN recording modal requires reason or symptom', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final client = _FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: ResidentDetailScreen(
          residentId: 'resident-1',
          apiClient: client,
          accessToken: 'token',
          currentCarerName: 'Nora Nurse',
          currentUserRole: AppUserRole.nurse,
        ),
      ),
    );

    await tester.pumpAndSettle();
    final recordPrnLabel = find.text('Record PRN event');
    await tester.scrollUntilVisible(
      recordPrnLabel,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final recordPrnButton = find.widgetWithText(
      OutlinedButton,
      'Record PRN event',
    );
    final prnAction = tester.widget<OutlinedButton>(recordPrnButton).onPressed;
    expect(prnAction, isNotNull);
    prnAction!.call();
    await tester.pumpAndSettle();
    final submitPrnButton = find
        .widgetWithText(FilledButton, 'Record PRN')
        .last;
    final submitAction = tester.widget<FilledButton>(submitPrnButton).onPressed;
    expect(submitAction, isNotNull);
    submitAction!.call();
    await tester.pumpAndSettle();

    expect(find.text('Reason or symptom is required.'), findsOneWidget);
  });

  testWidgets(
    'resident detail blocks medication actions until handover acknowledgement',
    (WidgetTester tester) async {
      final client = _FakeApiClient(handoverAcknowledged: false);

      await tester.pumpWidget(
        MaterialApp(
          home: ResidentDetailScreen(
            residentId: 'resident-1',
            apiClient: client,
            accessToken: 'token',
            currentCarerName: 'Nora Nurse',
            currentUserRole: AppUserRole.nurse,
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Open shift medication round'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Handover acknowledgement needed'), findsOneWidget);
      expect(
        find.textContaining('Acknowledge the current handover'),
        findsWidgets,
      );
      final openRoundButton = find.widgetWithText(
        FilledButton,
        'Open shift medication round',
      );
      expect(tester.widget<FilledButton>(openRoundButton).onPressed, isNull);

      final recordPrnButton = find.widgetWithText(
        OutlinedButton,
        'Record PRN event',
      );
      expect(tester.widget<OutlinedButton>(recordPrnButton).onPressed, isNull);
    },
  );

  testWidgets('nurse priorities surfaces the shift medication round shortcut', (
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
        summary: 'Medication round is due after acknowledgement.',
        createdAt: DateTime(2026, 4, 11, 6, 30),
        updatedAt: DateTime(2026, 4, 11, 6, 45),
      ),
      currentUser: const LoginUser(
        id: 'user-2',
        email: 'nurse@sercesync.local',
        displayName: 'Nora Nurse',
        role: AppUserRole.nurse,
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

    expect(find.text('Shift medication round'), findsOneWidget);
    expect(find.text('Open shift medication round'), findsOneWidget);

    final openRoundButton = find.widgetWithText(
      FilledButton,
      'Open shift medication round',
    );
    await tester.ensureVisible(openRoundButton);
    await tester.tap(openRoundButton);
    await tester.pumpAndSettle();

    expect(find.text('Round details'), findsOneWidget);
  });

  testWidgets(
    'nurse priorities surface medication urgency from shift summary',
    (WidgetTester tester) async {
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
          summary: 'Medication round is due after acknowledgement.',
          createdAt: DateTime(2026, 4, 11, 6, 30),
          updatedAt: DateTime(2026, 4, 11, 6, 45),
        ),
        currentUser: const LoginUser(
          id: 'user-2',
          email: 'nurse@sercesync.local',
          displayName: 'Nora Nurse',
          role: AppUserRole.nurse,
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

      expect(find.text('Medication round overdue'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Medication due soon'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Medication due soon'), findsOneWidget);
    },
  );

  testWidgets('nurse my shift no longer shows a duplicate round button', (
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
        summary: 'Medication round is due after acknowledgement.',
        createdAt: DateTime(2026, 4, 11, 6, 30),
        updatedAt: DateTime(2026, 4, 11, 6, 45),
      ),
      currentUser: const LoginUser(
        id: 'user-2',
        email: 'nurse@sercesync.local',
        displayName: 'Nora Nurse',
        role: AppUserRole.nurse,
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
    await tester.tap(find.text('My Shift').last);
    await tester.pumpAndSettle();

    expect(find.text('Medication Safety'), findsOneWidget);
    expect(find.text('Open shift medication round'), findsNothing);
    expect(
      find.text(
        'Use Priorities to open the shift medication round and see what needs recording now.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('medication round groups doses by the actual due window', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final client = _MedicationRoundGroupingApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: MedicationRoundScreen(
          apiClient: client,
          accessToken: 'token',
          shiftId: 'shift-1',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bedtime · 20:00 - 21:00'), findsOneWidget);
    expect(find.text('Morning · 20:00 - 21:00'), findsNothing);
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
          currentUserRole: AppUserRole.carer,
          highlightTaskId: 'task-1',
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Hydration round for Margaret Evans'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(
      find.byType(TextField).first,
      'Completed with resident comfortable after breakfast.',
    );
    final completeButton = find.widgetWithText(FilledButton, 'Complete').first;
    await tester.ensureVisible(completeButton);
    await tester.tap(completeButton);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Priority completed.'), findsOneWidget);
    expect(find.text('Hydration round for Margaret Evans'), findsNothing);
  });
}

class _FakeApiClient extends SerceSyncApiClient {
  _FakeApiClient({this.handoverAcknowledged = true})
    : super(baseUrl: 'http://localhost:3000') {
    final medicationTimestamp = DateTime(2026, 4, 11, 8);
    final morningSchedule = MedicationScheduleRecord(
      id: 'schedule-1',
      roundLabel: 'MORNING',
      anchorType: 'HANDOVER_ACKNOWLEDGED',
      daysOfWeek: const ['MONDAY', 'TUESDAY', 'WEDNESDAY'],
      active: true,
      createdAt: medicationTimestamp,
      updatedAt: medicationTimestamp,
      windowStartOffsetMinutes: 0,
      windowEndOffsetMinutes: 60,
    );
    final morningStock = MedicationStockSummary(
      id: 'stock-1',
      currentQuantity: '24',
      quantityUnit: 'capsule',
      updatedAt: medicationTimestamp,
      lastCheckedByUserId: 'user-2',
      lastCheckedByUserName: 'Nora Nurse',
      lastCheckedAt: medicationTimestamp,
      notes: 'Opening stock count.',
    );
    final scheduledOrder = MedicationOrderRecord(
      id: 'med-order-1',
      medicationName: 'Amoxicillin',
      formulation: 'Capsule',
      strength: '500mg',
      doseAmount: '1',
      doseUnit: 'capsule',
      route: 'oral',
      instructions: 'Give after breakfast with water.',
      startDate: medicationTimestamp,
      isActive: true,
      isControlledDrug: false,
      requiresWitness: false,
      isPRN: false,
      sourceType: 'MANUAL_ENTRY',
      createdByUserId: 'manager-1',
      updatedByUserId: 'manager-1',
      createdAt: medicationTimestamp,
      updatedAt: medicationTimestamp,
      schedules: [morningSchedule],
      stock: morningStock,
      createdByUserName: 'Morgan Manager',
      updatedByUserName: 'Morgan Manager',
    );
    final prnProtocol = PrnProtocolRecord(
      id: 'prn-1',
      indication: 'Pain',
      whenToOffer: 'Offer when Margaret reports breakthrough pain.',
      doseInstructions: 'Give one tablet and monitor comfort.',
      active: true,
      createdAt: medicationTimestamp,
      updatedAt: medicationTimestamp,
      minimumIntervalMinutes: 240,
      expectedEffect: 'Improved comfort within one hour.',
      whenToEscalate: 'Escalate if pain persists or worsens.',
    );
    final prnOrder = MedicationOrderRecord(
      id: 'med-order-prn-1',
      medicationName: 'Paracetamol',
      formulation: 'Tablet',
      strength: '500mg',
      doseAmount: '1',
      doseUnit: 'tablet',
      route: 'oral',
      instructions: 'Check prescribed PRN instructions before administration.',
      startDate: medicationTimestamp,
      isActive: true,
      isControlledDrug: false,
      requiresWitness: false,
      isPRN: true,
      sourceType: 'MANUAL_ENTRY',
      createdByUserId: 'manager-1',
      updatedByUserId: 'manager-1',
      createdAt: medicationTimestamp,
      updatedAt: medicationTimestamp,
      schedules: const [],
      prnProtocol: prnProtocol,
      createdByUserName: 'Morgan Manager',
      updatedByUserName: 'Morgan Manager',
    );
    final recentMedicationEvents = [
      MedicationAdministrationRecord(
        id: 'med-event-1',
        residentId: 'resident-1',
        residentName: 'Margaret Evans',
        roomLabel: 'Room 1',
        shiftId: 'shift-1',
        medicationOrderId: prnOrder.id,
        medicationName: prnOrder.medicationName,
        eventType: MedicationAdministrationEventType.prnAdministered,
        recordedByUserId: 'user-2',
        recordedAt: DateTime(2026, 4, 11, 7, 35),
        createdAt: DateTime(2026, 4, 11, 7, 35),
        strength: prnOrder.strength,
        formulation: prnOrder.formulation,
        doseGiven: '1',
        doseUnit: 'tablet',
        reason: 'Pain after mobilising.',
        recordedByUserName: 'Nora Nurse',
      ),
      MedicationAdministrationRecord(
        id: 'med-event-2',
        doseInstanceId: 'dose-1',
        residentId: 'resident-1',
        residentName: 'Margaret Evans',
        roomLabel: 'Room 1',
        shiftId: 'shift-1',
        medicationOrderId: scheduledOrder.id,
        medicationName: scheduledOrder.medicationName,
        eventType: MedicationAdministrationEventType.refused,
        recordedByUserId: 'user-2',
        recordedAt: DateTime(2026, 4, 10, 8, 10),
        createdAt: DateTime(2026, 4, 10, 8, 10),
        strength: scheduledOrder.strength,
        formulation: scheduledOrder.formulation,
        reason: 'Resident declined at breakfast.',
        recordedByUserName: 'Nora Nurse',
      ),
    ];
    _emarProfilesByResident['resident-1'] = ResidentEmarProfile(
      workflowNote:
          'Use the medication chart to review current orders, allergies, recent medication events, stock notes, and change history for this resident.',
      downtimeNotice:
          'If the system is unavailable, follow the care home downtime process and reconcile records afterwards.',
      safetyBanner:
          'Check medication label, resident identity and prescribed instructions before recording.',
      resident: const MedicationResidentSummary(
        id: 'resident-1',
        fullName: 'Margaret Evans',
        roomLabel: 'Room 1',
        floorNumber: 1,
        unitLabel: 'Willow Floor',
      ),
      chart: MedicationChartSummary(
        id: 'chart-1',
        status: 'ACTIVE',
        createdByUserId: 'manager-1',
        createdAt: medicationTimestamp,
        updatedAt: medicationTimestamp,
        createdByUserName: 'Morgan Manager',
      ),
      allergies: [
        MedicationAllergyRecord(
          id: 'allergy-1',
          substance: 'Penicillin',
          reaction: 'Rash',
          severity: 'High',
          recordedByUserId: 'manager-1',
          createdAt: medicationTimestamp,
          updatedAt: medicationTimestamp,
          recordedByUserName: 'Morgan Manager',
        ),
      ],
      scheduledMedications: [scheduledOrder],
      prnMedications: [prnOrder],
      recentEvents: recentMedicationEvents,
      stockOverview: [morningStock],
      changeHistory: [
        MedicationChangeLogRecord(
          id: 'change-1',
          medicationOrderId: scheduledOrder.id,
          residentId: 'resident-1',
          medicationName: scheduledOrder.medicationName,
          changedByUserId: 'manager-1',
          changeType: 'CREATED',
          reason: 'Initial medication chart entry.',
          createdAt: medicationTimestamp,
          changedByUserName: 'Morgan Manager',
        ),
      ],
    );
    _emarProfilesByResident['resident-2'] = ResidentEmarProfile(
      workflowNote:
          'Use the medication chart to review current orders, allergies, recent medication events, stock notes, and change history for this resident.',
      downtimeNotice:
          'If the system is unavailable, follow the care home downtime process and reconcile records afterwards.',
      safetyBanner:
          'Check medication label, resident identity and prescribed instructions before recording.',
      resident: const MedicationResidentSummary(
        id: 'resident-2',
        fullName: 'Raj Patel',
        roomLabel: 'Room 2',
        floorNumber: 1,
        unitLabel: 'Willow Floor',
      ),
      chart: MedicationChartSummary(
        id: 'chart-2',
        status: 'ACTIVE',
        createdByUserId: 'manager-1',
        createdAt: medicationTimestamp,
        updatedAt: medicationTimestamp,
        createdByUserName: 'Morgan Manager',
      ),
      allergies: const [],
      scheduledMedications: [scheduledOrder],
      prnMedications: const [],
      recentEvents: const [],
      stockOverview: const [],
      changeHistory: const [],
    );
    _handoverSnapshot = HandoverSnapshot(
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
        summary: 'Medication round is due after acknowledgement.',
        createdAt: DateTime(2026, 4, 11, 6, 30),
        updatedAt: DateTime(2026, 4, 11, 6, 45),
      ),
      currentUser: const LoginUser(
        id: 'user-2',
        email: 'nurse@sercesync.local',
        displayName: 'Nora Nurse',
        role: AppUserRole.nurse,
      ),
      acknowledged: handoverAcknowledged,
      acknowledgedAt: handoverAcknowledged
          ? DateTime(2026, 4, 11, 6, 55)
          : null,
    );
    _medicationRound = MedicationRoundSnapshot(
      workflowNote:
          'Use this round to record scheduled doses, outcome variances, and medication notes for residents on this shift.',
      safetyBanner:
          'Check medication label, resident identity and prescribed instructions before recording.',
      shift: MedicationRoundShift(
        id: 'shift-1',
        name: 'Morning Care Shift',
        floorNumber: 1,
        unitLabel: 'Willow Floor',
        startsAt: DateTime(2026, 4, 11, 7),
        endsAt: DateTime(2026, 4, 11, 15, 30),
        handoverAcknowledged: handoverAcknowledged,
        handoverAcknowledgedAt: handoverAcknowledged
            ? DateTime(2026, 4, 11, 6, 55)
            : null,
      ),
      witnessCandidates: const [
        MedicationRoundWitnessCandidate(
          id: 'user-3',
          displayName: 'Sasha Senior',
          role: 'nurse',
        ),
      ],
      groupedRounds: [
        MedicationRoundGroup(
          roundLabel: 'MORNING',
          items: [
            MedicationRoundItem(
              id: 'dose-1',
              residentId: 'resident-1',
              residentName: 'Margaret Evans',
              roomLabel: 'Room 1',
              floorNumber: 1,
              unitLabel: 'Willow Floor',
              medicationOrderId: scheduledOrder.id,
              medicationName: scheduledOrder.medicationName,
              doseAmount: scheduledOrder.doseAmount,
              doseUnit: scheduledOrder.doseUnit,
              route: scheduledOrder.route,
              instructions: scheduledOrder.instructions,
              roundLabel: 'MORNING',
              anchorType: 'HANDOVER_ACKNOWLEDGED',
              dueWindowStart: DateTime(2026, 4, 11, 6, 55),
              dueWindowEnd: DateTime(2026, 4, 11, 7, 55),
              status: MedicationDoseStatus.due,
              generatedAt: DateTime(2026, 4, 11, 6, 55),
              requiresWitness: false,
              allergies: const [
                {'substance': 'Penicillin', 'reaction': 'Rash'},
              ],
              formulation: scheduledOrder.formulation,
              strength: scheduledOrder.strength,
            ),
          ],
        ),
      ],
    );

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

  final bool handoverAcknowledged;
  bool _residentTaskCompleted = false;
  final Map<String, ResidentEmarProfile> _emarProfilesByResident = {};
  final Map<String, List<ResidentTimelineEntry>> _timelinesByResident = {};
  final Map<String, List<ResidentIncident>> _incidentsByResident = {};
  late final HandoverSnapshot _handoverSnapshot;
  late MedicationRoundSnapshot _medicationRound;

  @override
  Future<HandoverSnapshot> getCurrentHandover({
    required String accessToken,
  }) async {
    return _handoverSnapshot;
  }

  @override
  Future<ResidentEmarProfile> getResidentEmar({
    required String accessToken,
    required String residentId,
  }) async {
    final profile = _emarProfilesByResident[residentId];
    if (profile == null) {
      throw const ApiException('Medication details are not available.');
    }
    return profile;
  }

  @override
  Future<MedicationRoundSnapshot> getMedicationRound({
    required String accessToken,
    required String shiftId,
  }) async {
    return _medicationRound;
  }

  @override
  Future<PrnEventResult> recordPrnEvent({
    required String accessToken,
    required String residentId,
    required String medicationOrderId,
    required MedicationAdministrationEventType eventType,
    required String reason,
    String? doseGiven,
    String? doseUnit,
    String? notes,
    String? witnessUserId,
  }) async {
    final profile = _emarProfilesByResident[residentId];
    if (profile == null) {
      throw const ApiException('Medication details are not available.');
    }

    final order = profile.prnMedications.firstWhere(
      (candidate) => candidate.id == medicationOrderId,
    );
    final event = MedicationAdministrationRecord(
      id: 'med-event-${profile.recentEvents.length + 1}',
      residentId: residentId,
      residentName: profile.resident.fullName,
      roomLabel: profile.resident.roomLabel,
      shiftId: _handoverSnapshot.shift.id,
      medicationOrderId: medicationOrderId,
      medicationName: order.medicationName,
      eventType: eventType,
      recordedByUserId: _handoverSnapshot.currentUser.id,
      recordedAt: DateTime(2026, 4, 11, 8, 5),
      createdAt: DateTime(2026, 4, 11, 8, 5),
      strength: order.strength,
      formulation: order.formulation,
      doseGiven: doseGiven,
      doseUnit: doseUnit,
      reason: reason,
      notes: notes,
      recordedByUserName: _handoverSnapshot.currentUser.displayName,
      witnessUserId: witnessUserId,
    );

    _emarProfilesByResident[residentId] = ResidentEmarProfile(
      workflowNote: profile.workflowNote,
      downtimeNotice: profile.downtimeNotice,
      safetyBanner: profile.safetyBanner,
      resident: profile.resident,
      chart: profile.chart,
      allergies: profile.allergies,
      scheduledMedications: profile.scheduledMedications,
      prnMedications: profile.prnMedications,
      recentEvents: [event, ...profile.recentEvents],
      stockOverview: profile.stockOverview,
      changeHistory: profile.changeHistory,
    );

    return PrnEventResult(
      workflowNote: profile.workflowNote,
      warning:
          'This PRN was last recorded at 07:35. Check prescribed instructions before administration.',
      administrationEvent: event,
    );
  }

  @override
  Future<List<ShiftTask>> getCurrentTasks({required String accessToken}) async {
    return [
      ShiftTask(
        id: 'task-1',
        title: 'Hydration round for Margaret Evans',
        description: 'Offer fluids and record intake after breakfast.',
        dueAt: DateTime.now().add(const Duration(minutes: 30)),
        status: TaskStatus.pending,
        focus: TaskFocus.hydration,
        clinicalPriority: TaskClinicalPriority.routine,
        residentId: 'resident-1',
        residentName: 'Margaret Evans',
        room: 'Room 1',
      ),
      ShiftTask(
        id: 'task-2',
        title: 'Medication round for Margaret Evans',
        description: 'Administer lunchtime medication and confirm swallow.',
        dueAt: DateTime.now().add(const Duration(minutes: 15)),
        status: TaskStatus.pending,
        focus: TaskFocus.medication,
        clinicalPriority: TaskClinicalPriority.timeCritical,
        residentId: 'resident-1',
        residentName: 'Margaret Evans',
        room: 'Room 1',
        canComplete: false,
        canDefer: false,
        canEscalate: false,
        actionRestrictionReason: 'Only nurses can administer medication.',
      ),
      ShiftTask(
        id: 'task-3',
        title: 'Medication follow-up for Raj Patel',
        description: 'Overdue analgesia review still needs documenting.',
        dueAt: DateTime.now().subtract(const Duration(minutes: 10)),
        status: TaskStatus.overdue,
        focus: TaskFocus.medication,
        clinicalPriority: TaskClinicalPriority.priority,
        residentId: 'resident-2',
        residentName: 'Raj Patel',
        room: 'Room 2',
        canComplete: false,
        canDefer: false,
        canEscalate: false,
        actionRestrictionReason: 'Only nurses can administer medication.',
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
        aboutMe: '',
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
        aboutMe: '',
        todaySummary: 'Baseline amber due to ongoing mobility support.',
        assignmentContext: 'Assigned to Willow Floor for this shift',
        contextLine: 'Routine mobility support scheduled later in the shift.',
        alerts: const [],
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
      aboutMe: residentId == 'resident-1'
          ? 'Enjoys a calm start to the day, warm drinks, and friendly step-by-step support before care begins.'
          : 'Appreciates clear communication, predictable routines, and gentle reassurance during mobility support.',
      todaySummary: residentId == 'resident-1'
          ? 'Monitor mobility, hydration, and incident follow-up.'
          : 'Continue baseline amber support for mobility and reassurance.',
      assignmentContext: 'Assigned to Willow Floor for this shift',
      contextLine: 'Linked priority visible for this resident',
      alerts: residentId == 'resident-1' ? const ['Open incident'] : const [],
      baselinePriority: baselinePriority,
      effectivePriority: _effectivePriorityFor(residentId),
      prioritySource: _prioritySourceFor(residentId),
      activeIncidentCount: _activeIncidentCountFor(residentId),
      medicationSummary: residentId == 'resident-1'
          ? const MedicationTaskSummary(
              total: 1,
              overdue: 0,
              dueWithinHour: 1,
              highPriority: 1,
              headline: '1 medication due soon',
              warnings: [
                '1 medication due within the next hour',
                '1 high-priority medication active this shift',
              ],
            )
          : const MedicationTaskSummary(
              total: 1,
              overdue: 1,
              dueWithinHour: 0,
              highPriority: 1,
              headline: '1 medication overdue',
              warnings: [
                '1 medication overdue',
                '1 high-priority medication active this shift',
              ],
            ),
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
                focus: TaskFocus.hydration,
                clinicalPriority: TaskClinicalPriority.routine,
                residentId: residentId,
                residentName: 'Margaret Evans',
                room: 'Room 1',
              ),
              ResidentTaskSummary(
                id: 'task-2',
                title: 'Medication round for Margaret Evans',
                description:
                    'Administer lunchtime medication and confirm swallow.',
                status: TaskStatus.pending,
                dueAt: DateTime(2026, 4, 11, 10),
                focus: TaskFocus.medication,
                clinicalPriority: TaskClinicalPriority.timeCritical,
                residentId: residentId,
                residentName: 'Margaret Evans',
                room: 'Room 1',
                canComplete: false,
                canDefer: false,
                canEscalate: false,
                actionRestrictionReason:
                    'Only nurses can administer medication.',
              ),
            ]
          : residentId == 'resident-1'
          ? [
              ResidentTaskSummary(
                id: 'task-2',
                title: 'Medication round for Margaret Evans',
                description:
                    'Administer lunchtime medication and confirm swallow.',
                status: TaskStatus.pending,
                dueAt: DateTime(2026, 4, 11, 10),
                focus: TaskFocus.medication,
                clinicalPriority: TaskClinicalPriority.timeCritical,
                residentId: 'resident-1',
                residentName: 'Margaret Evans',
                room: 'Room 1',
                canComplete: false,
                canDefer: false,
                canEscalate: false,
                actionRestrictionReason:
                    'Only nurses can administer medication.',
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
    final generatedDetails =
        draft.details.trim().isEmpty &&
            draft.mealType != null &&
            draft.mealIntakeAmount != null
        ? 'No additional concerns noted.'
        : draft.details;
    final entry = ResidentTimelineEntry(
      id: 'timeline-${(_timelinesByResident[residentId]?.length ?? 0) + 1}',
      type: draft.type,
      title: draft.mealType != null && draft.mealIntakeAmount != null
          ? '${draft.mealType!.label} intake'
          : draft.personalCareSubtype?.label ?? draft.type.label,
      details: generatedDetails,
      personalCareSubtype: draft.personalCareSubtype,
      mealType: draft.mealType,
      mealIntakeAmount: draft.mealIntakeAmount,
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
      focus: TaskFocus.hydration,
      clinicalPriority: TaskClinicalPriority.routine,
      residentId: 'resident-1',
      residentName: 'Margaret Evans',
      room: 'Room 1',
    );
  }

  @override
  Future<ShiftOverview> getShiftOverview({required String accessToken}) async {
    final now = DateTime.now();

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
      medicationSummary: const MedicationTaskSummary(
        total: 2,
        overdue: 1,
        dueWithinHour: 1,
        highPriority: 2,
        headline: '1 medication overdue',
        warnings: [
          '1 medication overdue',
          '1 medication due within the next hour',
          '2 high-priority medications active this shift',
        ],
      ),
      medicationOperationalSummary: MedicationShiftOperationalSummary(
        residents: [
          MedicationResidentOperationalSummary(
            resident: const MedicationOperationalResidentIdentity(
              id: 'resident-1',
              fullName: 'Margaret Evans',
              roomLabel: 'Room 1',
              floorNumber: 1,
              unitLabel: 'Willow Floor',
            ),
            taskSummaryCompatible: const MedicationTaskSummary(
              total: 1,
              overdue: 0,
              dueWithinHour: 1,
              highPriority: 1,
              headline: '1 medication due soon',
              warnings: ['1 medication due within the next hour'],
            ),
            openDoses: MedicationOperationalOpenDoseSummary(
              due: 1,
              overdue: 0,
              dueWithinHour: 1,
              nextDueAt: now.add(const Duration(minutes: 20)),
            ),
          ),
          MedicationResidentOperationalSummary(
            resident: const MedicationOperationalResidentIdentity(
              id: 'resident-2',
              fullName: 'Raj Patel',
              roomLabel: 'Room 2',
              floorNumber: 1,
              unitLabel: 'Willow Floor',
            ),
            taskSummaryCompatible: const MedicationTaskSummary(
              total: 1,
              overdue: 1,
              dueWithinHour: 0,
              highPriority: 1,
              headline: '1 medication overdue',
              warnings: ['1 medication overdue'],
            ),
            openDoses: MedicationOperationalOpenDoseSummary(
              due: 0,
              overdue: 1,
              dueWithinHour: 0,
              nextDueAt: now.subtract(const Duration(minutes: 15)),
            ),
          ),
        ],
      ),
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

class _RoutineResidentApiClient extends _FakeApiClient {
  @override
  Future<ResidentDetail> getResidentById({
    required String accessToken,
    required String residentId,
  }) async {
    if (residentId != 'resident-routine') {
      return super.getResidentById(
        accessToken: accessToken,
        residentId: residentId,
      );
    }

    return const ResidentDetail(
      id: 'resident-routine',
      fullName: 'Amir Hussain',
      roomLabel: 'Room 8',
      floorNumber: 1,
      unitLabel: 'Willow Floor',
      recognitionImageKey: 'resident-a',
      aboutMe:
          'Enjoys a familiar routine, warm drinks, and calm encouragement before care begins.',
      todaySummary: 'Continue reassurance and keep a calm pace during care.',
      assignmentContext: 'Assigned to Willow Floor for this shift',
      contextLine: 'Routine support remains steady this shift.',
      alerts: [],
      baselinePriority: ResidentPriorityLevel.green,
      effectivePriority: ResidentPriorityLevel.green,
      prioritySource: ResidentPrioritySource.baseline,
      activeIncidentCount: 0,
      medicationSummary: MedicationTaskSummary(),
      activeIncidents: [],
      currentTasks: [
        ResidentTaskSummary(
          id: 'routine-task-1',
          title: 'Hydration prompt for Amir Hussain',
          description: 'Offer a preferred drink at the next check-in.',
          dueAt: null,
          status: TaskStatus.pending,
          focus: TaskFocus.hydration,
          clinicalPriority: TaskClinicalPriority.routine,
          residentId: 'resident-routine',
          residentName: 'Amir Hussain',
          room: 'Room 8',
          canComplete: true,
          canDefer: false,
          canEscalate: false,
        ),
      ],
      timeline: [],
    );
  }
}

class _MedicationRoundGroupingApiClient extends _FakeApiClient {
  @override
  Future<MedicationRoundSnapshot> getMedicationRound({
    required String accessToken,
    required String shiftId,
  }) async {
    return MedicationRoundSnapshot(
      workflowNote:
          'Use this round to record scheduled doses, outcome variances, and medication notes for residents on this shift.',
      safetyBanner:
          'Check medication label, resident identity and prescribed instructions before recording.',
      shift: MedicationRoundShift(
        id: 'shift-1',
        name: 'Morning Care Shift',
        floorNumber: 1,
        unitLabel: 'Willow Floor',
        startsAt: DateTime(2026, 4, 11, 7),
        endsAt: DateTime(2026, 4, 11, 15, 30),
        handoverAcknowledged: true,
        handoverAcknowledgedAt: DateTime(2026, 4, 11, 6, 55),
      ),
      witnessCandidates: const [],
      groupedRounds: [
        MedicationRoundGroup(
          roundLabel: 'MORNING',
          items: [
            MedicationRoundItem(
              id: 'dose-bedtime-1',
              residentId: 'resident-1',
              residentName: 'Joan Clarke',
              roomLabel: 'Room 8',
              floorNumber: 1,
              unitLabel: 'Willow Floor',
              medicationOrderId: 'order-1',
              medicationName: 'Aspirin',
              formulation: 'tablet',
              strength: '75mg',
              doseAmount: '1',
              doseUnit: 'tablet',
              route: 'oral',
              instructions: 'Give with the bedtime round.',
              roundLabel: 'MORNING',
              anchorType: 'FIXED_TIME',
              dueWindowStart: DateTime(2026, 4, 11, 20),
              dueWindowEnd: DateTime(2026, 4, 11, 21),
              status: MedicationDoseStatus.refused,
              generatedAt: DateTime(2026, 4, 11, 20),
              requiresWitness: false,
              allergies: const [],
            ),
          ],
        ),
        MedicationRoundGroup(
          roundLabel: 'MIDDAY',
          items: [
            MedicationRoundItem(
              id: 'dose-bedtime-2',
              residentId: 'resident-2',
              residentName: 'Casey Stone',
              roomLabel: 'Room 9',
              floorNumber: 1,
              unitLabel: 'Willow Floor',
              medicationOrderId: 'order-2',
              medicationName: 'Melatonin',
              formulation: 'tablet',
              strength: '3mg',
              doseAmount: '1',
              doseUnit: 'tablet',
              route: 'oral',
              instructions: 'Record with the bedtime window.',
              roundLabel: 'MIDDAY',
              anchorType: 'FIXED_TIME',
              dueWindowStart: DateTime(2026, 4, 11, 20),
              dueWindowEnd: DateTime(2026, 4, 11, 21),
              status: MedicationDoseStatus.due,
              generatedAt: DateTime(2026, 4, 11, 20),
              requiresWitness: false,
              allergies: const [],
            ),
          ],
        ),
      ],
    );
  }
}
