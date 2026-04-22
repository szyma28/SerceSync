import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/handover.dart';
import '../models/user.dart';

class MobileSessionController extends ChangeNotifier {
  bool _isAuthenticating = false;
  String? _authErrorMessage;
  bool _isHandoverLoading = false;
  String? _handoverErrorMessage;

  SerceSyncApiClient? _apiClient;
  String? _accessToken;
  LoginUser? _user;
  HandoverSnapshot? _handoverSnapshot;

  bool get isAuthenticating => _isAuthenticating;
  String? get authErrorMessage => _authErrorMessage;
  bool get isHandoverLoading => _isHandoverLoading;
  String? get handoverErrorMessage => _handoverErrorMessage;

  SerceSyncApiClient? get apiClient => _apiClient;
  String? get accessToken => _accessToken;
  LoginUser? get user => _user;
  HandoverSnapshot? get handoverSnapshot => _handoverSnapshot;

  bool get hasActiveSession =>
      _apiClient != null &&
      _accessToken != null &&
      _accessToken!.trim().isNotEmpty &&
      _user != null;

  Future<bool> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    _isAuthenticating = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final client = SerceSyncApiClient(baseUrl: baseUrl.trim());
      final response = await client.login(
        email: email.trim(),
        password: password,
      );

      _apiClient = client;
      _accessToken = response.accessToken;
      _user = response.user;
      _handoverSnapshot = null;
      return true;
    } on ApiException catch (error) {
      _authErrorMessage = error.message;
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentHandover({bool forceRefresh = false}) async {
    if (!hasActiveSession) {
      return;
    }
    if (!forceRefresh && _handoverSnapshot != null) {
      return;
    }

    _isHandoverLoading = true;
    _handoverErrorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _apiClient!.getCurrentHandover(
        accessToken: _accessToken!,
      );
      _handoverSnapshot = snapshot;
    } on ApiException catch (error) {
      _handoverErrorMessage = error.message;
    } finally {
      _isHandoverLoading = false;
      notifyListeners();
    }
  }

  Future<void> acknowledgeCurrentHandover() async {
    if (!hasActiveSession) {
      return;
    }

    _isHandoverLoading = true;
    _handoverErrorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _apiClient!.acknowledgeCurrentHandover(
        accessToken: _accessToken!,
      );
      _handoverSnapshot = snapshot;
    } on ApiException catch (error) {
      _handoverErrorMessage = error.message;
    } finally {
      _isHandoverLoading = false;
      notifyListeners();
    }
  }

  void clearSession() {
    _isAuthenticating = false;
    _authErrorMessage = null;
    _isHandoverLoading = false;
    _handoverErrorMessage = null;
    _apiClient = null;
    _accessToken = null;
    _user = null;
    _handoverSnapshot = null;
    notifyListeners();
  }
}
