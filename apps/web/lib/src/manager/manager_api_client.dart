part of '../../manager_app.dart';

class SerceSyncManagerApiClient {
  SerceSyncManagerApiClient({
    required this.baseUrl,
    ManagerDashboardLiveUpdatesConnector? liveUpdatesConnector,
    http.Client? httpClient,
  }) : _liveUpdatesConnector =
           liveUpdatesConnector ??
           buildManagerDashboardLiveUpdatesConnector(baseUrl),
       _httpClient = httpClient ?? createManagerHttpClient();

  final String baseUrl;
  final ManagerDashboardLiveUpdatesConnector _liveUpdatesConnector;
  final http.Client _httpClient;

  Uri _uri(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl$path');
  }

  Map<String, String> _headers({
    String? accessToken,
    bool includeJson = false,
  }) {
    final headers = <String, String>{};
    if (includeJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (accessToken != null && accessToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${accessToken.trim()}';
    }
    return headers;
  }

  Future<ManagerSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _httpClient.post(
      _uri('/auth/manager/login'),
      headers: _headers(includeJson: true),
      body: jsonEncode({'email': email, 'password': password}),
    );

    return ManagerSession.fromJson(_decodeJson(response));
  }

  Future<ManagerSession> restoreSession() async {
    final response = await _httpClient.get(_uri('/auth/manager/session'));
    return ManagerSession.fromJson(_decodeJson(response));
  }

  Future<void> logout() async {
    final response = await _httpClient.post(_uri('/auth/manager/logout'));
    _decodeJson(response);
  }

  Future<List<ManagerShiftSummary>> getActiveShifts({
    required String accessToken,
  }) async {
    final response = await _httpClient.get(
      _uri('/manager/dashboard/shifts'),
      headers: _headers(accessToken: accessToken),
    );

    final decoded = _decodeJson(response);
    return (decoded['activeShifts'] as List<dynamic>? ?? const [])
        .map(
          (entry) =>
              ManagerShiftSummary.fromJson(entry as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<ManagerDashboardSnapshot> getDashboard({
    required String accessToken,
    required String shiftId,
  }) async {
    final response = await _httpClient.get(
      _uri('/manager/dashboard?shiftId=$shiftId'),
      headers: _headers(accessToken: accessToken),
    );

    return ManagerDashboardSnapshot.fromJson(_decodeJson(response));
  }

  Stream<ManagerDashboardLiveUpdate> watchDashboard({
    required String accessToken,
    required String shiftId,
  }) {
    return _liveUpdatesConnector.connect(
      accessToken: accessToken,
      shiftId: shiftId,
    );
  }

  Future<List<ManagerResidentRecord>> getResidents({
    required String accessToken,
  }) async {
    final response = await _httpClient.get(
      _uri('/manager/residents'),
      headers: _headers(accessToken: accessToken),
    );

    final decoded = _decodeJson(response);
    return (decoded['residents'] as List<dynamic>? ?? const [])
        .map(
          (entry) =>
              ManagerResidentRecord.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ManagerResidentRecord> createResident({
    required String accessToken,
    required ManagerResidentDraft draft,
  }) async {
    final response = await _httpClient.post(
      _uri('/manager/residents'),
      headers: _headers(accessToken: accessToken, includeJson: true),
      body: jsonEncode(draft.toJson()),
    );

    final decoded = _decodeJson(response);
    return ManagerResidentRecord.fromJson(
      decoded['resident'] as Map<String, dynamic>,
    );
  }

  Future<ManagerResidentRecord> updateResident({
    required String accessToken,
    required String residentId,
    required ManagerResidentDraft draft,
  }) async {
    final response = await _httpClient.patch(
      _uri('/manager/residents/$residentId'),
      headers: _headers(accessToken: accessToken, includeJson: true),
      body: jsonEncode(draft.toJson()),
    );

    final decoded = _decodeJson(response);
    return ManagerResidentRecord.fromJson(
      decoded['resident'] as Map<String, dynamic>,
    );
  }

  Future<void> acknowledgeIncident({
    required String accessToken,
    required String incidentId,
    required String shiftId,
  }) async {
    final response = await _httpClient.post(
      _uri('/manager/incidents/$incidentId/acknowledge'),
      headers: _headers(accessToken: accessToken, includeJson: true),
      body: jsonEncode({'shiftId': shiftId}),
    );

    _decodeJson(response);
  }

  Future<void> resolveIncident({
    required String accessToken,
    required String incidentId,
    required String shiftId,
  }) async {
    final response = await _httpClient.post(
      _uri('/manager/incidents/$incidentId/resolve'),
      headers: _headers(accessToken: accessToken, includeJson: true),
      body: jsonEncode({'shiftId': shiftId}),
    );

    _decodeJson(response);
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String) {
          throw ApiException(message, statusCode: response.statusCode);
        }
        if (message is List && message.isNotEmpty) {
          throw ApiException(
            message.join(', '),
            statusCode: response.statusCode,
          );
        }
      }
      throw ApiException(
        'Request failed with status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }
    return decoded as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
