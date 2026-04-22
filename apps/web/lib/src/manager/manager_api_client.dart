import 'dart:convert';

import 'package:http/http.dart' as http;

import 'manager_dashboard_live_updates.dart';
import 'manager_dashboard_live_updates_api.dart';
import 'manager_http_client.dart';
import 'manager_models.dart';

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

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBaseUrl$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: <String, String>{
        ...uri.queryParameters,
        ...queryParameters,
      },
    );
  }

  Map<String, String> _freshQueryParameters([Map<String, String>? values]) {
    return <String, String>{
      if (values != null) ...values,
      '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
    };
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
    final response = await _httpClient.get(
      _uri('/auth/manager/session', queryParameters: _freshQueryParameters()),
    );
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
      _uri(
        '/manager/dashboard/shifts',
        queryParameters: _freshQueryParameters(),
      ),
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
    String? shiftId,
  }) async {
    final queryParameters = _freshQueryParameters(
      shiftId == null || shiftId.trim().isEmpty
          ? null
          : <String, String>{'shiftId': shiftId},
    );
    final response = await _httpClient.get(
      _uri('/manager/dashboard', queryParameters: queryParameters),
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
      _uri('/manager/residents', queryParameters: _freshQueryParameters()),
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

  Future<ManagerResidentEmarProfile> getResidentEmar({
    required String accessToken,
    required String residentId,
  }) async {
    final response = await _httpClient.get(
      _uri(
        '/residents/$residentId/emar',
        queryParameters: _freshQueryParameters(),
      ),
      headers: _headers(accessToken: accessToken),
    );

    return ManagerResidentEmarProfile.fromJson(_decodeJson(response));
  }

  Future<ManagerMedicationOrderRecord> createMedicationOrder({
    required String accessToken,
    required String residentId,
    required ManagerMedicationOrderDraft draft,
  }) async {
    final response = await _httpClient.post(
      _uri('/residents/$residentId/medications'),
      headers: _headers(accessToken: accessToken, includeJson: true),
      body: jsonEncode(draft.toCreateJson()),
    );

    final decoded = _decodeJson(response);
    return ManagerMedicationOrderRecord.fromJson(
      decoded['medicationOrder'] as Map<String, dynamic>,
    );
  }

  Future<ManagerMedicationOrderRecord> updateMedicationOrder({
    required String accessToken,
    required String medicationOrderId,
    required ManagerMedicationOrderDraft draft,
  }) async {
    final response = await _httpClient.patch(
      _uri('/medications/$medicationOrderId'),
      headers: _headers(accessToken: accessToken, includeJson: true),
      body: jsonEncode(draft.toUpdateJson()),
    );

    final decoded = _decodeJson(response);
    return ManagerMedicationOrderRecord.fromJson(
      decoded['medicationOrder'] as Map<String, dynamic>,
    );
  }

  Future<ManagerMedicationOrderRecord> deactivateMedicationOrder({
    required String accessToken,
    required String medicationOrderId,
    required String reason,
  }) async {
    final response = await _httpClient.post(
      _uri('/medications/$medicationOrderId/deactivate'),
      headers: _headers(accessToken: accessToken, includeJson: true),
      body: jsonEncode({'reason': reason}),
    );

    final decoded = _decodeJson(response);
    return ManagerMedicationOrderRecord.fromJson(
      decoded['medicationOrder'] as Map<String, dynamic>,
    );
  }

  Future<ManagerMedicationScheduleRecord> createMedicationSchedule({
    required String accessToken,
    required String medicationOrderId,
    required ManagerMedicationScheduleDraft draft,
  }) async {
    final response = await _httpClient.post(
      _uri('/medications/$medicationOrderId/schedules'),
      headers: _headers(accessToken: accessToken, includeJson: true),
      body: jsonEncode(draft.toJson()),
    );

    final decoded = _decodeJson(response);
    return ManagerMedicationScheduleRecord.fromJson(
      decoded['schedule'] as Map<String, dynamic>,
    );
  }

  Future<ManagerPrnProtocolRecord> createPrnProtocol({
    required String accessToken,
    required String medicationOrderId,
    required ManagerPrnProtocolDraft draft,
  }) async {
    final response = await _httpClient.post(
      _uri('/medications/$medicationOrderId/prn-protocol'),
      headers: _headers(accessToken: accessToken, includeJson: true),
      body: jsonEncode(draft.toJson()),
    );

    final decoded = _decodeJson(response);
    return ManagerPrnProtocolRecord.fromJson(
      decoded['prnProtocol'] as Map<String, dynamic>,
    );
  }

  Future<ManagerMedicationAllergyRecord> createMedicationAllergy({
    required String accessToken,
    required String residentId,
    required ManagerMedicationAllergyDraft draft,
  }) async {
    final response = await _httpClient.post(
      _uri('/residents/$residentId/medication-allergies'),
      headers: _headers(accessToken: accessToken, includeJson: true),
      body: jsonEncode(draft.toJson()),
    );

    final decoded = _decodeJson(response);
    return ManagerMedicationAllergyRecord.fromJson(
      decoded['allergy'] as Map<String, dynamic>,
    );
  }

  Future<ManagerMedicationStockSummary> createMedicationStockTransaction({
    required String accessToken,
    required String medicationOrderId,
    required ManagerMedicationStockTransactionDraft draft,
  }) async {
    final response = await _httpClient.post(
      _uri('/medications/$medicationOrderId/stock-transactions'),
      headers: _headers(accessToken: accessToken, includeJson: true),
      body: jsonEncode(draft.toJson()),
    );

    final decoded = _decodeJson(response);
    return ManagerMedicationStockSummary.fromJson(
      decoded['stock'] as Map<String, dynamic>,
    );
  }

  Future<String> exportResidentEmarCsv({
    required String accessToken,
    required String residentId,
  }) {
    return _getRawText(
      '/residents/$residentId/emar/export',
      accessToken: accessToken,
    );
  }

  Future<String> exportResidentDowntimePackCsv({
    required String accessToken,
    required String residentId,
  }) {
    return _getRawText(
      '/residents/$residentId/emar/downtime-pack/export',
      accessToken: accessToken,
    );
  }

  Future<String> exportMedicationRoundCsv({
    required String accessToken,
    required String shiftId,
  }) {
    return _getRawText(
      '/shifts/$shiftId/medication-round/export',
      accessToken: accessToken,
    );
  }

  Future<String> exportMedicationAuditCsv({required String accessToken}) {
    return _getRawText(
      '/manager/medication-audit/export',
      accessToken: accessToken,
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

  Future<String> _getRawText(String path, {required String accessToken}) async {
    final response = await _httpClient.get(
      _uri(path, queryParameters: _freshQueryParameters()),
      headers: _headers(accessToken: accessToken),
    );

    if (response.statusCode >= 400) {
      _decodeJson(response);
    }

    return response.body;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ManagerMedicationStockTransactionDraft {
  const ManagerMedicationStockTransactionDraft({
    required this.transactionType,
    required this.quantity,
    required this.quantityUnit,
    this.witnessUserId,
    this.reason,
  });

  final String transactionType;
  final String quantity;
  final String quantityUnit;
  final String? witnessUserId;
  final String? reason;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'transactionType': transactionType,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      if (witnessUserId != null && witnessUserId!.trim().isNotEmpty)
        'witnessUserId': witnessUserId!.trim(),
      if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
    };
  }
}
