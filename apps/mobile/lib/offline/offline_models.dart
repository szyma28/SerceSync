import 'dart:convert';

class CachedResource<T> {
  const CachedResource({required this.data, required this.fetchedAt});

  final T data;
  final DateTime fetchedAt;
}

enum QueuedMutationKind { residentTimelineEntry, residentIncident }

extension QueuedMutationKindX on QueuedMutationKind {
  String get storageValue {
    switch (this) {
      case QueuedMutationKind.residentTimelineEntry:
        return 'resident_timeline_entry';
      case QueuedMutationKind.residentIncident:
        return 'resident_incident';
    }
  }

  static QueuedMutationKind fromStorageValue(String value) {
    switch (value) {
      case 'resident_incident':
        return QueuedMutationKind.residentIncident;
      case 'resident_timeline_entry':
      default:
        return QueuedMutationKind.residentTimelineEntry;
    }
  }
}

enum QueuedMutationStatus { pending, failed, conflict }

extension QueuedMutationStatusX on QueuedMutationStatus {
  String get storageValue {
    switch (this) {
      case QueuedMutationStatus.pending:
        return 'pending';
      case QueuedMutationStatus.failed:
        return 'failed';
      case QueuedMutationStatus.conflict:
        return 'conflict';
    }
  }

  static QueuedMutationStatus fromStorageValue(String value) {
    switch (value) {
      case 'failed':
        return QueuedMutationStatus.failed;
      case 'conflict':
        return QueuedMutationStatus.conflict;
      case 'pending':
      default:
        return QueuedMutationStatus.pending;
    }
  }
}

class QueuedResidentMutation {
  const QueuedResidentMutation({
    required this.localId,
    required this.userId,
    required this.clientRequestId,
    required this.kind,
    required this.residentId,
    required this.shiftId,
    required this.payloadJson,
    required this.eventAt,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastErrorCode,
    this.lastErrorMessage,
  });

  final String localId;
  final String userId;
  final String clientRequestId;
  final QueuedMutationKind kind;
  final String residentId;
  final String shiftId;
  final String payloadJson;
  final DateTime eventAt;
  final QueuedMutationStatus status;
  final int retryCount;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> get payloadMap =>
      jsonDecode(payloadJson) as Map<String, dynamic>;
}

class OfflineQueueSummary {
  const OfflineQueueSummary({
    this.pendingCount = 0,
    this.failedCount = 0,
    this.conflictCount = 0,
    this.isSyncing = false,
  });

  final int pendingCount;
  final int failedCount;
  final int conflictCount;
  final bool isSyncing;

  int get outstandingCount => pendingCount + failedCount + conflictCount;
  bool get hasFailures => failedCount > 0;
  bool get hasConflicts => conflictCount > 0;
  bool get hasPendingWork => outstandingCount > 0;

  String get headline {
    if (isSyncing) {
      return 'Syncing care updates...';
    }
    if (failedCount > 0) {
      return '$failedCount failed';
    }
    if (pendingCount > 0) {
      return '$pendingCount pending';
    }
    if (conflictCount > 0) {
      return '$conflictCount needs review';
    }
    return 'All synced';
  }

  OfflineQueueSummary copyWith({
    int? pendingCount,
    int? failedCount,
    int? conflictCount,
    bool? isSyncing,
  }) {
    return OfflineQueueSummary(
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      conflictCount: conflictCount ?? this.conflictCount,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}
