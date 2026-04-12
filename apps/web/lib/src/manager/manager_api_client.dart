part of '../../manager_app.dart';

class SerceSyncManagerApiClient {
  SerceSyncManagerApiClient({required this.baseUrl});

  final String baseUrl;

  Uri _uri(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl$path');
  }

  Future<ManagerSession> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return ManagerSession.fromJson(_decodeJson(response));
  }

  Future<ManagerDashboardSnapshot> getDashboard({
    required String accessToken,
  }) async {
    final response = await http.get(
      _uri('/manager/dashboard'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    return ManagerDashboardSnapshot.fromJson(_decodeJson(response));
  }

  Future<List<ManagerResidentRecord>> getResidents({
    required String accessToken,
  }) async {
    final response = await http.get(
      _uri('/manager/residents'),
      headers: {'Authorization': 'Bearer $accessToken'},
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
    final response = await http.post(
      _uri('/manager/residents'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
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
    final response = await http.patch(
      _uri('/manager/residents/$residentId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(draft.toJson()),
    );

    final decoded = _decodeJson(response);
    return ManagerResidentRecord.fromJson(
      decoded['resident'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String) {
          throw ApiException(message);
        }
        if (message is List && message.isNotEmpty) {
          throw ApiException(message.join(', '));
        }
      }
      throw ApiException('Request failed with status ${response.statusCode}.');
    }
    return decoded as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
