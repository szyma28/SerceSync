import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'offline_models.dart';

part 'mobile_offline_database.g.dart';

class CacheEntries extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get userId => text()();
  TextColumn get json => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey, userId};
}

class QueuedMutations extends Table {
  TextColumn get localId => text()();
  TextColumn get userId => text()();
  TextColumn get clientRequestId => text()();
  TextColumn get kind => text()();
  TextColumn get residentId => text()();
  TextColumn get shiftId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get eventAt => dateTime()();
  TextColumn get status => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastErrorCode => text().nullable()();
  TextColumn get lastErrorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class CachedJsonRecord {
  const CachedJsonRecord({required this.json, required this.fetchedAt});

  final String json;
  final DateTime fetchedAt;
}

@DriftDatabase(tables: [CacheEntries, QueuedMutations])
class MobileOfflineDatabase extends _$MobileOfflineDatabase {
  MobileOfflineDatabase({QueryExecutor? executor})
    : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> putCacheEntry({
    required String userId,
    required String cacheKey,
    required String json,
    required DateTime fetchedAt,
  }) {
    return into(cacheEntries).insertOnConflictUpdate(
      CacheEntriesCompanion.insert(
        cacheKey: cacheKey,
        userId: userId,
        json: json,
        fetchedAt: fetchedAt,
      ),
    );
  }

  Future<CachedJsonRecord?> readCacheEntry({
    required String userId,
    required String cacheKey,
  }) async {
    final row =
        await (select(cacheEntries)..where(
              (tbl) =>
                  tbl.userId.equals(userId) & tbl.cacheKey.equals(cacheKey),
            ))
            .getSingleOrNull();

    if (row == null) {
      return null;
    }

    return CachedJsonRecord(json: row.json, fetchedAt: row.fetchedAt);
  }

  Future<void> enqueueMutation({
    required String localId,
    required String userId,
    required String clientRequestId,
    required QueuedMutationKind kind,
    required String residentId,
    required String shiftId,
    required String payloadJson,
    required DateTime eventAt,
    required QueuedMutationStatus status,
    String? lastErrorCode,
    String? lastErrorMessage,
    int retryCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now().toUtc();
    return into(queuedMutations).insertOnConflictUpdate(
      QueuedMutationsCompanion.insert(
        localId: localId,
        userId: userId,
        clientRequestId: clientRequestId,
        kind: kind.storageValue,
        residentId: residentId,
        shiftId: shiftId,
        payloadJson: payloadJson,
        eventAt: eventAt,
        status: status.storageValue,
        retryCount: Value(retryCount),
        lastErrorCode: Value(lastErrorCode),
        lastErrorMessage: Value(lastErrorMessage),
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
      ),
    );
  }

  Future<List<QueuedResidentMutation>> loadQueuedMutationsForUser(
    String userId,
  ) async {
    final rows =
        await (select(queuedMutations)
              ..where((tbl) => tbl.userId.equals(userId))
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
            .get();

    return rows.map(_mapQueuedMutation).toList();
  }

  Future<List<QueuedResidentMutation>> loadQueuedMutationsForResident({
    required String userId,
    required String residentId,
  }) async {
    final rows =
        await (select(queuedMutations)
              ..where(
                (tbl) =>
                    tbl.userId.equals(userId) &
                    tbl.residentId.equals(residentId),
              )
              ..orderBy([
                (tbl) => OrderingTerm.desc(tbl.eventAt),
                (tbl) => OrderingTerm.desc(tbl.createdAt),
              ]))
            .get();

    return rows.map(_mapQueuedMutation).toList();
  }

  Future<QueuedResidentMutation?> loadQueuedMutationById(String localId) async {
    final row = await (select(
      queuedMutations,
    )..where((tbl) => tbl.localId.equals(localId))).getSingleOrNull();

    return row == null ? null : _mapQueuedMutation(row);
  }

  Future<void> updateQueuedMutationState({
    required String localId,
    required QueuedMutationStatus status,
    String? lastErrorCode,
    String? lastErrorMessage,
    int? retryCount,
  }) {
    return (update(
      queuedMutations,
    )..where((tbl) => tbl.localId.equals(localId))).write(
      QueuedMutationsCompanion(
        status: Value(status.storageValue),
        retryCount: retryCount == null
            ? const Value.absent()
            : Value(retryCount),
        lastErrorCode: Value(lastErrorCode),
        lastErrorMessage: Value(lastErrorMessage),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> deleteQueuedMutation(String localId) {
    return (delete(
      queuedMutations,
    )..where((tbl) => tbl.localId.equals(localId))).go();
  }

  Future<void> clearAllData() async {
    await batch((batch) {
      batch.deleteAll(queuedMutations);
      batch.deleteAll(cacheEntries);
    });
  }

  Future<void> clearDataForOtherUsers(String userId) async {
    await (delete(
      cacheEntries,
    )..where((tbl) => tbl.userId.equals(userId).not())).go();
    await (delete(
      queuedMutations,
    )..where((tbl) => tbl.userId.equals(userId).not())).go();
  }

  Future<void> clearDataForUser(String userId) async {
    await (delete(
      cacheEntries,
    )..where((tbl) => tbl.userId.equals(userId))).go();
    await (delete(
      queuedMutations,
    )..where((tbl) => tbl.userId.equals(userId))).go();
  }

  Stream<OfflineQueueSummary> watchQueueSummary(String userId) {
    return (select(
      queuedMutations,
    )..where((tbl) => tbl.userId.equals(userId))).watch().map((rows) {
      var pendingCount = 0;
      var failedCount = 0;
      var conflictCount = 0;
      for (final row in rows) {
        switch (QueuedMutationStatusX.fromStorageValue(row.status)) {
          case QueuedMutationStatus.pending:
            pendingCount += 1;
          case QueuedMutationStatus.failed:
            failedCount += 1;
          case QueuedMutationStatus.conflict:
            conflictCount += 1;
        }
      }
      return OfflineQueueSummary(
        pendingCount: pendingCount,
        failedCount: failedCount,
        conflictCount: conflictCount,
      );
    });
  }

  QueuedResidentMutation _mapQueuedMutation(QueuedMutation row) {
    return QueuedResidentMutation(
      localId: row.localId,
      userId: row.userId,
      clientRequestId: row.clientRequestId,
      kind: QueuedMutationKindX.fromStorageValue(row.kind),
      residentId: row.residentId,
      shiftId: row.shiftId,
      payloadJson: row.payloadJson,
      eventAt: row.eventAt,
      status: QueuedMutationStatusX.fromStorageValue(row.status),
      retryCount: row.retryCount,
      lastErrorCode: row.lastErrorCode,
      lastErrorMessage: row.lastErrorMessage,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'sercesync_mobile.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
