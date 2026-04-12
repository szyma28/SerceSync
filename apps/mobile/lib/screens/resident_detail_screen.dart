import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
import '../models/workspace_models.dart';
import '../theme/app_theme.dart';

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
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load resident detail.');
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
    return task.status == 'PENDING' || task.status == 'OVERDUE';
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

  Future<void> _openAddEntrySheet([ResidentEntryType? initialType]) async {
    final draft = await showModalBottomSheet<ResidentTimelineEntryDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEntrySheet(
        initialType: initialType,
        onPickEvidence: _pickEvidence,
      ),
    );

    if (draft == null) return;

    setState(() => _isSaving = true);
    try {
      await widget.apiClient.createResidentTimelineEntry(
        accessToken: widget.accessToken,
        residentId: widget.residentId,
        draft: draft,
      );
      await _loadResident(showLoading: false);
      if (!mounted) return;
      await HapticFeedback.lightImpact();
      if (!mounted) return;
      _showNoteSaveConfirmation();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note saved.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Couldn\'t load resident detail',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loadResident,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
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
        floatingActionButton: FloatingActionButton.extended(
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
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadResident,
            color: AppTheme.primaryBlue,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 112),
              children: [
                _ResidentHeader(resident: resident),
                const SizedBox(height: 16),
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

class _ResidentHeader extends StatelessWidget {
  const _ResidentHeader({required this.resident});

  final ResidentDetail resident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              resident.photoAssetPath,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resident.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  resident.roomLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resident.assignmentContext,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: resident.alerts
                      .map(
                        (alert) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlueLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            alert,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.primaryBlueDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.resident,
    required this.taskNoteController,
    required this.onCompleteTask,
    required this.highlightTaskKey,
    required this.collapsingTaskIds,
    required this.successStateTaskIds,
    this.highlightTaskId,
    this.taskBeingUpdatedId,
  });

  final ResidentDetail resident;
  final String? highlightTaskId;
  final String? taskBeingUpdatedId;
  final GlobalKey highlightTaskKey;
  final Set<String> collapsingTaskIds;
  final Set<String> successStateTaskIds;
  final TextEditingController Function(String taskId) taskNoteController;
  final Future<void> Function(ResidentTaskSummary task) onCompleteTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(224),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlueDark.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shift summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            resident.todaySummary,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Active priorities',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (resident.currentTasks.isEmpty)
            Text(
              'No active priorities right now.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            )
          else
            ...resident.currentTasks.map((task) {
              final isCollapsing = collapsingTaskIds.contains(task.id);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: child,
                  ),
                ),
                child: isCollapsing
                    ? SizedBox(key: ValueKey('collapsed-${task.id}'))
                    : _ResidentTaskCard(
                        key: task.id == highlightTaskId
                            ? highlightTaskKey
                            : ValueKey(task.id),
                        task: task,
                        isHighlighted: task.id == highlightTaskId,
                        isSaving: task.id == taskBeingUpdatedId,
                        isSuccessState: successStateTaskIds.contains(task.id),
                        noteController: taskNoteController(task.id),
                        onComplete: () => onCompleteTask(task),
                      ),
              );
            }),
        ],
      ),
    );
  }
}

class _ResidentTaskCard extends StatelessWidget {
  const _ResidentTaskCard({
    super.key,
    required this.task,
    required this.isHighlighted,
    required this.isSaving,
    required this.isSuccessState,
    required this.noteController,
    required this.onComplete,
  });

  final ResidentTaskSummary task;
  final bool isHighlighted;
  final bool isSaving;
  final bool isSuccessState;
  final TextEditingController noteController;
  final VoidCallback onComplete;

  bool get _isCompletable {
    return task.status == 'PENDING' || task.status == 'OVERDUE';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isSuccessState
        ? AppTheme.successGreen
        : task.status == 'OVERDUE'
        ? AppTheme.errorRed
        : AppTheme.primaryBlue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccessState
            ? AppTheme.successGreen.withAlpha(14)
            : isHighlighted
            ? accentColor.withAlpha(12)
            : AppTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: isSuccessState || isHighlighted
            ? Border.all(color: accentColor.withAlpha(150), width: 1.6)
            : Border.all(color: AppTheme.borderLight),
        boxShadow: isSuccessState || isHighlighted
            ? [
                BoxShadow(
                  color: accentColor.withAlpha(22),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isSuccessState ? 'Done' : _statusLabel(task.status),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (task.description != null) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            task.dueAt == null
                ? 'Due this shift'
                : 'Due ${_formatTime(task.dueAt!)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlueDark,
            ),
          ),
          if (_isCompletable) ...[
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isSuccessState
                  ? Container(
                      key: ValueKey('success-${task.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withAlpha(16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.successGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Marked complete and added to the record.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.successGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      key: ValueKey('entry-${task.id}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: noteController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Completion note',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: isSaving ? null : onComplete,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.task_alt_rounded),
                            label: Text(isSaving ? 'Completing…' : 'Complete'),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'OVERDUE':
        return 'Overdue';
      case 'ESCALATED':
        return 'Escalated';
      case 'DEFERRED':
        return 'Deferred';
      case 'COMPLETED':
        return 'Completed';
      case 'PENDING':
      default:
        return 'Due';
    }
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.entry,
    required this.apiClient,
    required this.accessToken,
  });

  final ResidentTimelineEntry entry;
  final SerceSyncApiClient apiClient;
  final String accessToken;

  IconData get _icon {
    switch (entry.type) {
      case ResidentEntryType.observation:
        return Icons.visibility_outlined;
      case ResidentEntryType.personalCare:
        return Icons.shower_outlined;
      case ResidentEntryType.nutritionHydration:
        return Icons.local_drink_outlined;
      case ResidentEntryType.mobilityRepositioning:
        return Icons.accessibility_new_outlined;
      case ResidentEntryType.medicationNote:
        return Icons.medication_outlined;
      case ResidentEntryType.escalation:
        return Icons.trending_up;
      case ResidentEntryType.careGiven:
        return Icons.task_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: AppTheme.primaryBlueDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.details,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.38,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${entry.authorName} · ${_formatDateTime(entry.timestamp)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
                if (entry.media.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${entry.media.length} attachment${entry.media.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...entry.media.map(
                    (media) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              apiClient.resolveMediaUrl(media.downloadPath),
                              headers: {'Authorization': 'Bearer $accessToken'},
                              fit: BoxFit.cover,
                              height: 160,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: AppTheme.textSecondary,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            media.originalFileName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet({this.initialType, required this.onPickEvidence});

  final ResidentEntryType? initialType;
  final Future<TimelineEvidenceFile?> Function() onPickEvidence;

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  late ResidentEntryType _selectedType;
  final _detailsController = TextEditingController();
  TimelineEvidenceFile? _evidence;
  bool _isPickingEvidence = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? ResidentEntryType.careGiven;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() {
    final details = _detailsController.text.trim();
    if (details.isEmpty) return;

    Navigator.of(context).pop(
      ResidentTimelineEntryDraft(
        type: _selectedType,
        details: details,
        evidence: _evidence,
      ),
    );
  }

  Future<void> _attachEvidence() async {
    setState(() => _isPickingEvidence = true);
    try {
      final pickedEvidence = await widget.onPickEvidence();
      if (!mounted || pickedEvidence == null) return;
      setState(() => _evidence = pickedEvidence);
    } finally {
      if (mounted) {
        setState(() => _isPickingEvidence = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add note',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<ResidentEntryType>(
              initialValue: _selectedType,
              items: ResidentEntryType.values
                  .map(
                    (type) => DropdownMenuItem<ResidentEntryType>(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedType = value);
              },
              decoration: const InputDecoration(labelText: 'Note type'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Note',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isPickingEvidence ? null : _attachEvidence,
              icon: _isPickingEvidence
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo_outlined),
              label: Text(_evidence == null ? 'Attach photo' : 'Replace photo'),
            ),
            if (_evidence != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        Uint8List.fromList(_evidence!.bytes),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _evidence!.fileName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save note'),
            ),
          ],
        ),
      ),
    );
  }
}
