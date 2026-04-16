part of '../resident_detail_screen.dart';

class _ReportIncidentSheet extends StatefulWidget {
  const _ReportIncidentSheet({required this.onPickEvidence});

  final Future<TimelineEvidenceFile?> Function() onPickEvidence;

  @override
  State<_ReportIncidentSheet> createState() => _ReportIncidentSheetState();
}

class _ReportIncidentSheetState extends State<_ReportIncidentSheet> {
  IncidentSeverity _selectedSeverity = IncidentSeverity.amber;
  IncidentCategory _selectedCategory = IncidentCategory.fall;
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  TimelineEvidenceFile? _evidence;
  bool _isPickingEvidence = false;
  String? _validationMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
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

  void _submit() {
    final title = _titleController.text.trim();
    final details = _detailsController.text.trim();
    if (title.isEmpty || details.isEmpty) {
      setState(() {
        _validationMessage =
            'Add a short title and the incident details before submitting.';
      });
      return;
    }

    Navigator.of(context).pop(
      ResidentIncidentDraft(
        severity: _selectedSeverity,
        category: _selectedCategory,
        title: title,
        details: details,
        evidence: _evidence,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ResidentSheetScaffold(
      title: 'Report incident',
      subtitle:
          'Record the issue clearly so the manager workspace can react immediately.',
      children: [
        DropdownButtonFormField<IncidentSeverity>(
          initialValue: _selectedSeverity,
          items: IncidentSeverity.values
              .map(
                (severity) => DropdownMenuItem<IncidentSeverity>(
                  value: severity,
                  child: Text(severity.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedSeverity = value;
              _validationMessage = null;
            });
          },
          decoration: const InputDecoration(labelText: 'Severity'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<IncidentCategory>(
          initialValue: _selectedCategory,
          items: IncidentCategory.values
              .map(
                (category) => DropdownMenuItem<IncidentCategory>(
                  value: category,
                  child: Text(category.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedCategory = value;
              _validationMessage = null;
            });
          },
          decoration: const InputDecoration(labelText: 'Category'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          onChanged: (_) {
            if (_validationMessage != null) {
              setState(() => _validationMessage = null);
            }
          },
          decoration: const InputDecoration(labelText: 'Short title'),
        ),
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
            _evidence == null ? 'Attach evidence' : 'Replace evidence',
          ),
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
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.errorRed,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.emergency_outlined),
          label: const Text('Submit incident'),
        ),
      ],
    );
  }
}
