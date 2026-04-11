import 'dart:typed_data';

import 'package:flutter/material.dart';
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
  });

  final String residentId;
  final SerceSyncApiClient apiClient;
  final String accessToken;
  final String currentCarerName;

  @override
  State<ResidentDetailScreen> createState() => _ResidentDetailScreenState();
}

class _ResidentDetailScreenState extends State<ResidentDetailScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  ResidentDetail? _resident;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadResident();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resident entry added to the timeline.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.edit_note_rounded),
          label: Text(_isSaving ? 'Saving…' : 'Add Entry'),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadResident,
            color: AppTheme.primaryBlue,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
              children: [
                _ResidentHeader(resident: resident),
                const SizedBox(height: 20),
                _TodaySummaryCard(resident: resident),
                const SizedBox(height: 20),
                Text(
                  'Recent Care Timeline',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Structured entries keep continuity visible across the shift, including what was recorded, who logged it, and when.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                if (resident.timeline.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(210),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Text(
                      'No timeline entries have been recorded yet for this resident.',
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              resident.photoAssetPath,
              width: 92,
              height: 92,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 18),
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: resident.alerts
                      .map(
                        (alert) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
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
  const _TodaySummaryCard({required this.resident});

  final ResidentDetail resident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Shift', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            resident.todaySummary,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 14),
          Text(
            'Current priorities',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (resident.currentTasks.isEmpty)
            Text(
              resident.contextLine,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            )
          else
            ...resident.currentTasks.map(
              (task) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (task.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${task.status} ${task.dueAt != null ? '· due ${_formatTime(task.dueAt!)}' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlueDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: AppTheme.primaryBlueDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  entry.details,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${entry.authorName} · ${_formatDateTime(entry.timestamp)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
                if (entry.media.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    '${entry.media.length} evidence item attached${entry.media.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...entry.media.map(
                    (media) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              apiClient.resolveMediaUrl(media.downloadPath),
                              headers: {
                                'Authorization': 'Bearer $accessToken',
                              },
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
  const _AddEntrySheet({
    this.initialType,
    required this.onPickEvidence,
  });

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
              'Add Structured Entry',
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
              decoration: const InputDecoration(labelText: 'Entry type'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Details',
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
              label: Text(
                _evidence == null ? 'Attach photo evidence' : 'Replace photo evidence',
              ),
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
              label: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
