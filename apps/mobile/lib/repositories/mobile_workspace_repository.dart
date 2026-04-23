import 'dart:convert';

import '../api/api_client.dart';
import '../models/handover.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/workspace_models.dart';
import '../offline/mobile_offline_database.dart';
import '../offline/offline_models.dart';

class MobileWorkspaceRepository {
  MobileWorkspaceRepository({required this.offlineDatabase});

  static const String currentHandoverCacheKey = 'handover.current';
  static const String currentTasksCacheKey = 'tasks.current';
  static const String currentShiftOverviewCacheKey = 'shift.overview.current';
  static const String residentsListCacheKey = 'residents.list.current';

  final MobileOfflineDatabase offlineDatabase;

  String residentDetailCacheKey(String residentId) =>
      'resident.detail:$residentId';

  Future<CachedResource<T>?> _readCachedResource<T>({
    required PersistedMobileSession session,
    required String cacheKey,
    required T Function(Map<String, dynamic> json) decode,
  }) async {
    final cached = await offlineDatabase.readCacheEntry(
      userId: session.user.id,
      cacheKey: cacheKey,
    );
    if (cached == null) {
      return null;
    }

    final decoded = jsonDecode(cached.json) as Map<String, dynamic>;
    return CachedResource(data: decode(decoded), fetchedAt: cached.fetchedAt);
  }

  Future<CachedResource<T>> _refreshResource<T>({
    required PersistedMobileSession session,
    required String cacheKey,
    required Future<Map<String, dynamic>> Function(SerceSyncApiClient client)
    fetchJson,
    required T Function(Map<String, dynamic> json) decode,
  }) async {
    final client = SerceSyncApiClient(baseUrl: session.baseUrl);
    final decoded = await fetchJson(client);
    final fetchedAt = DateTime.now().toUtc();
    await offlineDatabase.putCacheEntry(
      userId: session.user.id,
      cacheKey: cacheKey,
      json: jsonEncode(decoded),
      fetchedAt: fetchedAt,
    );

    return CachedResource(data: decode(decoded), fetchedAt: fetchedAt);
  }

  Future<CachedResource<HandoverSnapshot>?> readCachedCurrentHandover(
    PersistedMobileSession session,
  ) {
    return _readCachedResource(
      session: session,
      cacheKey: currentHandoverCacheKey,
      decode: HandoverSnapshot.fromJson,
    );
  }

  Future<CachedResource<HandoverSnapshot>> refreshCurrentHandover(
    PersistedMobileSession session,
  ) {
    return _refreshResource(
      session: session,
      cacheKey: currentHandoverCacheKey,
      fetchJson: (client) =>
          client.getCurrentHandoverJson(accessToken: session.accessToken),
      decode: HandoverSnapshot.fromJson,
    );
  }

  Future<HandoverSnapshot> acknowledgeCurrentHandover(
    PersistedMobileSession session,
  ) async {
    final client = SerceSyncApiClient(baseUrl: session.baseUrl);
    final decoded = await client.acknowledgeCurrentHandoverJson(
      accessToken: session.accessToken,
    );
    final fetchedAt = DateTime.now().toUtc();
    await offlineDatabase.putCacheEntry(
      userId: session.user.id,
      cacheKey: currentHandoverCacheKey,
      json: jsonEncode(decoded),
      fetchedAt: fetchedAt,
    );
    return HandoverSnapshot.fromJson(decoded);
  }

  Future<CachedResource<List<ShiftTask>>?> readCachedCurrentTasks(
    PersistedMobileSession session,
  ) {
    return _readCachedResource(
      session: session,
      cacheKey: currentTasksCacheKey,
      decode: (json) {
        final tasks = json['tasks'] as List<dynamic>? ?? const [];
        return tasks
            .map((entry) => ShiftTask.fromJson(entry as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<CachedResource<List<ShiftTask>>> refreshCurrentTasks(
    PersistedMobileSession session,
  ) {
    return _refreshResource(
      session: session,
      cacheKey: currentTasksCacheKey,
      fetchJson: (client) =>
          client.getCurrentTasksJson(accessToken: session.accessToken),
      decode: (json) {
        final tasks = json['tasks'] as List<dynamic>? ?? const [];
        return tasks
            .map((entry) => ShiftTask.fromJson(entry as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<CachedResource<ShiftOverview>?> readCachedShiftOverview(
    PersistedMobileSession session,
  ) {
    return _readCachedResource(
      session: session,
      cacheKey: currentShiftOverviewCacheKey,
      decode: ShiftOverview.fromJson,
    );
  }

  Future<CachedResource<ShiftOverview>> refreshShiftOverview(
    PersistedMobileSession session,
  ) {
    return _refreshResource(
      session: session,
      cacheKey: currentShiftOverviewCacheKey,
      fetchJson: (client) =>
          client.getShiftOverviewJson(accessToken: session.accessToken),
      decode: ShiftOverview.fromJson,
    );
  }

  Future<CachedResource<List<ResidentListItem>>?> readCachedResidents(
    PersistedMobileSession session,
  ) {
    return _readCachedResource(
      session: session,
      cacheKey: residentsListCacheKey,
      decode: (json) {
        final residents = json['residents'] as List<dynamic>? ?? const [];
        return residents
            .map(
              (entry) =>
                  ResidentListItem.fromJson(entry as Map<String, dynamic>),
            )
            .toList();
      },
    );
  }

  Future<CachedResource<List<ResidentListItem>>> refreshResidents(
    PersistedMobileSession session,
  ) {
    return _refreshResource(
      session: session,
      cacheKey: residentsListCacheKey,
      fetchJson: (client) =>
          client.getResidentsJson(accessToken: session.accessToken),
      decode: (json) {
        final residents = json['residents'] as List<dynamic>? ?? const [];
        return residents
            .map(
              (entry) =>
                  ResidentListItem.fromJson(entry as Map<String, dynamic>),
            )
            .toList();
      },
    );
  }

  Future<CachedResource<ResidentDetail>?> readCachedResidentDetail({
    required PersistedMobileSession session,
    required String residentId,
  }) {
    return _readCachedResource(
      session: session,
      cacheKey: residentDetailCacheKey(residentId),
      decode: ResidentDetail.fromJson,
    );
  }

  Future<CachedResource<ResidentDetail>> refreshResidentDetail({
    required PersistedMobileSession session,
    required String residentId,
  }) {
    return _refreshResource(
      session: session,
      cacheKey: residentDetailCacheKey(residentId),
      fetchJson: (client) => client.getResidentByIdJson(
        accessToken: session.accessToken,
        residentId: residentId,
      ),
      decode: ResidentDetail.fromJson,
    );
  }
}
