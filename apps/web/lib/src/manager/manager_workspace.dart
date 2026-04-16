part of '../../manager_app.dart';

class ManagerWorkspaceScreen extends StatefulWidget {
  const ManagerWorkspaceScreen({
    super.key,
    required this.apiClient,
    required this.session,
    required this.onLogout,
  });

  final SerceSyncManagerApiClient apiClient;
  final ManagerSession session;
  final VoidCallback onLogout;

  @override
  State<ManagerWorkspaceScreen> createState() => _ManagerWorkspaceScreenState();
}

class _ManagerWorkspaceScreenState extends State<ManagerWorkspaceScreen> {
  WorkspaceTab _selectedTab = WorkspaceTab.dashboard;

  ManagerDashboardSnapshot? _dashboard;
  List<ManagerShiftSummary> _activeShifts = const [];
  List<ManagerResidentRecord> _residents = const [];

  bool _isDashboardLoading = true;
  bool _isResidentsLoading = true;
  bool _isSavingResident = false;

  String? _dashboardError;
  String? _residentsError;
  String? _editingResidentId;
  String? _selectedShiftId;

  final _fullNameController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _unitLabelController = TextEditingController();
  final _careSummaryController = TextEditingController();

  String _recognitionImageKey = 'resident-a';
  bool _isActive = true;
  ManagerResidentPriorityLevel _baselinePriority =
      ManagerResidentPriorityLevel.green;
  final Set<String> _incidentActionIds = <String>{};
  int _dashboardLoadVersion = 0;
  StreamSubscription<ManagerDashboardLiveUpdate>?
  _dashboardLiveUpdatesSubscription;
  String? _dashboardLiveUpdatesShiftId;

  @override
  void initState() {
    super.initState();
    _seedBlankResidentForm();
    _loadDashboard();
    _loadResidents();
  }

  @override
  void dispose() {
    _dashboardLiveUpdatesSubscription?.cancel();
    _fullNameController.dispose();
    _roomNumberController.dispose();
    _floorNumberController.dispose();
    _unitLabelController.dispose();
    _careSummaryController.dispose();
    super.dispose();
  }

  void _seedBlankResidentForm() {
    _editingResidentId = null;
    _fullNameController.clear();
    _roomNumberController.clear();
    _floorNumberController.text = '1';
    _unitLabelController.text = 'Willow Floor';
    _careSummaryController.clear();
    _recognitionImageKey = 'resident-a';
    _isActive = true;
    _baselinePriority = ManagerResidentPriorityLevel.green;
  }

  bool _isCurrentDashboardLoad(int loadVersion) {
    return mounted && loadVersion == _dashboardLoadVersion;
  }

  bool _isDashboardShiftUnavailable(ApiException error) {
    return error.message ==
        'Active shift was not found for the manager dashboard.';
  }

  void _cancelDashboardLiveUpdates() {
    final subscription = _dashboardLiveUpdatesSubscription;
    _dashboardLiveUpdatesSubscription = null;
    _dashboardLiveUpdatesShiftId = null;
    subscription?.cancel();
  }

  void _handleDashboardLiveUpdate(ManagerDashboardLiveUpdate update) {
    final activeShiftId = _selectedShiftId ?? _dashboard?.activeShift.id;
    if (!mounted ||
        _selectedTab != WorkspaceTab.dashboard ||
        update.type != ManagerDashboardLiveUpdateType.updated ||
        activeShiftId == null ||
        update.shiftId != activeShiftId ||
        _isDashboardLoading ||
        _incidentActionIds.isNotEmpty) {
      return;
    }

    _loadDashboard(preferredShiftId: update.shiftId);
  }

  void _syncDashboardLiveUpdates({String? preferredShiftId}) {
    final targetShiftId =
        preferredShiftId ?? _selectedShiftId ?? _dashboard?.activeShift.id;
    if (_selectedTab != WorkspaceTab.dashboard || targetShiftId == null) {
      _cancelDashboardLiveUpdates();
      return;
    }

    if (_dashboardLiveUpdatesShiftId == targetShiftId &&
        _dashboardLiveUpdatesSubscription != null) {
      return;
    }

    _cancelDashboardLiveUpdates();
    _dashboardLiveUpdatesShiftId = targetShiftId;
    _dashboardLiveUpdatesSubscription = widget.apiClient
        .watchDashboard(
          accessToken: widget.session.accessToken,
          shiftId: targetShiftId,
        )
        .listen(_handleDashboardLiveUpdate);
  }

  String _resolveDashboardShiftId(
    List<ManagerShiftSummary> activeShifts, {
    String? preferredShiftId,
  }) {
    final candidateShiftIds = [
      preferredShiftId,
      _selectedShiftId,
      _dashboard?.activeShift.id,
    ];

    for (final candidateShiftId in candidateShiftIds) {
      if (candidateShiftId != null &&
          activeShifts.any((shift) => shift.id == candidateShiftId)) {
        return candidateShiftId;
      }
    }

    return activeShifts.first.id;
  }

  Future<void> _loadDashboard({
    String? preferredShiftId,
    bool clearSnapshot = false,
  }) async {
    final loadVersion = ++_dashboardLoadVersion;

    setState(() {
      _isDashboardLoading = true;
      _dashboardError = null;
      if (clearSnapshot) {
        _dashboard = null;
      }
    });

    try {
      var activeShifts = await widget.apiClient.getActiveShifts(
        accessToken: widget.session.accessToken,
      );

      if (!_isCurrentDashboardLoad(loadVersion)) return;

      if (activeShifts.isEmpty) {
        setState(() {
          _activeShifts = const [];
          _selectedShiftId = null;
          _dashboard = null;
        });
        _syncDashboardLiveUpdates();
        return;
      }

      var selectedShiftId = _resolveDashboardShiftId(
        activeShifts,
        preferredShiftId: preferredShiftId,
      );

      late final ManagerDashboardSnapshot dashboard;
      try {
        dashboard = await widget.apiClient.getDashboard(
          accessToken: widget.session.accessToken,
          shiftId: selectedShiftId,
        );
      } on ApiException catch (error) {
        if (!_isCurrentDashboardLoad(loadVersion)) return;
        if (!_isDashboardShiftUnavailable(error)) {
          rethrow;
        }

        activeShifts = await widget.apiClient.getActiveShifts(
          accessToken: widget.session.accessToken,
        );

        if (!_isCurrentDashboardLoad(loadVersion)) return;

        if (activeShifts.isEmpty) {
          setState(() {
            _activeShifts = const [];
            _selectedShiftId = null;
            _dashboard = null;
          });
          _syncDashboardLiveUpdates();
          return;
        }

        selectedShiftId = _resolveDashboardShiftId(activeShifts);
        dashboard = await widget.apiClient.getDashboard(
          accessToken: widget.session.accessToken,
          shiftId: selectedShiftId,
        );
      }

      if (!_isCurrentDashboardLoad(loadVersion)) return;
      setState(() {
        _activeShifts = activeShifts;
        _selectedShiftId = selectedShiftId;
        _dashboard = dashboard;
      });
      _syncDashboardLiveUpdates(preferredShiftId: selectedShiftId);
    } on ApiException catch (error) {
      if (!_isCurrentDashboardLoad(loadVersion)) return;
      setState(() {
        _dashboardError = error.message;
        _dashboard = null;
      });
      _syncDashboardLiveUpdates();
    } finally {
      if (_isCurrentDashboardLoad(loadVersion)) {
        setState(() => _isDashboardLoading = false);
      }
    }
  }

  Future<void> _selectDashboardShift(String shiftId) async {
    if (shiftId == _selectedShiftId &&
        _dashboard?.activeShift.id == shiftId &&
        !_isDashboardLoading) {
      return;
    }

    _cancelDashboardLiveUpdates();
    await _loadDashboard(preferredShiftId: shiftId, clearSnapshot: true);
  }

  Future<void> _loadResidents() async {
    setState(() {
      _isResidentsLoading = true;
      _residentsError = null;
    });

    try {
      final residents = await widget.apiClient.getResidents(
        accessToken: widget.session.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _residents = residents;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _residentsError = error.message);
    } finally {
      if (mounted) {
        setState(() => _isResidentsLoading = false);
      }
    }
  }

  Future<void> _refreshSelectedTab() async {
    switch (_selectedTab) {
      case WorkspaceTab.dashboard:
        await _loadDashboard();
        break;
      case WorkspaceTab.residents:
        await _loadResidents();
        break;
      case WorkspaceTab.staff:
      case WorkspaceTab.compliance:
      case WorkspaceTab.console:
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This workspace section is not wired up yet.'),
          ),
        );
        break;
    }
  }

  Future<void> _refreshOperationalData() async {
    await Future.wait([_loadDashboard(), _loadResidents()]);
  }

  void _startCreateResident() {
    setState(_seedBlankResidentForm);
  }

  void _startEditResident(ManagerResidentRecord resident) {
    setState(() {
      _editingResidentId = resident.id;
      _fullNameController.text = resident.fullName;
      _roomNumberController.text = resident.roomNumber.toString();
      _floorNumberController.text = resident.floorNumber.toString();
      _unitLabelController.text = resident.unitLabel;
      _careSummaryController.text = resident.careSummary;
      _recognitionImageKey = resident.recognitionImageKey;
      _isActive = resident.isActive;
      _baselinePriority = resident.baselinePriority;
    });
  }

  Future<void> _saveResident() async {
    final roomNumber = int.tryParse(_roomNumberController.text.trim());
    final floorNumber = int.tryParse(_floorNumberController.text.trim());

    if (_fullNameController.text.trim().isEmpty ||
        roomNumber == null ||
        floorNumber == null ||
        _unitLabelController.text.trim().isEmpty ||
        _careSummaryController.text.trim().isEmpty) {
      setState(
        () => _residentsError =
            'Complete every resident field before saving the record.',
      );
      return;
    }

    setState(() {
      _isSavingResident = true;
      _residentsError = null;
    });

    final draft = ManagerResidentDraft(
      fullName: _fullNameController.text.trim(),
      roomNumber: roomNumber,
      floorNumber: floorNumber,
      unitLabel: _unitLabelController.text.trim(),
      recognitionImageKey: _recognitionImageKey,
      careSummary: _careSummaryController.text.trim(),
      isActive: _isActive,
      baselinePriority: _baselinePriority,
    );

    try {
      if (_editingResidentId == null) {
        await widget.apiClient.createResident(
          accessToken: widget.session.accessToken,
          draft: draft,
        );
      } else {
        await widget.apiClient.updateResident(
          accessToken: widget.session.accessToken,
          residentId: _editingResidentId!,
          draft: draft,
        );
      }

      await _loadResidents();
      if (!mounted) return;
      setState(_seedBlankResidentForm);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resident record saved.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _residentsError = error.message);
    } finally {
      if (mounted) {
        setState(() => _isSavingResident = false);
      }
    }
  }

  Future<void> _runIncidentAction({
    required String incidentId,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_incidentActionIds.contains(incidentId)) {
      return;
    }

    setState(() {
      _incidentActionIds.add(incidentId);
      _dashboardError = null;
    });

    try {
      await action();
      await _refreshOperationalData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _incidentActionIds.remove(incidentId);
        });
      }
    }
  }

  String _requireSelectedShiftId() {
    final selectedShiftId = _selectedShiftId ?? _dashboard?.activeShift.id;
    if (selectedShiftId == null) {
      throw StateError(
        'A dashboard shift must be selected before incident actions run.',
      );
    }
    return selectedShiftId;
  }

  Future<void> _acknowledgeIncident(String incidentId) {
    final selectedShiftId = _requireSelectedShiftId();

    return _runIncidentAction(
      incidentId: incidentId,
      action: () => widget.apiClient.acknowledgeIncident(
        accessToken: widget.session.accessToken,
        incidentId: incidentId,
        shiftId: selectedShiftId,
      ),
      successMessage: 'Incident acknowledged.',
    );
  }

  Future<void> _resolveIncident(String incidentId) {
    final selectedShiftId = _requireSelectedShiftId();

    return _runIncidentAction(
      incidentId: incidentId,
      action: () => widget.apiClient.resolveIncident(
        accessToken: widget.session.accessToken,
        incidentId: incidentId,
        shiftId: selectedShiftId,
      ),
      successMessage: 'Incident resolved.',
    );
  }

  void _exportWorkspaceData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Export action is staged for the next manager tools pass.',
        ),
      ),
    );
  }

  void _selectTab(WorkspaceTab tab) {
    if (tab == WorkspaceTab.staff ||
        tab == WorkspaceTab.compliance ||
        tab == WorkspaceTab.console) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This section is coming next.')),
      );
      return;
    }

    setState(() => _selectedTab = tab);
    _syncDashboardLiveUpdates();
  }

  String _headerTitle() {
    switch (_selectedTab) {
      case WorkspaceTab.dashboard:
        return 'Unit Overview';
      case WorkspaceTab.residents:
        return 'Residents';
      case WorkspaceTab.staff:
        return 'Staff & Shifts';
      case WorkspaceTab.compliance:
        return 'Compliance Reports';
      case WorkspaceTab.console:
        return 'Demo Console';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, viewportConstraints) {
          final safeVertical = MediaQuery.of(context).padding.vertical;
          final availableWidth = math.max(
            0.0,
            viewportConstraints.maxWidth - 32,
          );
          final availableHeight = math.max(
            0.0,
            viewportConstraints.maxHeight - safeVertical - 32,
          );
          final shellHeight = availableHeight.clamp(790.0, 1048.0).toDouble();
          final shellWidth = math.min(availableWidth, shellHeight * (16 / 9));

          return Container(
            color: _managerCanvas,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: availableHeight),
                  child: Center(
                    child: SizedBox(
                      width: shellWidth,
                      height: shellHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _managerShell,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: _managerBorder),
                          boxShadow: const [
                            BoxShadow(
                              color: _managerShadow,
                              blurRadius: 44,
                              offset: Offset(0, 22),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ManagerSidebar(
                                user: widget.session.user,
                                selectedTab: _selectedTab,
                                onSelectTab: _selectTab,
                              ),
                              Expanded(
                                child: Container(
                                  color: _managerBackground,
                                  child: Column(
                                    children: [
                                      _WorkspaceHeader(
                                        title: _headerTitle(),
                                        trailingLabel: _formatLongDate(
                                          DateTime.now(),
                                        ),
                                        onRefresh: _refreshSelectedTab,
                                        onExport: _exportWorkspaceData,
                                      ),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.all(24),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            child: switch (_selectedTab) {
                                              WorkspaceTab.dashboard =>
                                                _DashboardOverview(
                                                  key: const ValueKey(
                                                    'dashboard',
                                                  ),
                                                  dashboard: _dashboard,
                                                  activeShifts: _activeShifts,
                                                  selectedShiftId:
                                                      _selectedShiftId,
                                                  isLoading:
                                                      _isDashboardLoading,
                                                  errorMessage: _dashboardError,
                                                  pendingIncidentIds:
                                                      _incidentActionIds,
                                                  onShiftSelected:
                                                      _selectDashboardShift,
                                                  onAcknowledgeIncident:
                                                      _acknowledgeIncident,
                                                  onResolveIncident:
                                                      _resolveIncident,
                                                ),
                                              WorkspaceTab.residents =>
                                                _ResidentsManagement(
                                                  key: const ValueKey(
                                                    'residents',
                                                  ),
                                                  residents: _residents,
                                                  isLoading:
                                                      _isResidentsLoading,
                                                  isSaving: _isSavingResident,
                                                  errorMessage: _residentsError,
                                                  editingResidentId:
                                                      _editingResidentId,
                                                  fullNameController:
                                                      _fullNameController,
                                                  roomNumberController:
                                                      _roomNumberController,
                                                  floorNumberController:
                                                      _floorNumberController,
                                                  unitLabelController:
                                                      _unitLabelController,
                                                  careSummaryController:
                                                      _careSummaryController,
                                                  recognitionImageKey:
                                                      _recognitionImageKey,
                                                  isActive: _isActive,
                                                  baselinePriority:
                                                      _baselinePriority,
                                                  onRecognitionImageChanged:
                                                      (value) => setState(
                                                        () =>
                                                            _recognitionImageKey =
                                                                value,
                                                      ),
                                                  onActiveChanged: (value) =>
                                                      setState(
                                                        () => _isActive = value,
                                                      ),
                                                  onBaselinePriorityChanged:
                                                      (value) => setState(
                                                        () =>
                                                            _baselinePriority =
                                                                value,
                                                      ),
                                                  onCreateResident:
                                                      _startCreateResident,
                                                  onEditResident:
                                                      _startEditResident,
                                                  onSaveResident: _saveResident,
                                                ),
                                              WorkspaceTab.staff =>
                                                const _ComingSoonPanel(
                                                  key: ValueKey('staff'),
                                                  title: 'Staff & Shifts',
                                                  body:
                                                      'The shell is ready for the staffing view next. We can plug live rota and coverage data into this lane after the dashboard pass.',
                                                ),
                                              WorkspaceTab.compliance =>
                                                const _ComingSoonPanel(
                                                  key: ValueKey('compliance'),
                                                  title: 'Compliance Reports',
                                                  body:
                                                      'Compliance reporting will sit in this same workspace frame once we shape the next reporting surface.',
                                                ),
                                              WorkspaceTab.console =>
                                                const _ComingSoonPanel(
                                                  key: ValueKey('console'),
                                                  title: 'Demo Console',
                                                  body:
                                                      'The demo tooling slot is reserved here so the navigation mirrors the design while we keep the current build focused.',
                                                ),
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
