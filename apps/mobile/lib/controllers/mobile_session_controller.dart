import 'dart:async';

import 'package:flutter/widgets.dart';

import '../api/api_client.dart';
import '../models/handover.dart';
import '../models/user.dart';
import '../offline/mobile_offline_database.dart';
import '../offline/mobile_session_storage.dart';
import '../offline/mobile_sync_service.dart';
import '../offline/offline_models.dart';
import '../repositories/mobile_resident_repository.dart';
import '../repositories/mobile_session_repository.dart';
import '../repositories/mobile_workspace_repository.dart';

class MobileSessionController extends ChangeNotifier
    with WidgetsBindingObserver {
  MobileSessionController() {
    _offlineDatabase = MobileOfflineDatabase();
    _sessionStorage = MobileSessionStorage();
    _workspaceRepository = MobileWorkspaceRepository(
      offlineDatabase: _offlineDatabase,
    );
    _residentRepository = MobileResidentRepository(
      offlineDatabase: _offlineDatabase,
    );
    _sessionRepository = MobileSessionRepository(
      sessionStorage: _sessionStorage,
      offlineDatabase: _offlineDatabase,
    );
    _syncService = MobileSyncService(
      offlineDatabase: _offlineDatabase,
      workspaceRepository: _workspaceRepository,
      resolveSession:
          ({bool refreshIfNeeded = true, bool forceRefresh = false}) =>
              resolveSession(
                refreshIfNeeded: refreshIfNeeded,
                forceRefresh: forceRefresh,
              ),
      onReauthenticationRequired: _handleReauthenticationRequired,
    );
    _syncService.addListener(_handleSyncChanged);
    _syncService.start();
    WidgetsBinding.instance.addObserver(this);
  }

  late final MobileOfflineDatabase _offlineDatabase;
  late final MobileSessionStorage _sessionStorage;
  late final MobileWorkspaceRepository _workspaceRepository;
  late final MobileResidentRepository _residentRepository;
  late final MobileSessionRepository _sessionRepository;
  late final MobileSyncService _syncService;

  bool _isInitializing = true;
  bool _isAuthenticating = false;
  bool _isHandoverLoading = false;
  bool _requiresReauthentication = false;
  String? _authErrorMessage;
  String? _handoverErrorMessage;
  PersistedMobileSession? _session;
  SerceSyncApiClient? _apiClient;
  HandoverSnapshot? _handoverSnapshot;
  DateTime? _handoverLastUpdatedAt;
  bool _handoverShowingCachedData = false;
  String? _lastBaseUrl;
  Completer<PersistedMobileSession?>? _sessionRefreshCompleter;

  bool get isInitializing => _isInitializing;
  bool get isAuthenticating => _isAuthenticating;
  String? get authErrorMessage => _authErrorMessage;
  bool get isHandoverLoading => _isHandoverLoading;
  String? get handoverErrorMessage => _handoverErrorMessage;
  SerceSyncApiClient? get apiClient => _apiClient;
  String? get accessToken => _session?.accessToken;
  LoginUser? get user => _session?.user;
  HandoverSnapshot? get handoverSnapshot => _handoverSnapshot;
  DateTime? get handoverLastUpdatedAt => _handoverLastUpdatedAt;
  bool get handoverShowingCachedData => _handoverShowingCachedData;
  String? get lastBaseUrl => _lastBaseUrl;
  bool get requiresReauthentication => _requiresReauthentication;
  bool get hasActiveSession => _session != null && _apiClient != null;
  PersistedMobileSession? get currentSession => _session;
  MobileWorkspaceRepository get workspaceRepository => _workspaceRepository;
  MobileResidentRepository get residentRepository => _residentRepository;
  MobileSyncService get syncService => _syncService;
  OfflineQueueSummary get syncSummary => _syncService.summary;

  Future<void> initialize() async {
    try {
      final storedSession = await _sessionRepository.readStoredSession();
      _lastBaseUrl = storedSession?.baseUrl;
      if (storedSession == null) {
        return;
      }

      if (storedSession.isRefreshTokenExpired) {
        await _sessionRepository.clearStoredSession();
        return;
      }

      _adoptSession(storedSession, clearTransientState: true);
      final session =
          storedSession.isAccessTokenExpired ||
              _shouldRefreshAccessToken(storedSession)
          ? await _refreshSession()
          : storedSession;

      if (session == null) {
        return;
      }

      final cachedHandover = await _workspaceRepository
          .readCachedCurrentHandover(session);
      if (cachedHandover != null) {
        _handoverSnapshot = cachedHandover.data;
        _handoverLastUpdatedAt = cachedHandover.fetchedAt;
        _handoverShowingCachedData = true;
      }

      unawaited(loadCurrentHandover(forceRefresh: false));
      unawaited(triggerOfflineSync(reason: 'startup'));
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<PersistedMobileSession?> resolveSession({
    bool refreshIfNeeded = true,
    bool forceRefresh = false,
  }) async {
    final session = _session;
    if (session == null) {
      return null;
    }

    if (!forceRefresh &&
        (!refreshIfNeeded || !_shouldRefreshAccessToken(session))) {
      return session;
    }

    return _refreshSession();
  }

  Future<bool> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    _isAuthenticating = true;
    _authErrorMessage = null;
    notifyListeners();

    try {
      final session = await _sessionRepository.login(
        baseUrl: baseUrl,
        email: email,
        password: password,
      );
      _adoptSession(session, clearTransientState: true);
      _handoverSnapshot = null;
      _handoverLastUpdatedAt = null;
      _handoverShowingCachedData = false;
      unawaited(loadCurrentHandover(forceRefresh: false));
      unawaited(triggerOfflineSync(reason: 'login'));
      return true;
    } on ApiException catch (error) {
      _authErrorMessage = error.message;
      return false;
    } finally {
      _isAuthenticating = false;
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentHandover({bool forceRefresh = false}) async {
    final session = await resolveSession(refreshIfNeeded: true);
    if (session == null) {
      return;
    }

    if (!forceRefresh) {
      final cached = await _workspaceRepository.readCachedCurrentHandover(
        session,
      );
      if (cached != null) {
        _handoverSnapshot = cached.data;
        _handoverLastUpdatedAt = cached.fetchedAt;
        _handoverShowingCachedData = true;
        notifyListeners();
      }
    }

    _isHandoverLoading = true;
    _handoverErrorMessage = null;
    notifyListeners();

    try {
      final refreshed = await _workspaceRepository.refreshCurrentHandover(
        session,
      );
      _handoverSnapshot = refreshed.data;
      _handoverLastUpdatedAt = refreshed.fetchedAt;
      _handoverShowingCachedData = false;
    } on ApiException catch (error) {
      _handoverErrorMessage = error.message;
    } finally {
      _isHandoverLoading = false;
      notifyListeners();
    }
  }

  Future<void> acknowledgeCurrentHandover() async {
    final session = await resolveSession(refreshIfNeeded: true);
    if (session == null) {
      return;
    }

    _isHandoverLoading = true;
    _handoverErrorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _workspaceRepository.acknowledgeCurrentHandover(
        session,
      );
      _handoverSnapshot = snapshot;
      _handoverLastUpdatedAt = DateTime.now().toUtc();
      _handoverShowingCachedData = false;
    } on ApiException catch (error) {
      _handoverErrorMessage = error.message;
    } finally {
      _isHandoverLoading = false;
      notifyListeners();
    }
  }

  Future<void> triggerOfflineSync({String reason = 'manual'}) {
    return _syncService.triggerSync(reason: reason);
  }

  Future<void> logout() async {
    final session = _session;
    if (session != null) {
      await _sessionRepository.logout(session);
    } else {
      await _sessionRepository.clearStoredSession();
    }
    _clearSessionState(clearAuthMessage: true);
    notifyListeners();
  }

  void clearSession() {
    unawaited(logout());
  }

  bool _shouldRefreshAccessToken(PersistedMobileSession session) {
    final refreshThreshold = DateTime.now().toUtc().add(
      const Duration(minutes: 1),
    );
    return !session.accessTokenExpiresAt.isAfter(refreshThreshold);
  }

  Future<PersistedMobileSession?> _refreshSession() async {
    if (_sessionRefreshCompleter != null) {
      return _sessionRefreshCompleter!.future;
    }

    final session = _session;
    if (session == null) {
      return null;
    }

    final completer = Completer<PersistedMobileSession?>();
    _sessionRefreshCompleter = completer;

    try {
      final refreshedSession = await _sessionRepository.refreshSession(session);
      _adoptSession(refreshedSession);
      completer.complete(refreshedSession);
      return refreshedSession;
    } on ApiException {
      await _handleReauthenticationRequired();
      completer.complete(null);
      return null;
    } finally {
      _sessionRefreshCompleter = null;
    }
  }

  void _adoptSession(
    PersistedMobileSession session, {
    bool clearTransientState = false,
  }) {
    _session = session;
    _apiClient = SerceSyncApiClient(baseUrl: session.baseUrl);
    _lastBaseUrl = session.baseUrl;
    _requiresReauthentication = false;
    if (clearTransientState) {
      _authErrorMessage = null;
      _handoverErrorMessage = null;
    }
    _syncService.bindUser(session.user.id);
  }

  Future<void> _handleReauthenticationRequired() async {
    await _sessionRepository.clearStoredSession();
    _clearSessionState(clearAuthMessage: false);
    _requiresReauthentication = true;
    _authErrorMessage =
        'Session expired. Sign in again to finish syncing saved updates.';
    notifyListeners();
  }

  void _clearSessionState({required bool clearAuthMessage}) {
    _session = null;
    _apiClient = null;
    _handoverSnapshot = null;
    _handoverLastUpdatedAt = null;
    _handoverShowingCachedData = false;
    _handoverErrorMessage = null;
    _requiresReauthentication = false;
    if (clearAuthMessage) {
      _authErrorMessage = null;
    }
    _syncService.bindUser(null);
  }

  void _handleSyncChanged() {
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && hasActiveSession) {
      unawaited(triggerOfflineSync(reason: 'resume'));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncService.removeListener(_handleSyncChanged);
    _syncService.dispose();
    _offlineDatabase.close();
    super.dispose();
  }
}
