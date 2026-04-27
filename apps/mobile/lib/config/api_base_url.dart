import 'dart:io';

const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

String defaultApiBaseUrl() {
  final override = _apiBaseUrlOverride.trim();
  if (override.isNotEmpty) {
    return override;
  }

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3000';
  }

  return 'http://localhost:3000';
}
