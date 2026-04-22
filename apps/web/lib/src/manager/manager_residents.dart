import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'manager_api_client.dart';
import 'manager_emar.dart';
import 'manager_file_download_api.dart';
import 'manager_models.dart';
import 'manager_shared.dart';
import 'manager_theme.dart';

class ResidentsManagement extends StatelessWidget {
  const ResidentsManagement({
    super.key,
    required this.apiClient,
    required this.fileDownloader,
    required this.accessToken,
    required this.residents,
    required this.isLoading,
    required this.isSaving,
    required this.isEditorVisible,
    required this.errorMessage,
    required this.editingResidentId,
    required this.fullNameController,
    required this.roomNumberController,
    required this.floorNumberController,
    required this.unitLabelController,
    required this.aboutMeController,
    required this.recognitionImageKey,
    required this.isActive,
    required this.baselinePriority,
    required this.onRecognitionImageChanged,
    required this.onActiveChanged,
    required this.onBaselinePriorityChanged,
    required this.onCreateResident,
    required this.onCloseResidentEditor,
    required this.onEditResident,
    required this.onMedicationDataChanged,
    required this.onSaveResident,
  });

  final SerceSyncManagerApiClient apiClient;
  final ManagerFileDownloader fileDownloader;
  final String accessToken;
  final List<ManagerResidentRecord> residents;
  final bool isLoading;
  final bool isSaving;
  final bool isEditorVisible;
  final String? errorMessage;
  final String? editingResidentId;
  final TextEditingController fullNameController;
  final TextEditingController roomNumberController;
  final TextEditingController floorNumberController;
  final TextEditingController unitLabelController;
  final TextEditingController aboutMeController;
  final String recognitionImageKey;
  final bool isActive;
  final ManagerResidentPriorityLevel baselinePriority;
  final ValueChanged<String> onRecognitionImageChanged;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<ManagerResidentPriorityLevel> onBaselinePriorityChanged;
  final VoidCallback onCreateResident;
  final VoidCallback onCloseResidentEditor;
  final ValueChanged<ManagerResidentRecord> onEditResident;
  final Future<void> Function() onMedicationDataChanged;
  final Future<void> Function() onSaveResident;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final splitLayout = isEditorVisible && constraints.maxWidth >= 1120;
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
                apiClient: apiClient,
                fileDownloader: fileDownloader,
                accessToken: accessToken,
                onCreateResident: onCreateResident,
                onEditResident: onEditResident,
                onMedicationDataChanged: onMedicationDataChanged,
              ),
            ),
            if (isEditorVisible)
              SizedBox(
                width: formWidth,
                child: _ResidentEditorCard(
                  isSaving: isSaving,
                  editingResidentId: editingResidentId,
                  fullNameController: fullNameController,
                  roomNumberController: roomNumberController,
                  floorNumberController: floorNumberController,
                  unitLabelController: unitLabelController,
                  aboutMeController: aboutMeController,
                  recognitionImageKey: recognitionImageKey,
                  isActive: isActive,
                  baselinePriority: baselinePriority,
                  onRecognitionImageChanged: onRecognitionImageChanged,
                  onActiveChanged: onActiveChanged,
                  onBaselinePriorityChanged: onBaselinePriorityChanged,
                  onCreateResident: onCreateResident,
                  onCloseResidentEditor: onCloseResidentEditor,
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
    required this.apiClient,
    required this.fileDownloader,
    required this.accessToken,
    required this.onCreateResident,
    required this.onEditResident,
    required this.onMedicationDataChanged,
  });

  final List<ManagerResidentRecord> residents;
  final bool isLoading;
  final String? errorMessage;
  final SerceSyncManagerApiClient apiClient;
  final ManagerFileDownloader fileDownloader;
  final String accessToken;
  final VoidCallback onCreateResident;
  final ValueChanged<ManagerResidentRecord> onEditResident;
  final Future<void> Function() onMedicationDataChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: managerBorder),
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
                      style: TextStyle(color: managerMuted, height: 1.5),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onCreateResident,
                style: FilledButton.styleFrom(
                  backgroundColor: managerPrimarySoft,
                  foregroundColor: managerPrimary,
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
                color: managerCritical,
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
            const EmptySurface(
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
                    onOpenEmar: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => ResidentEmarDialog(
                          apiClient: apiClient,
                          fileDownloader: fileDownloader,
                          accessToken: accessToken,
                          resident: resident,
                          onChanged: onMedicationDataChanged,
                        ),
                      );
                    },
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
  const _ResidentDirectoryRow({
    required this.resident,
    required this.onEdit,
    required this.onOpenEmar,
  });

  final ManagerResidentRecord resident;
  final VoidCallback onEdit;
  final VoidCallback onOpenEmar;

  @override
  Widget build(BuildContext context) {
    final priorityTone = _residentPriorityToneFor(resident.effectivePriority);
    final incidentCountLabel = resident.activeIncidentCount == 1
        ? '1 active incident'
        : '${resident.activeIncidentCount} active incidents';

    return Container(
      key: ValueKey(
        'resident-card-${resident.id}-${resident.effectivePriority.apiValue}',
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: priorityTone.shellBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: priorityTone.shellBorder,
          width:
              resident.effectivePriority == ManagerResidentPriorityLevel.green
              ? 1
              : 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResidentPhotoAvatar(
            fullName: resident.fullName,
            recognitionImageKey: resident.recognitionImageKey,
            size: 44,
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
                    ResidentMetaPill(label: resident.roomLabel),
                    ResidentMetaPill(label: resident.unitLabel),
                    ResidentMetaPill(label: 'Floor ${resident.floorNumber}'),
                    ResidentMetaPill(
                      label: incidentCountLabel,
                      foreground: resident.activeIncidentCount > 0
                          ? managerCritical
                          : managerMuted,
                      background: resident.activeIncidentCount > 0
                          ? managerCriticalSoft
                          : const Color(0xFFF0F4F8),
                    ),
                    ResidentMetaPill(
                      label: resident.prioritySource.label,
                      foreground:
                          resident.prioritySource ==
                              ManagerResidentPrioritySource.incidentOverride
                          ? managerWarning
                          : managerMuted,
                      background:
                          resident.prioritySource ==
                              ManagerResidentPrioritySource.incidentOverride
                          ? managerWarningSoft
                          : const Color(0xFFF0F4F8),
                    ),
                    ResidentMetaPill(
                      label: resident.isActive ? 'Active' : 'Inactive',
                      foreground: resident.isActive
                          ? managerSuccess
                          : managerMuted,
                      background: resident.isActive
                          ? managerSuccessSoft
                          : const Color(0xFFF0F4F8),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  resident.aboutMe.isEmpty
                      ? 'No about me note added yet.'
                      : resident.aboutMe,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: managerMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FilledButton.tonal(
                key: ValueKey('resident-emar-${resident.id}'),
                onPressed: onOpenEmar,
                style: FilledButton.styleFrom(
                  foregroundColor: managerPrimary,
                  backgroundColor: managerPrimarySoft,
                ),
                child: const Text('Medication chart'),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: onEdit,
                style: FilledButton.styleFrom(
                  foregroundColor: managerPrimary,
                  backgroundColor: managerPrimarySoft,
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
        ],
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
    required this.aboutMeController,
    required this.recognitionImageKey,
    required this.isActive,
    required this.baselinePriority,
    required this.onRecognitionImageChanged,
    required this.onActiveChanged,
    required this.onBaselinePriorityChanged,
    required this.onCreateResident,
    required this.onCloseResidentEditor,
    required this.onSaveResident,
  });

  final bool isSaving;
  final String? editingResidentId;
  final TextEditingController fullNameController;
  final TextEditingController roomNumberController;
  final TextEditingController floorNumberController;
  final TextEditingController unitLabelController;
  final TextEditingController aboutMeController;
  final String recognitionImageKey;
  final bool isActive;
  final ManagerResidentPriorityLevel baselinePriority;
  final ValueChanged<String> onRecognitionImageChanged;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<ManagerResidentPriorityLevel> onBaselinePriorityChanged;
  final VoidCallback onCreateResident;
  final VoidCallback onCloseResidentEditor;
  final Future<void> Function() onSaveResident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: managerBorder),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: onCreateResident,
                    child: Text(
                      editingResidentId == null ? 'Reset' : 'New Resident',
                    ),
                  ),
                  TextButton(
                    onPressed: onCloseResidentEditor,
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Update the resident profile that powers the manager list and the mobile assignment context.',
            style: TextStyle(color: managerMuted, height: 1.5),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: managerBorder),
            ),
            child: Row(
              children: [
                ResidentPhotoAvatar(
                  fullName: fullNameController.text.trim().isEmpty
                      ? 'Resident preview'
                      : fullNameController.text.trim(),
                  recognitionImageKey: recognitionImageKey,
                  size: 64,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photo Preview',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: managerInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recognitionImageKey,
                        style: const TextStyle(
                          color: managerMuted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('photo-$recognitionImageKey-$editingResidentId'),
            initialValue: recognitionImageKey,
            decoration: const InputDecoration(labelText: 'Photo Key'),
            items: residentRecognitionImageKeys
                .map(
                  (photoKey) =>
                      DropdownMenuItem(value: photoKey, child: Text(photoKey)),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                onRecognitionImageChanged(value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: aboutMeController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'About Me',
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
              backgroundColor: managerPrimary,
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
    required this.shellBackground,
    required this.shellBorder,
  });

  final Color foreground;
  final Color background;
  final Color shellBackground;
  final Color shellBorder;
}

_ResidentPriorityTone _residentPriorityToneFor(
  ManagerResidentPriorityLevel priority,
) {
  switch (priority) {
    case ManagerResidentPriorityLevel.red:
      return const _ResidentPriorityTone(
        foreground: managerCritical,
        background: managerCriticalSoft,
        shellBackground: Color(0xFFFFF7F6),
        shellBorder: Color(0xFFF8C2BC),
      );
    case ManagerResidentPriorityLevel.amber:
      return const _ResidentPriorityTone(
        foreground: managerWarning,
        background: managerWarningSoft,
        shellBackground: Color(0xFFFFFAF2),
        shellBorder: Color(0xFFFFDEB0),
      );
    case ManagerResidentPriorityLevel.green:
      return const _ResidentPriorityTone(
        foreground: managerSuccess,
        background: managerSuccessSoft,
        shellBackground: Color(0xFFF8FBFE),
        shellBorder: managerBorder,
      );
  }
}
