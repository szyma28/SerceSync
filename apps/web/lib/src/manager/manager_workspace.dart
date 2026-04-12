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
  List<ManagerResidentRecord> _residents = const [];

  bool _isDashboardLoading = true;
  bool _isResidentsLoading = true;
  bool _isSavingResident = false;

  String? _dashboardError;
  String? _residentsError;
  String? _editingResidentId;

  final _fullNameController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _unitLabelController = TextEditingController();
  final _careSummaryController = TextEditingController();

  String _recognitionImageKey = 'resident-a';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _seedBlankResidentForm();
    _loadDashboard();
    _loadResidents();
  }

  @override
  void dispose() {
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
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isDashboardLoading = true;
      _dashboardError = null;
    });

    try {
      final dashboard = await widget.apiClient.getDashboard(
        accessToken: widget.session.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _dashboardError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _dashboardError = 'Unable to load the unit overview right now.',
      );
    } finally {
      if (mounted) {
        setState(() => _isDashboardLoading = false);
      }
    }
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
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _residentsError = 'Unable to load resident records right now.',
      );
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
      case WorkspaceTab.residents:
        await _loadResidents();
      case WorkspaceTab.staff:
      case WorkspaceTab.compliance:
      case WorkspaceTab.console:
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This workspace section is not wired up yet.'),
          ),
        );
    }
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _residentsError = 'Unable to save the resident record.');
    } finally {
      if (mounted) {
        setState(() => _isSavingResident = false);
      }
    }
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
                                                  isLoading:
                                                      _isDashboardLoading,
                                                  errorMessage: _dashboardError,
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
