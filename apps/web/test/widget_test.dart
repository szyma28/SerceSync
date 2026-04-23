import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_web/main.dart';
import 'package:sercesync_web/src/manager/manager_reporting.dart';
import 'package:sercesync_web/src/manager/manager_shared.dart';

class _FakeManagerFileDownloader implements ManagerFileDownloader {
  const _FakeManagerFileDownloader({this.shouldSucceed = true});

  final bool shouldSucceed;

  @override
  Future<bool> downloadText({
    required String fileName,
    required String contents,
    String mimeType = 'text/plain;charset=utf-8',
  }) async {
    return shouldSucceed;
  }
}

Finder _residentBaselinePriorityField() {
  return find.byWidgetPredicate(
    (widget) => widget is DropdownButtonFormField<ManagerResidentPriorityLevel>,
    description: 'resident baseline priority dropdown',
  );
}

Future<void> _selectResidentBaselinePriority(
  WidgetTester tester,
  String label,
) async {
  await tester.ensureVisible(_residentBaselinePriorityField());
  await tester.tap(_residentBaselinePriorityField());
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  test('CSV export cells are neutralised for spreadsheet safety', () {
    expect(escapeCsvCellForExport('=2+2'), "\"'=2+2\"");
    expect(escapeCsvCellForExport('@incident'), "\"'@incident\"");
    expect(escapeCsvCellForExport('Routine note'), '"Routine note"');
  });

  test(
    'parses medication exceptions without an explicit id by falling back to doseInstanceId',
    () {
      final snapshot = ManagerDashboardSnapshot.fromJson({
        'activeShift': {
          'id': 'shift-1',
          'name': 'Willow Morning Shift',
          'status': 'ACTIVE',
          'unitLabel': 'Willow Floor',
          'floorNumber': 1,
          'startsAt': '2026-04-18T07:00:00.000Z',
          'endsAt': '2026-04-18T15:00:00.000Z',
        },
        'activeShifts': [
          {
            'id': 'shift-1',
            'name': 'Willow Morning Shift',
            'status': 'ACTIVE',
            'unitLabel': 'Willow Floor',
            'floorNumber': 1,
            'startsAt': '2026-04-18T07:00:00.000Z',
            'endsAt': '2026-04-18T15:00:00.000Z',
          },
        ],
        'metrics': {
          'overdueTasks': 1,
          'escalatedItems': 0,
          'unreadHandovers': 0,
          'shiftCompletionPercent': 50,
          'activeIncidents': 1,
        },
        'activityFeed': const [],
        'exceptionFeed': const [],
        'complianceSeries': const [],
        'medicationOverview': {
          'workflowNote': 'Workflow note',
          'totals': const {
            'overdue': 1,
            'refused': 0,
            'omitted': 0,
            'delayed': 0,
            'notAvailable': 0,
            'held': 0,
            'recentPrnAdministrations': 0,
          },
          'exceptions': [
            {
              'residentId': 'resident-1',
              'residentName': 'Ava Jones',
              'roomLabel': 'Room 2',
              'medicationOrderId': 'order-1',
              'medicationName': 'Ramipril',
              'dueWindowStart': '2026-04-18T11:00:00.000Z',
              'dueWindowEnd': '2026-04-18T12:00:00.000Z',
              'status': 'OVERDUE',
              'recordedByUserId': null,
              'recordedByUserName': null,
              'recordedAt': null,
              'reason': null,
              'notes': null,
              'residentEmarPath': '/residents/resident-1/emar',
              'doseInstanceId': 'dose-1',
              'roundLabel': 'MIDDAY',
            },
          ],
          'recentPrnEvents': const [],
          'recentChanges': const [],
        },
      });

      expect(snapshot.medicationOverview, isNotNull);
      expect(snapshot.medicationOverview!.exceptions.single.id, 'dose-1');
    },
  );

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

      await tester.pumpWidget(
        SerceSyncWebApp(
          apiClient: apiClient,
          fileDownloader: const _FakeManagerFileDownloader(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manager dashboard'), findsOneWidget);
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

    await tester.pumpWidget(
      SerceSyncWebApp(
        apiClient: apiClient,
        fileDownloader: const _FakeManagerFileDownloader(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manager workspace'), findsOneWidget);
    expect(find.text('Manager dashboard'), findsNothing);
    expect(apiClient.requestLog.first, 'restoreSession');
  });

  testWidgets('shows workspace shell placeholders while restoring a session', (
    WidgetTester tester,
  ) async {
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

    await tester.pumpWidget(
      SerceSyncWebApp(
        apiClient: apiClient,
        fileDownloader: const _FakeManagerFileDownloader(),
      ),
    );

    expect(find.byType(ManagerSkeletonCard), findsWidgets);
    expect(find.text('Manager workspace'), findsNothing);
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

    await tester.pumpWidget(
      SerceSyncWebApp(
        apiClient: apiClient,
        fileDownloader: const _FakeManagerFileDownloader(),
      ),
    );
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
      lessThan(apiClient.requestLog.indexOf('dashboard:global')),
    );
  });

  testWidgets('dashboard renders active incidents card and incident actions', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    expect(find.text('Staff on duty'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('team members live now'), findsOneWidget);
    expect(find.text('9 carers • 3 nurses'), findsOneWidget);
    expect(find.text('ACTIVE INCIDENTS'), findsOneWidget);
    expect(find.text('Current follow-up'), findsOneWidget);
    expect(find.text('Recent care activity'), findsOneWidget);
    expect(
      find.text('Morning shower support completed safely.'),
      findsOneWidget,
    );
    expect(find.text('Hallway Fall'), findsOneWidget);
    expect(find.text('Acknowledge'), findsWidgets);
    expect(find.text('Resolve'), findsOneWidget);
  });

  testWidgets('dashboard header shows a live freshness label', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text && (widget.data?.startsWith('Live ') ?? false),
        description: 'dashboard live freshness label',
      ),
      findsOneWidget,
    );
  });

  testWidgets('dashboard refreshes when any active shift stream updates', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    expect(
      apiClient.requestLog.where((entry) => entry == 'dashboard:global').length,
      1,
    );

    apiClient.emitDashboardUpdate('shift-2');
    await tester.pump();
    await tester.pump();

    expect(
      apiClient.requestLog.where((entry) => entry == 'dashboard:global').length,
      2,
    );

    apiClient.emitDashboardUpdate('shift-1');
    await tester.pump();
    await tester.pump();

    expect(
      apiClient.requestLog.where((entry) => entry == 'dashboard:global').length,
      3,
    );
  });

  testWidgets('dashboard rows render location context across active floors', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    expect(
      find.text('Margaret Evans • Willow Floor • Floor 1 • Room 1'),
      findsWidgets,
    );
    expect(
      find.text('Thea Green • Willow Floor • Floor 1 • Room 4'),
      findsOneWidget,
    );
    expect(
      find.text('Daniel Miller • Maple Floor • Floor 2 • Room 11'),
      findsOneWidget,
    );
    expect(
      find.text('Agnes Cook • Cedar Floor • Floor 3 • Room 21'),
      findsWidgets,
    );
    expect(find.text('Staff on duty'), findsOneWidget);
  });

  testWidgets('incident actions use the incident row shift id', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    await tester.ensureVisible(
      find.byKey(const ValueKey('exception-row-incident-cedar-red')),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('exception-row-incident-cedar-red')),
        matching: find.text('Acknowledge'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      apiClient.requestLog,
      contains('acknowledge:incident-cedar-red:shift-3'),
    );
  });

  testWidgets('incident acknowledge uses the contextual success notice', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    final targetRow = find.byKey(
      const ValueKey('exception-row-incident-open-red'),
    );
    await tester.ensureVisible(targetRow);
    await tester.tap(
      find.descendant(of: targetRow, matching: find.text('Acknowledge')),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Incident marked as acknowledged.'), findsOneWidget);
  });

  testWidgets(
    'dashboard refreshes to the remaining active shift when coverage changes',
    (WidgetTester tester) async {
      final apiClient = _FakeManagerApiClient();
      await _pumpManagerWorkspace(tester, apiClient: apiClient);

      apiClient.enqueueActiveShiftsResponse(
        apiClient.shiftList(const ['shift-3']),
      );
      apiClient.setActiveShifts(apiClient.shiftList(const ['shift-3']));

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('staff-roster-shift-3')),
        findsOneWidget,
      );
      expect(find.text('Cedar Distress Episode'), findsOneWidget);
      expect(find.text('Hallway Fall'), findsNothing);
      expect(
        apiClient.requestLog.skip(apiClient.requestLog.length - 2).toList(),
        ['activeShifts', 'dashboard:global'],
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

    expect(find.text('Acknowledge'), findsWidgets);
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

    expect(find.text('New Resident Record'), findsNothing);

    await tester.tap(find.text('New Resident'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<DropdownButtonFormField<ManagerResidentPriorityLevel>>(
            _residentBaselinePriorityField(),
          )
          .initialValue,
      ManagerResidentPriorityLevel.green,
    );
    await _selectResidentBaselinePriority(tester, 'Amber baseline');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Resident Name'),
      'Holly Marsh',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Room'), '12');
    await tester.enterText(find.widgetWithText(TextFormField, 'Floor'), '2');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unit Label'),
      'Maple Floor',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'About Me'),
      'Prefers direct introductions and a slower pace before personal care.',
    );

    await tester.ensureVisible(find.text('Save Record'));
    await tester.tap(find.text('Save Record'));
    await tester.pumpAndSettle();

    expect(apiClient.lastSavedDraft, isNotNull);
    expect(
      apiClient.lastSavedDraft!.baselinePriority,
      ManagerResidentPriorityLevel.amber,
    );
    expect(
      apiClient.lastSavedDraft!.aboutMe,
      'Prefers direct introductions and a slower pace before personal care.',
    );
  });

  testWidgets('resident reset restores the baseline priority selection', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    await tester.tap(find.text('Residents'));
    await tester.pumpAndSettle();

    expect(find.text('New Resident Record'), findsNothing);

    await tester.tap(find.text('New Resident'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<DropdownButtonFormField<ManagerResidentPriorityLevel>>(
            _residentBaselinePriorityField(),
          )
          .initialValue,
      ManagerResidentPriorityLevel.green,
    );
    await _selectResidentBaselinePriority(tester, 'Amber baseline');

    expect(
      tester
          .widget<DropdownButtonFormField<ManagerResidentPriorityLevel>>(
            _residentBaselinePriorityField(),
          )
          .initialValue,
      ManagerResidentPriorityLevel.amber,
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<DropdownButtonFormField<ManagerResidentPriorityLevel>>(
            _residentBaselinePriorityField(),
          )
          .initialValue,
      ManagerResidentPriorityLevel.green,
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
      find.widgetWithText(TextFormField, 'About Me'),
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

  testWidgets('resident editor only appears after tapping new resident', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    await tester.tap(find.text('Residents'));
    await tester.pumpAndSettle();

    expect(find.text('New Resident Record'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Resident Name'), findsNothing);

    await tester.tap(find.text('New Resident'));
    await tester.pumpAndSettle();

    expect(find.text('New Resident Record'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Resident Name'), findsOneWidget);

    await tester.ensureVisible(find.text('Close'));
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('New Resident Record'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Resident Name'), findsNothing);
  });

  testWidgets('resident rows render priority and incident count pills', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    await tester.tap(find.text('Residents'));
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
    expect(find.text('Incident override'), findsOneWidget);
    expect(find.text('Priority RED'), findsNothing);
  });

  testWidgets('resident directory renders all thirty seeded residents', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    await tester.tap(find.text('Residents'));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsNWidgets(30));
    await tester.ensureVisible(
      find.byKey(const ValueKey('resident-card-resident-30-GREEN')),
    );
    expect(find.text('Ryan Coleman'), findsOneWidget);
    expect(find.text('Room 30'), findsOneWidget);
  });

  testWidgets('resident directory exposes the medication chart entry point', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    await tester.tap(find.text('Residents'));
    await tester.pumpAndSettle();

    final emarButton = find.byKey(const ValueKey('resident-emar-resident-1'));
    expect(emarButton, findsOneWidget);
    expect(
      find.descendant(of: emarButton, matching: find.text('Medication chart')),
      findsOneWidget,
    );

    await tester.tap(emarButton);
    await tester.pumpAndSettle();

    expect(find.text('Margaret Evans medication chart'), findsOneWidget);
    expect(find.text('Add medication'), findsOneWidget);
    expect(find.text('Record allergy'), findsWidgets);
    expect(
      find.textContaining(
        'Review current orders, allergies, recent medication events',
      ),
      findsOneWidget,
    );
    expect(find.text('Scheduled medication'), findsOneWidget);
    expect(find.text('PRN medication'), findsWidgets);
    expect(find.text('Amoxicillin 500mg'), findsWidgets);
    expect(find.text('Paracetamol 500mg'), findsWidgets);
    expect(apiClient.requestLog, contains('residentEmar:resident-1'));
  });

  testWidgets(
    'manager medication overview shows overdue refused and omitted events',
    (WidgetTester tester) async {
      final apiClient = _FakeManagerApiClient();
      await _pumpManagerWorkspace(tester, apiClient: apiClient);

      expect(find.text('Medication review'), findsOneWidget);
      expect(find.text('OVERDUE'), findsWidgets);
      expect(find.text('REFUSED'), findsWidgets);
      expect(find.text('OMITTED'), findsWidgets);
      expect(find.text('Margaret Evans • Room 1'), findsWidgets);
      expect(
        find.textContaining('Amoxicillin 500mg • Morning • overdue'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Paracetamol 500mg • Custom • refused'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Lactulose 10ml • Evening • omitted'),
        findsOneWidget,
      );
      expect(find.textContaining('Recent PRN activity'), findsOneWidget);
    },
  );

  testWidgets('staff tab is removed from the manager sidebar', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    expect(find.text('Staff & Shifts'), findsNothing);
  });

  testWidgets('reporting tab renders the lightweight CQC evidence pack', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    await tester.tap(find.text('Reporting'));
    await tester.pumpAndSettle();

    expect(find.text('CQC evidence pack'), findsOneWidget);
    expect(find.text('Live export snapshot'), findsWidgets);
    expect(find.text('Summary CSV'), findsOneWidget);
    expect(find.text('Incident register CSV'), findsOneWidget);
    expect(find.text('Medication audit CSV'), findsOneWidget);
    expect(find.text('Incident register ready for export'), findsOneWidget);
    expect(find.text('Resident records ready for export'), findsOneWidget);
    expect(find.text('Downtime pack'), findsWidgets);
  });

  testWidgets('reporting tab exports summary incident and resident packs', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeManagerApiClient();
    await _pumpManagerWorkspace(tester, apiClient: apiClient);

    await tester.tap(find.text('Reporting'));
    await tester.pumpAndSettle();

    expect(find.text('Export Data'), findsNothing);

    await tester.tap(find.text('Summary CSV'));
    await tester.pump();

    expect(
      find.text('Download started for cqc-evidence-pack-summary.csv.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Incident register CSV'));
    await tester.pump();

    expect(
      find.text('Download started for incident-register.csv.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Downtime pack').first);
    await tester.tap(find.text('Downtime pack').first);
    await tester.pump();

    expect(
      find.text('Download started for resident-01-emar-downtime-pack.csv.'),
      findsOneWidget,
    );
    expect(
      apiClient.requestLog,
      contains('residentDowntimePackExport:resident-1'),
    );
  });

  testWidgets(
    'reporting tab shows a helpful message when download start fails',
    (WidgetTester tester) async {
      final apiClient = _FakeManagerApiClient();
      await tester.binding.setSurfaceSize(const Size(1440, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        SerceSyncWebApp(
          apiClient: apiClient,
          fileDownloader: const _FakeManagerFileDownloader(
            shouldSucceed: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

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

      await tester.tap(find.text('Reporting'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Summary CSV'));
      await tester.pump();

      expect(
        find.text(
          'Could not start download for cqc-evidence-pack-summary.csv.',
        ),
        findsOneWidget,
      );
    },
  );
}

Future<void> _pumpManagerWorkspace(
  WidgetTester tester, {
  required _FakeManagerApiClient apiClient,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    SerceSyncWebApp(
      apiClient: apiClient,
      fileDownloader: const _FakeManagerFileDownloader(),
    ),
  );
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

  expect(find.text('Manager dashboard'), findsOneWidget);
}

List<ManagerUser> _assignedUsers(String shiftId) {
  switch (shiftId) {
    case 'shift-1':
      return const [
        ManagerUser(
          id: 'carer-1',
          email: 'eryk.carer@sercesync.local',
          displayName: 'Eryk Carer',
          role: ManagerUserRole.carer,
        ),
        ManagerUser(
          id: 'carer-2',
          email: 'aisha.carer@sercesync.local',
          displayName: 'Aisha Carer',
          role: ManagerUserRole.carer,
        ),
        ManagerUser(
          id: 'carer-3',
          email: 'jon.carer@sercesync.local',
          displayName: 'Jon Carer',
          role: ManagerUserRole.carer,
        ),
        ManagerUser(
          id: 'nurse-1',
          email: 'leah.nurse@sercesync.local',
          displayName: 'Leah Nurse',
          role: ManagerUserRole.nurse,
        ),
      ];
    case 'shift-2':
      return const [
        ManagerUser(
          id: 'carer-4',
          email: 'maya.carer@sercesync.local',
          displayName: 'Maya Carer',
          role: ManagerUserRole.carer,
        ),
        ManagerUser(
          id: 'carer-5',
          email: 'liam.carer@sercesync.local',
          displayName: 'Liam Carer',
          role: ManagerUserRole.carer,
        ),
        ManagerUser(
          id: 'carer-6',
          email: 'noah.carer@sercesync.local',
          displayName: 'Noah Carer',
          role: ManagerUserRole.carer,
        ),
        ManagerUser(
          id: 'nurse-2',
          email: 'sarah.nurse@sercesync.local',
          displayName: 'Sarah Nurse',
          role: ManagerUserRole.nurse,
        ),
      ];
    case 'shift-3':
      return const [
        ManagerUser(
          id: 'carer-7',
          email: 'ava.carer@sercesync.local',
          displayName: 'Ava Carer',
          role: ManagerUserRole.carer,
        ),
        ManagerUser(
          id: 'carer-8',
          email: 'ethan.carer@sercesync.local',
          displayName: 'Ethan Carer',
          role: ManagerUserRole.carer,
        ),
        ManagerUser(
          id: 'carer-9',
          email: 'ruby.carer@sercesync.local',
          displayName: 'Ruby Carer',
          role: ManagerUserRole.carer,
        ),
        ManagerUser(
          id: 'nurse-3',
          email: 'helen.nurse@sercesync.local',
          displayName: 'Helen Nurse',
          role: ManagerUserRole.nurse,
        ),
      ];
    default:
      return const [];
  }
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
            assignedUsers: _assignedUsers('shift-1'),
          ),
          ManagerShiftSummary(
            id: 'shift-2',
            name: 'Maple Day Shift',
            status: ManagerShiftStatus.active,
            unitLabel: 'Maple Floor',
            floorNumber: 2,
            startsAt: DateTime(2026, 4, 13, 7, 30),
            endsAt: DateTime(2026, 4, 13, 14, 30),
            assignedUsers: _assignedUsers('shift-2'),
          ),
          ManagerShiftSummary(
            id: 'shift-3',
            name: 'Cedar Support Shift',
            status: ManagerShiftStatus.active,
            unitLabel: 'Cedar Floor',
            floorNumber: 3,
            startsAt: DateTime(2026, 4, 13, 8),
            endsAt: DateTime(2026, 4, 13, 15),
            assignedUsers: _assignedUsers('shift-3'),
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
                assignedUsers: _assignedUsers('shift-1'),
              ),
              ManagerShiftSummary(
                id: 'shift-2',
                name: 'Maple Day Shift',
                status: ManagerShiftStatus.active,
                unitLabel: 'Maple Floor',
                floorNumber: 2,
                startsAt: DateTime(2026, 4, 13, 7, 30),
                endsAt: DateTime(2026, 4, 13, 14, 30),
                assignedUsers: _assignedUsers('shift-2'),
              ),
              ManagerShiftSummary(
                id: 'shift-3',
                name: 'Cedar Support Shift',
                status: ManagerShiftStatus.active,
                unitLabel: 'Cedar Floor',
                floorNumber: 3,
                startsAt: DateTime(2026, 4, 13, 8),
                endsAt: DateTime(2026, 4, 13, 15),
                assignedUsers: _assignedUsers('shift-3'),
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
  late final Map<String, ManagerResidentEmarProfile> _residentEmarProfiles =
      _buildResidentEmarProfiles();
  late final ManagerMedicationOverview _medicationOverview =
      _buildMedicationOverview();

  void enqueueActiveShiftsResponse(List<ManagerShiftSummary> activeShifts) {
    _queuedActiveShiftResponses.add(
      () async => List<ManagerShiftSummary>.from(activeShifts),
    );
  }

  void emitDashboardUpdate(
    String shiftId, {
    String reason = 'timeline-entry-created',
  }) {
    final update = ManagerDashboardLiveUpdate(
      type: ManagerDashboardLiveUpdateType.updated,
      shiftId: shiftId,
      eventId: 'event-$shiftId-${requestLog.length}',
      occurredAt: DateTime(2026, 4, 13, 10, 50),
      reason: reason,
    );

    final controller = _dashboardUpdateControllers.putIfAbsent(
      shiftId,
      () => StreamController<ManagerDashboardLiveUpdate>.broadcast(),
    );
    controller.add(update);
  }

  void enqueueDashboardResponse(
    String? shiftId,
    Future<ManagerDashboardSnapshot> Function() response,
  ) {
    _queuedDashboardResponses
        .putIfAbsent(_dashboardKey(shiftId), () => [])
        .add(response);
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

  String _dashboardKey(String? shiftId) {
    if (shiftId == null || shiftId.trim().isEmpty) {
      return 'global';
    }
    return shiftId;
  }

  int _shiftCompletionPercent(String shiftId) {
    switch (shiftId) {
      case 'shift-3':
        return 71;
      case 'shift-2':
        return 68;
      case 'shift-1':
      default:
        return 74;
    }
  }

  ManagerDashboardSnapshot snapshotForDashboard({String? shiftId}) {
    if (shiftId != null && shiftId.trim().isNotEmpty) {
      return snapshotForShift(shiftId);
    }

    if (_activeShifts.isEmpty) {
      throw StateError(
        'Dashboard should not be requested without active shifts.',
      );
    }

    if (_activeShifts.length == 1) {
      return snapshotForShift(_activeShifts.first.id);
    }

    final activeShiftIds = _activeShifts.map((shift) => shift.id).toSet();
    final activityFeed = <ManagerActivityFeedItem>[
      if (activeShiftIds.contains('shift-1'))
        ManagerActivityFeedItem(
          id: 'note-willow-1',
          kind: ManagerActivityKind.note,
          title: 'Personal Care · Shower',
          shiftId: 'shift-1',
          residentName: 'Margaret Evans',
          floorNumber: 1,
          unitLabel: 'Willow Floor',
          roomLabel: 'Room 1',
          description: 'Morning shower support completed safely.',
          actorName: 'Alex Carer',
          occurredAt: DateTime(2026, 4, 13, 10, 46),
          badge: 'PERSONAL CARE',
          badgeTone: 'info',
        ),
      if (activeShiftIds.contains('shift-2'))
        ManagerActivityFeedItem(
          id: 'note-maple-1',
          kind: ManagerActivityKind.note,
          title: 'Wellbeing Check',
          shiftId: 'shift-2',
          residentName: 'Daniel Miller',
          floorNumber: 2,
          unitLabel: 'Maple Floor',
          roomLabel: 'Room 11',
          description:
              'Settled after reassurance and a gentle walk before breakfast.',
          actorName: 'Mia Maple',
          occurredAt: DateTime(2026, 4, 13, 9, 35),
          badge: 'OBSERVATION',
          badgeTone: 'info',
        ),
      if (activeShiftIds.contains('shift-3'))
        ManagerActivityFeedItem(
          id: 'note-cedar-1',
          kind: ManagerActivityKind.note,
          title: 'Comfort Check',
          shiftId: 'shift-3',
          residentName: 'Agnes Cook',
          floorNumber: 3,
          unitLabel: 'Cedar Floor',
          roomLabel: 'Room 21',
          description:
              'Settled after reassurance and a supported transfer back to the armchair.',
          actorName: 'Casey Cedar',
          occurredAt: DateTime(2026, 4, 13, 9, 35),
          badge: 'OBSERVATION',
          badgeTone: 'info',
        ),
    ];

    final exceptionFeed = <ManagerExceptionFeedItem>[
      if (activeShiftIds.contains('shift-1'))
        ManagerExceptionFeedItem(
          id: 'incident-open-red',
          kind: ManagerExceptionKind.incident,
          title: 'Hallway Fall',
          shiftId: 'shift-1',
          residentName: 'Margaret Evans',
          floorNumber: 1,
          unitLabel: 'Willow Floor',
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
      if (activeShiftIds.contains('shift-1'))
        ManagerExceptionFeedItem(
          id: 'incident-ack-amber',
          kind: ManagerExceptionKind.incident,
          title: 'Medication Refusal',
          shiftId: 'shift-1',
          residentName: 'Thea Green',
          floorNumber: 1,
          unitLabel: 'Willow Floor',
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
      if (activeShiftIds.contains('shift-3'))
        ManagerExceptionFeedItem(
          id: 'incident-cedar-red',
          kind: ManagerExceptionKind.incident,
          title: 'Cedar Distress Episode',
          shiftId: 'shift-3',
          residentName: 'Agnes Cook',
          floorNumber: 3,
          unitLabel: 'Cedar Floor',
          roomLabel: 'Room 21',
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
      if (activeShiftIds.contains('shift-1'))
        ManagerExceptionFeedItem(
          id: 'task-overdue',
          kind: ManagerExceptionKind.task,
          title: 'Hydration Round',
          shiftId: 'shift-1',
          residentName: 'Margaret Evans',
          floorNumber: 1,
          unitLabel: 'Willow Floor',
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
    ];

    final completionPercent =
        _activeShifts
            .map((shift) => _shiftCompletionPercent(shift.id))
            .reduce((sum, value) => sum + value) ~/
        _activeShifts.length;
    final activeIncidents = exceptionFeed
        .where((item) => item.kind == ManagerExceptionKind.incident)
        .length;
    final overdueTasks = exceptionFeed
        .where((item) => item.status == ManagerExceptionStatus.overdue)
        .length;
    final escalatedItems = activeShiftIds.contains('shift-3') ? 1 : 0;

    return ManagerDashboardSnapshot(
      activeShift: _activeShifts.first,
      metrics: ManagerDashboardMetrics(
        overdueTasks: overdueTasks,
        escalatedItems: escalatedItems,
        unreadHandovers: 0,
        shiftCompletionPercent: completionPercent,
        activeIncidents: activeIncidents,
      ),
      activityFeed: activityFeed,
      exceptionFeed: exceptionFeed,
      complianceSeries: [
        ManagerCompliancePoint(timestamp: DateTime(2026, 4, 13, 9), value: 92),
        ManagerCompliancePoint(timestamp: DateTime(2026, 4, 13, 11), value: 88),
        ManagerCompliancePoint(timestamp: DateTime(2026, 4, 13, 13), value: 90),
      ],
      medicationOverview: _medicationOverview,
    );
  }

  ManagerDashboardSnapshot snapshotForShift(String shiftId) {
    switch (shiftId) {
      case 'shift-3':
        return ManagerDashboardSnapshot(
          activeShift: shiftSummary('shift-3'),
          metrics: const ManagerDashboardMetrics(
            overdueTasks: 0,
            escalatedItems: 1,
            unreadHandovers: 0,
            shiftCompletionPercent: 71,
            activeIncidents: 1,
          ),
          activityFeed: [
            ManagerActivityFeedItem(
              id: 'note-cedar-1',
              kind: ManagerActivityKind.note,
              title: 'Comfort Check',
              shiftId: 'shift-3',
              residentName: 'Agnes Cook',
              floorNumber: 3,
              unitLabel: 'Cedar Floor',
              roomLabel: 'Room 21',
              description:
                  'Settled after reassurance and a supported transfer back to the armchair.',
              actorName: 'Casey Cedar',
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
              shiftId: 'shift-3',
              residentName: 'Agnes Cook',
              floorNumber: 3,
              unitLabel: 'Cedar Floor',
              roomLabel: 'Room 21',
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
          medicationOverview: _medicationOverview,
        );
      case 'shift-2':
        return ManagerDashboardSnapshot(
          activeShift: shiftSummary('shift-2'),
          metrics: const ManagerDashboardMetrics(
            overdueTasks: 0,
            escalatedItems: 0,
            unreadHandovers: 0,
            shiftCompletionPercent: 68,
            activeIncidents: 0,
          ),
          activityFeed: [
            ManagerActivityFeedItem(
              id: 'note-maple-1',
              kind: ManagerActivityKind.note,
              title: 'Wellbeing Check',
              shiftId: 'shift-2',
              residentName: 'Daniel Miller',
              floorNumber: 2,
              unitLabel: 'Maple Floor',
              roomLabel: 'Room 11',
              description:
                  'Settled after reassurance and a gentle walk before breakfast.',
              actorName: 'Mia Maple',
              occurredAt: DateTime(2026, 4, 13, 9, 35),
              badge: 'OBSERVATION',
              badgeTone: 'info',
            ),
          ],
          exceptionFeed: const [],
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
          medicationOverview: _medicationOverview,
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
              shiftId: 'shift-1',
              residentName: 'Margaret Evans',
              floorNumber: 1,
              unitLabel: 'Willow Floor',
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
              shiftId: 'shift-1',
              residentName: 'Margaret Evans',
              floorNumber: 1,
              unitLabel: 'Willow Floor',
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
              shiftId: 'shift-1',
              residentName: 'Margaret Evans',
              floorNumber: 1,
              unitLabel: 'Willow Floor',
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
              shiftId: 'shift-1',
              residentName: 'Thea Green',
              floorNumber: 1,
              unitLabel: 'Willow Floor',
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
              shiftId: 'shift-1',
              residentName: 'Margaret Evans',
              floorNumber: 1,
              unitLabel: 'Willow Floor',
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
          medicationOverview: _medicationOverview,
        );
    }
  }

  final List<ManagerResidentRecord> _residents = _buildResidentDirectory();

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
    String? shiftId,
  }) async {
    final dashboardKey = _dashboardKey(shiftId);
    requestLog.add('dashboard:$dashboardKey');
    final queuedResponses = _queuedDashboardResponses[dashboardKey];
    if (queuedResponses != null && queuedResponses.isNotEmpty) {
      return queuedResponses.removeAt(0)();
    }
    if (_activeShifts.isEmpty) {
      throw StateError(
        'Dashboard should not be requested without active shifts.',
      );
    }

    return snapshotForDashboard(shiftId: shiftId);
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
  Future<ManagerResidentEmarProfile> getResidentEmar({
    required String accessToken,
    required String residentId,
  }) async {
    requestLog.add('residentEmar:$residentId');
    final profile = _residentEmarProfiles[residentId];
    if (profile == null) {
      throw const ApiException('Medication chart unavailable.');
    }
    return profile;
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
      aboutMe: draft.aboutMe,
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
      aboutMe: draft.aboutMe,
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

  @override
  Future<String> exportMedicationAuditCsv({required String accessToken}) async {
    requestLog.add('medicationAuditExport');
    return 'section,metric,value\nWell-led,Medication audit export,Available';
  }

  @override
  Future<String> exportMedicationRoundCsv({
    required String accessToken,
    required String shiftId,
  }) async {
    requestLog.add('medicationRoundExport:$shiftId');
    return 'shiftId,status\n$shiftId,ACTIVE';
  }

  @override
  Future<String> exportResidentEmarCsv({
    required String accessToken,
    required String residentId,
  }) async {
    requestLog.add('residentEmarExport:$residentId');
    return 'residentId,export\n$residentId,eMAR';
  }

  @override
  Future<String> exportResidentDowntimePackCsv({
    required String accessToken,
    required String residentId,
  }) async {
    requestLog.add('residentDowntimePackExport:$residentId');
    return 'residentId,export\n$residentId,downtime-pack';
  }

  Map<String, ManagerResidentEmarProfile> _buildResidentEmarProfiles() {
    final timestamp = DateTime(2026, 4, 13, 8);
    final morningSchedule = ManagerMedicationScheduleRecord(
      id: 'schedule-1',
      roundLabel: 'MORNING',
      anchorType: 'HANDOVER_ACKNOWLEDGED',
      windowStartOffsetMinutes: 0,
      windowEndOffsetMinutes: 60,
      fixedTimeLocal: null,
      daysOfWeek: const ['MONDAY', 'TUESDAY', 'WEDNESDAY'],
      active: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final scheduledOrder = ManagerMedicationOrderRecord(
      id: 'med-order-1',
      medicationName: 'Amoxicillin',
      formulation: 'Capsule',
      strength: '500mg',
      doseAmount: '1',
      doseUnit: 'capsule',
      route: 'oral',
      instructions: 'Give after breakfast with water.',
      startDate: timestamp,
      endDate: null,
      isActive: true,
      isControlledDrug: false,
      requiresWitness: false,
      isPrn: false,
      sourceType: 'MANUAL_ENTRY',
      createdByUserId: 'manager-1',
      createdByUserName: 'Morgan Manager',
      updatedByUserId: 'manager-1',
      updatedByUserName: 'Morgan Manager',
      createdAt: timestamp,
      updatedAt: timestamp,
      deactivatedAt: null,
      deactivationReason: null,
      schedules: [morningSchedule],
      prnProtocol: null,
      stock: ManagerMedicationStockSummary(
        id: 'stock-1',
        currentQuantity: '24',
        quantityUnit: 'capsule',
        lastCheckedByUserId: 'manager-1',
        lastCheckedByUserName: 'Morgan Manager',
        lastCheckedAt: timestamp,
        notes: 'Opening stock count.',
        updatedAt: timestamp,
      ),
    );
    final prnProtocol = ManagerPrnProtocolRecord(
      id: 'prn-1',
      indication: 'Breakthrough pain',
      whenToOffer: 'Offer when Margaret reports pain after mobilising.',
      doseInstructions: 'Give one tablet and monitor comfort.',
      minimumIntervalMinutes: 240,
      maxDosePer24Hours: 4,
      expectedEffect: 'Improved comfort within one hour.',
      monitoringRequired: 'Observe comfort and hydration.',
      whenToEscalate: 'Escalate if pain persists or worsens.',
      active: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final prnOrder = ManagerMedicationOrderRecord(
      id: 'med-order-prn-1',
      medicationName: 'Paracetamol',
      formulation: 'Tablet',
      strength: '500mg',
      doseAmount: '1',
      doseUnit: 'tablet',
      route: 'oral',
      instructions: 'Check prescribed PRN instructions before administration.',
      startDate: timestamp,
      endDate: null,
      isActive: true,
      isControlledDrug: false,
      requiresWitness: false,
      isPrn: true,
      sourceType: 'MANUAL_ENTRY',
      createdByUserId: 'manager-1',
      createdByUserName: 'Morgan Manager',
      updatedByUserId: 'manager-1',
      updatedByUserName: 'Morgan Manager',
      createdAt: timestamp,
      updatedAt: timestamp,
      deactivatedAt: null,
      deactivationReason: null,
      schedules: const [],
      prnProtocol: prnProtocol,
      stock: null,
    );

    return {
      'resident-1': ManagerResidentEmarProfile(
        workflowNote:
            'Use the medication chart to review current orders, allergies, recent medication events, stock notes, and change history for this resident.',
        downtimeNotice:
            'If the system is unavailable, follow the care home downtime process and reconcile records afterwards.',
        safetyBanner:
            'Check medication label, resident identity and prescribed instructions before recording.',
        chart: ManagerMedicationChartSummary(
          id: 'chart-1',
          status: 'ACTIVE',
          createdByUserId: 'manager-1',
          createdByUserName: 'Morgan Manager',
          reviewedByUserId: null,
          reviewedByUserName: null,
          archivedAt: null,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
        allergies: [
          ManagerMedicationAllergyRecord(
            id: 'allergy-1',
            substance: 'Penicillin',
            reaction: 'Rash',
            severity: 'High',
            recordedByUserId: 'manager-1',
            recordedByUserName: 'Morgan Manager',
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        ],
        scheduledMedications: [scheduledOrder],
        prnMedications: [prnOrder],
        recentEvents: [
          ManagerMedicationAdministrationRecord(
            id: 'event-1',
            doseInstanceId: 'dose-1',
            residentId: 'resident-1',
            residentName: 'Margaret Evans',
            roomLabel: 'Room 1',
            shiftId: 'shift-1',
            medicationOrderId: scheduledOrder.id,
            medicationName: scheduledOrder.medicationName,
            strength: scheduledOrder.strength,
            formulation: scheduledOrder.formulation,
            eventType: 'REFUSED',
            doseGiven: null,
            doseUnit: null,
            reason: 'Resident declined at breakfast.',
            notes: null,
            recordedByUserId: 'user-2',
            recordedByUserName: 'Nina Nurse',
            recordedAt: DateTime(2026, 4, 13, 8, 20),
            witnessUserId: null,
            witnessUserName: null,
            createdAt: DateTime(2026, 4, 13, 8, 20),
          ),
          ManagerMedicationAdministrationRecord(
            id: 'event-2',
            doseInstanceId: null,
            residentId: 'resident-1',
            residentName: 'Margaret Evans',
            roomLabel: 'Room 1',
            shiftId: 'shift-1',
            medicationOrderId: prnOrder.id,
            medicationName: prnOrder.medicationName,
            strength: prnOrder.strength,
            formulation: prnOrder.formulation,
            eventType: 'PRN_ADMINISTERED',
            doseGiven: '1',
            doseUnit: 'tablet',
            reason: 'Pain after mobilising.',
            notes: null,
            recordedByUserId: 'user-2',
            recordedByUserName: 'Nina Nurse',
            recordedAt: DateTime(2026, 4, 13, 10, 5),
            witnessUserId: null,
            witnessUserName: null,
            createdAt: DateTime(2026, 4, 13, 10, 5),
          ),
        ],
        stockOverview: [scheduledOrder.stock!],
        changeHistory: [
          ManagerMedicationChangeLogRecord(
            id: 'change-1',
            medicationOrderId: scheduledOrder.id,
            residentId: 'resident-1',
            medicationName: scheduledOrder.medicationName,
            changedByUserId: 'manager-1',
            changedByUserName: 'Morgan Manager',
            changeType: 'CREATED',
            previousValueJson: null,
            newValueJson: const {'doseAmount': '1', 'doseUnit': 'capsule'},
            reason: 'Initial medication chart entry.',
            createdAt: timestamp,
          ),
        ],
      ),
    };
  }

  ManagerMedicationOverview _buildMedicationOverview() {
    final dueStart = DateTime(2026, 4, 13, 8);
    return ManagerMedicationOverview(
      workflowNote:
          'Review missed or varied medication outcomes across active shifts and export the audit trail when needed.',
      totals: const ManagerMedicationOverviewTotals(
        overdue: 1,
        refused: 1,
        omitted: 1,
        delayed: 1,
        notAvailable: 1,
        held: 0,
        recentPrnAdministrations: 1,
      ),
      exceptions: [
        ManagerMedicationException(
          id: 'med-ex-overdue',
          residentId: 'resident-1',
          residentName: 'Margaret Evans',
          roomLabel: 'Room 1',
          medicationOrderId: 'med-order-1',
          medicationName: 'Amoxicillin',
          strength: '500mg',
          roundLabel: 'MORNING',
          status: 'OVERDUE',
          dueWindowStart: dueStart,
          dueWindowEnd: dueStart.add(const Duration(hours: 1)),
          recordedByUserId: null,
          recordedByUserName: null,
          recordedAt: null,
          reason: 'Due window passed before recording.',
          notes: null,
          residentEmarPath: '/residents/resident-1/emar',
          doseInstanceId: 'dose-1',
        ),
        ManagerMedicationException(
          id: 'med-ex-refused',
          residentId: 'resident-1',
          residentName: 'Margaret Evans',
          roomLabel: 'Room 1',
          medicationOrderId: 'med-order-prn-1',
          medicationName: 'Paracetamol',
          strength: '500mg',
          roundLabel: 'CUSTOM',
          status: 'REFUSED',
          dueWindowStart: dueStart.add(const Duration(hours: 2)),
          dueWindowEnd: dueStart.add(const Duration(hours: 3)),
          recordedByUserId: 'user-2',
          recordedByUserName: 'Nina Nurse',
          recordedAt: dueStart.add(const Duration(hours: 2, minutes: 5)),
          reason: 'Resident declined pain relief.',
          notes: null,
          residentEmarPath: '/residents/resident-1/emar',
          doseInstanceId: 'dose-2',
        ),
        ManagerMedicationException(
          id: 'med-ex-omitted',
          residentId: 'resident-8',
          residentName: 'Lila Bishop',
          roomLabel: 'Room 8',
          medicationOrderId: 'med-order-3',
          medicationName: 'Lactulose',
          strength: '10ml',
          roundLabel: 'EVENING',
          status: 'OMITTED',
          dueWindowStart: dueStart.add(const Duration(hours: 10)),
          dueWindowEnd: dueStart.add(const Duration(hours: 11)),
          recordedByUserId: 'user-4',
          recordedByUserName: 'Sam Senior',
          recordedAt: dueStart.add(const Duration(hours: 10, minutes: 15)),
          reason: 'Medication unavailable from supply.',
          notes: null,
          residentEmarPath: '/residents/resident-8/emar',
          doseInstanceId: 'dose-3',
        ),
      ],
      recentPrnEvents: [
        ManagerMedicationAdministrationRecord(
          id: 'prn-event-1',
          doseInstanceId: null,
          residentId: 'resident-1',
          residentName: 'Margaret Evans',
          roomLabel: 'Room 1',
          shiftId: 'shift-1',
          medicationOrderId: 'med-order-prn-1',
          medicationName: 'Paracetamol',
          strength: '500mg',
          formulation: 'Tablet',
          eventType: 'PRN_ADMINISTERED',
          doseGiven: '1',
          doseUnit: 'tablet',
          reason: 'Pain after mobilising.',
          notes: null,
          recordedByUserId: 'user-2',
          recordedByUserName: 'Nina Nurse',
          recordedAt: dueStart.add(const Duration(hours: 2)),
          witnessUserId: null,
          witnessUserName: null,
          createdAt: dueStart.add(const Duration(hours: 2)),
        ),
      ],
      recentChanges: [
        ManagerMedicationChangeLogRecord(
          id: 'change-1',
          medicationOrderId: 'med-order-1',
          residentId: 'resident-1',
          medicationName: 'Amoxicillin',
          changedByUserId: 'manager-1',
          changedByUserName: 'Morgan Manager',
          changeType: 'SCHEDULE_CHANGED',
          previousValueJson: const {'roundLabel': 'MORNING'},
          newValueJson: const {
            'roundLabel': 'MORNING',
            'anchorType': 'HANDOVER_ACKNOWLEDGED',
          },
          reason:
              'Medication morning round aligned to handover acknowledgement.',
          createdAt: dueStart,
        ),
      ],
    );
  }
}

List<ManagerResidentRecord> _buildResidentDirectory() {
  final residents = <ManagerResidentRecord>[];

  void addFloorResidents({
    required int floorNumber,
    required String unitLabel,
    required int startingRoom,
    required List<String> names,
  }) {
    for (var index = 0; index < names.length; index += 1) {
      final residentNumber = residents.length + 1;
      final roomNumber = startingRoom + index;
      final fullName = names[index];
      final baselinePriority = residentNumber == 2
          ? ManagerResidentPriorityLevel.amber
          : ManagerResidentPriorityLevel.green;
      final effectivePriority = residentNumber == 1
          ? ManagerResidentPriorityLevel.red
          : baselinePriority;
      final prioritySource = residentNumber == 1
          ? ManagerResidentPrioritySource.incidentOverride
          : ManagerResidentPrioritySource.baseline;
      final activeIncidentCount = residentNumber == 1 ? 1 : 0;

      residents.add(
        ManagerResidentRecord(
          id: 'resident-$residentNumber',
          fullName: fullName,
          roomNumber: roomNumber,
          roomLabel: 'Room $roomNumber',
          floorNumber: floorNumber,
          unitLabel: unitLabel,
          recognitionImageKey: 'resident-$residentNumber',
          aboutMe: _residentAboutMe(fullName),
          isActive: true,
          baselinePriority: baselinePriority,
          effectivePriority: effectivePriority,
          prioritySource: prioritySource,
          activeIncidentCount: activeIncidentCount,
        ),
      );
    }
  }

  addFloorResidents(
    floorNumber: 1,
    unitLabel: 'Willow Floor',
    startingRoom: 1,
    names: const [
      'Margaret Evans',
      'Emma Parker',
      'Elliot Turner',
      'Thea Green',
      'Amir Hussain',
      'Sheila Morgan',
      'Brian Foster',
      'Joan Clarke',
      'Peter Wallace',
      'Lily Bennett',
    ],
  );
  addFloorResidents(
    floorNumber: 2,
    unitLabel: 'Maple Floor',
    startingRoom: 11,
    names: const [
      'Daniel Miller',
      'Alice Morton',
      'Isaac Collins',
      'Sophie Brooks',
      'Thomas Walker',
      'Simone Price',
      'Chloe Hughes',
      'James Carter',
      'Hannah Dixon',
      'Mark Osei',
    ],
  );
  addFloorResidents(
    floorNumber: 3,
    unitLabel: 'Cedar Floor',
    startingRoom: 21,
    names: const [
      'Agnes Cook',
      'Zara Khan',
      'Mabel Reed',
      'Amelia Lewis',
      'Simon Fletcher',
      'Jean Porter',
      'Frank Russell',
      'Olive Chapman',
      'Tara Banks',
      'Ryan Coleman',
    ],
  );

  return residents;
}

String _residentAboutMe(String fullName) {
  return '$fullName responds best to calm introductions, a steady pace, and clear reassurance before care routines.';
}
