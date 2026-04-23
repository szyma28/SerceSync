import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/handover.dart';
import '../models/task.dart';
import '../models/workspace_models.dart';
import '../offline/offline_models.dart';
import 'mobile_session_controller.dart';

class ShiftWorkspaceController extends ChangeNotifier {
  ShiftWorkspaceController({required this.sessionController}) {
    sessionController.addListener(_handleSessionUpdated);
    refreshPriorities();
    refreshOverview();
  }

  final MobileSessionController sessionController;

  List<ShiftTask> _tasks = const [];
  ShiftOverview? _overview;
  bool _isPrioritiesLoading = true;
  bool _isOverviewLoading = true;
  String? _prioritiesErrorMessage;
  String? _overviewErrorMessage;
  DateTime? _prioritiesLastUpdatedAt;
  DateTime? _overviewLastUpdatedAt;
  bool _showingCachedPrioritiesData = false;
  bool _showingCachedOverviewData = false;

  List<ShiftTask> get tasks => _tasks;
  ShiftOverview? get overview => _overview;
  bool get isPrioritiesLoading => _isPrioritiesLoading;
  bool get isOverviewLoading => _isOverviewLoading;
  String? get prioritiesErrorMessage => _prioritiesErrorMessage;
  String? get overviewErrorMessage => _overviewErrorMessage;
  DateTime? get prioritiesLastUpdatedAt => _prioritiesLastUpdatedAt;
  DateTime? get overviewLastUpdatedAt => _overviewLastUpdatedAt;
  bool get showingCachedPrioritiesData => _showingCachedPrioritiesData;
  bool get showingCachedOverviewData => _showingCachedOverviewData;
  SerceSyncApiClient get apiClient => sessionController.apiClient!;
  String get accessToken => sessionController.accessToken ?? '';

  String get shiftName =>
      _overview?.currentShift?.name ?? snapshot?.shift.name ?? 'Current shift';
  String get shiftId => _overview?.currentShift?.id ?? snapshot?.shift.id ?? '';
  ShiftAssignment? get currentShift => _overview?.currentShift;
  HandoverSnapshot? get snapshot => sessionController.handoverSnapshot;
  bool get handoverAcknowledged =>
      currentShift?.handoverAcknowledged ?? snapshot?.acknowledged ?? false;
  String get currentCarerName => sessionController.user?.displayName ?? '';
  AppUserRole get currentUserRole =>
      sessionController.user?.role ?? AppUserRole.carer;

  String? _toErrorMessage(Object error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return null;
  }

  void _applyCachedOverview(
    CachedResource<ShiftOverview> cachedOverview, {
    required bool markPrioritiesAsCached,
    required bool markOverviewAsCached,
  }) {
    _overview = cachedOverview.data;
    if (markPrioritiesAsCached) {
      _showingCachedPrioritiesData = true;
    }
    if (markOverviewAsCached) {
      _overviewLastUpdatedAt = cachedOverview.fetchedAt;
      _showingCachedOverviewData = true;
    }
  }

  Future<void> refreshPriorities() async {
    final session = await sessionController.resolveSession(
      refreshIfNeeded: true,
    );
    if (session == null) {
      return;
    }

    final workspaceRepository = sessionController.workspaceRepository;
    final cachedTasks = await workspaceRepository.readCachedCurrentTasks(
      session,
    );
    final cachedOverview = await workspaceRepository.readCachedShiftOverview(
      session,
    );

    if (cachedTasks != null) {
      _tasks = cachedTasks.data;
      _prioritiesLastUpdatedAt = cachedTasks.fetchedAt;
      _showingCachedPrioritiesData = true;
    }
    if (cachedOverview != null) {
      _applyCachedOverview(
        cachedOverview,
        markPrioritiesAsCached: true,
        markOverviewAsCached: false,
      );
    }
    if (cachedTasks != null || cachedOverview != null) {
      notifyListeners();
    }

    _isPrioritiesLoading = true;
    _prioritiesErrorMessage = null;
    notifyListeners();

    try {
      final refreshedTasks = await workspaceRepository.refreshCurrentTasks(
        session,
      );
      _tasks = refreshedTasks.data;
      _prioritiesLastUpdatedAt = refreshedTasks.fetchedAt;
      _showingCachedPrioritiesData = false;
    } catch (error) {
      final message = _toErrorMessage(error);
      if (message != null) {
        _prioritiesErrorMessage = message;
      }
    }

    try {
      final refreshedOverview = await workspaceRepository.refreshShiftOverview(
        session,
      );
      _overview = refreshedOverview.data;
      _showingCachedPrioritiesData = false;
    } catch (error) {
      final message = _toErrorMessage(error);
      if (message != null && _prioritiesErrorMessage == null) {
        _prioritiesErrorMessage = message;
      }
    } finally {
      _isPrioritiesLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshOverview() async {
    final session = await sessionController.resolveSession(
      refreshIfNeeded: true,
    );
    if (session == null) {
      return;
    }

    final workspaceRepository = sessionController.workspaceRepository;
    final cachedOverview = await workspaceRepository.readCachedShiftOverview(
      session,
    );
    if (cachedOverview != null) {
      _applyCachedOverview(
        cachedOverview,
        markPrioritiesAsCached: false,
        markOverviewAsCached: true,
      );
      notifyListeners();
    }

    _isOverviewLoading = true;
    _overviewErrorMessage = null;
    notifyListeners();

    try {
      final refreshedOverview = await workspaceRepository.refreshShiftOverview(
        session,
      );
      _overview = refreshedOverview.data;
      _overviewLastUpdatedAt = refreshedOverview.fetchedAt;
      _showingCachedOverviewData = false;
    } catch (error) {
      final message = _toErrorMessage(error);
      if (message != null) {
        _overviewErrorMessage = message;
      }
    } finally {
      _isOverviewLoading = false;
      notifyListeners();
    }
  }

  void _handleSessionUpdated() {
    notifyListeners();
  }

  @override
  void dispose() {
    sessionController.removeListener(_handleSessionUpdated);
    super.dispose();
  }
}
