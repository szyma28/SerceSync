import 'manager_dashboard_live_updates_stub.dart'
    if (dart.library.html) 'manager_dashboard_live_updates_web.dart';

enum ManagerDashboardLiveUpdateType { connected, updated }

class ManagerDashboardLiveUpdate {
  const ManagerDashboardLiveUpdate({
    required this.type,
    required this.shiftId,
    required this.eventId,
    required this.occurredAt,
    required this.reason,
  });

  factory ManagerDashboardLiveUpdate.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardLiveUpdate(
      type: switch (json['type']) {
        'stream.connected' => ManagerDashboardLiveUpdateType.connected,
        'dashboard.updated' => ManagerDashboardLiveUpdateType.updated,
        _ => ManagerDashboardLiveUpdateType.updated,
      },
      shiftId: json['shiftId'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      occurredAt:
          DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.now(),
      reason: json['reason'] as String? ?? 'unknown',
    );
  }

  final ManagerDashboardLiveUpdateType type;
  final String shiftId;
  final String eventId;
  final DateTime occurredAt;
  final String reason;
}

abstract class ManagerDashboardLiveUpdatesConnector {
  Stream<ManagerDashboardLiveUpdate> connect({
    required String accessToken,
    required String shiftId,
  });
}

ManagerDashboardLiveUpdatesConnector buildManagerDashboardLiveUpdatesConnector(
  String baseUrl,
) {
  return createManagerDashboardLiveUpdatesConnector(baseUrl);
}
