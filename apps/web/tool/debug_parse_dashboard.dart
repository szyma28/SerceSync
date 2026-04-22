import 'dart:convert';
import 'dart:io';

import 'package:sercesync_web/manager_app.dart';

void main() async {
  final client = HttpClient();
  final loginRequest = await client.postUrl(
    Uri.parse('http://localhost:3000/auth/manager/login'),
  );
  loginRequest.headers.contentType = ContentType.json;
  loginRequest.write(
    jsonEncode({
      'email': 'manager@sercesync.local',
      'password': 'Password123!',
    }),
  );
  final loginResponse = await loginRequest.close();
  final cookies = loginResponse.cookies;
  await utf8.decoder.bind(loginResponse).join();

  final dashboardRequest = await client.getUrl(
    Uri.parse('http://localhost:3000/manager/dashboard'),
  );
  for (final cookie in cookies) {
    dashboardRequest.cookies.add(cookie);
  }
  final dashboardResponse = await dashboardRequest.close();
  final body = await utf8.decoder.bind(dashboardResponse).join();
  final decoded = jsonDecode(body) as Map<String, dynamic>;

  stdout.writeln('status: ${dashboardResponse.statusCode}');
  stdout.writeln(
    'activeShifts raw: ${(decoded['activeShifts'] as List).length}',
  );
  final snapshot = ManagerDashboardSnapshot.fromJson(decoded);
  stdout.writeln('parsed active shift: ${snapshot.activeShift.name}');
  stdout.writeln('parsed incidents: ${snapshot.exceptionFeed.length}');
}
