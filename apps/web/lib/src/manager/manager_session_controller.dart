import 'package:flutter/foundation.dart';

import 'manager_api_client.dart';
import 'manager_models.dart';

class ManagerSessionController extends ChangeNotifier {
  ManagerSessionController({required this.apiClient});

  final SerceSyncManagerApiClient apiClient;

  ManagerSession? _session;
  bool _isRestoringSession = true;
  String? _restoreErrorMessage;
  bool _isAuthenticating = false;
  String? _authErrorMessage;

  ManagerSession? get session => _session;
  bool get isRestoringSession => _isRestoringSession;
  String? get restoreErrorMessage => _restoreErrorMessage;
  bool get isAuthenticating => _isAuthenticating;
  String? get authErrorMessage => _authErrorMessage;

  Future<void> restoreSession() async {
    _isRestoringSession = true;
    _restoreErrorMessage = null;
    notifyListeners();

    try {
      _session = await apiClient.restoreSession();
      _restoreErrorMessage = null;
    } on ApiException catch (error) {
      _session = null;
      _restoreErrorMessage = error.statusCode == 401 ? null : error.message;
    } finally {
      _isRestoringSession = false;
      notifyListeners();
    }
  }

  Future<bool> renewSessionSilently() async {
    try {
      _session = await apiClient.restoreSession();
      _restoreErrorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        _session = null;
        notifyListeners();
        return false;
      }

      return _session != null;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isAuthenticating = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      _session = await apiClient.login(email: email, password: password);
      _restoreErrorMessage = null;
      return true;
    } on ApiException catch (error) {
      _authErrorMessage = error.message;
      return false;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<String?> logout() async {
    try {
      await apiClient.logout();
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        return error.message;
      }
    }

    _session = null;
    notifyListeners();
    return null;
  }
}
