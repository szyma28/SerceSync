import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/handover.dart';
import '../models/task.dart';

class SerceSyncApiClient {
  SerceSyncApiClient({required this.baseUrl});

  final String baseUrl;

  Uri _uri(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl$path');
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

    final decoded = _decodeJsonList(response);
    return decoded
        .map((e) => ShiftTask.fromJson(e as Map<String, dynamic>))
        .toList();
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

    return ShiftTask.fromJson(_decodeJson(response));
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

    return ShiftTask.fromJson(_decodeJson(response));
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

    return ShiftTask.fromJson(_decodeJson(response));
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    final dynamic decoded = jsonDecode(response.body);
    _checkError(response, decoded);
    return decoded as Map<String, dynamic>;
  }

  List<dynamic> _decodeJsonList(http.Response response) {
    if (response.body.isEmpty) return [];
    final dynamic decoded = jsonDecode(response.body);
    _checkError(response, decoded);
    return decoded as List<dynamic>;
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
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
