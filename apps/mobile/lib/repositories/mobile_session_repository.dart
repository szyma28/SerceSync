import '../api/api_client.dart';
import '../models/user.dart';
import '../offline/mobile_offline_database.dart';
import '../offline/mobile_session_storage.dart';

class MobileSessionRepository {
  MobileSessionRepository({
    required this.sessionStorage,
    required this.offlineDatabase,
  });

  final MobileSessionStorage sessionStorage;
  final MobileOfflineDatabase offlineDatabase;

  Future<PersistedMobileSession?> readStoredSession() {
    return sessionStorage.readSession();
  }

  Future<PersistedMobileSession> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final client = SerceSyncApiClient(baseUrl: baseUrl.trim());
    final response = await client.login(
      email: email.trim(),
      password: password,
    );
    final session = PersistedMobileSession.fromLoginResponse(
      baseUrl: baseUrl.trim(),
      loginResponse: response,
    );

    await offlineDatabase.clearDataForOtherUsers(session.user.id);
    await sessionStorage.writeSession(session);
    return session;
  }

  Future<PersistedMobileSession> refreshSession(
    PersistedMobileSession session,
  ) async {
    final client = SerceSyncApiClient(baseUrl: session.baseUrl);
    final response = await client.refreshSession(
      refreshToken: session.refreshToken,
    );
    final refreshedSession = PersistedMobileSession.fromLoginResponse(
      baseUrl: session.baseUrl,
      loginResponse: response,
    );
    await sessionStorage.writeSession(refreshedSession);
    return refreshedSession;
  }

  Future<void> persistSession(PersistedMobileSession session) {
    return sessionStorage.writeSession(session);
  }

  Future<void> clearStoredSession() {
    return sessionStorage.clearSession();
  }

  Future<void> logout(PersistedMobileSession session) async {
    final client = SerceSyncApiClient(baseUrl: session.baseUrl);
    try {
      await client.logout(refreshToken: session.refreshToken);
    } on ApiException {
      // Local logout should still complete even if the device is offline.
    }

    await offlineDatabase.clearDataForUser(session.user.id);
    await sessionStorage.clearSession();
  }
}
