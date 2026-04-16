import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
import '../models/workspace_models.dart';
import '../theme/app_theme.dart';
import '../widgets/resident_priority_badge.dart';
import '../widgets/screen_message_state.dart';
import '../widgets/date_time_formatters.dart';

part 'resident_detail/resident_detail_header.dart';
part 'resident_detail/resident_detail_tasks.dart';
part 'resident_detail/resident_detail_timeline.dart';
part 'resident_detail/resident_detail_sheet_widgets.dart';
part 'resident_detail/resident_detail_entry_sheet.dart';
part 'resident_detail/resident_detail_incident_sheet.dart';

class ResidentDetailScreen extends StatefulWidget {
  const ResidentDetailScreen({
    super.key,
    required this.residentId,
    required this.apiClient,
    required this.accessToken,
    required this.currentCarerName,
    this.highlightTaskId,
  });

  final String residentId;
  final SerceSyncApiClient apiClient;
  final String accessToken;
  final String currentCarerName;
  final String? highlightTaskId;

  @override
  State<ResidentDetailScreen> createState() => _ResidentDetailScreenState();
}

class _ResidentDetailScreenState extends State<ResidentDetailScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _highlightTaskKey = GlobalKey();
  final Map<String, TextEditingController> _completionControllers = {};
  Timer? _highlightClearTimer;
  Timer? _noteSaveConfirmationTimer;
  ResidentDetail? _resident;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _taskBeingUpdatedId;
  String? _activeHighlightTaskId;
  String? _errorMessage;
  final Set<String> _collapsingTaskIds = <String>{};
  final Set<String> _successStateTaskIds = <String>{};
  bool _noteSaveConfirmed = false;

  @override
  void initState() {
    super.initState();
    _activeHighlightTaskId = widget.highlightTaskId;
    _loadResident();
  }

  @override
  void dispose() {
    _highlightClearTimer?.cancel();
    _noteSaveConfirmationTimer?.cancel();
    for (final controller in _completionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadResident({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final resident = await widget.apiClient.getResidentById(
        accessToken: widget.accessToken,
        residentId: widget.residentId,
      );
      if (!mounted) return;
      setState(() {
        _resident = resident;
        _errorMessage = null;
      });
      _scheduleHighlightedTaskReveal(resident);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  TextEditingController _completionControllerForTask(String taskId) {
    return _completionControllers.putIfAbsent(
      taskId,
      TextEditingController.new,
    );
  }

  bool _isTaskCompletable(ResidentTaskSummary task) {
    return task.status == TaskStatus.pending ||
        task.status == TaskStatus.overdue;
  }

  void _scheduleHighlightedTaskReveal(ResidentDetail resident) {
    final taskId = _activeHighlightTaskId;
    if (taskId == null) {
      return;
    }

    final highlightedTaskExists = resident.currentTasks.any(
      (task) => task.id == taskId,
    );
    if (!highlightedTaskExists) {
      if (mounted) {
        setState(() => _activeHighlightTaskId = null);
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealHighlightedTask(taskId);
    });
  }

  Future<void> _revealHighlightedTask(String taskId) async {
    if (!mounted || _activeHighlightTaskId != taskId) {
      return;
    }

    final targetContext = _highlightTaskKey.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.18,
      );
    }

    _highlightClearTimer?.cancel();
    _highlightClearTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted || _activeHighlightTaskId != taskId) {
        return;
      }
      setState(() => _activeHighlightTaskId = null);
    });
  }

  Future<void> _completeResidentTask(ResidentTaskSummary task) async {
    if (!_isTaskCompletable(task) || _taskBeingUpdatedId != null) {
      return;
    }

    final controller = _completionControllerForTask(task.id);
    final note = controller.text.trim();

    setState(() => _taskBeingUpdatedId = task.id);
    try {
      await widget.apiClient.completeTask(
        accessToken: widget.accessToken,
        taskId: task.id,
        note: note.isEmpty ? null : note,
      );
      controller.clear();
      if (!mounted) return;
      setState(() {
        _taskBeingUpdatedId = null;
        _activeHighlightTaskId = null;
        _successStateTaskIds.add(task.id);
      });
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;
      setState(() {
        _successStateTaskIds.remove(task.id);
        _collapsingTaskIds.add(task.id);
      });
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await _loadResident(showLoading: false);
      if (!mounted) return;
      setState(() => _collapsingTaskIds.remove(task.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Priority completed.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _taskBeingUpdatedId = null);
      }
    }
  }

  Future<T?> _showResidentSheet<T>(WidgetBuilder builder) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: builder,
    );
  }

  Future<void> _runResidentSave<T>({
    required T? draft,
    required Future<void> Function(T draft) persistDraft,
    required Future<void> Function() onSaved,
    required String successMessage,
  }) async {
    if (draft == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await persistDraft(draft);
      await _loadResident(showLoading: false);
      if (!mounted) return;
      await onSaved();
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
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openAddEntrySheet([ResidentEntryType? initialType]) async {
    final draft = await _showResidentSheet<ResidentTimelineEntryDraft>(
      (context) => _AddEntrySheet(
        initialType: initialType,
        onPickEvidence: _pickEvidence,
      ),
    );

    await _runResidentSave(
      draft: draft,
      persistDraft: (residentDraft) =>
          widget.apiClient.createResidentTimelineEntry(
            accessToken: widget.accessToken,
            residentId: widget.residentId,
            draft: residentDraft,
          ),
      onSaved: () async {
        await HapticFeedback.lightImpact();
        if (!mounted) return;
        _showNoteSaveConfirmation();
      },
      successMessage: 'Note saved.',
    );
  }

  Future<void> _openReportIncidentSheet() async {
    final draft = await _showResidentSheet<ResidentIncidentDraft>(
      (context) => _ReportIncidentSheet(onPickEvidence: _pickEvidence),
    );

    await _runResidentSave(
      draft: draft,
      persistDraft: (incidentDraft) => widget.apiClient.createResidentIncident(
        accessToken: widget.accessToken,
        residentId: widget.residentId,
        draft: incidentDraft,
      ),
      onSaved: () => HapticFeedback.heavyImpact(),
      successMessage: 'Incident reported.',
    );
  }

  void _showNoteSaveConfirmation() {
    _noteSaveConfirmationTimer?.cancel();
    setState(() => _noteSaveConfirmed = true);
    _noteSaveConfirmationTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _noteSaveConfirmed = false);
    });
  }

  Future<TimelineEvidenceFile?> _pickEvidence() async {
    final selectedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 82,
    );

    if (selectedFile == null) {
      return null;
    }

    final bytes = await selectedFile.readAsBytes();
    return TimelineEvidenceFile(
      fileName: selectedFile.name,
      bytes: bytes,
      mediaType: _inferMediaType(selectedFile.name),
    );
  }

  String _inferMediaType(String fileName) {
    final lowerCase = fileName.toLowerCase();
    if (lowerCase.endsWith('.png')) return 'image/png';
    if (lowerCase.endsWith('.webp')) return 'image/webp';
    if (lowerCase.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _resident == null) {
      return Container(
        decoration: AppTheme.atmosphericBackground,
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          ),
        ),
      );
    }

    if (_errorMessage != null && _resident == null) {
      return Container(
        decoration: AppTheme.atmosphericBackground,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Resident')),
          body: ScreenMessageState(
            title: 'Couldn\'t load resident detail',
            message: _errorMessage!,
            actionLabel: 'Try Again',
            onAction: _loadResident,
          ),
        ),
      );
    }

    final resident = _resident!;

    return Container(
      decoration: AppTheme.atmosphericBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(resident.fullName),
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _loadResident,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'report-incident',
              onPressed: _isSaving ? null : _openReportIncidentSheet,
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.emergency_outlined),
              label: Text(_isSaving ? 'Saving…' : 'Report incident'),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'add-note',
              onPressed: _isSaving ? null : _openAddEntrySheet,
              backgroundColor: _noteSaveConfirmed
                  ? AppTheme.successGreen
                  : AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _isSaving
                    ? const SizedBox(
                        key: ValueKey('saving-note'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _noteSaveConfirmed
                            ? Icons.check_circle_rounded
                            : Icons.edit_note_rounded,
                        key: ValueKey(_noteSaveConfirmed),
                      ),
              ),
              label: Text(
                _isSaving
                    ? 'Saving…'
                    : _noteSaveConfirmed
                    ? 'Saved'
                    : 'Add note',
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadResident,
            color: AppTheme.primaryBlue,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 112),
              children: [
                _ResidentHeader(resident: resident),
                const SizedBox(height: 16),
                if (resident.activeIncidents.isNotEmpty) ...[
                  _ActiveIncidentSummaryCard(
                    incidents: resident.activeIncidents,
                  ),
                  const SizedBox(height: 16),
                ],
                _TodaySummaryCard(
                  resident: resident,
                  highlightTaskId: _activeHighlightTaskId,
                  taskBeingUpdatedId: _taskBeingUpdatedId,
                  highlightTaskKey: _highlightTaskKey,
                  collapsingTaskIds: _collapsingTaskIds,
                  successStateTaskIds: _successStateTaskIds,
                  taskNoteController: _completionControllerForTask,
                  onCompleteTask: _completeResidentTask,
                ),
                const SizedBox(height: 16),
                Text(
                  'Care notes',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                if (resident.timeline.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(210),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Text(
                      'No notes recorded yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  )
                else
                  ...resident.timeline.map(
                    (entry) => _TimelineCard(
                      entry: entry,
                      apiClient: widget.apiClient,
                      accessToken: widget.accessToken,
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
