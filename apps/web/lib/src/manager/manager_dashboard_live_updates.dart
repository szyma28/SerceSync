import 'manager_dashboard_live_updates_api.dart';
import 'manager_dashboard_live_updates_stub.dart'
    if (dart.library.html) 'manager_dashboard_live_updates_web.dart';

ManagerDashboardLiveUpdatesConnector buildManagerDashboardLiveUpdatesConnector(
  String baseUrl,
) {
  return createManagerDashboardLiveUpdatesConnector(baseUrl);
}
