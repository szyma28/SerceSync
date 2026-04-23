import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'manager_api_client.dart';
import 'manager_dashboard.dart';
import 'manager_file_download_api.dart';
import 'manager_models.dart';
import 'manager_reporting.dart';
import 'manager_residents.dart';
import 'manager_session_controller.dart';
import 'manager_shared.dart';
import 'manager_sidebar.dart';
import 'manager_theme.dart';
import 'manager_workspace_controller.dart';

class ManagerWorkspaceScreen extends StatefulWidget {
  const ManagerWorkspaceScreen({
    super.key,
    required this.apiClient,
    required this.fileDownloader,
    required this.session,
    required this.onLogout,
  });

  final SerceSyncManagerApiClient apiClient;
  final ManagerFileDownloader fileDownloader;
  final ManagerSession session;
  final VoidCallback onLogout;

  @override
  State<ManagerWorkspaceScreen> createState() => _ManagerWorkspaceScreenState();
}

class _ManagerWorkspaceScreenState extends State<ManagerWorkspaceScreen>
    with WidgetsBindingObserver {
  late final ManagerWorkspaceController _workspaceController;
  DateTime? _lastResumeRefreshAt;

  final _fullNameController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _unitLabelController = TextEditingController();
  final _aboutMeController = TextEditingController();

  bool _isResidentEditorVisible = false;
  String? _editingResidentId;
  String _recognitionImageKey = residentRecognitionImageKeys.first;
  bool _isActive = true;
  ManagerResidentPriorityLevel _baselinePriority =
      ManagerResidentPriorityLevel.green;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _workspaceController = ManagerWorkspaceController(
      apiClient: widget.apiClient,
      session: widget.session,
      renewSessionSilently: () =>
          context.read<ManagerSessionController>().renewSessionSilently(),
    )..initialize();
    _seedBlankResidentForm();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _workspaceController.dispose();
    _fullNameController.dispose();
    _roomNumberController.dispose();
    _floorNumberController.dispose();
    _unitLabelController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    unawaited(_refreshOnResume());
  }

  Future<void> _refreshOnResume() async {
    final now = DateTime.now();
    final lastResumeRefreshAt = _lastResumeRefreshAt;
    if (lastResumeRefreshAt != null &&
        now.difference(lastResumeRefreshAt) < const Duration(seconds: 2)) {
      return;
    }

    _lastResumeRefreshAt = now;

    final sessionRecovered = await context
        .read<ManagerSessionController>()
        .renewSessionSilently();
    if (!mounted || !sessionRecovered) {
      return;
    }

    await _workspaceController.refreshSelectedTab();
  }

  void _seedBlankResidentForm() {
    _editingResidentId = null;
    _fullNameController.clear();
    _roomNumberController.clear();
    _floorNumberController.text = '1';
    _unitLabelController.text = 'Willow Floor';
    _aboutMeController.clear();
    _recognitionImageKey = residentRecognitionImageKeys.first;
    _isActive = true;
    _baselinePriority = ManagerResidentPriorityLevel.green;
  }

  void _startCreateResident() {
    setState(() {
      _seedBlankResidentForm();
      _isResidentEditorVisible = true;
    });
  }

  void _startEditResident(ManagerResidentRecord resident) {
    setState(() {
      _isResidentEditorVisible = true;
      _editingResidentId = resident.id;
      _fullNameController.text = resident.fullName;
      _roomNumberController.text = resident.roomNumber.toString();
      _floorNumberController.text = resident.floorNumber.toString();
      _unitLabelController.text = resident.unitLabel;
      _aboutMeController.text = resident.aboutMe;
      _recognitionImageKey = resident.recognitionImageKey;
      _isActive = resident.isActive;
      _baselinePriority = resident.baselinePriority;
    });
  }

  void _closeResidentEditor() {
    setState(() {
      _seedBlankResidentForm();
      _isResidentEditorVisible = false;
    });
  }

  Future<void> _saveResident() async {
    final roomNumber = int.tryParse(_roomNumberController.text.trim());
    final floorNumber = int.tryParse(_floorNumberController.text.trim());

    if (_fullNameController.text.trim().isEmpty ||
        roomNumber == null ||
        floorNumber == null ||
        _unitLabelController.text.trim().isEmpty ||
        _aboutMeController.text.trim().isEmpty) {
      showManagerNotice(
        context,
        message: 'Complete every resident field before saving this record.',
        isError: true,
      );
      return;
    }

    final draft = ManagerResidentDraft(
      fullName: _fullNameController.text.trim(),
      roomNumber: roomNumber,
      floorNumber: floorNumber,
      unitLabel: _unitLabelController.text.trim(),
      recognitionImageKey: _recognitionImageKey,
      aboutMe: _aboutMeController.text.trim(),
      isActive: _isActive,
      baselinePriority: _baselinePriority,
    );
    final wasCreating = _editingResidentId == null;

    final saved = await _workspaceController.saveResident(
      draft: draft,
      residentId: _editingResidentId,
    );
    if (!mounted || !saved) {
      return;
    }

    setState(() {
      _seedBlankResidentForm();
      _isResidentEditorVisible = false;
    });
    showManagerNotice(
      context,
      message: wasCreating
          ? 'Resident record created.'
          : 'Resident record updated.',
    );
  }

  Future<void> _runIncidentAction({
    required String incidentId,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    try {
      await action();
      if (!mounted) {
        return;
      }
      showManagerNotice(context, message: successMessage);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showManagerNotice(
        context,
        message: error is ApiException
            ? error.message
            : 'The manager workspace can’t reach the API right now.',
        isError: true,
      );
    }
  }

  Future<void> _acknowledgeIncident(String incidentId, String shiftId) {
    return _runIncidentAction(
      incidentId: incidentId,
      action: () =>
          _workspaceController.acknowledgeIncident(incidentId, shiftId),
      successMessage: 'Incident marked as acknowledged.',
    );
  }

  Future<void> _resolveIncident(String incidentId, String shiftId) {
    return _runIncidentAction(
      incidentId: incidentId,
      action: () => _workspaceController.resolveIncident(incidentId, shiftId),
      successMessage: 'Incident marked as resolved.',
    );
  }

  Future<void> _downloadCsv({
    required Future<String> Function() loader,
    required String fileName,
  }) async {
    try {
      final csv = await loader();
      if (!mounted) {
        return;
      }
      await downloadCsvExport(
        context,
        downloader: widget.fileDownloader,
        fileName: fileName,
        csv: csv,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showManagerNotice(
        context,
        message: error is ApiException
            ? error.message
            : 'The manager workspace can’t reach the API right now.',
        isError: true,
      );
    }
  }

  Future<void> _downloadMedicationAuditCsv() {
    return _downloadCsv(
      loader: () => widget.apiClient.exportMedicationAuditCsv(
        accessToken: widget.session.accessToken,
      ),
      fileName: 'medication-audit.csv',
    );
  }

  Future<void> _downloadMedicationRoundCsv(String shiftId) {
    return _downloadCsv(
      loader: () => widget.apiClient.exportMedicationRoundCsv(
        accessToken: widget.session.accessToken,
        shiftId: shiftId,
      ),
      fileName: 'shift-$shiftId-medication-round.csv',
    );
  }

  Future<void> _downloadResidentEmarCsv(ManagerResidentRecord resident) {
    return _downloadCsv(
      loader: () => widget.apiClient.exportResidentEmarCsv(
        accessToken: widget.session.accessToken,
        residentId: resident.id,
      ),
      fileName:
          'resident-${resident.roomNumber.toString().padLeft(2, '0')}-emar.csv',
    );
  }

  Future<void> _downloadResidentDowntimePackCsv(
    ManagerResidentRecord resident,
  ) {
    return _downloadCsv(
      loader: () => widget.apiClient.exportResidentDowntimePackCsv(
        accessToken: widget.session.accessToken,
        residentId: resident.id,
      ),
      fileName:
          'resident-${resident.roomNumber.toString().padLeft(2, '0')}-emar-downtime-pack.csv',
    );
  }

  Future<void> _downloadEvidencePackSummaryCsv() async {
    await downloadCsvExport(
      context,
      downloader: widget.fileDownloader,
      fileName: 'cqc-evidence-pack-summary.csv',
      csv: buildCqcEvidencePackSummaryCsv(
        generatedAt: DateTime.now(),
        dashboard: _workspaceController.dashboard,
        activeShifts: _workspaceController.activeShifts,
        residents: _workspaceController.residents,
        dashboardError: _workspaceController.dashboardError,
        residentsError: _workspaceController.residentsError,
      ),
    );
  }

  Future<void> _downloadIncidentRegisterCsv() async {
    await downloadCsvExport(
      context,
      downloader: widget.fileDownloader,
      fileName: 'incident-register.csv',
      csv: buildIncidentRegisterCsv(
        generatedAt: DateTime.now(),
        dashboard: _workspaceController.dashboard,
      ),
    );
  }

  void _selectTab(WorkspaceTab tab) {
    if (tab == WorkspaceTab.console) {
      showManagerNotice(
        context,
        message: 'Operational tools are outside the current demo workspace.',
      );
      return;
    }

    _workspaceController.selectTab(tab);
  }

  Future<void> _refreshSelectedTab() async {
    await _workspaceController.refreshSelectedTab();
  }

  DateTime? _selectedTabLastUpdated(
    ManagerWorkspaceController workspaceController,
  ) {
    switch (workspaceController.selectedTab) {
      case WorkspaceTab.dashboard:
        return workspaceController.dashboardLastUpdatedAt;
      case WorkspaceTab.residents:
        return workspaceController.residentsLastUpdatedAt;
      case WorkspaceTab.compliance:
        final dashboardUpdatedAt = workspaceController.dashboardLastUpdatedAt;
        final residentsUpdatedAt = workspaceController.residentsLastUpdatedAt;
        if (dashboardUpdatedAt == null) {
          return residentsUpdatedAt;
        }
        if (residentsUpdatedAt == null) {
          return dashboardUpdatedAt;
        }
        return dashboardUpdatedAt.isAfter(residentsUpdatedAt)
            ? dashboardUpdatedAt
            : residentsUpdatedAt;
      case WorkspaceTab.console:
        return null;
    }
  }

  bool _isSelectedTabRefreshing(
    ManagerWorkspaceController workspaceController,
  ) {
    switch (workspaceController.selectedTab) {
      case WorkspaceTab.dashboard:
        return workspaceController.isDashboardLoading &&
            workspaceController.dashboard != null;
      case WorkspaceTab.residents:
        return workspaceController.isResidentsLoading &&
            workspaceController.residents.isNotEmpty;
      case WorkspaceTab.compliance:
        return (workspaceController.isDashboardLoading &&
                workspaceController.dashboard != null) ||
            (workspaceController.isResidentsLoading &&
                workspaceController.residents.isNotEmpty);
      case WorkspaceTab.console:
        return false;
    }
  }

  String? _headerStatusLabel(ManagerWorkspaceController workspaceController) {
    switch (workspaceController.selectedTab) {
      case WorkspaceTab.dashboard:
        return formatManagerFreshnessLabel(
          workspaceController.dashboardLastUpdatedAt,
          isRefreshing: _isSelectedTabRefreshing(workspaceController),
          isLive: true,
        );
      case WorkspaceTab.residents:
      case WorkspaceTab.compliance:
        return formatManagerFreshnessLabel(
          _selectedTabLastUpdated(workspaceController),
          isRefreshing: _isSelectedTabRefreshing(workspaceController),
        );
      case WorkspaceTab.console:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ManagerWorkspaceController>.value(
      value: _workspaceController,
      child: Consumer<ManagerWorkspaceController>(
        builder: (context, workspaceController, _) {
          return Scaffold(
            body: Container(
              color: managerCanvas,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox.expand(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: managerShell,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: managerBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: managerShadow,
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
                            ManagerSidebar(
                              user: widget.session.user,
                              selectedTab: workspaceController.selectedTab,
                              onSelectTab: _selectTab,
                            ),
                            Expanded(
                              child: Container(
                                color: managerBackground,
                                child: Column(
                                  children: [
                                    WorkspaceHeader(
                                      title: workspaceController.headerTitle,
                                      trailingLabel: formatLongDate(
                                        DateTime.now(),
                                      ),
                                      onRefresh: _refreshSelectedTab,
                                      statusLabel: _headerStatusLabel(
                                        workspaceController,
                                      ),
                                      statusIcon:
                                          workspaceController.selectedTab ==
                                              WorkspaceTab.dashboard
                                          ? Icons.wifi_tethering_rounded
                                          : Icons.schedule_rounded,
                                      isRefreshing: _isSelectedTabRefreshing(
                                        workspaceController,
                                      ),
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(24),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          child: switch (workspaceController
                                              .selectedTab) {
                                            WorkspaceTab.dashboard =>
                                              DashboardOverview(
                                                key: const ValueKey(
                                                  'dashboard',
                                                ),
                                                apiClient: widget.apiClient,
                                                fileDownloader:
                                                    widget.fileDownloader,
                                                accessToken:
                                                    widget.session.accessToken,
                                                dashboard: workspaceController
                                                    .dashboard,
                                                activeShifts:
                                                    workspaceController
                                                        .activeShifts,
                                                isLoading: workspaceController
                                                    .isDashboardLoading,
                                                errorMessage:
                                                    workspaceController
                                                        .dashboardError,
                                                pendingIncidentIds:
                                                    workspaceController
                                                        .pendingIncidentIds,
                                                onAcknowledgeIncident:
                                                    _acknowledgeIncident,
                                                onResolveIncident:
                                                    _resolveIncident,
                                              ),
                                            WorkspaceTab.residents =>
                                              ResidentsManagement(
                                                key: const ValueKey(
                                                  'residents',
                                                ),
                                                apiClient: widget.apiClient,
                                                fileDownloader:
                                                    widget.fileDownloader,
                                                accessToken:
                                                    widget.session.accessToken,
                                                residents: workspaceController
                                                    .residents,
                                                isLoading: workspaceController
                                                    .isResidentsLoading,
                                                isSaving: workspaceController
                                                    .isSavingResident,
                                                isEditorVisible:
                                                    _isResidentEditorVisible,
                                                errorMessage:
                                                    workspaceController
                                                        .residentsError,
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
                                                aboutMeController:
                                                    _aboutMeController,
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
                                                      () => _baselinePriority =
                                                          value,
                                                    ),
                                                onCreateResident:
                                                    _startCreateResident,
                                                onCloseResidentEditor:
                                                    _closeResidentEditor,
                                                onEditResident:
                                                    _startEditResident,
                                                onMedicationDataChanged:
                                                    workspaceController
                                                        .refreshOperationalData,
                                                onSaveResident: _saveResident,
                                              ),
                                            WorkspaceTab.compliance => CqcEvidencePack(
                                              key: const ValueKey('compliance'),
                                              dashboard:
                                                  workspaceController.dashboard,
                                              activeShifts: workspaceController
                                                  .activeShifts,
                                              residents:
                                                  workspaceController.residents,
                                              isDashboardLoading:
                                                  workspaceController
                                                      .isDashboardLoading,
                                              isResidentsLoading:
                                                  workspaceController
                                                      .isResidentsLoading,
                                              dashboardError:
                                                  workspaceController
                                                      .dashboardError,
                                              residentsError:
                                                  workspaceController
                                                      .residentsError,
                                              onDownloadSummary: () => unawaited(
                                                _downloadEvidencePackSummaryCsv(),
                                              ),
                                              onDownloadIncidentRegister: () =>
                                                  unawaited(
                                                    _downloadIncidentRegisterCsv(),
                                                  ),
                                              onDownloadMedicationAudit: () =>
                                                  unawaited(
                                                    _downloadMedicationAuditCsv(),
                                                  ),
                                              onDownloadMedicationRound:
                                                  workspaceController
                                                      .activeShifts
                                                      .isEmpty
                                                  ? null
                                                  : () => unawaited(
                                                      _downloadMedicationRoundCsv(
                                                        (workspaceController
                                                                    .dashboard
                                                                    ?.activeShift ??
                                                                workspaceController
                                                                    .activeShifts
                                                                    .first)
                                                            .id,
                                                      ),
                                                    ),
                                              onDownloadResidentEmar:
                                                  (resident) => unawaited(
                                                    _downloadResidentEmarCsv(
                                                      resident,
                                                    ),
                                                  ),
                                              onDownloadResidentDowntimePack:
                                                  (resident) => unawaited(
                                                    _downloadResidentDowntimePackCsv(
                                                      resident,
                                                    ),
                                                  ),
                                            ),
                                            WorkspaceTab.console =>
                                              const ComingSoonPanel(
                                                key: ValueKey('console'),
                                                title: 'Operational tools',
                                                body:
                                                    'Additional operational tools will appear here as they are brought into the manager workspace.',
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
          );
        },
      ),
    );
  }
}
