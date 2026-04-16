part of '../resident_detail_screen.dart';

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet({this.initialType, required this.onPickEvidence});

  final ResidentEntryType? initialType;
  final Future<TimelineEvidenceFile?> Function() onPickEvidence;

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  late ResidentEntryType _selectedType;
  PersonalCareSubtype? _selectedPersonalCareSubtype;
  final _detailsController = TextEditingController();
  TimelineEvidenceFile? _evidence;
  bool _isPickingEvidence = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _selectedType =
        widget.initialType != null &&
            residentEntryTypesForNewNotes.contains(widget.initialType)
        ? widget.initialType!
        : ResidentEntryType.personalCare;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() {
    final details = _detailsController.text.trim();
    if (details.isEmpty) {
      setState(() => _validationMessage = 'Add a note before saving.');
      return;
    }

    if (_selectedType == ResidentEntryType.personalCare &&
        _selectedPersonalCareSubtype == null) {
      setState(() {
        _validationMessage =
            'Choose the personal care subtype before saving this note.';
      });
      return;
    }

    Navigator.of(context).pop(
      ResidentTimelineEntryDraft(
        type: _selectedType,
        details: details,
        personalCareSubtype: _selectedPersonalCareSubtype,
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
    return _ResidentSheetScaffold(
      title: 'Add note',
      children: [
        DropdownButtonFormField<ResidentEntryType>(
          initialValue: _selectedType,
          items: residentEntryTypesForNewNotes
              .map(
                (type) => DropdownMenuItem<ResidentEntryType>(
                  value: type,
                  child: Text(type.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedType = value;
              _validationMessage = null;
              if (value != ResidentEntryType.personalCare) {
                _selectedPersonalCareSubtype = null;
              }
            });
          },
          decoration: const InputDecoration(labelText: 'Note type'),
        ),
        if (_selectedType == ResidentEntryType.personalCare) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<PersonalCareSubtype>(
            initialValue: _selectedPersonalCareSubtype,
            items: PersonalCareSubtype.values
                .map(
                  (subtype) => DropdownMenuItem<PersonalCareSubtype>(
                    value: subtype,
                    child: Text(subtype.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedPersonalCareSubtype = value;
                _validationMessage = null;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Personal care subtype',
            ),
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
