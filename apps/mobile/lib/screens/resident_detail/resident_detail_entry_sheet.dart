part of '../resident_detail_screen.dart';

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet({
    this.initialType,
    required this.currentUserRole,
    required this.onPickEvidence,
  });

  final ResidentEntryType? initialType;
  final AppUserRole currentUserRole;
  final Future<TimelineEvidenceFile?> Function() onPickEvidence;

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  late ResidentEntryType _selectedType;
  PersonalCareSubtype? _selectedPersonalCareSubtype;
  MealType? _selectedMealType;
  MealIntakeAmount? _selectedMealIntakeAmount;
  final _detailsController = TextEditingController();
  TimelineEvidenceFile? _evidence;
  bool _isPickingEvidence = false;
  String? _validationMessage;

  bool get _hasStructuredMealLog =>
      _selectedMealType != null && _selectedMealIntakeAmount != null;

  bool get _hasPartialMealLog =>
      (_selectedMealType == null) != (_selectedMealIntakeAmount == null);

  List<ResidentEntryType> get _availableEntryTypes {
    if (widget.currentUserRole == AppUserRole.nurse) {
      return residentEntryTypesForNewNotes;
    }

    return residentEntryTypesForNewNotes
        .where((type) => type != ResidentEntryType.medicationNote)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedType =
        widget.initialType != null &&
            _availableEntryTypes.contains(widget.initialType)
        ? widget.initialType!
        : _availableEntryTypes.first;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() {
    final details = _detailsController.text.trim();
    if (_selectedType == ResidentEntryType.personalCare &&
        _selectedPersonalCareSubtype == null) {
      setState(() {
        _validationMessage =
            'Choose the personal care subtype before saving this note.';
      });
      return;
    }

    if (_selectedType == ResidentEntryType.nutritionHydration &&
        _hasPartialMealLog) {
      setState(() {
        _validationMessage =
            'Choose both meal type and amount eaten, or leave both blank.';
      });
      return;
    }

    if (details.isEmpty && !_hasStructuredMealLog) {
      setState(() {
        _validationMessage =
            _selectedType == ResidentEntryType.nutritionHydration
            ? 'Add a note or record the meal type and amount eaten before saving.'
            : 'Add a note before saving.';
      });
      return;
    }

    Navigator.of(context).pop(
      ResidentTimelineEntryDraft(
        type: _selectedType,
        details: details,
        personalCareSubtype: _selectedPersonalCareSubtype,
        mealType: _selectedMealType,
        mealIntakeAmount: _selectedMealIntakeAmount,
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

  DropdownButtonFormField<T> _buildEnumDropdown<T>({
    required T? value,
    required List<T> options,
    required String labelText,
    required String Function(T option) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option,
              child: Text(labelBuilder(option)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: labelText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ResidentSheetScaffold(
      title: 'Add note',
      children: [
        _buildEnumDropdown<ResidentEntryType>(
          value: _selectedType,
          options: _availableEntryTypes,
          labelText: 'Note type',
          labelBuilder: (type) => type.label,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedType = value;
              _validationMessage = null;
              if (value != ResidentEntryType.personalCare) {
                _selectedPersonalCareSubtype = null;
              }
              if (value != ResidentEntryType.nutritionHydration) {
                _selectedMealType = null;
                _selectedMealIntakeAmount = null;
              }
            });
          },
        ),
        if (_selectedType == ResidentEntryType.personalCare) ...[
          const SizedBox(height: 16),
          _buildEnumDropdown<PersonalCareSubtype>(
            value: _selectedPersonalCareSubtype,
            options: PersonalCareSubtype.values,
            labelText: 'Personal care subtype',
            labelBuilder: (subtype) => subtype.label,
            onChanged: (value) {
              setState(() {
                _selectedPersonalCareSubtype = value;
                _validationMessage = null;
              });
            },
          ),
        ],
        if (_selectedType == ResidentEntryType.nutritionHydration) ...[
          const SizedBox(height: 16),
          _buildEnumDropdown<MealType>(
            value: _selectedMealType,
            options: MealType.values,
            labelText: 'Meal type',
            labelBuilder: (mealType) => mealType.label,
            onChanged: (value) {
              setState(() {
                _selectedMealType = value;
                _validationMessage = null;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildEnumDropdown<MealIntakeAmount>(
            value: _selectedMealIntakeAmount,
            options: MealIntakeAmount.values,
            labelText: 'Amount eaten',
            labelBuilder: (amount) => amount.label,
            onChanged: (value) {
              setState(() {
                _selectedMealIntakeAmount = value;
                _validationMessage = null;
              });
            },
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _detailsController,
          maxLines: 5,
          onChanged: (_) {
            if (_validationMessage != null) {
              setState(() => _validationMessage = null);
            }
          },
          decoration: InputDecoration(
            labelText: _selectedType == ResidentEntryType.nutritionHydration
                ? 'Note or concern'
                : 'Note',
            helperText: _selectedType == ResidentEntryType.nutritionHydration
                ? 'Optional when meal type and amount eaten are recorded.'
                : null,
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
          _EvidencePreviewCard(evidence: _evidence!),
        ],
        if (_validationMessage != null) ...[
          const SizedBox(height: 14),
          Text(
            _validationMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.errorRed,
              fontWeight: FontWeight.w700,
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
    );
  }
}
