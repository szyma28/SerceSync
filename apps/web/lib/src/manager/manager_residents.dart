part of '../../manager_app.dart';

class _ResidentsManagement extends StatelessWidget {
  const _ResidentsManagement({
    super.key,
    required this.residents,
    required this.isLoading,
    required this.isSaving,
    required this.errorMessage,
    required this.editingResidentId,
    required this.fullNameController,
    required this.roomNumberController,
    required this.floorNumberController,
    required this.unitLabelController,
    required this.careSummaryController,
    required this.recognitionImageKey,
    required this.isActive,
    required this.baselinePriority,
    required this.onRecognitionImageChanged,
    required this.onActiveChanged,
    required this.onBaselinePriorityChanged,
    required this.onCreateResident,
    required this.onEditResident,
    required this.onSaveResident,
  });

  final List<ManagerResidentRecord> residents;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? editingResidentId;
  final TextEditingController fullNameController;
  final TextEditingController roomNumberController;
  final TextEditingController floorNumberController;
  final TextEditingController unitLabelController;
  final TextEditingController careSummaryController;
  final String recognitionImageKey;
  final bool isActive;
  final ManagerResidentPriorityLevel baselinePriority;
  final ValueChanged<String> onRecognitionImageChanged;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<ManagerResidentPriorityLevel> onBaselinePriorityChanged;
  final VoidCallback onCreateResident;
  final ValueChanged<ManagerResidentRecord> onEditResident;
  final Future<void> Function() onSaveResident;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final splitLayout = constraints.maxWidth >= 1120;
        final formWidth = splitLayout
            ? math.max(320.0, constraints.maxWidth * 0.36)
            : constraints.maxWidth;
        final listWidth = splitLayout
            ? constraints.maxWidth - formWidth - 18
            : constraints.maxWidth;

        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            SizedBox(
              width: listWidth,
              child: _ResidentsListCard(
                residents: residents,
                isLoading: isLoading,
                errorMessage: errorMessage,
                onCreateResident: onCreateResident,
                onEditResident: onEditResident,
              ),
            ),
            SizedBox(
              width: formWidth,
              child: _ResidentEditorCard(
                isSaving: isSaving,
                editingResidentId: editingResidentId,
                fullNameController: fullNameController,
                roomNumberController: roomNumberController,
                floorNumberController: floorNumberController,
                unitLabelController: unitLabelController,
                careSummaryController: careSummaryController,
                recognitionImageKey: recognitionImageKey,
                isActive: isActive,
                baselinePriority: baselinePriority,
                onRecognitionImageChanged: onRecognitionImageChanged,
                onActiveChanged: onActiveChanged,
                onBaselinePriorityChanged: onBaselinePriorityChanged,
                onCreateResident: onCreateResident,
                onSaveResident: onSaveResident,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResidentsListCard extends StatelessWidget {
  const _ResidentsListCard({
    required this.residents,
    required this.isLoading,
    required this.errorMessage,
    required this.onCreateResident,
    required this.onEditResident,
  });

  final List<ManagerResidentRecord> residents;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onCreateResident;
  final ValueChanged<ManagerResidentRecord> onEditResident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _managerBorder),
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
                      'Resident Directory',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Keep room placement, unit ownership, and care context aligned with the live manager view.',
                      style: TextStyle(color: _managerMuted, height: 1.5),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onCreateResident,
                style: FilledButton.styleFrom(
                  backgroundColor: _managerPrimarySoft,
                  foregroundColor: _managerPrimary,
                  elevation: 0,
                ),
                child: const Text('New Resident'),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: _managerCritical,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (isLoading)
            const SizedBox(
              height: 360,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (residents.isEmpty)
            const _EmptySurface(
              title: 'No residents available',
              body:
                  'Create the first resident record to populate the manager workspace.',
            )
          else
            Column(
              children: [
                for (final resident in residents) ...[
                  _ResidentDirectoryRow(
                    resident: resident,
                    onEdit: () => onEditResident(resident),
                  ),
                  if (resident != residents.last) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ResidentDirectoryRow extends StatelessWidget {
  const _ResidentDirectoryRow({required this.resident, required this.onEdit});

  final ManagerResidentRecord resident;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final priorityTone = _residentPriorityToneFor(resident.effectivePriority);
    final incidentCountLabel = resident.activeIncidentCount == 1
        ? '1 active incident'
        : '${resident.activeIncidentCount} active incidents';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _managerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _managerPrimarySoft,
            foregroundColor: _managerPrimary,
            child: Text(
              _initialsForName(resident.fullName),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resident.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ResidentMetaPill(label: resident.roomLabel),
                    _ResidentMetaPill(label: resident.unitLabel),
                    _ResidentMetaPill(label: 'Floor ${resident.floorNumber}'),
                    _ResidentMetaPill(
                      label:
                          'Priority ${resident.effectivePriority.label.toUpperCase()}',
                      foreground: priorityTone.foreground,
                      background: priorityTone.background,
                    ),
                    _ResidentMetaPill(
                      label: incidentCountLabel,
                      foreground: resident.activeIncidentCount > 0
                          ? _managerCritical
                          : _managerMuted,
                      background: resident.activeIncidentCount > 0
                          ? _managerCriticalSoft
                          : const Color(0xFFF0F4F8),
                    ),
                    _ResidentMetaPill(
                      label: resident.prioritySource.label,
                      foreground:
                          resident.prioritySource ==
                              ManagerResidentPrioritySource.incidentOverride
                          ? _managerWarning
                          : _managerMuted,
                      background:
                          resident.prioritySource ==
                              ManagerResidentPrioritySource.incidentOverride
                          ? _managerWarningSoft
                          : const Color(0xFFF0F4F8),
                    ),
                    _ResidentMetaPill(
                      label: resident.isActive ? 'Active' : 'Inactive',
                      foreground: resident.isActive
                          ? _managerSuccess
                          : _managerMuted,
                      background: resident.isActive
                          ? _managerSuccessSoft
                          : const Color(0xFFF0F4F8),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  resident.careSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _managerMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: onEdit,
            style: FilledButton.styleFrom(
              foregroundColor: _managerPrimary,
              backgroundColor: _managerPrimarySoft,
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _ResidentMetaPill extends StatelessWidget {
  const _ResidentMetaPill({
    required this.label,
    this.foreground = _managerMuted,
    this.background = const Color(0xFFF0F4F8),
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
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ResidentEditorCard extends StatelessWidget {
  const _ResidentEditorCard({
    required this.isSaving,
    required this.editingResidentId,
    required this.fullNameController,
    required this.roomNumberController,
    required this.floorNumberController,
    required this.unitLabelController,
    required this.careSummaryController,
    required this.recognitionImageKey,
    required this.isActive,
    required this.baselinePriority,
    required this.onRecognitionImageChanged,
    required this.onActiveChanged,
    required this.onBaselinePriorityChanged,
    required this.onCreateResident,
    required this.onSaveResident,
  });

  final bool isSaving;
  final String? editingResidentId;
  final TextEditingController fullNameController;
  final TextEditingController roomNumberController;
  final TextEditingController floorNumberController;
  final TextEditingController unitLabelController;
  final TextEditingController careSummaryController;
  final String recognitionImageKey;
  final bool isActive;
  final ManagerResidentPriorityLevel baselinePriority;
  final ValueChanged<String> onRecognitionImageChanged;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<ManagerResidentPriorityLevel> onBaselinePriorityChanged;
  final VoidCallback onCreateResident;
  final Future<void> Function() onSaveResident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  editingResidentId == null
                      ? 'New Resident Record'
                      : 'Edit Resident Record',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton(
                onPressed: onCreateResident,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Update the resident profile that powers the manager list and the mobile assignment context.',
            style: TextStyle(color: _managerMuted, height: 1.5),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: fullNameController,
            decoration: const InputDecoration(labelText: 'Resident Name'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: roomNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Room'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: floorNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Floor'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: unitLabelController,
            decoration: const InputDecoration(labelText: 'Unit Label'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ManagerResidentPriorityLevel>(
            key: ValueKey(
              'resident-baseline-priority-${editingResidentId ?? 'new'}-$baselinePriority',
            ),
            initialValue: baselinePriority,
            decoration: const InputDecoration(labelText: 'Baseline Priority'),
            items: ManagerResidentPriorityLevel.values
                .map(
                  (priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(priority.baselineLabel),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                onBaselinePriorityChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('photo-$recognitionImageKey-$editingResidentId'),
            initialValue: recognitionImageKey,
            decoration: const InputDecoration(labelText: 'Photo Key'),
            items: const [
              DropdownMenuItem(value: 'resident-a', child: Text('resident-a')),
              DropdownMenuItem(value: 'resident-b', child: Text('resident-b')),
              DropdownMenuItem(value: 'resident-c', child: Text('resident-c')),
              DropdownMenuItem(value: 'resident-d', child: Text('resident-d')),
            ],
            onChanged: (value) {
              if (value != null) {
                onRecognitionImageChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: careSummaryController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Clinical Summary',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            value: isActive,
            contentPadding: EdgeInsets.zero,
            title: const Text('Resident Active'),
            onChanged: onActiveChanged,
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: isSaving ? null : () => onSaveResident(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _managerPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Record'),
          ),
        ],
      ),
    );
  }
}

class _ResidentPriorityTone {
  const _ResidentPriorityTone({
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;
}

_ResidentPriorityTone _residentPriorityToneFor(
  ManagerResidentPriorityLevel priority,
) {
  switch (priority) {
    case ManagerResidentPriorityLevel.red:
      return const _ResidentPriorityTone(
        foreground: _managerCritical,
        background: _managerCriticalSoft,
      );
    case ManagerResidentPriorityLevel.amber:
      return const _ResidentPriorityTone(
        foreground: _managerWarning,
        background: _managerWarningSoft,
      );
    case ManagerResidentPriorityLevel.green:
      return const _ResidentPriorityTone(
        foreground: _managerSuccess,
        background: _managerSuccessSoft,
      );
  }
}
