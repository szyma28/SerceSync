import 'package:flutter/material.dart';

import '../models/workspace_models.dart';
import '../theme/app_theme.dart';

class ResidentDetailScreen extends StatefulWidget {
  const ResidentDetailScreen({
    super.key,
    required this.profile,
    required this.currentCarerName,
    required this.onProfileChanged,
  });

  final ResidentProfile profile;
  final String currentCarerName;
  final ValueChanged<ResidentProfile> onProfileChanged;

  @override
  State<ResidentDetailScreen> createState() => _ResidentDetailScreenState();
}

class _ResidentDetailScreenState extends State<ResidentDetailScreen> {
  late ResidentProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<void> _openAddEntrySheet() async {
    final draft = await showModalBottomSheet<_EntryDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddEntrySheet(),
    );

    if (draft == null) return;

    final entry = ResidentTimelineEntry(
      id: 'entry-${DateTime.now().microsecondsSinceEpoch}',
      type: draft.type,
      title: draft.title,
      details: draft.details,
      authorName: widget.currentCarerName,
      timestamp: DateTime.now(),
    );

    setState(() {
      _profile = _profile.copyWith(timeline: [entry, ..._profile.timeline]);
    });
    widget.onProfileChanged(_profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(_profile.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddEntrySheet,
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Add Entry'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
          children: [
            _ResidentHeader(profile: _profile),
            const SizedBox(height: 20),
            _TodaySummaryCard(profile: _profile),
            const SizedBox(height: 20),
            _QuickActionsStrip(onAddEntry: _openAddEntrySheet),
            const SizedBox(height: 20),
            _PhotoGovernanceCard(),
            const SizedBox(height: 20),
            Text(
              'Recent Care Timeline',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Structured notes keep continuity visible across the shift, including what was done, who logged it, and when.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            ..._profile.timeline.map((entry) => _TimelineCard(entry: entry)),
          ],
        ),
      ),
    );
  }
}

class _ResidentHeader extends StatelessWidget {
  const _ResidentHeader({required this.profile});

  final ResidentProfile profile;

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
              profile.photoAssetPath,
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
                  profile.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  profile.room,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.assignmentContext,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.alerts
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
  const _TodaySummaryCard({required this.profile});

  final ResidentProfile profile;

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
          Text('Today', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            profile.todaySummary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppTheme.warningYellow,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    profile.contextLine,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsStrip extends StatelessWidget {
  const _QuickActionsStrip({required this.onAddEntry});

  final VoidCallback onAddEntry;

  @override
  Widget build(BuildContext context) {
    const actions = [
      'Care Given',
      'Observation',
      'Personal Care',
      'Nutrition / Hydration',
      'Mobility / Repositioning',
      'Medication Note',
      'Escalation',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Add', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: actions
                .map(
                  (label) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ActionChip(
                      onPressed: onAddEntry,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.borderLight),
                      label: Text(label),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PhotoGovernanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlueLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.photo_camera_back_outlined,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Photo Evidence Placeholder',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Identity photos, wound progress photos, and life-event images are part of the future care-evidence model, but this pass keeps them behind governance messaging only. Consent, lawful basis, audit trail, secure storage, and role-based access must be in place before capture or upload goes live.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.entry});

  final ResidentTimelineEntry entry;

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
      case ResidentEntryType.photoEvidence:
        return Icons.photo_library_outlined;
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
              color: AppTheme.surfaceBackground,
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
                  entry.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  entry.details,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 10),
                Text(
                  '${entry.authorName} · ${_formatTimestamp(entry.timestamp)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTimestamp(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet();

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  ResidentEntryType _selectedType = ResidentEntryType.careGiven;

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
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
              'Add structured note',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ResidentEntryType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Entry type'),
              items: ResidentEntryType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_labelFor(type)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'What happened'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Details',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed:
                  _titleController.text.trim().isEmpty ||
                      _detailsController.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(
                      _EntryDraft(
                        type: _selectedType,
                        title: _titleController.text.trim(),
                        details: _detailsController.text.trim(),
                      ),
                    ),
              child: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  static String _labelFor(ResidentEntryType type) {
    switch (type) {
      case ResidentEntryType.careGiven:
        return 'Care Given';
      case ResidentEntryType.observation:
        return 'Observation';
      case ResidentEntryType.personalCare:
        return 'Personal Care';
      case ResidentEntryType.nutritionHydration:
        return 'Nutrition / Hydration';
      case ResidentEntryType.mobilityRepositioning:
        return 'Mobility / Repositioning';
      case ResidentEntryType.medicationNote:
        return 'Medication Note';
      case ResidentEntryType.escalation:
        return 'Escalation';
      case ResidentEntryType.photoEvidence:
        return 'Photo Evidence';
    }
  }
}

class _EntryDraft {
  const _EntryDraft({
    required this.type,
    required this.title,
    required this.details,
  });

  final ResidentEntryType type;
  final String title;
  final String details;
}
