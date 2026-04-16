import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/handover.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/workspace_models.dart';

class SerceSyncApiClient {
  SerceSyncApiClient({required this.baseUrl});

  final String baseUrl;

  Uri _uri(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl$path');
  }

  String resolveMediaUrl(String downloadPath) {
    return _uri(downloadPath).toString();
  }

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return LoginResponse.fromJson(_decodeJson(response));
  }

  Future<HandoverSnapshot> getCurrentHandover({
    required String accessToken,
  }) async {
    final response = await http.get(
      _uri('/handovers/current'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    return HandoverSnapshot.fromJson(_decodeJson(response));
  }

  Future<HandoverSnapshot> acknowledgeCurrentHandover({
    required String accessToken,
  }) async {
    final response = await http.post(
      _uri('/handovers/current/acknowledge'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    return HandoverSnapshot.fromJson(_decodeJson(response));
  }

  Future<List<ShiftTask>> getCurrentTasks({required String accessToken}) async {
    final response = await http.get(
      _uri('/tasks/current'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final decoded = _decodeJson(response);
    final tasks = decoded['tasks'] as List<dynamic>? ?? const [];
    return tasks
        .map((entry) => ShiftTask.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<ShiftOverview> getShiftOverview({required String accessToken}) async {
    final response = await http.get(
      _uri('/shifts/my'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    return ShiftOverview.fromJson(_decodeJson(response));
  }

  Future<ShiftTask> completeTask({
    required String accessToken,
    required String taskId,
    String? note,
  }) async {
    final response = await http.post(
      _uri('/tasks/$taskId/complete'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: note != null ? jsonEncode({'note': note}) : null,
    );

    final decoded = _decodeJson(response);
    return ShiftTask.fromJson(decoded['task'] as Map<String, dynamic>);
  }

  Future<ShiftTask> deferTask({
    required String accessToken,
    required String taskId,
    required String reason,
  }) async {
    final response = await http.post(
      _uri('/tasks/$taskId/defer'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );

    final decoded = _decodeJson(response);
    return ShiftTask.fromJson(decoded['task'] as Map<String, dynamic>);
  }

  Future<ShiftTask> escalateTask({
    required String accessToken,
    required String taskId,
    required String reason,
  }) async {
    final response = await http.post(
      _uri('/tasks/$taskId/escalate'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'reason': reason}),
    );

    final decoded = _decodeJson(response);
    return ShiftTask.fromJson(decoded['task'] as Map<String, dynamic>);
  }

  Future<List<ResidentListItem>> getResidents({
    required String accessToken,
  }) async {
    final response = await http.get(
      _uri('/residents'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final decoded = _decodeJson(response);
    final residents = decoded['residents'] as List<dynamic>? ?? const [];
    return residents
        .map(
          (entry) => ResidentListItem.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ResidentDetail> getResidentById({
    required String accessToken,
    required String residentId,
  }) async {
    final response = await http.get(
      _uri('/residents/$residentId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    return ResidentDetail.fromJson(_decodeJson(response));
  }

  Future<ResidentTimelineEntry> createResidentTimelineEntry({
    required String accessToken,
    required String residentId,
    required ResidentTimelineEntryDraft draft,
  }) async {
    if (draft.evidence != null) {
      final request = http.MultipartRequest(
        'POST',
        _uri('/residents/$residentId/timeline'),
      );
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['type'] = draft.type.apiValue;
      request.fields['details'] = draft.details;
      if (draft.personalCareSubtype != null) {
        request.fields['personalCareSubtype'] =
            draft.personalCareSubtype!.apiValue;
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'evidence',
          draft.evidence!.bytes,
          filename: draft.evidence!.fileName,
          contentType: _mediaTypeHeaderValue(draft.evidence!.mediaType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = _decodeJson(response);
      return ResidentTimelineEntry.fromJson(
        decoded['entry'] as Map<String, dynamic>,
      );
    }

    final response = await http.post(
      _uri('/residents/$residentId/timeline'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(draft.toJson()),
    );

    final decoded = _decodeJson(response);
    return ResidentTimelineEntry.fromJson(
      decoded['entry'] as Map<String, dynamic>,
    );
  }

  Future<ResidentIncident> createResidentIncident({
    required String accessToken,
    required String residentId,
    required ResidentIncidentDraft draft,
  }) async {
    if (draft.evidence != null) {
      final request = http.MultipartRequest(
        'POST',
        _uri('/residents/$residentId/incidents'),
      );
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['severity'] = draft.severity.apiValue;
      request.fields['category'] = draft.category.apiValue;
      request.fields['title'] = draft.title;
      request.fields['details'] = draft.details;
      request.files.add(
        http.MultipartFile.fromBytes(
          'evidence',
          draft.evidence!.bytes,
          filename: draft.evidence!.fileName,
          contentType: _mediaTypeHeaderValue(draft.evidence!.mediaType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = _decodeJson(response);
      return ResidentIncident.fromJson(
        decoded['incident'] as Map<String, dynamic>,
      );
    }

    final response = await http.post(
      _uri('/residents/$residentId/incidents'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(draft.toJson()),
    );

    final decoded = _decodeJson(response);
    return ResidentIncident.fromJson(
      decoded['incident'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    final dynamic decoded = jsonDecode(response.body);
    _checkError(response, decoded);
    return decoded as Map<String, dynamic>;
  }

  void _checkError(http.Response response, dynamic decoded) {
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
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
