part of '../medication_round_screen.dart';

class _MedicationRoundLoadingSkeleton extends StatelessWidget {
  const _MedicationRoundLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 112),
      children: const [
        SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(height: 18, width: 180, radius: 12),
              SizedBox(height: 10),
              SkeletonBlock(height: 14, width: double.infinity, radius: 10),
              SizedBox(height: 8),
              SkeletonBlock(height: 14, width: 240, radius: 10),
            ],
          ),
        ),
        SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(height: 16, width: 150, radius: 10),
              SizedBox(height: 12),
              SkeletonBlock(height: 48, width: double.infinity, radius: 16),
              SizedBox(height: 10),
              SkeletonBlock(height: 48, width: double.infinity, radius: 16),
            ],
          ),
        ),
        SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(height: 18, width: 160, radius: 10),
              SizedBox(height: 10),
              SkeletonBlock(height: 14, width: double.infinity, radius: 10),
              SizedBox(height: 8),
              SkeletonBlock(height: 14, width: 260, radius: 10),
            ],
          ),
        ),
      ],
    );
  }
}

enum _MedicationRoundAction {
  administer,
  refuse,
  omit,
  delay,
  notAvailable,
  hold,
}

extension on _MedicationRoundAction {
  String get label {
    switch (this) {
      case _MedicationRoundAction.administer:
        return 'Administer';
      case _MedicationRoundAction.refuse:
        return 'Refuse';
      case _MedicationRoundAction.omit:
        return 'Omit';
      case _MedicationRoundAction.delay:
        return 'Delay';
      case _MedicationRoundAction.notAvailable:
        return 'Not available';
      case _MedicationRoundAction.hold:
        return 'Hold';
    }
  }

  IconData get icon {
    switch (this) {
      case _MedicationRoundAction.administer:
        return Icons.check_circle_outline_rounded;
      case _MedicationRoundAction.refuse:
        return Icons.block_outlined;
      case _MedicationRoundAction.omit:
        return Icons.do_not_disturb_alt_outlined;
      case _MedicationRoundAction.delay:
        return Icons.schedule_rounded;
      case _MedicationRoundAction.notAvailable:
        return Icons.inventory_2_outlined;
      case _MedicationRoundAction.hold:
        return Icons.pause_circle_outline_rounded;
    }
  }
}

class _DoseOutcomeDraft {
  const _DoseOutcomeDraft({
    this.reason,
    this.doseGiven,
    this.doseUnit,
    this.notes,
    this.witnessUserId,
  });

  final String? reason;
  final String? doseGiven;
  final String? doseUnit;
  final String? notes;
  final String? witnessUserId;
}

class _MedicationOutcomeSheet extends StatefulWidget {
  const _MedicationOutcomeSheet({
    required this.item,
    required this.action,
    required this.witnessCandidates,
  });

  final MedicationRoundItem item;
  final _MedicationRoundAction action;
  final List<MedicationRoundWitnessCandidate> witnessCandidates;

  @override
  State<_MedicationOutcomeSheet> createState() =>
      _MedicationOutcomeSheetState();
}

class _MedicationOutcomeSheetState extends State<_MedicationOutcomeSheet> {
  late final TextEditingController _reasonController;
  late final TextEditingController _doseGivenController;
  late final TextEditingController _doseUnitController;
  late final TextEditingController _notesController;
  String? _selectedWitnessUserId;
  bool _showValidation = false;

  bool get _reasonRequired =>
      widget.action != _MedicationRoundAction.administer;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _doseGivenController = TextEditingController(text: widget.item.doseAmount);
    _doseUnitController = TextEditingController(text: widget.item.doseUnit);
    _notesController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _doseGivenController.dispose();
    _doseUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (_reasonRequired && reason.length < 3) {
      setState(() => _showValidation = true);
      return;
    }
    if (widget.item.requiresWitness &&
        (_selectedWitnessUserId == null || _selectedWitnessUserId!.isEmpty)) {
      setState(() => _showValidation = true);
      return;
    }

    Navigator.of(context).pop(
      _DoseOutcomeDraft(
        reason: reason.isEmpty ? null : reason,
        doseGiven: _doseGivenController.text.trim().isEmpty
            ? null
            : _doseGivenController.text.trim(),
        doseUnit: _doseUnitController.text.trim().isEmpty
            ? null
            : _doseUnitController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        witnessUserId: _selectedWitnessUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final title = '${widget.action.label} ${widget.item.medicationName}';

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  '${widget.item.residentName} · ${widget.item.roomLabel} · ${_displayMedicationWindowLabel(widget.item.dueWindowStart, widget.item.dueWindowEnd)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.action == _MedicationRoundAction.administer) ...[
                  TextField(
                    controller: _doseGivenController,
                    decoration: const InputDecoration(
                      labelText: 'Dose given',
                      hintText: 'Enter the recorded dose',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _doseUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Dose unit',
                      hintText: 'tablet, ml, puff, capsule',
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Record why this medication was not given now.',
                      errorText:
                          _showValidation &&
                              _reasonController.text.trim().length < 3
                          ? 'A reason is required.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText:
                        'Optional extra note for audit and handover context.',
                  ),
                ),
                if (widget.item.requiresWitness) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'dose-witness-${_selectedWitnessUserId ?? 'none'}',
                    ),
                    initialValue: _selectedWitnessUserId,
                    decoration: InputDecoration(
                      labelText: 'Witness',
                      errorText:
                          _showValidation &&
                              (_selectedWitnessUserId == null ||
                                  _selectedWitnessUserId!.isEmpty)
                          ? 'A witness is required.'
                          : null,
                    ),
                    items: widget.witnessCandidates
                        .map(
                          (candidate) => DropdownMenuItem<String>(
                            value: candidate.id,
                            child: Text(candidate.displayName),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() => _selectedWitnessUserId = value);
                    },
                  ),
                ],
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.warningYellow.withAlpha(28),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.warningYellow.withAlpha(90),
                    ),
                  ),
                  child: Text(
                    'Record exactly what was given and document any variance from the prescribed instructions for audit and handover.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF9A6700),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: Icon(widget.action.icon),
                        label: Text(widget.action.label),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicationRoundNoticeCard extends StatelessWidget {
  const _MedicationRoundNoticeCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.tone,
    required this.background,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color tone;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withAlpha(36)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.45,
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

class _MedicationRoundScopeCard extends StatelessWidget {
  const _MedicationRoundScopeCard({
    required this.shift,
    required this.medicationCount,
  });

  final MedicationRoundShift shift;
  final int medicationCount;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Round details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _ScopeRow(label: 'Round', value: shift.name),
          _ScopeRow(
            label: 'Area',
            value: '${shift.unitLabel} · Floor ${shift.floorNumber}',
          ),
          _ScopeRow(
            label: 'Window',
            value: formatHourMinuteRange(shift.startsAt, shift.endsAt),
          ),
          _ScopeRow(
            label: 'Handover',
            value: shift.handoverAcknowledged
                ? 'Acknowledged at ${formatHourMinute(shift.handoverAcknowledgedAt ?? shift.startsAt)}'
                : 'Pending acknowledgement',
          ),
          _ScopeRow(label: 'Doses due', value: medicationCount.toString()),
        ],
      ),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _MedicationRoundEmptyCard extends StatelessWidget {
  const _MedicationRoundEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Text(
        'No medication doses are due on this shift right now.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

class _MedicationRoundGroupCard extends StatelessWidget {
  const _MedicationRoundGroupCard({
    required this.group,
    required this.activeDoseId,
    required this.noteResidentId,
    required this.onAdminister,
    required this.onRefuse,
    required this.onOmit,
    required this.onDelay,
    required this.onNotAvailable,
    required this.onHold,
    required this.onAddNote,
  });

  final _DisplayedMedicationRoundGroup group;
  final String? activeDoseId;
  final String? noteResidentId;
  final ValueChanged<MedicationRoundItem> onAdminister;
  final ValueChanged<MedicationRoundItem> onRefuse;
  final ValueChanged<MedicationRoundItem> onOmit;
  final ValueChanged<MedicationRoundItem> onDelay;
  final ValueChanged<MedicationRoundItem> onNotAvailable;
  final ValueChanged<MedicationRoundItem> onHold;
  final ValueChanged<MedicationRoundItem> onAddNote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.heading,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryBlueDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${group.items.length} medication ${group.items.length == 1 ? 'entry' : 'entries'}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          ...group.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MedicationDoseCard(
                item: item,
                isSubmitting: activeDoseId == item.id,
                isSavingNote: noteResidentId == item.residentId,
                onAdminister: () => onAdminister(item),
                onRefuse: () => onRefuse(item),
                onOmit: () => onOmit(item),
                onDelay: () => onDelay(item),
                onNotAvailable: () => onNotAvailable(item),
                onHold: () => onHold(item),
                onAddNote: () => onAddNote(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationDoseCard extends StatelessWidget {
  const _MedicationDoseCard({
    required this.item,
    required this.isSubmitting,
    required this.isSavingNote,
    required this.onAdminister,
    required this.onRefuse,
    required this.onOmit,
    required this.onDelay,
    required this.onNotAvailable,
    required this.onHold,
    required this.onAddNote,
  });

  final MedicationRoundItem item;
  final bool isSubmitting;
  final bool isSavingNote;
  final VoidCallback onAdminister;
  final VoidCallback onRefuse;
  final VoidCallback onOmit;
  final VoidCallback onDelay;
  final VoidCallback onNotAvailable;
  final VoidCallback onHold;
  final VoidCallback onAddNote;

  bool get _isActionable =>
      item.status == MedicationDoseStatus.due ||
      item.status == MedicationDoseStatus.overdue;

  Color get _statusColor {
    switch (item.status) {
      case MedicationDoseStatus.administered:
        return AppTheme.successGreen;
      case MedicationDoseStatus.overdue:
      case MedicationDoseStatus.refused:
      case MedicationDoseStatus.omitted:
      case MedicationDoseStatus.notAvailable:
        return AppTheme.errorRed;
      case MedicationDoseStatus.delayed:
      case MedicationDoseStatus.held:
        return const Color(0xFF9A6700);
      case MedicationDoseStatus.cancelled:
        return AppTheme.textSecondary;
      case MedicationDoseStatus.due:
        return AppTheme.primaryBlueDark;
    }
  }

  Future<void> _openOutcomeActions(BuildContext context) async {
    final options = <({String label, IconData icon, VoidCallback onSelected})>[
      (label: 'Refuse', icon: Icons.block_outlined, onSelected: onRefuse),
      (
        label: 'Omit',
        icon: Icons.do_not_disturb_alt_outlined,
        onSelected: onOmit,
      ),
      (label: 'Delay', icon: Icons.schedule_rounded, onSelected: onDelay),
      (
        label: 'Not available',
        icon: Icons.inventory_2_outlined,
        onSelected: onNotAvailable,
      ),
      (
        label: 'Hold',
        icon: Icons.pause_circle_outline_rounded,
        onSelected: onHold,
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.82,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                20 + mediaQuery.viewPadding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Record outcome',
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(
                          color: AppTheme.primaryBlueDark,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.residentName} · ${item.roomLabel} · ${item.titleLine}',
                    style: Theme.of(sheetContext).textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ...options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            option.onSelected();
                          },
                          icon: Icon(option.icon),
                          label: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(option.label),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor.withAlpha(36)),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                      '${item.residentName} · ${item.roomLabel}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryBlueDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.titleLine,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.status.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DoseMetaPill(label: '${item.doseAmount} ${item.doseUnit}'),
              _DoseMetaPill(label: item.route),
              if (item.formulation != null &&
                  item.formulation!.trim().isNotEmpty)
                _DoseMetaPill(label: item.formulation!),
              if (item.requiresWitness)
                const _DoseMetaPill(
                  label: 'Witness required',
                  foreground: AppTheme.errorRed,
                  background: Color(0xFFFFEEEC),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Due ${formatHourMinuteRange(item.dueWindowStart, item.dueWindowEnd)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryBlueDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.instructions,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          if (item.allergies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withAlpha(10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.errorRed.withAlpha(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Allergy / intolerance warning',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...item.allergies.map(
                    (allergy) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${allergy['substance']}${allergy['reaction'] == null ? '' : ' · ${allergy['reaction']}'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (item.reason != null ||
              item.notes != null ||
              item.recordedAt != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.recordedAt != null)
                    Text(
                      'Recorded ${formatHourMinute(item.recordedAt!)}${item.recordedByUserName == null ? '' : ' by ${item.recordedByUserName}'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryBlueDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (item.reason != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Reason: ${item.reason}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (item.notes != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Notes: ${item.notes}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_isActionable)
                FilledButton.icon(
                  onPressed: isSubmitting ? null : onAdminister,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Administer'),
                ),
              if (_isActionable)
                OutlinedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () => _openOutcomeActions(context),
                  icon: const Icon(Icons.more_horiz_rounded),
                  label: const Text('Record outcome'),
                ),
              TextButton.icon(
                onPressed: isSavingNote ? null : onAddNote,
                icon: isSavingNote
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.note_add_outlined),
                label: const Text('Add note'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoseMetaPill extends StatelessWidget {
  const _DoseMetaPill({
    required this.label,
    this.foreground = AppTheme.primaryBlueDark,
    this.background = AppTheme.primaryBlueLight,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DisplayedMedicationRoundGroup {
  const _DisplayedMedicationRoundGroup({
    required this.heading,
    required this.sortAt,
    required this.items,
  });

  final String heading;
  final DateTime sortAt;
  final List<MedicationRoundItem> items;
}

List<_DisplayedMedicationRoundGroup> _buildDisplayedMedicationGroups(
  List<MedicationRoundGroup> groupedRounds,
) {
  final groupedItems = <String, List<MedicationRoundItem>>{};
  final headings = <String, String>{};
  final sortAt = <String, DateTime>{};

  for (final item in groupedRounds.expand((group) => group.items)) {
    final bucketLabel = _deriveMedicationBucketLabel(item.dueWindowStart);
    final heading =
        '$bucketLabel · ${formatHourMinuteRange(item.dueWindowStart, item.dueWindowEnd)}';
    final key =
        '$bucketLabel|${item.dueWindowStart.toIso8601String()}|${item.dueWindowEnd.toIso8601String()}';
    groupedItems.putIfAbsent(key, () => <MedicationRoundItem>[]).add(item);
    headings[key] = heading;
    sortAt[key] = item.dueWindowStart;
  }

  final result = groupedItems.entries
      .map(
        (entry) => _DisplayedMedicationRoundGroup(
          heading: headings[entry.key]!,
          sortAt: sortAt[entry.key]!,
          items: entry.value,
        ),
      )
      .toList();

  result.sort((left, right) => left.sortAt.compareTo(right.sortAt));
  return result;
}

String _displayMedicationWindowLabel(DateTime start, DateTime end) {
  return '${_deriveMedicationBucketLabel(start)} window ${formatHourMinuteRange(start, end)}';
}

String _deriveMedicationBucketLabel(DateTime dueWindowStart) {
  final hour = dueWindowStart.hour;

  if (hour >= 5 && hour < 11) {
    return 'Morning';
  }
  if (hour >= 11 && hour < 16) {
    return 'Midday';
  }
  if (hour >= 16 && hour < 20) {
    return 'Evening';
  }
  return 'Bedtime';
}
