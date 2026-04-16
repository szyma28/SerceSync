import 'package:http/http.dart' as http;

import 'manager_http_client_stub.dart'
    if (dart.library.html) 'manager_http_client_web.dart';

http.Client createManagerHttpClient() {
  return createPlatformManagerHttpClient();
}
