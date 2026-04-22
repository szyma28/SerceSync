import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/handover.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/workspace_models.dart';

class ShiftWorkspaceController extends ChangeNotifier {
  ShiftWorkspaceController({
    required this.apiClient,
    required this.accessToken,
    required this.user,
    required this.snapshot,
  }) {
    refreshPriorities();
    refreshOverview();
  }

  final SerceSyncApiClient apiClient;
  final String accessToken;
  final LoginUser user;
  HandoverSnapshot snapshot;

  List<ShiftTask> _tasks = const [];
  ShiftOverview? _overview;
  bool _isPrioritiesLoading = true;
  bool _isOverviewLoading = true;
  String? _prioritiesErrorMessage;
  String? _overviewErrorMessage;

  List<ShiftTask> get tasks => _tasks;
  ShiftOverview? get overview => _overview;
  bool get isPrioritiesLoading => _isPrioritiesLoading;
  bool get isOverviewLoading => _isOverviewLoading;
  String? get prioritiesErrorMessage => _prioritiesErrorMessage;
  String? get overviewErrorMessage => _overviewErrorMessage;

  String get shiftName => snapshot.shift.name;
  String get shiftId => snapshot.shift.id;
  ShiftAssignment? get currentShift => _overview?.currentShift;
  bool get handoverAcknowledged =>
      currentShift?.handoverAcknowledged ?? snapshot.acknowledged;
  String get currentCarerName => user.displayName;
  AppUserRole get currentUserRole => user.role;

  Future<void> refreshPriorities() async {
    _isPrioritiesLoading = true;
    _prioritiesErrorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        apiClient.getCurrentTasks(accessToken: accessToken),
        apiClient.getShiftOverview(accessToken: accessToken),
      ]);

      _tasks = results[0] as List<ShiftTask>;
      _overview = results[1] as ShiftOverview;
      _overviewErrorMessage = null;
    } on ApiException catch (error) {
      _prioritiesErrorMessage = error.message;
    } finally {
      _isPrioritiesLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshOverview() async {
    _isOverviewLoading = true;
    _overviewErrorMessage = null;
    notifyListeners();

    try {
      _overview = await apiClient.getShiftOverview(accessToken: accessToken);
    } on ApiException catch (error) {
      _overviewErrorMessage = error.message;
    } finally {
      _isOverviewLoading = false;
      notifyListeners();
    }
  }
}
