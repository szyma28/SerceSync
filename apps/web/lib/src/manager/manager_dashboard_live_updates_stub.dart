import 'manager_dashboard_live_updates.dart';

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
    required String shiftId,
  }) {
    return const Stream<ManagerDashboardLiveUpdate>.empty();
  }
}
