import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/user.dart';
import '../models/workspace_models.dart';
import '../repositories/mobile_workspace_repository.dart';
import 'mobile_offline_database.dart';
import 'offline_models.dart';

typedef MutationSubmitter =
    Future<void> Function(
      PersistedMobileSession session,
      QueuedResidentMutation mutation,
    );

typedef ResidentRefreshHandler =
    Future<void> Function(PersistedMobileSession session, String residentId);

typedef SessionResolver =
    Future<PersistedMobileSession?> Function({
      bool refreshIfNeeded,
      bool forceRefresh,
    });

typedef ReauthenticationHandler = Future<void> Function();

class MobileSyncService extends ChangeNotifier {
  MobileSyncService({
    required this.offlineDatabase,
    required this.workspaceRepository,
    required this.resolveSession,
    required this.onReauthenticationRequired,
    MutationSubmitter? submitMutation,
    ResidentRefreshHandler? refreshResidentDetail,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity(),
       _submitMutation = submitMutation,
       _refreshResidentDetail = refreshResidentDetail;

  final MobileOfflineDatabase offlineDatabase;
  final MobileWorkspaceRepository workspaceRepository;
  final SessionResolver resolveSession;
  final ReauthenticationHandler onReauthenticationRequired;
  final Connectivity _connectivity;
  final MutationSubmitter? _submitMutation;
  final ResidentRefreshHandler? _refreshResidentDetail;

  StreamSubscription<dynamic>? _connectivitySubscription;
  StreamSubscription<OfflineQueueSummary>? _summarySubscription;
  OfflineQueueSummary _summary = const OfflineQueueSummary();
  bool _isSyncing = false;
  String? _activeUserId;

  OfflineQueueSummary get summary => _summary.copyWith(isSyncing: _isSyncing);

  void start() {
    _connectivitySubscription ??= _connectivity.onConnectivityChanged.listen((
      dynamic event,
    ) {
      if (_hasConnectivity(event)) {
        unawaited(triggerSync(reason: 'connectivity-restored'));
      }
    });
  }

  void bindUser(String? userId) {
    if (_activeUserId == userId) {
      return;
    }

    _activeUserId = userId;
    _summarySubscription?.cancel();
    _summarySubscription = null;

    if (userId == null) {
      _summary = const OfflineQueueSummary();
      notifyListeners();
      return;
    }

    _summarySubscription = offlineDatabase.watchQueueSummary(userId).listen((
      summary,
    ) {
      _summary = summary.copyWith(isSyncing: _isSyncing);
      notifyListeners();
    });
  }

  Future<void> retryFailedMutations({String? localId}) async {
    if (localId != null) {
      final mutation = await offlineDatabase.loadQueuedMutationById(localId);
      if (mutation != null && mutation.status == QueuedMutationStatus.failed) {
        await offlineDatabase.updateQueuedMutationState(
          localId: localId,
          status: QueuedMutationStatus.pending,
          lastErrorCode: null,
          lastErrorMessage: null,
        );
      }
    } else {
      final userId = _activeUserId;
      if (userId == null) {
        return;
      }
      final mutations = await offlineDatabase.loadQueuedMutationsForUser(
        userId,
      );
      for (final mutation in mutations.where(
        (item) => item.status == QueuedMutationStatus.failed,
      )) {
        await offlineDatabase.updateQueuedMutationState(
          localId: mutation.localId,
          status: QueuedMutationStatus.pending,
          lastErrorCode: null,
          lastErrorMessage: null,
        );
      }
    }

    await triggerSync(reason: 'manual-retry');
  }

  Future<void> triggerSync({String reason = 'manual'}) async {
    final userId = _activeUserId;
    if (userId == null || _isSyncing) {
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      while (true) {
        final queuedMutations = await offlineDatabase
            .loadQueuedMutationsForUser(userId);
        QueuedResidentMutation? nextMutation;
        for (final mutation in queuedMutations) {
          if (mutation.status != QueuedMutationStatus.conflict) {
            nextMutation = mutation;
            break;
          }
        }

        if (nextMutation == null) {
          break;
        }

        var session = await resolveSession(refreshIfNeeded: true);
        if (session == null) {
          await onReauthenticationRequired();
          break;
        }

        try {
          await _submit(session, nextMutation);
          await offlineDatabase.deleteQueuedMutation(nextMutation.localId);
          session = await resolveSession(refreshIfNeeded: false) ?? session;
          await _refreshResident(session, nextMutation.residentId);
        } on ApiException catch (error) {
          if (error.isUnauthorized) {
            final refreshedSession = await resolveSession(
              refreshIfNeeded: true,
              forceRefresh: true,
            );
            if (refreshedSession != null &&
                refreshedSession.accessToken != session!.accessToken) {
              try {
                await _submit(refreshedSession, nextMutation);
                await offlineDatabase.deleteQueuedMutation(
                  nextMutation.localId,
                );
                await _refreshResident(
                  refreshedSession,
                  nextMutation.residentId,
                );
                continue;
              } on ApiException catch (retryError) {
                if (retryError.isUnauthorized) {
                  await onReauthenticationRequired();
                  break;
                }
                final nextStatus = await _recordMutationFailure(
                  nextMutation,
                  retryError,
                );
                if (nextStatus == QueuedMutationStatus.failed) {
                  break;
                }
                continue;
              }
            }

            await onReauthenticationRequired();
            break;
          }

          final nextStatus = await _recordMutationFailure(nextMutation, error);
          if (nextStatus == QueuedMutationStatus.failed) {
            break;
          }
        }
      }
    } finally {
      _isSyncing = false;
      _summary = _summary.copyWith(isSyncing: false);
      notifyListeners();
      debugPrint('Offline sync finished: $reason');
    }
  }

  Future<void> _submitQueuedMutation(
    PersistedMobileSession session,
    QueuedResidentMutation mutation,
  ) async {
    final client = SerceSyncApiClient(baseUrl: session.baseUrl);

    switch (mutation.kind) {
      case QueuedMutationKind.residentTimelineEntry:
        await client.createResidentTimelineEntry(
          accessToken: session.accessToken,
          residentId: mutation.residentId,
          draft: ResidentTimelineEntryDraft.fromJson(mutation.payloadMap),
          clientRequestId: mutation.clientRequestId,
          recordedAt: mutation.eventAt,
        );
        break;
      case QueuedMutationKind.residentIncident:
        await client.createResidentIncident(
          accessToken: session.accessToken,
          residentId: mutation.residentId,
          draft: ResidentIncidentDraft.fromJson(mutation.payloadMap),
          clientRequestId: mutation.clientRequestId,
          occurredAt: mutation.eventAt,
        );
        break;
    }
  }

  Future<void> _submit(
    PersistedMobileSession session,
    QueuedResidentMutation mutation,
  ) {
    final submitMutation = _submitMutation;
    if (submitMutation != null) {
      return submitMutation(session, mutation);
    }

    return _submitQueuedMutation(session, mutation);
  }

  Future<void> _refreshResident(
    PersistedMobileSession session,
    String residentId,
  ) {
    final refreshResidentDetail = _refreshResidentDetail;
    if (refreshResidentDetail != null) {
      return refreshResidentDetail(session, residentId);
    }

    return workspaceRepository.refreshResidentDetail(
      session: session,
      residentId: residentId,
    );
  }

  Future<QueuedMutationStatus> _recordMutationFailure(
    QueuedResidentMutation mutation,
    ApiException error,
  ) async {
    final nextStatus = error.isNetworkError || error.isRetryableServerError
        ? QueuedMutationStatus.failed
        : QueuedMutationStatus.conflict;

    await offlineDatabase.updateQueuedMutationState(
      localId: mutation.localId,
      status: nextStatus,
      retryCount: mutation.retryCount + 1,
      lastErrorCode: error.code ?? error.statusCode?.toString(),
      lastErrorMessage: error.message,
    );
    return nextStatus;
  }

  bool _hasConnectivity(dynamic event) {
    if (event is ConnectivityResult) {
      return event != ConnectivityResult.none;
    }
    if (event is List<ConnectivityResult>) {
      return event.any((result) => result != ConnectivityResult.none);
    }
    return true;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _summarySubscription?.cancel();
    super.dispose();
  }
}
