import 'package:flutter/material.dart';

import 'manager_api_client.dart';
import 'manager_file_download_api.dart';
import 'manager_models.dart';
import 'manager_shared.dart';
import 'manager_theme.dart';

part 'manager_emar_sections.dart';
part 'manager_emar_dialogs.dart';

class ResidentEmarDialog extends StatefulWidget {
  const ResidentEmarDialog({
    super.key,
    required this.apiClient,
    required this.fileDownloader,
    required this.accessToken,
    required this.resident,
    required this.onChanged,
  });

  final SerceSyncManagerApiClient apiClient;
  final ManagerFileDownloader fileDownloader;
  final String accessToken;
  final ManagerResidentRecord resident;
  final Future<void> Function() onChanged;

  @override
  State<ResidentEmarDialog> createState() => ResidentEmarDialogState();
}

class ResidentEmarDialogState extends State<ResidentEmarDialog> {
  ManagerResidentEmarProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmar();
  }

  Future<void> _loadEmar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await widget.apiClient.getResidentEmar(
        accessToken: widget.accessToken,
        residentId: widget.resident.id,
      );
      if (!mounted) {
        return;
      }
      setState(() => _profile = profile);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runMutation(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _isSaving = true);
    try {
      await action();
      await _loadEmar();
      await widget.onChanged();
      if (!mounted) {
        return;
      }
      showManagerNotice(context, message: successMessage);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      showManagerNotice(context, message: error.message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _createMedicationOrder() async {
    final draft = await showDialog<ManagerMedicationOrderDraft>(
      context: context,
      builder: (context) => const _MedicationOrderEditorDialog(),
    );
    if (draft == null) {
      return;
    }

    await _runMutation(() async {
      await widget.apiClient.createMedicationOrder(
        accessToken: widget.accessToken,
        residentId: widget.resident.id,
        draft: draft,
      );
    }, successMessage: 'Medication order added to the medication chart.');
  }

  Future<void> _editMedicationOrder(ManagerMedicationOrderRecord order) async {
    final draft = await showDialog<ManagerMedicationOrderDraft>(
      context: context,
      builder: (context) => _MedicationOrderEditorDialog(order: order),
    );
    if (draft == null) {
      return;
    }

    await _runMutation(() async {
      await widget.apiClient.updateMedicationOrder(
        accessToken: widget.accessToken,
        medicationOrderId: order.id,
        draft: draft,
      );
    }, successMessage: 'Medication order updated.');
  }

  Future<void> _deactivateMedicationOrder(
    ManagerMedicationOrderRecord order,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _MedicationReasonDialog(
        title: 'Deactivate ${order.medicationName}',
        prompt:
            'Document why this medication order is being deactivated in the medication chart.',
        confirmLabel: 'Deactivate',
      ),
    );
    if (reason == null) {
      return;
    }

    await _runMutation(() async {
      await widget.apiClient.deactivateMedicationOrder(
        accessToken: widget.accessToken,
        medicationOrderId: order.id,
        reason: reason,
      );
    }, successMessage: 'Medication order deactivated.');
  }

  Future<void> _addSchedule(ManagerMedicationOrderRecord order) async {
    final draft = await showDialog<ManagerMedicationScheduleDraft>(
      context: context,
      builder: (context) => const _MedicationScheduleDialog(),
    );
    if (draft == null) {
      return;
    }

    await _runMutation(() async {
      await widget.apiClient.createMedicationSchedule(
        accessToken: widget.accessToken,
        medicationOrderId: order.id,
        draft: draft,
      );
    }, successMessage: 'Medication schedule added.');
  }

  Future<void> _addPrnProtocol(ManagerMedicationOrderRecord order) async {
    final draft = await showDialog<ManagerPrnProtocolDraft>(
      context: context,
      builder: (context) => _PrnProtocolDialog(protocol: order.prnProtocol),
    );
    if (draft == null) {
      return;
    }

    await _runMutation(() async {
      await widget.apiClient.createPrnProtocol(
        accessToken: widget.accessToken,
        medicationOrderId: order.id,
        draft: draft,
      );
    }, successMessage: 'PRN protocol recorded.');
  }

  Future<void> _addAllergy() async {
    final draft = await showDialog<ManagerMedicationAllergyDraft>(
      context: context,
      builder: (context) => const _MedicationAllergyDialog(),
    );
    if (draft == null) {
      return;
    }

    await _runMutation(() async {
      await widget.apiClient.createMedicationAllergy(
        accessToken: widget.accessToken,
        residentId: widget.resident.id,
        draft: draft,
      );
    }, successMessage: 'Allergy/intolerance recorded.');
  }

  Future<void> _recordStockTransaction(
    ManagerMedicationOrderRecord order,
  ) async {
    final draft = await showDialog<ManagerMedicationStockTransactionDraft>(
      context: context,
      builder: (context) => _MedicationStockTransactionDialog(order: order),
    );
    if (draft == null) {
      return;
    }

    await _runMutation(() async {
      await widget.apiClient.createMedicationStockTransaction(
        accessToken: widget.accessToken,
        medicationOrderId: order.id,
        draft: draft,
      );
    }, successMessage: 'Stock balance recorded for ${order.medicationName}.');
  }

  Future<void> _downloadResidentExport() async {
    try {
      final csv = await widget.apiClient.exportResidentEmarCsv(
        accessToken: widget.accessToken,
        residentId: widget.resident.id,
      );
      if (!mounted) {
        return;
      }
      await downloadCsvExport(
        context,
        downloader: widget.fileDownloader,
        fileName:
            'resident-${widget.resident.roomNumber.toString().padLeft(2, '0')}-emar.csv',
        csv: csv,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      showManagerNotice(context, message: error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.resident.fullName} medication chart',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.resident.roomLabel} • ${widget.resident.unitLabel} • Floor ${widget.resident.floorNumber}',
                          style: const TextStyle(
                            color: managerMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Review current orders, allergies, recent medication events, stock notes, and change history for this resident.',
                          style: TextStyle(color: managerMuted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _loadEmar,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isSaving ? null : _downloadResidentExport,
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Export CSV'),
                      ),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _createMedicationOrder,
                        icon: const Icon(Icons.add_box_outlined),
                        label: const Text('Add medication'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _isSaving ? null : _addAllergy,
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: const Text('Record allergy'),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (profile?.downtimeNotice.isNotEmpty ?? false)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: managerWarningSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: managerWarning.withAlpha(90)),
                  ),
                  child: Text(
                    profile!.downtimeNotice,
                    style: const TextStyle(
                      color: Color(0xFF9A6700),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Expanded(
                child: _isLoading && profile == null
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null && profile == null
                    ? ErrorSurface(message: _errorMessage!)
                    : profile == null
                    ? const EmptySurface(
                        title: 'Medication chart unavailable',
                        body:
                            'The resident medication profile could not be loaded.',
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _EmarChartSummaryCard(
                              resident: widget.resident,
                              chart: profile.chart,
                              safetyBanner: profile.safetyBanner,
                            ),
                            const SizedBox(height: 18),
                            _EmarAllergySection(
                              allergies: profile.allergies,
                              onAddAllergy: _isSaving ? null : _addAllergy,
                            ),
                            const SizedBox(height: 18),
                            _EmarMedicationSection(
                              title: 'Scheduled medication',
                              emptyTitle: 'No scheduled medication recorded',
                              emptyBody:
                                  'Add a medication order to start building the resident chart.',
                              children: profile.scheduledMedications
                                  .map(
                                    (order) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _EmarMedicationOrderCard(
                                        order: order,
                                        onEdit: _isSaving
                                            ? null
                                            : () => _editMedicationOrder(order),
                                        onDeactivate:
                                            _isSaving || !order.isActive
                                            ? null
                                            : () => _deactivateMedicationOrder(
                                                order,
                                              ),
                                        onAddSchedule: _isSaving || order.isPrn
                                            ? null
                                            : () => _addSchedule(order),
                                        onAddPrnProtocol:
                                            _isSaving || !order.isPrn
                                            ? null
                                            : () => _addPrnProtocol(order),
                                        onRecordStock: _isSaving
                                            ? null
                                            : () => _recordStockTransaction(
                                                order,
                                              ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 18),
                            _EmarMedicationSection(
                              title: 'PRN medication',
                              emptyTitle: 'No PRN medication recorded',
                              emptyBody:
                                  'Use PRN lines to document as-needed medication protocols without generating timed reminders.',
                              children: profile.prnMedications
                                  .map(
                                    (order) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _EmarMedicationOrderCard(
                                        order: order,
                                        onEdit: _isSaving
                                            ? null
                                            : () => _editMedicationOrder(order),
                                        onDeactivate:
                                            _isSaving || !order.isActive
                                            ? null
                                            : () => _deactivateMedicationOrder(
                                                order,
                                              ),
                                        onAddSchedule: null,
                                        onAddPrnProtocol: _isSaving
                                            ? null
                                            : () => _addPrnProtocol(order),
                                        onRecordStock: _isSaving
                                            ? null
                                            : () => _recordStockTransaction(
                                                order,
                                              ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 18),
                            _EmarRecentEventsSection(
                              events: profile.recentEvents,
                            ),
                            const SizedBox(height: 18),
                            _EmarStockSection(
                              stockOverview: profile.stockOverview,
                              orders: <ManagerMedicationOrderRecord>[
                                ...profile.scheduledMedications,
                                ...profile.prnMedications,
                              ],
                              onRecordStock: _isSaving
                                  ? null
                                  : _recordStockTransaction,
                            ),
                            const SizedBox(height: 18),
                            _EmarChangeHistorySection(
                              changeHistory: profile.changeHistory,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
