import 'package:flutter_test/flutter_test.dart';
import 'package:sercesync_mobile/models/user.dart';
import 'package:sercesync_mobile/models/workspace_models.dart';

void main() {
  test('login response round-trips the mobile session payload', () {
    final response = LoginResponse.fromJson({
      'accessToken': 'access-token',
      'accessTokenExpiresAt': '2026-04-22T10:00:00.000Z',
      'refreshToken': 'refresh-token',
      'refreshTokenExpiresAt': '2026-05-06T10:00:00.000Z',
      'user': {
        'id': 'user-1',
        'email': 'carer@sercesync.local',
        'displayName': 'Alex Carer',
        'role': 'CARER',
      },
    });

    final session = PersistedMobileSession.fromLoginResponse(
      baseUrl: 'http://localhost:3000',
      loginResponse: response,
    );

    expect(session.baseUrl, 'http://localhost:3000');
    expect(session.accessToken, 'access-token');
    expect(session.refreshToken, 'refresh-token');
    expect(session.user.displayName, 'Alex Carer');
    expect(session.toJson()['user'], isA<Map<String, dynamic>>());
  });

  test('resident timeline entries retain local sync metadata via copyWith', () {
    final entry = ResidentTimelineEntry(
      id: 'entry-1',
      type: ResidentEntryType.observation,
      title: 'Morning note',
      details: 'Resident settled after breakfast.',
      authorName: 'Alex Carer',
      timestamp: DateTime.utc(2026, 4, 22, 8),
      media: const [],
      syncStatus: OfflineSyncStatus.pending,
      localMutationId: 'mutation-1',
    );

    final updated = entry.copyWith(
      syncStatus: OfflineSyncStatus.failed,
      syncMessage: 'Will retry when online.',
    );

    expect(updated.syncStatus, OfflineSyncStatus.failed);
    expect(updated.syncMessage, 'Will retry when online.');
    expect(updated.localMutationId, 'mutation-1');
  });

  test('resident incidents retain local sync metadata via copyWith', () {
    final incident = ResidentIncident(
      id: 'incident-1',
      severity: IncidentSeverity.red,
      status: IncidentStatus.open,
      category: IncidentCategory.fall,
      categoryLabel: 'Fall',
      title: 'Bathroom fall',
      details: 'Observed near the sink during morning checks.',
      occurredAt: DateTime.utc(2026, 4, 22, 7, 45),
      createdAt: DateTime.utc(2026, 4, 22, 7, 50),
      createdByName: 'Alex Carer',
      evidence: const [],
      syncStatus: OfflineSyncStatus.pending,
      localMutationId: 'mutation-2',
    );

    final updated = incident.copyWith(
      syncStatus: OfflineSyncStatus.conflict,
      syncMessage: 'Needs review before retrying.',
    );

    expect(updated.syncStatus, OfflineSyncStatus.conflict);
    expect(updated.syncMessage, 'Needs review before retrying.');
    expect(updated.localMutationId, 'mutation-2');
  });
}
