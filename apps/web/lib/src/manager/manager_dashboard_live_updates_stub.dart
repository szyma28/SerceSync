import 'manager_dashboard_live_updates_api.dart';

ManagerDashboardLiveUpdatesConnector createManagerDashboardLiveUpdatesConnector(
  String baseUrl,
) {
  return _UnsupportedManagerDashboardLiveUpdatesConnector();
}

class _UnsupportedManagerDashboardLiveUpdatesConnector
    implements ManagerDashboardLiveUpdatesConnector {
  @override
  Stream<ManagerDashboardLiveUpdate> connect({
    required String accessToken,
    String? shiftId,
  }) {
    return const Stream<ManagerDashboardLiveUpdate>.empty();
  }
}
