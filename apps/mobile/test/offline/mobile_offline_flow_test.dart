import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_mobile/api/api_client.dart';
import 'package:sercesync_mobile/models/user.dart';
import 'package:sercesync_mobile/models/workspace_models.dart';
import 'package:sercesync_mobile/offline/mobile_offline_database.dart';
import 'package:sercesync_mobile/offline/mobile_sync_service.dart';
import 'package:sercesync_mobile/offline/offline_models.dart';
import 'package:sercesync_mobile/repositories/mobile_resident_repository.dart';
import 'package:sercesync_mobile/repositories/mobile_workspace_repository.dart';

void main() {
  group('MobileResidentRepository', () {
    late MobileOfflineDatabase offlineDatabase;

    setUp(() {
      offlineDatabase = MobileOfflineDatabase(
        executor: NativeDatabase.memory(),
      );
    });

    tearDown(() async {
      await offlineDatabase.close();
    });

    test('queues text-only timeline entries for offline sync', () async {
      final offlineClient = _OfflineApiClient();
      final repository = MobileResidentRepository(
        offlineDatabase: offlineDatabase,
        apiClientFactory: (_) => offlineClient,
      );

      final result = await repository.saveTimelineEntry(
        session: _session(),
        residentId: 'resident-1',
        shiftId: 'shift-1',
        draft: const ResidentTimelineEntryDraft(
          type: ResidentEntryType.observation,
          details: 'Resident settled after breakfast.',
        ),
      );

      final queued = await offlineDatabase.loadQueuedMutationsForUser('user-1');

      expect(result.wasQueued, isTrue);
      expect(result.item.syncStatus, OfflineSyncStatus.pending);
      expect(queued, hasLength(1));
      expect(queued.single.kind, QueuedMutationKind.residentTimelineEntry);
      expect(queued.single.status, QueuedMutationStatus.pending);
    });

    test('queues text-only incidents for offline sync', () async {
      final offlineClient = _OfflineApiClient();
      final repository = MobileResidentRepository(
        offlineDatabase: offlineDatabase,
        apiClientFactory: (_) => offlineClient,
      );

      final result = await repository.saveIncident(
        session: _session(),
        residentId: 'resident-1',
        shiftId: 'shift-1',
        draft: const ResidentIncidentDraft(
          severity: IncidentSeverity.red,
          category: IncidentCategory.fall,
          title: 'Bathroom fall',
          details: 'Observed near the sink during morning checks.',
        ),
      );

      final queued = await offlineDatabase.loadQueuedMutationsForUser('user-1');

      expect(result.wasQueued, isTrue);
      expect(result.item.syncStatus, OfflineSyncStatus.pending);
      expect(queued, hasLength(1));
      expect(queued.single.kind, QueuedMutationKind.residentIncident);
      expect(queued.single.status, QueuedMutationStatus.pending);
    });

    test(
      'keeps evidence-backed notes online-only and does not queue them',
      () async {
        final fakeClient = _FakeApiClient();
        final repository = MobileResidentRepository(
          offlineDatabase: offlineDatabase,
          apiClientFactory: (_) => fakeClient,
        );

        final result = await repository.saveTimelineEntry(
          session: _session(),
          residentId: 'resident-1',
          shiftId: 'shift-1',
          draft: const ResidentTimelineEntryDraft(
            type: ResidentEntryType.observation,
            details: 'Photo evidence captured.',
            evidence: TimelineEvidenceFile(
              fileName: 'note.jpg',
              bytes: [1, 2, 3],
              mediaType: 'image/jpeg',
            ),
          ),
        );

        final queued = await offlineDatabase.loadQueuedMutationsForUser(
          'user-1',
        );

        expect(result.wasQueued, isFalse);
        expect(fakeClient.timelineCreateCalls, 1);
        expect(queued, isEmpty);
      },
    );

    test(
      'syncs text-only notes immediately when the API is reachable',
      () async {
        final fakeClient = _FakeApiClient();
        final repository = MobileResidentRepository(
          offlineDatabase: offlineDatabase,
          apiClientFactory: (_) => fakeClient,
        );

        final result = await repository.saveTimelineEntry(
          session: _session(),
          residentId: 'resident-1',
          shiftId: 'shift-1',
          draft: const ResidentTimelineEntryDraft(
            type: ResidentEntryType.observation,
            details: 'Resident settled after breakfast.',
          ),
        );

        final queued = await offlineDatabase.loadQueuedMutationsForUser(
          'user-1',
        );

        expect(result.wasQueued, isFalse);
        expect(result.isPendingSync, isFalse);
        expect(result.item.id, 'server-entry');
        expect(fakeClient.timelineCreateCalls, 1);
        expect(queued, isEmpty);
      },
    );

    test(
      'merges queued offline items into resident detail in timestamp order',
      () async {
        final repository = MobileResidentRepository(
          offlineDatabase: offlineDatabase,
        );
        final session = _session();

        await offlineDatabase.enqueueMutation(
          localId: 'local-note',
          userId: session.user.id,
          clientRequestId: 'client-note',
          kind: QueuedMutationKind.residentTimelineEntry,
          residentId: 'resident-1',
          shiftId: 'shift-1',
          payloadJson: jsonEncode(
            const ResidentTimelineEntryDraft(
              type: ResidentEntryType.observation,
              details: 'Queued observation',
            ).toJson(),
          ),
          eventAt: DateTime.utc(2026, 4, 22, 11),
          status: QueuedMutationStatus.pending,
          createdAt: DateTime.utc(2026, 4, 22, 11),
          updatedAt: DateTime.utc(2026, 4, 22, 11),
        );

        await offlineDatabase.enqueueMutation(
          localId: 'local-incident',
          userId: session.user.id,
          clientRequestId: 'client-incident',
          kind: QueuedMutationKind.residentIncident,
          residentId: 'resident-1',
          shiftId: 'shift-1',
          payloadJson: jsonEncode(
            const ResidentIncidentDraft(
              severity: IncidentSeverity.amber,
              category: IncidentCategory.behaviour,
              title: 'Upset during lunch',
              details: 'Resident became distressed in the dining room.',
            ).toJson(),
          ),
          eventAt: DateTime.utc(2026, 4, 22, 10, 30),
          status: QueuedMutationStatus.pending,
          createdAt: DateTime.utc(2026, 4, 22, 10, 30),
          updatedAt: DateTime.utc(2026, 4, 22, 10, 30),
        );

        final merged = await repository.mergeQueuedResidentState(
          session: session,
          residentDetail: _residentDetail(
            timeline: [
              ResidentTimelineEntry(
                id: 'server-entry',
                type: ResidentEntryType.observation,
                title: 'Server note',
                details: 'Earlier synced note.',
                authorName: 'Alex Carer',
                timestamp: DateTime.utc(2026, 4, 22, 9),
                media: const [],
              ),
            ],
            incidents: const [],
          ),
        );

        expect(merged.timeline.first.localMutationId, 'local-note');
        expect(merged.timeline.first.syncStatus, OfflineSyncStatus.pending);
        expect(merged.activeIncidents.first.localMutationId, 'local-incident');
        expect(
          merged.activeIncidents.first.syncStatus,
          OfflineSyncStatus.pending,
        );
      },
    );
  });

  group('MobileSyncService', () {
    late MobileOfflineDatabase offlineDatabase;
    late MobileWorkspaceRepository workspaceRepository;

    setUp(() {
      offlineDatabase = MobileOfflineDatabase(
        executor: NativeDatabase.memory(),
      );
      workspaceRepository = MobileWorkspaceRepository(
        offlineDatabase: offlineDatabase,
      );
    });

    tearDown(() async {
      await offlineDatabase.close();
    });

    test('syncs a pending mutation and clears it from the queue', () async {
      final session = _session();
      await _enqueueTimelineMutation(offlineDatabase, session.user.id);

      var submitCalls = 0;
      var refreshCalls = 0;

      final service = MobileSyncService(
        offlineDatabase: offlineDatabase,
        workspaceRepository: workspaceRepository,
        resolveSession:
            ({bool refreshIfNeeded = true, bool forceRefresh = false}) async =>
                session,
        onReauthenticationRequired: () async {},
        submitMutation: (resolvedSession, mutation) async {
          submitCalls += 1;
          expect(resolvedSession.user.id, 'user-1');
          expect(mutation.residentId, 'resident-1');
        },
        refreshResidentDetail: (resolvedSession, residentId) async {
          refreshCalls += 1;
          expect(resolvedSession.user.id, 'user-1');
          expect(residentId, 'resident-1');
        },
      )..bindUser(session.user.id);

      await service.triggerSync(reason: 'test-success');

      final remaining = await offlineDatabase.loadQueuedMutationsForUser(
        session.user.id,
      );
      expect(submitCalls, 1);
      expect(refreshCalls, 1);
      expect(remaining, isEmpty);
    });

    test('marks retryable failures as failed and keeps them queued', () async {
      final session = _session();
      await _enqueueTimelineMutation(offlineDatabase, session.user.id);

      final service = MobileSyncService(
        offlineDatabase: offlineDatabase,
        workspaceRepository: workspaceRepository,
        resolveSession:
            ({bool refreshIfNeeded = true, bool forceRefresh = false}) async =>
                session,
        onReauthenticationRequired: () async {},
        submitMutation: (resolvedSession, mutation) async {
          expect(resolvedSession.user.id, 'user-1');
          expect(mutation.localId, 'local-note');
          throw const ApiException(
            'No connection available right now.',
            isNetworkError: true,
          );
        },
      )..bindUser(session.user.id);

      await service.triggerSync(reason: 'test-network-failure');

      final queued = await offlineDatabase.loadQueuedMutationsForUser(
        session.user.id,
      );
      expect(queued, hasLength(1));
      expect(queued.single.status, QueuedMutationStatus.failed);
      expect(queued.single.retryCount, 1);
    });

    test('marks non-retryable errors as conflicts', () async {
      final session = _session();
      await _enqueueTimelineMutation(offlineDatabase, session.user.id);

      final service = MobileSyncService(
        offlineDatabase: offlineDatabase,
        workspaceRepository: workspaceRepository,
        resolveSession:
            ({bool refreshIfNeeded = true, bool forceRefresh = false}) async =>
                session,
        onReauthenticationRequired: () async {},
        submitMutation: (resolvedSession, mutation) async {
          expect(resolvedSession.user.id, 'user-1');
          expect(mutation.localId, 'local-note');
          throw const ApiException(
            'No active shift',
            statusCode: 409,
            code: 'NO_ACTIVE_SHIFT',
          );
        },
      )..bindUser(session.user.id);

      await service.triggerSync(reason: 'test-conflict');

      final queued = await offlineDatabase.loadQueuedMutationsForUser(
        session.user.id,
      );
      expect(queued, hasLength(1));
      expect(queued.single.status, QueuedMutationStatus.conflict);
      expect(queued.single.retryCount, 1);
    });

    test(
      'refreshes the session once on unauthorized sync and retries successfully',
      () async {
        final initialSession = _session(accessToken: 'expired-token');
        final refreshedSession = _session(accessToken: 'fresh-token');
        await _enqueueTimelineMutation(offlineDatabase, initialSession.user.id);

        var forceRefreshRequests = 0;
        var submitCalls = 0;

        final service = MobileSyncService(
          offlineDatabase: offlineDatabase,
          workspaceRepository: workspaceRepository,
          resolveSession:
              ({bool refreshIfNeeded = true, bool forceRefresh = false}) async {
                if (forceRefresh) {
                  forceRefreshRequests += 1;
                  return refreshedSession;
                }
                return initialSession;
              },
          onReauthenticationRequired: () async {
            fail(
              'Reauthentication should not be required when refresh succeeds.',
            );
          },
          submitMutation: (session, mutation) async {
            submitCalls += 1;
            expect(mutation.localId, 'local-note');
            if (session.accessToken == 'expired-token') {
              throw const ApiException('Unauthorized', isUnauthorized: true);
            }
          },
          refreshResidentDetail: (resolvedSession, residentId) async {
            expect(resolvedSession.accessToken, 'fresh-token');
            expect(residentId, 'resident-1');
          },
        )..bindUser(initialSession.user.id);

        await service.triggerSync(reason: 'test-refresh');

        final queued = await offlineDatabase.loadQueuedMutationsForUser(
          initialSession.user.id,
        );
        expect(forceRefreshRequests, 1);
        expect(submitCalls, 2);
        expect(queued, isEmpty);
      },
    );
  });
}

PersistedMobileSession _session({String accessToken = 'access-token'}) {
  return PersistedMobileSession(
    baseUrl: 'http://localhost:3000',
    accessToken: accessToken,
    accessTokenExpiresAt: DateTime.utc(2026, 4, 22, 20),
    refreshToken: 'refresh-token',
    refreshTokenExpiresAt: DateTime.utc(2026, 5, 22, 20),
    user: const LoginUser(
      id: 'user-1',
      email: 'carer@sercesync.local',
      displayName: 'Alex Carer',
      role: AppUserRole.carer,
    ),
  );
}

ResidentDetail _residentDetail({
  required List<ResidentTimelineEntry> timeline,
  required List<ResidentIncident> incidents,
}) {
  return ResidentDetail(
    id: 'resident-1',
    fullName: 'Joan Clarke',
    roomLabel: 'Room 8',
    floorNumber: 1,
    unitLabel: 'Willow Floor',
    recognitionImageKey: 'resident_profile_01',
    todaySummary: 'Settled this morning.',
    assignmentContext: 'Assigned to Willow Floor for this shift',
    contextLine: 'Observation priority today',
    alerts: const [],
    aboutMe: 'Enjoys a calm start to the day.',
    baselinePriority: ResidentPriorityLevel.green,
    effectivePriority: ResidentPriorityLevel.amber,
    prioritySource: ResidentPrioritySource.baseline,
    activeIncidentCount: incidents.length,
    activeIncidents: incidents,
    currentTasks: const [],
    timeline: timeline,
  );
}

Future<void> _enqueueTimelineMutation(
  MobileOfflineDatabase database,
  String userId,
) {
  final draft = const ResidentTimelineEntryDraft(
    type: ResidentEntryType.observation,
    details: 'Queued observation',
  );

  return database.enqueueMutation(
    localId: 'local-note',
    userId: userId,
    clientRequestId: 'client-note',
    kind: QueuedMutationKind.residentTimelineEntry,
    residentId: 'resident-1',
    shiftId: 'shift-1',
    payloadJson: jsonEncode(draft.toJson()),
    eventAt: DateTime.utc(2026, 4, 22, 12),
    status: QueuedMutationStatus.pending,
    createdAt: DateTime.utc(2026, 4, 22, 12),
    updatedAt: DateTime.utc(2026, 4, 22, 12),
  );
}

class _FakeApiClient extends SerceSyncApiClient {
  _FakeApiClient() : super(baseUrl: 'http://localhost:3000');

  int timelineCreateCalls = 0;

  @override
  Future<ResidentTimelineEntry> createResidentTimelineEntry({
    required String accessToken,
    required String residentId,
    required ResidentTimelineEntryDraft draft,
    String? clientRequestId,
    DateTime? recordedAt,
  }) async {
    timelineCreateCalls += 1;
    return ResidentTimelineEntry(
      id: 'server-entry',
      type: draft.type,
      title: 'Uploaded note',
      details: draft.details,
      authorName: 'Alex Carer',
      timestamp: recordedAt ?? DateTime.utc(2026, 4, 22, 12),
      media: const [],
    );
  }
}

class _OfflineApiClient extends SerceSyncApiClient {
  _OfflineApiClient() : super(baseUrl: 'http://localhost:3000');

  @override
  Future<ResidentTimelineEntry> createResidentTimelineEntry({
    required String accessToken,
    required String residentId,
    required ResidentTimelineEntryDraft draft,
    String? clientRequestId,
    DateTime? recordedAt,
  }) {
    throw const ApiException(
      'No connection available right now.',
      isNetworkError: true,
    );
  }

  @override
  Future<ResidentIncident> createResidentIncident({
    required String accessToken,
    required String residentId,
    required ResidentIncidentDraft draft,
    String? clientRequestId,
    DateTime? occurredAt,
  }) {
    throw const ApiException(
      'No connection available right now.',
      isNetworkError: true,
    );
  }
}
