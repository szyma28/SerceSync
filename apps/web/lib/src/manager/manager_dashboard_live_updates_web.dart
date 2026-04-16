import 'dart:async';
import 'dart:convert';
import 'package:web/web.dart' as web;

import 'manager_dashboard_live_updates.dart';

ManagerDashboardLiveUpdatesConnector createManagerDashboardLiveUpdatesConnector(
  String baseUrl,
) {
  return _WebManagerDashboardLiveUpdatesConnector(baseUrl);
}

class _WebManagerDashboardLiveUpdatesConnector
    implements ManagerDashboardLiveUpdatesConnector {
  _WebManagerDashboardLiveUpdatesConnector(this.baseUrl);

  final String baseUrl;

  Uri _uri(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl$path');
  }

  @override
  Stream<ManagerDashboardLiveUpdate> connect({
    required String accessToken,
    required String shiftId,
  }) {
    late final StreamController<ManagerDashboardLiveUpdate> controller;
    web.EventSource? eventSource;
    StreamSubscription<web.MessageEvent>? messageSubscription;

    controller = StreamController<ManagerDashboardLiveUpdate>(
      onListen: () {
        final uri = _uri('/manager/dashboard/stream?shiftId=$shiftId');

        eventSource = web.EventSource(
          uri.toString(),
          web.EventSourceInit(withCredentials: true),
        );
        messageSubscription = eventSource!.onMessage.listen((event) {
          final data = event.data?.toString();
          if (data == null || data.trim().isEmpty) {
            return;
          }

          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) {
            controller.add(ManagerDashboardLiveUpdate.fromJson(decoded));
          }
        });
      },
      onCancel: () async {
        await messageSubscription?.cancel();
        eventSource?.close();
      },
    );

    return controller.stream;
  }
}
