import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client createPlatformManagerHttpClient() {
  final client = BrowserClient();
  client.withCredentials = true;
  return client;
}
