import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../controllers/mobile_session_controller.dart';
import '../models/medication_models.dart';
import '../models/workspace_models.dart';
import '../theme/app_theme.dart';
import '../widgets/data_freshness_indicator.dart';
import '../widgets/date_time_formatters.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/resume_refresh_mixin.dart';
import '../widgets/screen_message_state.dart';

part 'medication_round/medication_round_components.dart';

class MedicationRoundScreen extends StatefulWidget {
  const MedicationRoundScreen({
    super.key,
    required this.apiClient,
    required this.accessToken,
    required this.shiftId,
  });

  final SerceSyncApiClient apiClient;
  final String accessToken;
  final String shiftId;

  @override
  State<MedicationRoundScreen> createState() => _MedicationRoundScreenState();
}

class _MedicationRoundScreenState extends State<MedicationRoundScreen>
    with WidgetsBindingObserver, ResumeRefreshStateMixin {
  MedicationRoundSnapshot? _round;
  bool _isLoading = true;
  String? _errorMessage;
  String? _activeDoseId;
  String? _noteResidentId;
  DateTime? _lastUpdatedAt;

  MobileSessionController get _sessionController =>
      context.read<MobileSessionController>();

  @override
  void initState() {
    super.initState();
    _loadRound();
  }

  @override
  bool get canTriggerResumeRefresh =>
      context.read<MobileSessionController>().hasActiveSession;

  @override
  bool get hasVisibleContentForResumeRefresh => _round != null;

  @override
  Future<void> refreshAfterResume() => _loadRound(showLoading: false);

  Future<({SerceSyncApiClient apiClient, String accessToken})?>
  _resolveActiveClientSession() async {
    final session = await _sessionController.resolveSession(
      refreshIfNeeded: true,
    );
    final apiClient = _sessionController.apiClient ?? widget.apiClient;
    final accessToken = session?.accessToken ?? widget.accessToken;

    if (accessToken.isEmpty) {
      return null;
    }

    return (apiClient: apiClient, accessToken: accessToken);
  }

  void _showRoundMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorRed : null,
      ),
    );
  }

  Future<void> _loadRound({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = null);
    }

    try {
      final clientSession = await _resolveActiveClientSession();
      if (clientSession == null) {
        if (mounted) {
          setState(
            () => _errorMessage = 'Your session expired. Please sign in again.',
          );
        }
        return;
      }

      final round = await clientSession.apiClient.getMedicationRound(
        accessToken: clientSession.accessToken,
        shiftId: widget.shiftId,
      );
      if (!mounted) return;
      setState(() {
        _round = round;
        _errorMessage = null;
        _lastUpdatedAt = DateTime.now();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openOutcomeSheet(
    MedicationRoundItem item,
    _MedicationRoundAction action,
  ) async {
    final round = _round;
    if (round == null) {
      return;
    }

    final draft = await showModalBottomSheet<_DoseOutcomeDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MedicationOutcomeSheet(
        item: item,
        action: action,
        witnessCandidates: round.witnessCandidates,
      ),
    );

    if (draft == null) {
      return;
    }

    setState(() => _activeDoseId = item.id);
    try {
      final clientSession = await _resolveActiveClientSession();
      if (clientSession == null) {
        _showRoundMessage(
          'Your session expired. Please sign in again.',
          isError: true,
        );
        return;
      }

      switch (action) {
        case _MedicationRoundAction.administer:
          await clientSession.apiClient.administerMedicationDose(
            accessToken: clientSession.accessToken,
            doseInstanceId: item.id,
            doseGiven: draft.doseGiven,
            doseUnit: draft.doseUnit,
            notes: draft.notes,
            witnessUserId: draft.witnessUserId,
          );
          break;
        case _MedicationRoundAction.refuse:
          await clientSession.apiClient.refuseMedicationDose(
            accessToken: clientSession.accessToken,
            doseInstanceId: item.id,
            reason: draft.reason!,
            notes: draft.notes,
            witnessUserId: draft.witnessUserId,
          );
          break;
        case _MedicationRoundAction.omit:
          await clientSession.apiClient.omitMedicationDose(
            accessToken: clientSession.accessToken,
            doseInstanceId: item.id,
            reason: draft.reason!,
            notes: draft.notes,
            witnessUserId: draft.witnessUserId,
          );
          break;
        case _MedicationRoundAction.delay:
          await clientSession.apiClient.delayMedicationDose(
            accessToken: clientSession.accessToken,
            doseInstanceId: item.id,
            reason: draft.reason!,
            notes: draft.notes,
            witnessUserId: draft.witnessUserId,
          );
          break;
        case _MedicationRoundAction.notAvailable:
          await clientSession.apiClient.markMedicationNotAvailable(
            accessToken: clientSession.accessToken,
            doseInstanceId: item.id,
            reason: draft.reason!,
            notes: draft.notes,
            witnessUserId: draft.witnessUserId,
          );
          break;
        case _MedicationRoundAction.hold:
          await clientSession.apiClient.holdMedicationDose(
            accessToken: clientSession.accessToken,
            doseInstanceId: item.id,
            reason: draft.reason!,
            notes: draft.notes,
            witnessUserId: draft.witnessUserId,
          );
          break;
      }

      await _loadRound();
      _showRoundMessage('${action.label} recorded for ${item.medicationName}.');
    } on ApiException catch (error) {
      _showRoundMessage(error.message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _activeDoseId = null);
      }
    }
  }

  Future<void> _openAddNoteDialog(MedicationRoundItem item) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medication Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: 'Note',
            hintText:
                'Record a medication note linked to this resident and dose.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save note'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (note == null || note.isEmpty) {
      return;
    }

    setState(() => _noteResidentId = item.residentId);
    try {
      final clientSession = await _resolveActiveClientSession();
      if (clientSession == null) {
        _showRoundMessage(
          'Your session expired. Please sign in again.',
          isError: true,
        );
        return;
      }

      await clientSession.apiClient.createResidentTimelineEntry(
        accessToken: clientSession.accessToken,
        residentId: item.residentId,
        draft: ResidentTimelineEntryDraft(
          type: ResidentEntryType.medicationNote,
          details:
              '${item.titleLine} (${_displayMedicationWindowLabel(item.dueWindowStart, item.dueWindowEnd)}, ${item.roomLabel}) — $note',
        ),
      );
      _showRoundMessage('Medication note saved for ${item.residentName}.');
    } on ApiException catch (error) {
      _showRoundMessage(error.message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _noteResidentId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _round == null) {
      return Container(
        decoration: AppTheme.atmosphericBackground,
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(child: _MedicationRoundLoadingSkeleton()),
        ),
      );
    }

    if (_errorMessage != null && _round == null) {
      return Container(
        decoration: AppTheme.atmosphericBackground,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Medication Round')),
          body: ScreenMessageState(
            title: 'Couldn\'t load medication round',
            message: _errorMessage!,
            actionLabel: 'Try Again',
            onAction: _loadRound,
          ),
        ),
      );
    }

    final round = _round!;
    final groups = _buildDisplayedMedicationGroups(round.groupedRounds);
    final totalItems = groups.fold<int>(
      0,
      (sum, group) => sum + group.items.length,
    );

    return Container(
      decoration: AppTheme.atmosphericBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Medication Round'),
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _loadRound,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadRound,
            color: AppTheme.primaryBlue,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 112),
              children: [
                DataFreshnessIndicator(
                  lastUpdatedAt: _lastUpdatedAt,
                  isRefreshing: _isLoading,
                  label: 'Live medication round',
                ),
                _MedicationRoundNoticeCard(
                  title: 'Medication recording',
                  body:
                      'Use this round to record scheduled doses, outcome variances, and medication notes for residents on this shift.',
                  icon: Icons.health_and_safety_outlined,
                  tone: AppTheme.primaryBlueDark,
                  background: Colors.white.withAlpha(220),
                ),
                const SizedBox(height: 12),
                _MedicationRoundNoticeCard(
                  title: 'Follow local policy',
                  body: round.safetyBanner,
                  icon: Icons.warning_amber_rounded,
                  tone: const Color(0xFF9A6700),
                  background: AppTheme.warningYellow.withAlpha(28),
                ),
                const SizedBox(height: 12),
                _MedicationRoundNoticeCard(
                  title: 'Identity and label check',
                  body:
                      'Check medication label, resident identity and prescribed instructions before recording.',
                  icon: Icons.verified_user_outlined,
                  tone: AppTheme.errorRed,
                  background: AppTheme.errorRed.withAlpha(12),
                ),
                const SizedBox(height: 16),
                _MedicationRoundScopeCard(
                  shift: round.shift,
                  medicationCount: totalItems,
                ),
                const SizedBox(height: 18),
                if (groups.isEmpty)
                  const _MedicationRoundEmptyCard()
                else
                  ...groups.map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _MedicationRoundGroupCard(
                        group: group,
                        activeDoseId: _activeDoseId,
                        noteResidentId: _noteResidentId,
                        onAdminister: (item) => _openOutcomeSheet(
                          item,
                          _MedicationRoundAction.administer,
                        ),
                        onRefuse: (item) => _openOutcomeSheet(
                          item,
                          _MedicationRoundAction.refuse,
                        ),
                        onOmit: (item) => _openOutcomeSheet(
                          item,
                          _MedicationRoundAction.omit,
                        ),
                        onDelay: (item) => _openOutcomeSheet(
                          item,
                          _MedicationRoundAction.delay,
                        ),
                        onNotAvailable: (item) => _openOutcomeSheet(
                          item,
                          _MedicationRoundAction.notAvailable,
                        ),
                        onHold: (item) => _openOutcomeSheet(
                          item,
                          _MedicationRoundAction.hold,
                        ),
                        onAddNote: _openAddNoteDialog,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
