import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';

class MobileSessionStorage {
  MobileSessionStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _sessionStorageKey = 'sercesync.mobile.session';

  final FlutterSecureStorage _secureStorage;

  Future<PersistedMobileSession?> readSession() async {
    final rawValue = await _secureStorage.read(key: _sessionStorageKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawValue) as Map<String, dynamic>;
    return PersistedMobileSession.fromJson(decoded);
  }

  Future<void> writeSession(PersistedMobileSession session) {
    return _secureStorage.write(
      key: _sessionStorageKey,
      value: jsonEncode(session.toJson()),
    );
  }

  Future<void> clearSession() {
    return _secureStorage.delete(key: _sessionStorageKey);
  }
}
