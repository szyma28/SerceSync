import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../models/user.dart';
import '../models/workspace_models.dart';
import '../offline/mobile_offline_database.dart';
import '../offline/offline_models.dart';

typedef ApiClientFactory = SerceSyncApiClient Function(String baseUrl);

enum QueuedSaveState { synced, pending, conflict }

class QueuedSaveResult<T> {
  const QueuedSaveResult({required this.item, required this.state});

  final T item;
  final QueuedSaveState state;

  bool get wasQueued => state != QueuedSaveState.synced;
  bool get isPendingSync => state == QueuedSaveState.pending;
  bool get needsReview => state == QueuedSaveState.conflict;
}

class MobileResidentRepository {
  MobileResidentRepository({
    required this.offlineDatabase,
    Uuid? uuid,
    ApiClientFactory? apiClientFactory,
  }) : _uuid = uuid ?? const Uuid(),
       _apiClientFactory =
           apiClientFactory ??
           ((baseUrl) => SerceSyncApiClient(baseUrl: baseUrl));

  final MobileOfflineDatabase offlineDatabase;
  final Uuid _uuid;
  final ApiClientFactory _apiClientFactory;

  Future<QueuedSaveResult<ResidentTimelineEntry>> saveTimelineEntry({
    required PersistedMobileSession session,
    required String residentId,
    required String shiftId,
    required ResidentTimelineEntryDraft draft,
  }) async {
    final client = _apiClientFactory(session.baseUrl);
    final recordedAt = DateTime.now().toUtc();
    final clientRequestId = _uuid.v4();

    if (draft.evidence != null) {
      final entry = await client.createResidentTimelineEntry(
        accessToken: session.accessToken,
        residentId: residentId,
        draft: draft,
        clientRequestId: clientRequestId,
        recordedAt: recordedAt,
      );
      return QueuedSaveResult(item: entry, state: QueuedSaveState.synced);
    }

    final localId = _uuid.v4();
    final payloadJson = jsonEncode(draft.toJson());
    await offlineDatabase.enqueueMutation(
      localId: localId,
      userId: session.user.id,
      clientRequestId: clientRequestId,
      kind: QueuedMutationKind.residentTimelineEntry,
      residentId: residentId,
      shiftId: shiftId,
      payloadJson: payloadJson,
      eventAt: recordedAt,
      status: QueuedMutationStatus.pending,
    );

    try {
      final entry = await client.createResidentTimelineEntry(
        accessToken: session.accessToken,
        residentId: residentId,
        draft: draft,
        clientRequestId: clientRequestId,
        recordedAt: recordedAt,
      );
      await offlineDatabase.deleteQueuedMutation(localId);
      return QueuedSaveResult(item: entry, state: QueuedSaveState.synced);
    } on ApiException catch (error) {
      if (error.isNetworkError || error.isRetryableServerError) {
        return QueuedSaveResult(
          item: _buildLocalTimelineEntry(
            localId: localId,
            authorName: session.user.displayName,
            draft: draft,
            status: QueuedMutationStatus.pending,
            eventAt: recordedAt,
          ),
          state: QueuedSaveState.pending,
        );
      }

      await offlineDatabase.updateQueuedMutationState(
        localId: localId,
        status: QueuedMutationStatus.conflict,
        lastErrorCode: error.code ?? error.statusCode?.toString(),
        lastErrorMessage: error.message,
      );
      return QueuedSaveResult(
        item: _buildLocalTimelineEntry(
          localId: localId,
          authorName: session.user.displayName,
          draft: draft,
          status: QueuedMutationStatus.conflict,
          eventAt: recordedAt,
          syncMessage: error.message,
        ),
        state: QueuedSaveState.conflict,
      );
    }
  }

  Future<QueuedSaveResult<ResidentIncident>> saveIncident({
    required PersistedMobileSession session,
    required String residentId,
    required String shiftId,
    required ResidentIncidentDraft draft,
  }) async {
    final client = _apiClientFactory(session.baseUrl);
    final occurredAt = DateTime.now().toUtc();
    final clientRequestId = _uuid.v4();

    if (draft.evidence != null) {
      final incident = await client.createResidentIncident(
        accessToken: session.accessToken,
        residentId: residentId,
        draft: draft,
        clientRequestId: clientRequestId,
        occurredAt: occurredAt,
      );
      return QueuedSaveResult(item: incident, state: QueuedSaveState.synced);
    }

    final localId = _uuid.v4();
    final payloadJson = jsonEncode(draft.toJson());
    await offlineDatabase.enqueueMutation(
      localId: localId,
      userId: session.user.id,
      clientRequestId: clientRequestId,
      kind: QueuedMutationKind.residentIncident,
      residentId: residentId,
      shiftId: shiftId,
      payloadJson: payloadJson,
      eventAt: occurredAt,
      status: QueuedMutationStatus.pending,
    );

    try {
      final incident = await client.createResidentIncident(
        accessToken: session.accessToken,
        residentId: residentId,
        draft: draft,
        clientRequestId: clientRequestId,
        occurredAt: occurredAt,
      );
      await offlineDatabase.deleteQueuedMutation(localId);
      return QueuedSaveResult(item: incident, state: QueuedSaveState.synced);
    } on ApiException catch (error) {
      if (error.isNetworkError || error.isRetryableServerError) {
        return QueuedSaveResult(
          item: _buildLocalIncident(
            localId: localId,
            createdByName: session.user.displayName,
            draft: draft,
            status: QueuedMutationStatus.pending,
            occurredAt: occurredAt,
          ),
          state: QueuedSaveState.pending,
        );
      }

      await offlineDatabase.updateQueuedMutationState(
        localId: localId,
        status: QueuedMutationStatus.conflict,
        lastErrorCode: error.code ?? error.statusCode?.toString(),
        lastErrorMessage: error.message,
      );
      return QueuedSaveResult(
        item: _buildLocalIncident(
          localId: localId,
          createdByName: session.user.displayName,
          draft: draft,
          status: QueuedMutationStatus.conflict,
          occurredAt: occurredAt,
          syncMessage: error.message,
        ),
        state: QueuedSaveState.conflict,
      );
    }
  }

  Future<ResidentDetail> mergeQueuedResidentState({
    required PersistedMobileSession session,
    required ResidentDetail residentDetail,
  }) async {
    final queuedItems = await offlineDatabase.loadQueuedMutationsForResident(
      userId: session.user.id,
      residentId: residentDetail.id,
    );

    final projectedTimeline = queuedItems
        .where((item) => item.kind == QueuedMutationKind.residentTimelineEntry)
        .map(
          (item) => _buildLocalTimelineEntry(
            localId: item.localId,
            authorName: session.user.displayName,
            draft: ResidentTimelineEntryDraft.fromJson(item.payloadMap),
            status: item.status,
            eventAt: item.eventAt,
            syncMessage: item.lastErrorMessage,
          ),
        )
        .toList();
    final projectedIncidents = queuedItems
        .where((item) => item.kind == QueuedMutationKind.residentIncident)
        .map(
          (item) => _buildLocalIncident(
            localId: item.localId,
            createdByName: session.user.displayName,
            draft: ResidentIncidentDraft.fromJson(item.payloadMap),
            status: item.status,
            occurredAt: item.eventAt,
            syncMessage: item.lastErrorMessage,
          ),
        )
        .toList();

    final mergedTimeline = [...projectedTimeline, ...residentDetail.timeline]
      ..sort((left, right) => right.timestamp.compareTo(left.timestamp));
    final mergedIncidents =
        [...projectedIncidents, ...residentDetail.activeIncidents]
          ..sort((left, right) {
            if (left.severity != right.severity) {
              return left.severity == IncidentSeverity.red ? -1 : 1;
            }
            return right.occurredAt.compareTo(left.occurredAt);
          });

    return residentDetail.copyWith(
      activeIncidents: mergedIncidents,
      activeIncidentCount:
          residentDetail.activeIncidentCount + projectedIncidents.length,
      timeline: mergedTimeline,
    );
  }

  Future<void> discardQueuedMutation(String localId) {
    return offlineDatabase.deleteQueuedMutation(localId);
  }

  ResidentTimelineEntry _buildLocalTimelineEntry({
    required String localId,
    required String authorName,
    required ResidentTimelineEntryDraft draft,
    required QueuedMutationStatus status,
    required DateTime eventAt,
    String? syncMessage,
  }) {
    return ResidentTimelineEntry(
      id: 'local-$localId',
      type: draft.type,
      personalCareSubtype: draft.personalCareSubtype,
      mealType: draft.mealType,
      mealIntakeAmount: draft.mealIntakeAmount,
      title: _buildTimelineTitle(draft),
      details: _resolveTimelineDetails(draft),
      authorName: authorName,
      timestamp: eventAt,
      media: const [],
      syncStatus: _mapOfflineStatus(status),
      syncMessage: syncMessage,
      localMutationId: localId,
    );
  }

  ResidentIncident _buildLocalIncident({
    required String localId,
    required String createdByName,
    required ResidentIncidentDraft draft,
    required QueuedMutationStatus status,
    required DateTime occurredAt,
    String? syncMessage,
  }) {
    return ResidentIncident(
      id: 'local-$localId',
      severity: draft.severity,
      status: IncidentStatus.open,
      category: draft.category,
      categoryLabel: draft.category.label,
      title: draft.title,
      details: draft.details,
      occurredAt: occurredAt,
      createdAt: occurredAt,
      createdByName: createdByName,
      evidence: const [],
      syncStatus: _mapOfflineStatus(status),
      syncMessage: syncMessage,
      localMutationId: localId,
    );
  }

  OfflineSyncStatus _mapOfflineStatus(QueuedMutationStatus status) {
    switch (status) {
      case QueuedMutationStatus.pending:
        return OfflineSyncStatus.pending;
      case QueuedMutationStatus.failed:
        return OfflineSyncStatus.failed;
      case QueuedMutationStatus.conflict:
        return OfflineSyncStatus.conflict;
    }
  }

  String _buildTimelineTitle(ResidentTimelineEntryDraft draft) {
    if (draft.type == ResidentEntryType.personalCare &&
        draft.personalCareSubtype != null) {
      return 'Personal Care · ${draft.personalCareSubtype!.label}';
    }

    if (draft.type == ResidentEntryType.nutritionHydration &&
        draft.mealType != null &&
        draft.mealIntakeAmount != null) {
      return '${draft.mealType!.label} intake · ${draft.mealIntakeAmount!.label}';
    }

    return draft.type.label;
  }

  String _resolveTimelineDetails(ResidentTimelineEntryDraft draft) {
    if (draft.details.trim().isNotEmpty) {
      return draft.details.trim();
    }

    if (draft.mealType != null && draft.mealIntakeAmount != null) {
      return 'No additional concerns noted.';
    }

    return draft.details.trim();
  }
}
