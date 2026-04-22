part of '../resident_detail_screen.dart';

class _ResidentMedicationSection extends StatelessWidget {
  const _ResidentMedicationSection({
    required this.profile,
    required this.isLoading,
    required this.errorMessage,
    required this.canRecordMedicationAdministration,
    required this.handoverAcknowledged,
    required this.onOpenMedicationRound,
    required this.onRecordPrnEvent,
  });

  final ResidentEmarProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final bool canRecordMedicationAdministration;
  final bool handoverAcknowledged;
  final VoidCallback? onOpenMedicationRound;
  final VoidCallback? onRecordPrnEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(224),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medication',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Review medication context here, then use the shift medication round for scheduled doses and dose outcomes.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
            )
          else if (errorMessage != null)
            Text(
              errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (profile == null)
            Text(
              'Medication details are not available right now.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            )
          else ...[
            if (profile!.allergies.isNotEmpty)
              _ResidentAllergySection(allergies: profile!.allergies),
            if (profile!.allergies.isNotEmpty) const SizedBox(height: 16),
            _MedicationSubsection(
              title: 'Scheduled medication',
              description:
                  'Scheduled doses stay in the shift medication round so timing, acknowledgement, and outcomes are recorded in one place.',
              action: canRecordMedicationAdministration
                  ? _MedicationRoundWorkflowCard(
                      handoverAcknowledged: handoverAcknowledged,
                      onOpenMedicationRound: handoverAcknowledged
                          ? onOpenMedicationRound
                          : null,
                    )
                  : null,
              emptyLabel: 'No scheduled medication is active.',
              children: profile!.scheduledMedications
                  .map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ResidentMedicationOrderCard(
                        order: order,
                        recentEvents: profile!.recentEvents,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            _MedicationSubsection(
              title: 'PRN medication',
              description:
                  'Record as-needed medication here when it has already been prescribed for this resident.',
              action: canRecordMedicationAdministration
                  ? _ResidentPrnActionCard(
                      handoverAcknowledged: handoverAcknowledged,
                      onRecordPrnEvent: handoverAcknowledged
                          ? onRecordPrnEvent
                          : null,
                    )
                  : null,
              emptyLabel: 'No PRN medication is active.',
              children: profile!.prnMedications
                  .map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ResidentMedicationOrderCard(
                        order: order,
                        recentEvents: profile!.recentEvents,
                        emphasisePrn: true,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            _ResidentMedicationEventsSection(events: profile!.recentEvents),
          ],
        ],
      ),
    );
  }
}

String _residentMedicationRoundLabel(String value) {
  switch (value) {
    case 'MIDDAY':
      return 'Midday';
    case 'EVENING':
      return 'Evening';
    case 'BEDTIME':
      return 'Bedtime';
    case 'CUSTOM':
      return 'Custom';
    case 'MORNING':
    default:
      return 'Morning';
  }
}

String _residentMedicationLabel(String value) {
  return value
      .toLowerCase()
      .split('_')
      .where((segment) => segment.isNotEmpty)
      .map(
        (segment) =>
            '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
      )
      .join(' ');
}

class _MedicationSubsection extends StatelessWidget {
  const _MedicationSubsection({
    required this.title,
    this.description,
    this.action,
    required this.emptyLabel,
    required this.children,
  });

  final String title;
  final String? description;
  final Widget? action;
  final String emptyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryBlueDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 6),
          Text(
            description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 12), action!],
        const SizedBox(height: 12),
        if (children.isEmpty)
          Text(
            emptyLabel,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          )
        else
          ...children,
      ],
    );
  }
}

class _MedicationRoundWorkflowCard extends StatelessWidget {
  const _MedicationRoundWorkflowCard({
    required this.handoverAcknowledged,
    required this.onOpenMedicationRound,
  });

  final bool handoverAcknowledged;
  final VoidCallback? onOpenMedicationRound;

  @override
  Widget build(BuildContext context) {
    final accentColor = handoverAcknowledged
        ? AppTheme.primaryBlueDark
        : const Color(0xFF9A6700);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withAlpha(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_liquid_outlined, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  handoverAcknowledged
                      ? 'Shift medication round ready'
                      : 'Handover acknowledgement needed',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            handoverAcknowledged
                ? 'Open the shift medication round to administer scheduled doses, refusals, delays, and omissions across the active shift.'
                : 'Acknowledge the current handover before opening the shift medication round or recording medication administration.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpenMedicationRound,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open shift medication round'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResidentPrnActionCard extends StatelessWidget {
  const _ResidentPrnActionCard({
    required this.handoverAcknowledged,
    required this.onRecordPrnEvent,
  });

  final bool handoverAcknowledged;
  final VoidCallback? onRecordPrnEvent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onRecordPrnEvent,
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Record PRN event'),
          ),
        ),
        if (!handoverAcknowledged) ...[
          const SizedBox(height: 8),
          Text(
            'PRN recording becomes available after the current handover is acknowledged.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF9A6700),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _ResidentAllergySection extends StatelessWidget {
  const _ResidentAllergySection({required this.allergies});

  final List<MedicationAllergyRecord> allergies;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withAlpha(10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.errorRed.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Allergies and intolerances',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.errorRed,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...allergies.map(
            (allergy) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${allergy.substance}${allergy.reaction == null ? '' : ' · ${allergy.reaction}'}${allergy.severity == null ? '' : ' · ${allergy.severity}'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResidentMedicationOrderCard extends StatelessWidget {
  const _ResidentMedicationOrderCard({
    required this.order,
    required this.recentEvents,
    this.emphasisePrn = false,
  });

  final MedicationOrderRecord order;
  final List<MedicationAdministrationRecord> recentEvents;
  final bool emphasisePrn;

  MedicationAdministrationRecord? get _latestMatchingEvent {
    for (final event in recentEvents) {
      if (event.medicationOrderId == order.id) {
        return event;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final latestEvent = _latestMatchingEvent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emphasisePrn
            ? AppTheme.primaryBlueLight.withAlpha(56)
            : AppTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: emphasisePrn
              ? AppTheme.primaryBlue.withAlpha(48)
              : AppTheme.borderLight,
        ),
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
                      order.titleLine,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${order.doseAmount} ${order.doseUnit} · ${order.route}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryBlueDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (order.requiresWitness)
                const _MedicationPill(
                  label: 'Witness',
                  foreground: AppTheme.errorRed,
                  background: Color(0xFFFFEEEC),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.instructions,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (order.formulation != null &&
                  order.formulation!.trim().isNotEmpty)
                _MedicationPill(label: order.formulation!),
              _MedicationPill(
                label: _residentMedicationLabel(order.sourceType),
              ),
              if (!order.isPRN)
                ...order.schedules.map(
                  (schedule) => _MedicationPill(
                    label:
                        '${_residentMedicationRoundLabel(schedule.roundLabel)} · ${_residentMedicationLabel(schedule.anchorType)}',
                    foreground: AppTheme.primaryBlueDark,
                    background: AppTheme.primaryBlueLight,
                  ),
                ),
            ],
          ),
          if (order.prnProtocol != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(180),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRN protocol',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryBlueDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Indication: ${order.prnProtocol!.indication}'),
                  const SizedBox(height: 4),
                  Text('When to offer: ${order.prnProtocol!.whenToOffer}'),
                  const SizedBox(height: 4),
                  Text(
                    'Dose instructions: ${order.prnProtocol!.doseInstructions}',
                  ),
                  if (order.prnProtocol!.minimumIntervalMinutes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Minimum interval: ${order.prnProtocol!.minimumIntervalMinutes} minutes',
                    ),
                  ],
                  if (latestEvent != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last PRN record: ${latestEvent.eventType.label} at ${formatHourMinute(latestEvent.recordedAt)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryBlueDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (latestEvent != null) ...[
            const SizedBox(height: 10),
            Text(
              'Most recent event: ${latestEvent.eventType.label} at ${formatHourMinute(latestEvent.recordedAt)}${latestEvent.reason == null ? '' : ' · ${latestEvent.reason}'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResidentMedicationEventsSection extends StatelessWidget {
  const _ResidentMedicationEventsSection({required this.events});

  final List<MedicationAdministrationRecord> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent medication events',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryBlueDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          Text(
            'No medication events have been recorded yet.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          )
        else
          ...events
              .take(6)
              .map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatHourMinute(event.recordedAt)} · ${event.medicationName}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.primaryBlueDark,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.eventType.label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (event.reason != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.reason!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _MedicationPill extends StatelessWidget {
  const _MedicationPill({
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

class _PrnEventDraft {
  const _PrnEventDraft({
    required this.medicationOrderId,
    required this.eventType,
    required this.reason,
    this.doseGiven,
    this.doseUnit,
    this.notes,
    this.witnessUserId,
  });

  final String medicationOrderId;
  final MedicationAdministrationEventType eventType;
  final String reason;
  final String? doseGiven;
  final String? doseUnit;
  final String? notes;
  final String? witnessUserId;
}

class _RecordPrnEventSheet extends StatefulWidget {
  const _RecordPrnEventSheet({
    required this.prnMedications,
    required this.recentEvents,
    required this.witnessCandidates,
  });

  final List<MedicationOrderRecord> prnMedications;
  final List<MedicationAdministrationRecord> recentEvents;
  final List<MedicationRoundWitnessCandidate> witnessCandidates;

  @override
  State<_RecordPrnEventSheet> createState() => _RecordPrnEventSheetState();
}

class _RecordPrnEventSheetState extends State<_RecordPrnEventSheet> {
  late MedicationOrderRecord _selectedMedication;
  MedicationAdministrationEventType _eventType =
      MedicationAdministrationEventType.prnAdministered;
  late final TextEditingController _reasonController;
  late final TextEditingController _doseGivenController;
  late final TextEditingController _doseUnitController;
  late final TextEditingController _notesController;
  String? _selectedWitnessUserId;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _selectedMedication = widget.prnMedications.first;
    _reasonController = TextEditingController();
    _doseGivenController = TextEditingController(
      text: _selectedMedication.doseAmount,
    );
    _doseUnitController = TextEditingController(
      text: _selectedMedication.doseUnit,
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _doseGivenController.dispose();
    _doseUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateSelectedMedication(String medicationOrderId) {
    final nextMedication = widget.prnMedications.firstWhere(
      (order) => order.id == medicationOrderId,
    );
    setState(() {
      _selectedMedication = nextMedication;
      _doseGivenController.text = nextMedication.doseAmount;
      _doseUnitController.text = nextMedication.doseUnit;
      _selectedWitnessUserId = null;
    });
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.length < 3) {
      setState(() => _showValidation = true);
      return;
    }
    if (_selectedMedication.requiresWitness &&
        (_selectedWitnessUserId == null || _selectedWitnessUserId!.isEmpty)) {
      setState(() => _showValidation = true);
      return;
    }

    Navigator.of(context).pop(
      _PrnEventDraft(
        medicationOrderId: _selectedMedication.id,
        eventType: _eventType,
        reason: reason,
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

  Widget _buildProtocolCallout(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
    Color background = AppTheme.surfaceBackground,
    Color tone = AppTheme.primaryBlueDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tone),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProtocolLine(
    BuildContext context, {
    required String label,
    required String value,
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryBlueDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: emphasize
                    ? AppTheme.primaryBlueDark
                    : AppTheme.textSecondary,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolPanel(
    BuildContext context,
    MedicationAdministrationRecord? latestEvent,
  ) {
    final protocol = _selectedMedication.prnProtocol;
    final afterGivingTitle =
        _eventType == MedicationAdministrationEventType.prnAdministered
        ? 'After giving'
        : 'If you administer now';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            protocol == null
                ? 'PRN protocol not recorded yet.'
                : 'PRN protocol',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryBlueDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            protocol == null
                ? 'Pause and confirm the prescribed PRN instructions with the MAR or nurse in charge before recording an administration.'
                : 'Use this guidance at the bedside before you record the event.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          if (protocol != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (protocol.minimumIntervalMinutes != null)
                  _MedicationPill(
                    label: 'Min ${protocol.minimumIntervalMinutes} min apart',
                    foreground: AppTheme.warningYellow,
                    background: AppTheme.warningYellow.withAlpha(18),
                  ),
                if (protocol.maxDosePer24Hours != null)
                  _MedicationPill(
                    label: 'Max ${protocol.maxDosePer24Hours} doses / 24h',
                    foreground: AppTheme.primaryBlueDark,
                    background: AppTheme.primaryBlueLight.withAlpha(80),
                  ),
                if (_selectedMedication.requiresWitness)
                  _MedicationPill(
                    label: 'Witness required',
                    foreground: AppTheme.errorRed,
                    background: AppTheme.errorRed.withAlpha(12),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProtocolCallout(
              context,
              icon: Icons.fact_check_outlined,
              title: 'Before giving',
              background: AppTheme.primaryBlueLight.withAlpha(56),
              children: [
                _buildProtocolLine(
                  context,
                  label: 'Indication',
                  value: protocol.indication,
                  emphasize: true,
                ),
                _buildProtocolLine(
                  context,
                  label: 'When to offer',
                  value: protocol.whenToOffer,
                ),
                _buildProtocolLine(
                  context,
                  label: 'Dose instructions',
                  value: protocol.doseInstructions,
                ),
                if (protocol.minimumIntervalMinutes != null)
                  _buildProtocolLine(
                    context,
                    label: 'Minimum interval',
                    value:
                        '${protocol.minimumIntervalMinutes} minutes between doses',
                  ),
                if (protocol.maxDosePer24Hours != null)
                  _buildProtocolLine(
                    context,
                    label: '24-hour limit',
                    value:
                        'Do not exceed ${protocol.maxDosePer24Hours} recorded doses in 24 hours without review',
                    emphasize: true,
                  ),
                if (_selectedMedication.requiresWitness)
                  _buildProtocolLine(
                    context,
                    label: 'Witness',
                    value:
                        'A witness must be present and recorded for this PRN event',
                    emphasize: true,
                  ),
              ],
            ),
            if (protocol.expectedEffect != null ||
                protocol.monitoringRequired != null) ...[
              const SizedBox(height: 10),
              _buildProtocolCallout(
                context,
                icon: Icons.visibility_outlined,
                title: afterGivingTitle,
                background: AppTheme.successGreen.withAlpha(10),
                tone: AppTheme.successGreen,
                children: [
                  if (protocol.expectedEffect != null)
                    _buildProtocolLine(
                      context,
                      label: 'Expected effect',
                      value: protocol.expectedEffect!,
                    ),
                  if (protocol.monitoringRequired != null)
                    _buildProtocolLine(
                      context,
                      label: 'Monitoring required',
                      value: protocol.monitoringRequired!,
                      emphasize: true,
                    ),
                  Text(
                    'Use Notes to document the resident response, monitoring completed, or any concern after this PRN event.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ],
            if (protocol.whenToEscalate != null) ...[
              const SizedBox(height: 10),
              _buildProtocolCallout(
                context,
                icon: Icons.warning_amber_rounded,
                title: 'Escalate',
                background: AppTheme.warningYellow.withAlpha(16),
                tone: AppTheme.warningYellow,
                children: [
                  _buildProtocolLine(
                    context,
                    label: 'Escalate when',
                    value: protocol.whenToEscalate!,
                    emphasize: true,
                  ),
                ],
              ),
            ],
          ],
          if (latestEvent != null) ...[
            const SizedBox(height: 10),
            Text(
              'Last recorded PRN: ${latestEvent.eventType.label} at ${formatHourMinute(latestEvent.recordedAt)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryBlueDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    MedicationAdministrationRecord? latestEvent;
    for (final event in widget.recentEvents) {
      if (event.medicationOrderId == _selectedMedication.id) {
        latestEvent = event;
        break;
      }
    }

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
                Text(
                  'Record PRN event',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _eventType ==
                          MedicationAdministrationEventType.prnAdministered
                      ? 'Confirm the symptom matches the protocol below, then record the dose and any observed response.'
                      : 'Use the protocol below to decide whether this PRN should be offered, withheld, or escalated.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF9A6700),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('prn-medication-${_selectedMedication.id}'),
                  initialValue: _selectedMedication.id,
                  decoration: const InputDecoration(
                    labelText: 'PRN medication',
                  ),
                  items: widget.prnMedications
                      .map(
                        (order) => DropdownMenuItem<String>(
                          value: order.id,
                          child: Text(order.titleLine),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      _updateSelectedMedication(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MedicationAdministrationEventType>(
                  key: ValueKey('prn-event-${_eventType.apiValue}'),
                  initialValue: _eventType,
                  decoration: const InputDecoration(labelText: 'PRN outcome'),
                  items: const [
                    DropdownMenuItem(
                      value: MedicationAdministrationEventType.prnOffered,
                      child: Text('Offered'),
                    ),
                    DropdownMenuItem(
                      value: MedicationAdministrationEventType.prnAdministered,
                      child: Text('Administered'),
                    ),
                    DropdownMenuItem(
                      value: MedicationAdministrationEventType.prnRefused,
                      child: Text('Refused'),
                    ),
                    DropdownMenuItem(
                      value: MedicationAdministrationEventType.prnNotGiven,
                      child: Text('Not given'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _eventType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Reason / symptom',
                    hintText: 'Document why the PRN was offered or given.',
                    errorText:
                        _showValidation &&
                            _reasonController.text.trim().length < 3
                        ? 'Reason or symptom is required.'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _doseGivenController,
                  decoration: const InputDecoration(labelText: 'Dose given'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _doseUnitController,
                  decoration: const InputDecoration(labelText: 'Dose unit'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    hintText:
                        _eventType ==
                            MedicationAdministrationEventType.prnAdministered
                        ? 'Record observed effect, monitoring completed, or any concerns.'
                        : 'Optional note for this PRN record.',
                  ),
                ),
                if (_selectedMedication.requiresWitness) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'prn-witness-${_selectedWitnessUserId ?? 'none'}',
                    ),
                    initialValue: _selectedWitnessUserId,
                    decoration: InputDecoration(
                      labelText: 'Witness',
                      helperText: widget.witnessCandidates.isEmpty
                          ? 'Witnesses come from the current shift medication round. None are available right now.'
                          : 'Select a witness from the current shift medication round.',
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
                    onChanged: widget.witnessCandidates.isEmpty
                        ? null
                        : (value) {
                            setState(() => _selectedWitnessUserId = value);
                          },
                  ),
                ],
                const SizedBox(height: 16),
                _buildProtocolPanel(context, latestEvent),
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
                        icon: const Icon(Icons.medication_outlined),
                        label: const Text('Record PRN'),
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
