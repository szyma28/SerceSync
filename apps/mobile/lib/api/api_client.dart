import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/handover.dart';
import '../models/medication_models.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/workspace_models.dart';

class SerceSyncApiClient {
  SerceSyncApiClient({required this.baseUrl});

  static const Duration _requestTimeout = Duration(seconds: 20);

  final String baseUrl;

  Uri _uri(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl$path');
  }

  Map<String, String> _headers({
    String? accessToken,
    bool includeJsonContentType = false,
  }) {
    return {
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      if (includeJsonContentType) 'Content-Type': 'application/json',
    };
  }

  String resolveMediaUrl(String downloadPath) {
    return _uri(downloadPath).toString();
  }

  Future<http.Response> _runRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        'Request timed out. Check your connection and try again.',
        isNetworkError: true,
      );
    } on SocketException {
      throw const ApiException(
        'No connection available right now.',
        isNetworkError: true,
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        error.message.isEmpty
            ? 'A network error occurred while contacting the server.'
            : error.message,
        isNetworkError: true,
      );
    }
  }

  Future<http.Response> _runMultipartRequest(
    http.MultipartRequest request,
  ) async {
    try {
      final streamedResponse = await request.send().timeout(_requestTimeout);
      return http.Response.fromStream(streamedResponse);
    } on TimeoutException {
      throw const ApiException(
        'Request timed out. Check your connection and try again.',
        isNetworkError: true,
      );
    } on SocketException {
      throw const ApiException(
        'No connection available right now.',
        isNetworkError: true,
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        error.message.isEmpty
            ? 'A network error occurred while contacting the server.'
            : error.message,
        isNetworkError: true,
      );
    }
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    String? accessToken,
  }) async {
    final response = await _runRequest(
      () => http.get(_uri(path), headers: _headers(accessToken: accessToken)),
    );
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    String? accessToken,
    Object? body,
  }) async {
    final response = await _runRequest(
      () => http.post(
        _uri(path),
        headers: _headers(
          accessToken: accessToken,
          includeJsonContentType: true,
        ),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> _patchJson(
    String path, {
    String? accessToken,
    Object? body,
  }) async {
    final response = await _runRequest(
      () => http.patch(
        _uri(path),
        headers: _headers(
          accessToken: accessToken,
          includeJsonContentType: true,
        ),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> _multipartJson(
    http.MultipartRequest request,
  ) async {
    final response = await _runMultipartRequest(request);
    return _decodeJson(response);
  }

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final decoded = await _postJson(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    return LoginResponse.fromJson(decoded);
  }

  Future<LoginResponse> refreshSession({required String refreshToken}) async {
    final decoded = await _postJson(
      '/auth/refresh',
      body: {'refreshToken': refreshToken},
    );

    return LoginResponse.fromJson(decoded);
  }

  Future<void> logout({required String refreshToken}) async {
    await _postJson('/auth/logout', body: {'refreshToken': refreshToken});
  }

  Future<Map<String, dynamic>> getCurrentHandoverJson({
    required String accessToken,
  }) {
    return _getJson('/handovers/current', accessToken: accessToken);
  }

  Future<HandoverSnapshot> getCurrentHandover({
    required String accessToken,
  }) async {
    return HandoverSnapshot.fromJson(
      await getCurrentHandoverJson(accessToken: accessToken),
    );
  }

  Future<HandoverSnapshot> acknowledgeCurrentHandover({
    required String accessToken,
  }) async {
    final decoded = await acknowledgeCurrentHandoverJson(
      accessToken: accessToken,
    );

    return HandoverSnapshot.fromJson(decoded);
  }

  Future<Map<String, dynamic>> acknowledgeCurrentHandoverJson({
    required String accessToken,
  }) {
    return _postJson(
      '/handovers/current/acknowledge',
      accessToken: accessToken,
    );
  }

  Future<Map<String, dynamic>> getCurrentTasksJson({
    required String accessToken,
  }) {
    return _getJson('/tasks/current', accessToken: accessToken);
  }

  Future<List<ShiftTask>> getCurrentTasks({required String accessToken}) async {
    final decoded = await getCurrentTasksJson(accessToken: accessToken);
    final tasks = decoded['tasks'] as List<dynamic>? ?? const [];
    return tasks
        .map((entry) => ShiftTask.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getShiftOverviewJson({
    required String accessToken,
  }) {
    return _getJson('/shifts/my', accessToken: accessToken);
  }

  Future<ShiftOverview> getShiftOverview({required String accessToken}) async {
    return ShiftOverview.fromJson(
      await getShiftOverviewJson(accessToken: accessToken),
    );
  }

  Future<ShiftTask> completeTask({
    required String accessToken,
    required String taskId,
    String? note,
  }) async {
    final decoded = await _postJson(
      '/tasks/$taskId/complete',
      accessToken: accessToken,
      body: note != null ? {'note': note} : null,
    );

    return ShiftTask.fromJson(decoded['task'] as Map<String, dynamic>);
  }

  Future<ShiftTask> deferTask({
    required String accessToken,
    required String taskId,
    required String reason,
  }) async {
    final decoded = await _postJson(
      '/tasks/$taskId/defer',
      accessToken: accessToken,
      body: {'reason': reason},
    );

    return ShiftTask.fromJson(decoded['task'] as Map<String, dynamic>);
  }

  Future<ShiftTask> escalateTask({
    required String accessToken,
    required String taskId,
    required String reason,
  }) async {
    final decoded = await _postJson(
      '/tasks/$taskId/escalate',
      accessToken: accessToken,
      body: {'reason': reason},
    );

    return ShiftTask.fromJson(decoded['task'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getResidentsJson({required String accessToken}) {
    return _getJson('/residents', accessToken: accessToken);
  }

  Future<List<ResidentListItem>> getResidents({
    required String accessToken,
  }) async {
    final decoded = await getResidentsJson(accessToken: accessToken);
    final residents = decoded['residents'] as List<dynamic>? ?? const [];
    return residents
        .map(
          (entry) => ResidentListItem.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
  }

  Future<Map<String, dynamic>> getResidentByIdJson({
    required String accessToken,
    required String residentId,
  }) {
    return _getJson('/residents/$residentId', accessToken: accessToken);
  }

  Future<ResidentDetail> getResidentById({
    required String accessToken,
    required String residentId,
  }) async {
    return ResidentDetail.fromJson(
      await getResidentByIdJson(
        accessToken: accessToken,
        residentId: residentId,
      ),
    );
  }

  Future<ResidentEmarProfile> getResidentEmar({
    required String accessToken,
    required String residentId,
  }) async {
    return ResidentEmarProfile.fromJson(
      await _getJson('/residents/$residentId/emar', accessToken: accessToken),
    );
  }

  Future<MedicationRoundSnapshot> getMedicationRound({
    required String accessToken,
    required String shiftId,
  }) async {
    return MedicationRoundSnapshot.fromJson(
      await _getJson(
        '/shifts/$shiftId/medication-round',
        accessToken: accessToken,
      ),
    );
  }

  Future<MedicationDoseActionResult> administerMedicationDose({
    required String accessToken,
    required String doseInstanceId,
    String? doseGiven,
    String? doseUnit,
    String? notes,
    String? witnessUserId,
  }) {
    return _postDoseOutcome(
      accessToken: accessToken,
      doseInstanceId: doseInstanceId,
      actionPath: 'administer',
      doseGiven: doseGiven,
      doseUnit: doseUnit,
      notes: notes,
      witnessUserId: witnessUserId,
    );
  }

  Future<MedicationDoseActionResult> refuseMedicationDose({
    required String accessToken,
    required String doseInstanceId,
    required String reason,
    String? notes,
    String? witnessUserId,
  }) {
    return _postDoseOutcome(
      accessToken: accessToken,
      doseInstanceId: doseInstanceId,
      actionPath: 'refuse',
      reason: reason,
      notes: notes,
      witnessUserId: witnessUserId,
    );
  }

  Future<MedicationDoseActionResult> omitMedicationDose({
    required String accessToken,
    required String doseInstanceId,
    required String reason,
    String? notes,
    String? witnessUserId,
  }) {
    return _postDoseOutcome(
      accessToken: accessToken,
      doseInstanceId: doseInstanceId,
      actionPath: 'omit',
      reason: reason,
      notes: notes,
      witnessUserId: witnessUserId,
    );
  }

  Future<MedicationDoseActionResult> delayMedicationDose({
    required String accessToken,
    required String doseInstanceId,
    required String reason,
    String? notes,
    String? witnessUserId,
  }) {
    return _postDoseOutcome(
      accessToken: accessToken,
      doseInstanceId: doseInstanceId,
      actionPath: 'delay',
      reason: reason,
      notes: notes,
      witnessUserId: witnessUserId,
    );
  }

  Future<MedicationDoseActionResult> markMedicationNotAvailable({
    required String accessToken,
    required String doseInstanceId,
    required String reason,
    String? notes,
    String? witnessUserId,
  }) {
    return _postDoseOutcome(
      accessToken: accessToken,
      doseInstanceId: doseInstanceId,
      actionPath: 'not-available',
      reason: reason,
      notes: notes,
      witnessUserId: witnessUserId,
    );
  }

  Future<MedicationDoseActionResult> holdMedicationDose({
    required String accessToken,
    required String doseInstanceId,
    required String reason,
    String? notes,
    String? witnessUserId,
  }) async {
    return MedicationDoseActionResult.fromJson(
      await _patchJson(
        '/medication-dose-instances/$doseInstanceId/status',
        accessToken: accessToken,
        body: {
          'status': MedicationDoseStatus.held.apiValue,
          'reason': reason.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          if (witnessUserId != null && witnessUserId.trim().isNotEmpty)
            'witnessUserId': witnessUserId.trim(),
        },
      ),
    );
  }

  Future<PrnEventResult> recordPrnEvent({
    required String accessToken,
    required String residentId,
    required String medicationOrderId,
    required MedicationAdministrationEventType eventType,
    required String reason,
    String? doseGiven,
    String? doseUnit,
    String? notes,
    String? witnessUserId,
  }) async {
    return PrnEventResult.fromJson(
      await _postJson(
        '/residents/$residentId/prn-events',
        accessToken: accessToken,
        body: {
          'medicationOrderId': medicationOrderId,
          'eventType': eventType.apiValue,
          'reason': reason,
          if (doseGiven != null && doseGiven.trim().isNotEmpty)
            'doseGiven': doseGiven.trim(),
          if (doseUnit != null && doseUnit.trim().isNotEmpty)
            'doseUnit': doseUnit.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          if (witnessUserId != null && witnessUserId.trim().isNotEmpty)
            'witnessUserId': witnessUserId.trim(),
        },
      ),
    );
  }

  Future<MedicationDoseActionResult> _postDoseOutcome({
    required String accessToken,
    required String doseInstanceId,
    required String actionPath,
    String? reason,
    String? doseGiven,
    String? doseUnit,
    String? notes,
    String? witnessUserId,
  }) async {
    return MedicationDoseActionResult.fromJson(
      await _postJson(
        '/medication-dose-instances/$doseInstanceId/$actionPath',
        accessToken: accessToken,
        body: {
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
          if (doseGiven != null && doseGiven.trim().isNotEmpty)
            'doseGiven': doseGiven.trim(),
          if (doseUnit != null && doseUnit.trim().isNotEmpty)
            'doseUnit': doseUnit.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          if (witnessUserId != null && witnessUserId.trim().isNotEmpty)
            'witnessUserId': witnessUserId.trim(),
        },
      ),
    );
  }

  Future<ResidentTimelineEntry> createResidentTimelineEntry({
    required String accessToken,
    required String residentId,
    required ResidentTimelineEntryDraft draft,
    String? clientRequestId,
    DateTime? recordedAt,
  }) async {
    if (draft.evidence != null) {
      final request = http.MultipartRequest(
        'POST',
        _uri('/residents/$residentId/timeline'),
      );
      request.headers.addAll(_headers(accessToken: accessToken));
      request.fields['type'] = draft.type.apiValue;
      request.fields['details'] = draft.details;
      if (draft.personalCareSubtype != null) {
        request.fields['personalCareSubtype'] =
            draft.personalCareSubtype!.apiValue;
      }
      if (draft.mealType != null) {
        request.fields['mealType'] = draft.mealType!.apiValue;
      }
      if (draft.mealIntakeAmount != null) {
        request.fields['mealIntakeAmount'] = draft.mealIntakeAmount!.apiValue;
      }
      if (clientRequestId != null && clientRequestId.trim().isNotEmpty) {
        request.fields['clientRequestId'] = clientRequestId.trim();
      }
      if (recordedAt != null) {
        request.fields['recordedAt'] = recordedAt.toUtc().toIso8601String();
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'evidence',
          draft.evidence!.bytes,
          filename: draft.evidence!.fileName,
          contentType: _mediaTypeHeaderValue(draft.evidence!.mediaType),
        ),
      );

      final decoded = await _multipartJson(request);
      return ResidentTimelineEntry.fromJson(
        decoded['entry'] as Map<String, dynamic>,
      );
    }

    final decoded = await _postJson(
      '/residents/$residentId/timeline',
      accessToken: accessToken,
      body: {
        ...draft.toJson(),
        if (clientRequestId != null && clientRequestId.trim().isNotEmpty)
          'clientRequestId': clientRequestId.trim(),
        if (recordedAt != null)
          'recordedAt': recordedAt.toUtc().toIso8601String(),
      },
    );

    return ResidentTimelineEntry.fromJson(
      decoded['entry'] as Map<String, dynamic>,
    );
  }

  Future<ResidentIncident> createResidentIncident({
    required String accessToken,
    required String residentId,
    required ResidentIncidentDraft draft,
    String? clientRequestId,
    DateTime? occurredAt,
  }) async {
    if (draft.evidence != null) {
      final request = http.MultipartRequest(
        'POST',
        _uri('/residents/$residentId/incidents'),
      );
      request.headers.addAll(_headers(accessToken: accessToken));
      request.fields['severity'] = draft.severity.apiValue;
      request.fields['category'] = draft.category.apiValue;
      request.fields['title'] = draft.title;
      request.fields['details'] = draft.details;
      if (clientRequestId != null && clientRequestId.trim().isNotEmpty) {
        request.fields['clientRequestId'] = clientRequestId.trim();
      }
      if (occurredAt != null) {
        request.fields['occurredAt'] = occurredAt.toUtc().toIso8601String();
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'evidence',
          draft.evidence!.bytes,
          filename: draft.evidence!.fileName,
          contentType: _mediaTypeHeaderValue(draft.evidence!.mediaType),
        ),
      );

      final decoded = await _multipartJson(request);
      return ResidentIncident.fromJson(
        decoded['incident'] as Map<String, dynamic>,
      );
    }

    final decoded = await _postJson(
      '/residents/$residentId/incidents',
      accessToken: accessToken,
      body: {
        ...draft.toJson(),
        if (clientRequestId != null && clientRequestId.trim().isNotEmpty)
          'clientRequestId': clientRequestId.trim(),
        if (occurredAt != null)
          'occurredAt': occurredAt.toUtc().toIso8601String(),
      },
    );

    return ResidentIncident.fromJson(
      decoded['incident'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.body.isEmpty) {
      _checkError(response, const <String, dynamic>{});
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(response.body);
    _checkError(response, decoded);
    return decoded as Map<String, dynamic>;
  }

  void _checkError(http.Response response, dynamic decoded) {
    if (response.statusCode < 400) {
      return;
    }

    String? code;
    if (decoded is Map<String, dynamic>) {
      final rawCode = decoded['code'];
      if (rawCode is String && rawCode.trim().isNotEmpty) {
        code = rawCode.trim();
      }

      final message = decoded['message'];
      if (message is String) {
        throw ApiException(
          message,
          statusCode: response.statusCode,
          code: code,
          isUnauthorized: response.statusCode == 401,
        );
      }
      if (message is List && message.isNotEmpty) {
        throw ApiException(
          message.join(', '),
          statusCode: response.statusCode,
          code: code,
          isUnauthorized: response.statusCode == 401,
        );
      }
    }

    throw ApiException(
      'Request failed with status ${response.statusCode}.',
      statusCode: response.statusCode,
      code: code,
      isUnauthorized: response.statusCode == 401,
    );
  }

  MediaType? _mediaTypeHeaderValue(String mediaType) {
    final segments = mediaType.split('/');
    if (segments.length != 2) {
      return null;
    }

    return MediaType(segments.first, segments.last);
  }
}

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.isNetworkError = false,
    this.isUnauthorized = false,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final bool isNetworkError;
  final bool isUnauthorized;

  bool get isRetryableServerError =>
      statusCode != null && statusCode! >= 500 && statusCode! < 600;

  @override
  String toString() => message;
}
