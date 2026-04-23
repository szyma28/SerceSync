import 'dart:async';

import 'package:flutter/foundation.dart';

import 'manager_api_client.dart';
import 'manager_dashboard_live_updates_api.dart';
import 'manager_models.dart';
import 'manager_theme.dart';

class ManagerWorkspaceController extends ChangeNotifier {
  ManagerWorkspaceController({
    required this.apiClient,
    required this.session,
    required this.renewSessionSilently,
  });

  final SerceSyncManagerApiClient apiClient;
  final ManagerSession session;
  final Future<bool> Function() renewSessionSilently;

  WorkspaceTab _selectedTab = WorkspaceTab.dashboard;
  ManagerDashboardSnapshot? _dashboard;
  List<ManagerShiftSummary> _activeShifts = const [];
  List<ManagerResidentRecord> _residents = const [];
  bool _isDashboardLoading = true;
  bool _isResidentsLoading = true;
  bool _isSavingResident = false;
  String? _dashboardError;
  String? _residentsError;
  DateTime? _dashboardLastUpdatedAt;
  DateTime? _residentsLastUpdatedAt;
  final Set<String> _incidentActionIds = <String>{};
  int _dashboardLoadVersion = 0;
  Future<bool>? _sessionRecovery;
  final Map<String, StreamSubscription<ManagerDashboardLiveUpdate>>
  _dashboardLiveUpdatesSubscriptions = {};

  WorkspaceTab get selectedTab => _selectedTab;
  ManagerDashboardSnapshot? get dashboard => _dashboard;
  List<ManagerShiftSummary> get activeShifts => _activeShifts;
  List<ManagerResidentRecord> get residents => _residents;
  bool get isDashboardLoading => _isDashboardLoading;
  bool get isResidentsLoading => _isResidentsLoading;
  bool get isSavingResident => _isSavingResident;
  String? get dashboardError => _dashboardError;
  String? get residentsError => _residentsError;
  DateTime? get dashboardLastUpdatedAt => _dashboardLastUpdatedAt;
  DateTime? get residentsLastUpdatedAt => _residentsLastUpdatedAt;
  Set<String> get pendingIncidentIds => _incidentActionIds;

  String get headerTitle {
    switch (_selectedTab) {
      case WorkspaceTab.dashboard:
        return 'Manager dashboard';
      case WorkspaceTab.residents:
        return 'Residents';
      case WorkspaceTab.compliance:
        return 'Reporting';
      case WorkspaceTab.console:
        return 'Operational tools';
    }
  }

  void initialize() {
    unawaited(loadDashboard());
    unawaited(loadResidents());
  }

  void _sortResidents(List<ManagerResidentRecord> residents) {
    residents.sort((left, right) {
      final floorOrder = left.floorNumber.compareTo(right.floorNumber);
      if (floorOrder != 0) {
        return floorOrder;
      }

      final unitOrder = left.unitLabel.compareTo(right.unitLabel);
      if (unitOrder != 0) {
        return unitOrder;
      }

      final roomOrder = left.roomNumber.compareTo(right.roomNumber);
      if (roomOrder != 0) {
        return roomOrder;
      }

      return left.fullName.compareTo(right.fullName);
    });
  }

  bool _isCurrentDashboardLoad(int loadVersion) {
    return loadVersion == _dashboardLoadVersion;
  }

  String _describeRequestError(
    Object error, {
    required String unavailableMessage,
  }) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'Your manager session expired. Sign in again to continue.';
      }
      return error.message;
    }

    return unavailableMessage;
  }

  Future<bool> _recoverSession() {
    final activeRecovery = _sessionRecovery;
    if (activeRecovery != null) {
      return activeRecovery;
    }

    final recovery = renewSessionSilently();
    _sessionRecovery = recovery.whenComplete(() {
      _sessionRecovery = null;
    });
    return _sessionRecovery!;
  }

  Future<T> _runWithSessionRecovery<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }

      final recovered = await _recoverSession();
      if (!recovered) {
        rethrow;
      }

      return operation();
    }
  }

  void _cancelDashboardLiveUpdates() {
    final subscriptions = _dashboardLiveUpdatesSubscriptions.values.toList(
      growable: false,
    );
    _dashboardLiveUpdatesSubscriptions.clear();
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  }

  void _handleDashboardLiveUpdate(ManagerDashboardLiveUpdate update) {
    if (_selectedTab != WorkspaceTab.dashboard ||
        update.type != ManagerDashboardLiveUpdateType.updated ||
        _isDashboardLoading ||
        _incidentActionIds.isNotEmpty) {
      return;
    }

    if (!_activeShifts.any((shift) => shift.id == update.shiftId)) {
      return;
    }

    unawaited(loadDashboard());
  }

  void _syncDashboardLiveUpdates() {
    if (_selectedTab != WorkspaceTab.dashboard || _activeShifts.isEmpty) {
      _cancelDashboardLiveUpdates();
      return;
    }

    final activeShiftIds = _activeShifts.map((shift) => shift.id).toSet();
    final obsoleteShiftIds = _dashboardLiveUpdatesSubscriptions.keys
        .where((shiftId) => !activeShiftIds.contains(shiftId))
        .toList(growable: false);

    for (final shiftId in obsoleteShiftIds) {
      _dashboardLiveUpdatesSubscriptions.remove(shiftId)?.cancel();
    }

    for (final shift in _activeShifts) {
      _dashboardLiveUpdatesSubscriptions.putIfAbsent(
        shift.id,
        () => apiClient
            .watchDashboard(accessToken: session.accessToken, shiftId: shift.id)
            .listen(_handleDashboardLiveUpdate),
      );
    }
  }

  Future<void> loadDashboard({bool clearSnapshot = false}) async {
    final loadVersion = ++_dashboardLoadVersion;
    var activeShifts = const <ManagerShiftSummary>[];

    _isDashboardLoading = true;
    _dashboardError = null;
    if (clearSnapshot) {
      _dashboard = null;
    }
    notifyListeners();

    try {
      activeShifts = await _runWithSessionRecovery(
        () => apiClient.getActiveShifts(accessToken: session.accessToken),
      );

      if (!_isCurrentDashboardLoad(loadVersion)) return;

      if (activeShifts.isEmpty) {
        _activeShifts = const [];
        _dashboard = null;
        _dashboardLastUpdatedAt = DateTime.now();
        _syncDashboardLiveUpdates();
        return;
      }

      final dashboard = await _runWithSessionRecovery(
        () => apiClient.getDashboard(accessToken: session.accessToken),
      );

      if (!_isCurrentDashboardLoad(loadVersion)) return;
      _activeShifts = activeShifts;
      _dashboard = dashboard;
      _dashboardLastUpdatedAt = DateTime.now();
      _syncDashboardLiveUpdates();
    } on Object catch (error) {
      if (!_isCurrentDashboardLoad(loadVersion)) return;
      if (activeShifts.isNotEmpty || _activeShifts.isEmpty) {
        _activeShifts = activeShifts;
      }
      _dashboardError = _describeRequestError(
        error,
        unavailableMessage:
            'The manager dashboard can’t reach the API right now. Keep this view open and refresh once the connection comes back.',
      );
      _syncDashboardLiveUpdates();
    } finally {
      if (_isCurrentDashboardLoad(loadVersion)) {
        _isDashboardLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadResidents() async {
    _isResidentsLoading = true;
    _residentsError = null;
    notifyListeners();

    try {
      final residents = await _runWithSessionRecovery(
        () => apiClient.getResidents(accessToken: session.accessToken),
      );
      _sortResidents(residents);
      _residents = residents;
      _residentsLastUpdatedAt = DateTime.now();
    } on Object catch (error) {
      _residentsError = _describeRequestError(
        error,
        unavailableMessage:
            'Resident records can’t reach the API right now. Keep this tab open and try again once the connection returns.',
      );
    } finally {
      _isResidentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshOperationalData() async {
    await Future.wait([loadDashboard(), loadResidents()]);
  }

  Future<void> refreshSelectedTab() async {
    switch (_selectedTab) {
      case WorkspaceTab.dashboard:
        await loadDashboard();
        break;
      case WorkspaceTab.residents:
        await loadResidents();
        break;
      case WorkspaceTab.compliance:
        await refreshOperationalData();
        break;
      case WorkspaceTab.console:
        break;
    }
  }

  void selectTab(WorkspaceTab tab) {
    _selectedTab = tab;
    _syncDashboardLiveUpdates();
    notifyListeners();
  }

  Future<bool> saveResident({
    required ManagerResidentDraft draft,
    String? residentId,
  }) async {
    _isSavingResident = true;
    _residentsError = null;
    notifyListeners();

    try {
      if (residentId == null) {
        await _runWithSessionRecovery(
          () => apiClient.createResident(
            accessToken: session.accessToken,
            draft: draft,
          ),
        );
      } else {
        await _runWithSessionRecovery(
          () => apiClient.updateResident(
            accessToken: session.accessToken,
            residentId: residentId,
            draft: draft,
          ),
        );
      }

      await loadResidents();
      return true;
    } on Object catch (error) {
      _residentsError = _describeRequestError(
        error,
        unavailableMessage:
            'The resident record could not be saved because the API is unavailable right now.',
      );
      notifyListeners();
      return false;
    } finally {
      _isSavingResident = false;
      notifyListeners();
    }
  }

  Future<void> _runIncidentAction({
    required String incidentId,
    required Future<void> Function() action,
  }) async {
    if (_incidentActionIds.contains(incidentId)) {
      return;
    }

    _incidentActionIds.add(incidentId);
    _dashboardError = null;
    notifyListeners();

    try {
      await _runWithSessionRecovery(action);
      await refreshOperationalData();
    } finally {
      _incidentActionIds.remove(incidentId);
      notifyListeners();
    }
  }

  Future<void> acknowledgeIncident(String incidentId, String shiftId) {
    return _runIncidentAction(
      incidentId: incidentId,
      action: () => apiClient.acknowledgeIncident(
        accessToken: session.accessToken,
        incidentId: incidentId,
        shiftId: shiftId,
      ),
    );
  }

  Future<void> resolveIncident(String incidentId, String shiftId) {
    return _runIncidentAction(
      incidentId: incidentId,
      action: () => apiClient.resolveIncident(
        accessToken: session.accessToken,
        incidentId: incidentId,
        shiftId: shiftId,
      ),
    );
  }

  @override
  void dispose() {
    _cancelDashboardLiveUpdates();
    super.dispose();
  }
}
