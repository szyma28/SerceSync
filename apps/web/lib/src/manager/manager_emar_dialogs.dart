part of 'manager_emar.dart';

class _MedicationOrderEditorDialog extends StatefulWidget {
  const _MedicationOrderEditorDialog({this.order});

  final ManagerMedicationOrderRecord? order;

  @override
  State<_MedicationOrderEditorDialog> createState() =>
      _MedicationOrderEditorDialogState();
}

class _MedicationOrderEditorDialogState
    extends State<_MedicationOrderEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _formulationController;
  late final TextEditingController _strengthController;
  late final TextEditingController _doseAmountController;
  late final TextEditingController _doseUnitController;
  late final TextEditingController _routeController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _reasonController;
  String _sourceType = 'MANUAL_ENTRY';
  bool _isControlledDrug = false;
  bool _requiresWitness = false;
  bool _isPrn = false;
  bool _showValidation = false;

  bool get _isEditing => widget.order != null;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _nameController = TextEditingController(text: order?.medicationName ?? '');
    _formulationController = TextEditingController(
      text: order?.formulation ?? '',
    );
    _strengthController = TextEditingController(text: order?.strength ?? '');
    _doseAmountController = TextEditingController(
      text: order?.doseAmount ?? '',
    );
    _doseUnitController = TextEditingController(text: order?.doseUnit ?? '');
    _routeController = TextEditingController(text: order?.route ?? '');
    _instructionsController = TextEditingController(
      text: order?.instructions ?? '',
    );
    _startDateController = TextEditingController(
      text: _formatDateInput(order?.startDate ?? DateTime.now()),
    );
    _endDateController = TextEditingController(
      text: order?.endDate == null ? '' : _formatDateInput(order!.endDate!),
    );
    _reasonController = TextEditingController(
      text: order == null ? '' : 'Medication instructions reviewed',
    );
    _sourceType = order?.sourceType ?? 'MANUAL_ENTRY';
    _isControlledDrug = order?.isControlledDrug ?? false;
    _requiresWitness = order?.requiresWitness ?? false;
    _isPrn = order?.isPrn ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _formulationController.dispose();
    _strengthController.dispose();
    _doseAmountController.dispose();
    _doseUnitController.dispose();
    _routeController.dispose();
    _instructionsController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final hasCoreFields = [
      _nameController.text,
      _doseAmountController.text,
      _doseUnitController.text,
      _routeController.text,
      _instructionsController.text,
      _startDateController.text,
    ].every((value) => value.trim().isNotEmpty);
    final reasonRequired = _isEditing;
    final hasReason = _reasonController.text.trim().length >= 3;

    if (!hasCoreFields || (reasonRequired && !hasReason)) {
      setState(() => _showValidation = true);
      return;
    }

    Navigator.of(context).pop(
      ManagerMedicationOrderDraft(
        medicationName: _nameController.text.trim(),
        formulation: _formulationController.text.trim(),
        strength: _strengthController.text.trim(),
        doseAmount: _doseAmountController.text.trim(),
        doseUnit: _doseUnitController.text.trim(),
        route: _routeController.text.trim(),
        instructions: _instructionsController.text.trim(),
        startDateIso: _startDateController.text.trim(),
        endDateIso: _endDateController.text.trim().isEmpty
            ? null
            : _endDateController.text.trim(),
        isControlledDrug: _isControlledDrug,
        requiresWitness: _requiresWitness,
        isPrn: _isPrn,
        sourceType: _sourceType,
        changeReason: _isEditing ? null : _reasonController.text.trim(),
        reason: _isEditing ? _reasonController.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit medication order' : 'Add medication order',
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Medication name',
                  errorText:
                      _showValidation && _nameController.text.trim().isEmpty
                      ? 'Medication name is required.'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _formulationController,
                      decoration: const InputDecoration(
                        labelText: 'Formulation',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _strengthController,
                      decoration: const InputDecoration(labelText: 'Strength'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _doseAmountController,
                      decoration: InputDecoration(
                        labelText: 'Dose amount',
                        errorText:
                            _showValidation &&
                                _doseAmountController.text.trim().isEmpty
                            ? 'Dose amount is required.'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _doseUnitController,
                      decoration: InputDecoration(
                        labelText: 'Dose unit',
                        errorText:
                            _showValidation &&
                                _doseUnitController.text.trim().isEmpty
                            ? 'Dose unit is required.'
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _routeController,
                decoration: InputDecoration(
                  labelText: 'Route',
                  errorText:
                      _showValidation && _routeController.text.trim().isEmpty
                      ? 'Route is required.'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Instructions',
                  errorText:
                      _showValidation &&
                          _instructionsController.text.trim().isEmpty
                      ? 'Instructions are required.'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startDateController,
                      decoration: InputDecoration(
                        labelText: 'Start date (YYYY-MM-DD)',
                        errorText:
                            _showValidation &&
                                _startDateController.text.trim().isEmpty
                            ? 'Start date is required.'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _endDateController,
                      decoration: const InputDecoration(
                        labelText: 'End date (optional)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _sourceType,
                decoration: const InputDecoration(labelText: 'Source type'),
                items: const [
                  DropdownMenuItem(
                    value: 'MANUAL_ENTRY',
                    child: Text('Manual entry'),
                  ),
                  DropdownMenuItem(
                    value: 'PHARMACY_SUPPLIED',
                    child: Text('Pharmacy supplied'),
                  ),
                  DropdownMenuItem(value: 'IMPORTED', child: Text('Imported')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sourceType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _isPrn,
                onChanged: (value) => setState(() => _isPrn = value ?? false),
                title: const Text('PRN medication'),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _isControlledDrug,
                onChanged: (value) =>
                    setState(() => _isControlledDrug = value ?? false),
                title: const Text('Controlled drug'),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _requiresWitness,
                onChanged: (value) =>
                    setState(() => _requiresWitness = value ?? false),
                title: const Text('Witness confirmation required'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'Reason for update'
                      : 'Optional creation note',
                  errorText:
                      _showValidation &&
                          _isEditing &&
                          _reasonController.text.trim().length < 3
                      ? 'A reason is required when editing a medication order.'
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save changes' : 'Add medication'),
        ),
      ],
    );
  }
}

class _MedicationScheduleDialog extends StatefulWidget {
  const _MedicationScheduleDialog();

  @override
  State<_MedicationScheduleDialog> createState() =>
      _MedicationScheduleDialogState();
}

class _MedicationScheduleDialogState extends State<_MedicationScheduleDialog> {
  String _roundLabel = 'MORNING';
  String _anchorType = 'HANDOVER_ACKNOWLEDGED';
  final _windowStartController = TextEditingController(text: '0');
  final _windowEndController = TextEditingController(text: '60');
  final _fixedTimeController = TextEditingController();
  final _daysController = TextEditingController();
  bool _showValidation = false;

  @override
  void dispose() {
    _windowStartController.dispose();
    _windowEndController.dispose();
    _fixedTimeController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _submit() {
    final windowStart = int.tryParse(_windowStartController.text.trim());
    final windowEnd = int.tryParse(_windowEndController.text.trim());
    final needsFixedTime = _anchorType == 'FIXED_TIME';
    if (windowStart == null ||
        windowEnd == null ||
        (needsFixedTime && _fixedTimeController.text.trim().isEmpty)) {
      setState(() => _showValidation = true);
      return;
    }

    Navigator.of(context).pop(
      ManagerMedicationScheduleDraft(
        roundLabel: _roundLabel,
        anchorType: _anchorType,
        windowStartOffsetMinutes: windowStart,
        windowEndOffsetMinutes: windowEnd,
        fixedTimeLocal: _fixedTimeController.text.trim().isEmpty
            ? null
            : _fixedTimeController.text.trim(),
        daysOfWeek: _daysController.text.trim().isEmpty
            ? const []
            : _daysController.text
                  .split(',')
                  .map((entry) => entry.trim())
                  .where((entry) => entry.isNotEmpty)
                  .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add medication schedule'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _roundLabel,
                decoration: const InputDecoration(labelText: 'Round label'),
                items: const [
                  DropdownMenuItem(value: 'MORNING', child: Text('Morning')),
                  DropdownMenuItem(value: 'MIDDAY', child: Text('Midday')),
                  DropdownMenuItem(value: 'EVENING', child: Text('Evening')),
                  DropdownMenuItem(value: 'BEDTIME', child: Text('Bedtime')),
                  DropdownMenuItem(value: 'CUSTOM', child: Text('Custom')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _roundLabel = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _anchorType,
                decoration: const InputDecoration(labelText: 'Anchor type'),
                items: const [
                  DropdownMenuItem(
                    value: 'SHIFT_START',
                    child: Text('Shift start'),
                  ),
                  DropdownMenuItem(
                    value: 'HANDOVER_ACKNOWLEDGED',
                    child: Text('Handover acknowledged'),
                  ),
                  DropdownMenuItem(
                    value: 'FIXED_TIME',
                    child: Text('Fixed local time'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _anchorType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _windowStartController,
                      decoration: InputDecoration(
                        labelText: 'Window start offset',
                        errorText:
                            _showValidation &&
                                int.tryParse(
                                      _windowStartController.text.trim(),
                                    ) ==
                                    null
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _windowEndController,
                      decoration: InputDecoration(
                        labelText: 'Window end offset',
                        errorText:
                            _showValidation &&
                                int.tryParse(
                                      _windowEndController.text.trim(),
                                    ) ==
                                    null
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fixedTimeController,
                decoration: InputDecoration(
                  labelText: 'Fixed time (HH:MM)',
                  hintText: 'Required for fixed-time schedules',
                  errorText:
                      _showValidation &&
                          _anchorType == 'FIXED_TIME' &&
                          _fixedTimeController.text.trim().isEmpty
                      ? 'Fixed time is required.'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _daysController,
                decoration: const InputDecoration(
                  labelText: 'Days of week (comma separated)',
                  hintText: 'MONDAY,TUESDAY or leave empty for every day',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add schedule')),
      ],
    );
  }
}

class _PrnProtocolDialog extends StatefulWidget {
  const _PrnProtocolDialog({this.protocol});

  final ManagerPrnProtocolRecord? protocol;

  @override
  State<_PrnProtocolDialog> createState() => _PrnProtocolDialogState();
}

class _PrnProtocolDialogState extends State<_PrnProtocolDialog> {
  late final TextEditingController _indicationController;
  late final TextEditingController _whenToOfferController;
  late final TextEditingController _doseInstructionsController;
  late final TextEditingController _minimumIntervalController;
  late final TextEditingController _maxDoseController;
  late final TextEditingController _expectedEffectController;
  late final TextEditingController _monitoringController;
  late final TextEditingController _escalationController;
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    final protocol = widget.protocol;
    _indicationController = TextEditingController(
      text: protocol?.indication ?? '',
    );
    _whenToOfferController = TextEditingController(
      text: protocol?.whenToOffer ?? '',
    );
    _doseInstructionsController = TextEditingController(
      text: protocol?.doseInstructions ?? '',
    );
    _minimumIntervalController = TextEditingController(
      text: protocol?.minimumIntervalMinutes?.toString() ?? '',
    );
    _maxDoseController = TextEditingController(
      text: protocol?.maxDosePer24Hours?.toString() ?? '',
    );
    _expectedEffectController = TextEditingController(
      text: protocol?.expectedEffect ?? '',
    );
    _monitoringController = TextEditingController(
      text: protocol?.monitoringRequired ?? '',
    );
    _escalationController = TextEditingController(
      text: protocol?.whenToEscalate ?? '',
    );
  }

  @override
  void dispose() {
    _indicationController.dispose();
    _whenToOfferController.dispose();
    _doseInstructionsController.dispose();
    _minimumIntervalController.dispose();
    _maxDoseController.dispose();
    _expectedEffectController.dispose();
    _monitoringController.dispose();
    _escalationController.dispose();
    super.dispose();
  }

  void _submit() {
    final requiredFields = [
      _indicationController.text,
      _whenToOfferController.text,
      _doseInstructionsController.text,
    ];
    if (requiredFields.any((value) => value.trim().isEmpty)) {
      setState(() => _showValidation = true);
      return;
    }

    Navigator.of(context).pop(
      ManagerPrnProtocolDraft(
        indication: _indicationController.text.trim(),
        whenToOffer: _whenToOfferController.text.trim(),
        doseInstructions: _doseInstructionsController.text.trim(),
        minimumIntervalMinutes: int.tryParse(
          _minimumIntervalController.text.trim(),
        ),
        maxDosePer24Hours: int.tryParse(_maxDoseController.text.trim()),
        expectedEffect: _expectedEffectController.text.trim(),
        monitoringRequired: _monitoringController.text.trim(),
        whenToEscalate: _escalationController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.protocol == null ? 'Add PRN protocol' : 'Replace PRN protocol',
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _indicationController,
                decoration: InputDecoration(
                  labelText: 'Indication',
                  errorText:
                      _showValidation &&
                          _indicationController.text.trim().isEmpty
                      ? 'Indication is required.'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _whenToOfferController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'When to offer',
                  errorText:
                      _showValidation &&
                          _whenToOfferController.text.trim().isEmpty
                      ? 'When to offer is required.'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _doseInstructionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Dose instructions',
                  errorText:
                      _showValidation &&
                          _doseInstructionsController.text.trim().isEmpty
                      ? 'Dose instructions are required.'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minimumIntervalController,
                      decoration: const InputDecoration(
                        labelText: 'Minimum interval (mins)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxDoseController,
                      decoration: const InputDecoration(
                        labelText: 'Max dose per 24h',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _expectedEffectController,
                decoration: const InputDecoration(labelText: 'Expected effect'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _monitoringController,
                decoration: const InputDecoration(
                  labelText: 'Monitoring required',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _escalationController,
                decoration: const InputDecoration(
                  labelText: 'When to escalate',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save protocol')),
      ],
    );
  }
}

class _MedicationAllergyDialog extends StatefulWidget {
  const _MedicationAllergyDialog();

  @override
  State<_MedicationAllergyDialog> createState() =>
      _MedicationAllergyDialogState();
}

class _MedicationAllergyDialogState extends State<_MedicationAllergyDialog> {
  final _substanceController = TextEditingController();
  final _reactionController = TextEditingController();
  final _severityController = TextEditingController();
  bool _showValidation = false;

  @override
  void dispose() {
    _substanceController.dispose();
    _reactionController.dispose();
    _severityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_substanceController.text.trim().isEmpty) {
      setState(() => _showValidation = true);
      return;
    }

    Navigator.of(context).pop(
      ManagerMedicationAllergyDraft(
        substance: _substanceController.text.trim(),
        reaction: _reactionController.text.trim(),
        severity: _severityController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record allergy or intolerance'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _substanceController,
              decoration: InputDecoration(
                labelText: 'Substance',
                errorText:
                    _showValidation && _substanceController.text.trim().isEmpty
                    ? 'Substance is required.'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reactionController,
              decoration: const InputDecoration(labelText: 'Reaction'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _severityController,
              decoration: const InputDecoration(labelText: 'Severity'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Record allergy')),
      ],
    );
  }
}

class _MedicationStockTransactionDialog extends StatefulWidget {
  const _MedicationStockTransactionDialog({required this.order});

  final ManagerMedicationOrderRecord order;

  @override
  State<_MedicationStockTransactionDialog> createState() =>
      _MedicationStockTransactionDialogState();
}

class _MedicationStockTransactionDialogState
    extends State<_MedicationStockTransactionDialog> {
  late final TextEditingController _quantityController;
  late final TextEditingController _quantityUnitController;
  late final TextEditingController _reasonController;
  late final TextEditingController _witnessUserIdController;
  String _transactionType = 'ADJUSTED';
  bool _showValidation = false;

  bool get _isAdjustment => _transactionType == 'ADJUSTED';

  String get _currentRecordedBalance {
    final stock = widget.order.stock;
    if (stock == null) {
      return 'No previous balance recorded.';
    }
    return 'Current recorded balance: ${stock.currentQuantity} ${stock.quantityUnit}.';
  }

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.order.stock?.currentQuantity ?? '',
    );
    _quantityUnitController = TextEditingController(
      text: (widget.order.stock?.quantityUnit ?? '').trim().isEmpty
          ? widget.order.doseUnit
          : widget.order.stock!.quantityUnit,
    );
    _reasonController = TextEditingController();
    _witnessUserIdController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityUnitController.dispose();
    _reasonController.dispose();
    _witnessUserIdController.dispose();
    super.dispose();
  }

  void _handleTransactionTypeChanged(String value) {
    final currentBalance = widget.order.stock?.currentQuantity ?? '';
    final switchingToAdjustment = value == 'ADJUSTED';
    final switchingFromAdjustment = _transactionType == 'ADJUSTED';

    if (switchingFromAdjustment && !switchingToAdjustment) {
      if (_quantityController.text.trim() == currentBalance) {
        _quantityController.clear();
      }
    } else if (switchingToAdjustment &&
        _quantityController.text.trim().isEmpty &&
        currentBalance.isNotEmpty) {
      _quantityController.text = currentBalance;
    }

    setState(() => _transactionType = value);
  }

  void _submit() {
    final hasCoreFields =
        _quantityController.text.trim().isNotEmpty &&
        _quantityUnitController.text.trim().isNotEmpty;
    final requiresWitness = widget.order.requiresWitness;
    final hasWitness = _witnessUserIdController.text.trim().isNotEmpty;
    if (!hasCoreFields || (requiresWitness && !hasWitness)) {
      setState(() => _showValidation = true);
      return;
    }

    Navigator.of(context).pop(
      ManagerMedicationStockTransactionDraft(
        transactionType: _transactionType,
        quantity: _quantityController.text.trim(),
        quantityUnit: _quantityUnitController.text.trim(),
        witnessUserId: _witnessUserIdController.text.trim().isEmpty
            ? null
            : _witnessUserIdController.text.trim(),
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return AlertDialog(
      title: Text('Record stock update for ${order.medicationName}'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAdjustment
                    ? 'Record the current on-hand balance for this medication line.'
                    : 'Record the stock movement and transaction type for this medication line.',
                style: const TextStyle(color: managerMuted, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: managerBorder),
                ),
                child: Text(
                  _isAdjustment
                      ? order.stock == null
                            ? 'No previous balance recorded. Enter the opening or current balance below.'
                            : '$_currentRecordedBalance Saving here updates the recorded balance and logs the selected stock transaction type.'
                      : order.stock == null
                      ? 'No previous balance recorded. Enter the quantity moved for this transaction and the system will create the opening stock record from that entry.'
                      : '$_currentRecordedBalance Enter the quantity moved for this transaction and the system will update the running balance automatically.',
                  style: const TextStyle(color: managerMuted, height: 1.5),
                ),
              ),
              if (order.requiresWitness) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: managerCriticalSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: managerCriticalSoft),
                  ),
                  child: const Text(
                    'This medication requires witness confirmation for stock entries. Enter the witness user ID before saving.',
                    style: TextStyle(
                      color: managerCritical,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _transactionType,
                decoration: const InputDecoration(
                  labelText: 'Transaction type',
                ),
                items: const [
                  DropdownMenuItem(value: 'ADJUSTED', child: Text('Adjusted')),
                  DropdownMenuItem(value: 'RECEIVED', child: Text('Received')),
                  DropdownMenuItem(value: 'RETURNED', child: Text('Returned')),
                  DropdownMenuItem(value: 'DISPOSED', child: Text('Disposed')),
                  DropdownMenuItem(
                    value: 'ADMINISTERED',
                    child: Text('Administered'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _handleTransactionTypeChanged(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: _isAdjustment
                            ? 'On-hand balance quantity'
                            : 'Transaction quantity',
                        helperText: _isAdjustment
                            ? 'Enter the quantity that should remain on hand after reconciliation.'
                            : 'Enter the quantity being received, returned, disposed, or administered.',
                        errorText:
                            _showValidation &&
                                _quantityController.text.trim().isEmpty
                            ? 'Quantity is required.'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _quantityUnitController,
                      decoration: InputDecoration(
                        labelText: 'Quantity unit',
                        errorText:
                            _showValidation &&
                                _quantityUnitController.text.trim().isEmpty
                            ? 'Quantity unit is required.'
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason or stock note (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _witnessUserIdController,
                decoration: InputDecoration(
                  labelText: order.requiresWitness
                      ? 'Witness user ID'
                      : 'Witness user ID (optional)',
                  helperText: order.requiresWitness
                      ? 'Required because this medication line needs witness confirmation.'
                      : 'Only needed when a witness should be attached to this stock transaction.',
                  errorText:
                      _showValidation &&
                          order.requiresWitness &&
                          _witnessUserIdController.text.trim().isEmpty
                      ? 'Witness user ID is required.'
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _transactionType == 'ADMINISTERED'
                    ? 'Use administered sparingly here. Normal medication administrations already create stock history automatically.'
                    : 'Select the transaction type that best explains why the recorded balance changed.',
                style: const TextStyle(color: managerMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            order.stock == null
                ? 'Record opening balance'
                : 'Save stock update',
          ),
        ),
      ],
    );
  }
}

class _MedicationReasonDialog extends StatefulWidget {
  const _MedicationReasonDialog({
    required this.title,
    required this.prompt,
    required this.confirmLabel,
  });

  final String title;
  final String prompt;
  final String confirmLabel;

  @override
  State<_MedicationReasonDialog> createState() =>
      _MedicationReasonDialogState();
}

class _MedicationReasonDialogState extends State<_MedicationReasonDialog> {
  final _reasonController = TextEditingController();
  bool _showValidation = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_reasonController.text.trim().length < 3) {
      setState(() => _showValidation = true);
      return;
    }

    Navigator.of(context).pop(_reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.prompt, style: const TextStyle(color: managerMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason',
                errorText: _showValidation ? 'A reason is required.' : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

String _formatDateInput(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _formatMedicationChangeType(String value) {
  switch (value) {
    case 'SCHEDULE_CHANGED':
      return 'Schedule changed';
    case 'PRN_PROTOCOL_CHANGED':
      return 'PRN protocol changed';
    case 'DEACTIVATED':
      return 'Deactivated';
    case 'REACTIVATED':
      return 'Reactivated';
    case 'UPDATED':
      return 'Updated';
    case 'CREATED':
    default:
      return 'Created';
  }
}
