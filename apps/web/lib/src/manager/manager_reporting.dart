import 'package:flutter/material.dart';

import 'manager_models.dart';
import 'manager_shared.dart';
import 'manager_theme.dart';

class CqcEvidencePack extends StatelessWidget {
  const CqcEvidencePack({
    super.key,
    required this.dashboard,
    required this.activeShifts,
    required this.residents,
    required this.isDashboardLoading,
    required this.isResidentsLoading,
    required this.dashboardError,
    required this.residentsError,
    required this.onDownloadSummary,
    required this.onDownloadIncidentRegister,
    required this.onDownloadMedicationAudit,
    required this.onDownloadResidentEmar,
    required this.onDownloadResidentDowntimePack,
    this.onDownloadMedicationRound,
  });

  final ManagerDashboardSnapshot? dashboard;
  final List<ManagerShiftSummary> activeShifts;
  final List<ManagerResidentRecord> residents;
  final bool isDashboardLoading;
  final bool isResidentsLoading;
  final String? dashboardError;
  final String? residentsError;
  final VoidCallback onDownloadSummary;
  final VoidCallback onDownloadIncidentRegister;
  final VoidCallback onDownloadMedicationAudit;
  final VoidCallback? onDownloadMedicationRound;
  final ValueChanged<ManagerResidentRecord> onDownloadResidentEmar;
  final ValueChanged<ManagerResidentRecord> onDownloadResidentDowntimePack;

  @override
  Widget build(BuildContext context) {
    if (isDashboardLoading &&
        isResidentsLoading &&
        dashboard == null &&
        residents.isEmpty) {
      return const _ReportingLoadingSkeleton();
    }

    final activeResidents = residents
        .where((resident) => resident.isActive)
        .toList(growable: false);
    final incidentFeed =
        (dashboard?.exceptionFeed ?? const <ManagerExceptionFeedItem>[])
            .where((entry) => entry.isIncident)
            .toList(growable: false);
    final visibleIncidents = incidentFeed.take(6).toList(growable: false);
    final medicationExceptionCount =
        dashboard?.medicationOverview?.exceptions.length ?? 0;
    final highlightedResidents = _selectEvidencePackResidents(
      residents: activeResidents,
      dashboard: dashboard,
    );
    final activeShiftLabel = activeShifts.isEmpty
        ? 'No active shifts loaded'
        : activeShifts.length == 1
        ? '${activeShifts.first.name} • ${activeShifts.first.unitLabel}'
        : '${activeShifts.length} active shifts in scope';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CqcPackHeroCard(
          activeShiftLabel: activeShiftLabel,
          activeResidentsCount: activeResidents.length,
          activeIncidentCount: incidentFeed.length,
          medicationExceptionCount: medicationExceptionCount,
          onDownloadSummary: onDownloadSummary,
          onDownloadIncidentRegister: onDownloadIncidentRegister,
          onDownloadMedicationAudit: onDownloadMedicationAudit,
          onDownloadMedicationRound: onDownloadMedicationRound,
        ),
        if (dashboardError != null && dashboard == null) ...[
          const SizedBox(height: 18),
          ErrorSurface(message: dashboardError!),
        ],
        if (residentsError != null && residents.isEmpty) ...[
          const SizedBox(height: 18),
          ErrorSurface(message: residentsError!),
        ],
        const SizedBox(height: 18),
        _CqcSectionCard(
          title: 'Incident register ready for export',
          subtitle:
              'Current incident-level follow-up items from the manager dashboard can now be exported as a CSV register for inspection prep and handover review.',
          child: visibleIncidents.isEmpty
              ? const EmptySurface(
                  title: 'No incidents currently in scope',
                  body:
                      'The incident register export is still available and will download an empty register until new incidents appear.',
                )
              : Column(
                  children: [
                    for (
                      var index = 0;
                      index < visibleIncidents.length;
                      index++
                    ) ...[
                      _IncidentEvidenceRow(incident: visibleIncidents[index]),
                      if (index != visibleIncidents.length - 1)
                        const Divider(height: 24, color: managerBorder),
                    ],
                    if (incidentFeed.length > visibleIncidents.length) ...[
                      const SizedBox(height: 18),
                      Text(
                        '${incidentFeed.length - visibleIncidents.length} additional incident${incidentFeed.length - visibleIncidents.length == 1 ? '' : 's'} remain in the downloadable register.',
                        style: const TextStyle(
                          color: managerMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 18),
        _CqcSectionCard(
          title: 'Resident records ready for export',
          subtitle:
              'These resident-level records are the quickest evidence trail we can show today: eMAR history plus a paper-friendly downtime pack.',
          child: highlightedResidents.isEmpty
              ? const EmptySurface(
                  title: 'No resident records highlighted',
                  body:
                      'Load resident data or activate residents to surface export-ready records here.',
                )
              : Column(
                  children: [
                    for (
                      var index = 0;
                      index < highlightedResidents.length;
                      index++
                    ) ...[
                      _ResidentEvidenceRow(
                        resident: highlightedResidents[index],
                        onDownloadResidentEmar: () =>
                            onDownloadResidentEmar(highlightedResidents[index]),
                        onDownloadResidentDowntimePack: () =>
                            onDownloadResidentDowntimePack(
                              highlightedResidents[index],
                            ),
                      ),
                      if (index != highlightedResidents.length - 1)
                        const Divider(height: 24, color: managerBorder),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _CqcPackHeroCard extends StatelessWidget {
  const _CqcPackHeroCard({
    required this.activeShiftLabel,
    required this.activeResidentsCount,
    required this.activeIncidentCount,
    required this.medicationExceptionCount,
    required this.onDownloadSummary,
    required this.onDownloadIncidentRegister,
    required this.onDownloadMedicationAudit,
    this.onDownloadMedicationRound,
  });

  final String activeShiftLabel;
  final int activeResidentsCount;
  final int activeIncidentCount;
  final int medicationExceptionCount;
  final VoidCallback onDownloadSummary;
  final VoidCallback onDownloadIncidentRegister;
  final VoidCallback onDownloadMedicationAudit;
  final VoidCallback? onDownloadMedicationRound;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: managerBorder),
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
                      'CQC evidence pack',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A focused operational export view for the evidence trail SerceSync can show today, ready for handover prep, inspections, and shift review.',
                      style: TextStyle(color: managerMuted, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: managerWarningSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Live export snapshot',
                  style: TextStyle(
                    color: Color(0xFF9A6700),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CqcMetricPill(
                label: 'Scope',
                value: activeShiftLabel,
                toneColor: managerPrimary,
                toneBackground: managerPrimarySoft,
              ),
              _CqcMetricPill(
                label: 'Active residents',
                value: activeResidentsCount.toString(),
                toneColor: managerSuccess,
                toneBackground: managerSuccessSoft,
              ),
              _CqcMetricPill(
                label: 'Live incidents',
                value: activeIncidentCount.toString(),
                toneColor: managerCritical,
                toneBackground: managerCriticalSoft,
              ),
              _CqcMetricPill(
                label: 'Medication exceptions',
                value: medicationExceptionCount.toString(),
                toneColor: managerWarning,
                toneBackground: managerWarningSoft,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onDownloadSummary,
                icon: const Icon(Icons.summarize_outlined),
                label: const Text('Summary CSV'),
              ),
              FilledButton.tonalIcon(
                onPressed: onDownloadIncidentRegister,
                icon: const Icon(Icons.crisis_alert_outlined),
                label: const Text('Incident register CSV'),
              ),
              FilledButton.tonalIcon(
                onPressed: onDownloadMedicationAudit,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Medication audit CSV'),
              ),
              if (onDownloadMedicationRound != null)
                OutlinedButton.icon(
                  onPressed: onDownloadMedicationRound,
                  icon: const Icon(Icons.medication_liquid_outlined),
                  label: const Text('Current round CSV'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportingLoadingSkeleton extends StatelessWidget {
  const _ReportingLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ManagerSkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ManagerSkeletonBlock(height: 20, width: 180),
              SizedBox(height: 12),
              ManagerSkeletonBlock(height: 14, width: double.infinity),
              SizedBox(height: 8),
              ManagerSkeletonBlock(height: 14, width: 300),
              SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: ManagerSkeletonBlock(height: 52, radius: 18)),
                  SizedBox(width: 12),
                  Expanded(child: ManagerSkeletonBlock(height: 52, radius: 18)),
                ],
              ),
            ],
          ),
        ),
        ManagerSkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ManagerSkeletonBlock(height: 18, width: 220),
              SizedBox(height: 12),
              ManagerSkeletonBlock(height: 14, width: double.infinity),
              SizedBox(height: 8),
              ManagerSkeletonBlock(height: 14, width: 260),
              SizedBox(height: 16),
              ManagerSkeletonBlock(
                height: 120,
                width: double.infinity,
                radius: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CqcMetricPill extends StatelessWidget {
  const _CqcMetricPill({
    required this.label,
    required this.value,
    required this.toneColor,
    required this.toneBackground,
  });

  final String label;
  final String value;
  final Color toneColor;
  final Color toneBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: toneBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: toneColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CqcSectionCard extends StatelessWidget {
  const _CqcSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: managerMuted, height: 1.55),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ResidentEvidenceRow extends StatelessWidget {
  const _ResidentEvidenceRow({
    required this.resident,
    required this.onDownloadResidentEmar,
    required this.onDownloadResidentDowntimePack,
  });

  final ManagerResidentRecord resident;
  final VoidCallback onDownloadResidentEmar;
  final VoidCallback onDownloadResidentDowntimePack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resident.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${resident.roomLabel} • ${resident.unitLabel} • Floor ${resident.floorNumber}',
                style: const TextStyle(
                  color: managerMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ResidentEvidenceTag(
                    label: resident.baselinePriority.baselineLabel,
                  ),
                  _ResidentEvidenceTag(
                    label: resident.activeIncidentCount == 0
                        ? 'No open incidents'
                        : '${resident.activeIncidentCount} active incident${resident.activeIncidentCount == 1 ? '' : 's'}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: onDownloadResidentEmar,
              icon: const Icon(Icons.description_outlined),
              label: const Text('eMAR CSV'),
            ),
            FilledButton.tonalIcon(
              onPressed: onDownloadResidentDowntimePack,
              icon: const Icon(Icons.print_outlined),
              label: const Text('Downtime pack'),
            ),
          ],
        ),
      ],
    );
  }
}

class _IncidentEvidenceRow extends StatelessWidget {
  const _IncidentEvidenceRow({required this.incident});

  final ManagerExceptionFeedItem incident;

  @override
  Widget build(BuildContext context) {
    final severityLabel = incident.severity == null
        ? null
        : '${incident.severity!.label} severity';
    final occurredLabel = incident.occurredAt == null
        ? null
        : 'Occurred ${formatTimeOfDay(incident.occurredAt)}';
    final dueLabel = incident.dueAt == null
        ? null
        : 'Due ${formatTimeOfDay(incident.dueAt)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                incident.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${incident.residentName} • ${incident.locationLabel}',
                style: const TextStyle(
                  color: managerMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                incident.description,
                style: const TextStyle(color: managerInk, height: 1.5),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ResidentEvidenceTag(
                    label: incident.status.label.toUpperCase(),
                  ),
                  if (severityLabel != null)
                    _ResidentEvidenceTag(label: severityLabel),
                  _ResidentEvidenceTag(label: incident.badge),
                  if (occurredLabel != null)
                    _ResidentEvidenceTag(label: occurredLabel),
                  if (dueLabel != null) _ResidentEvidenceTag(label: dueLabel),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResidentEvidenceTag extends StatelessWidget {
  const _ResidentEvidenceTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: managerBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: managerMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

List<ManagerResidentRecord> _selectEvidencePackResidents({
  required List<ManagerResidentRecord> residents,
  ManagerDashboardSnapshot? dashboard,
  int maxResidents = 6,
}) {
  if (residents.isEmpty) {
    return const [];
  }

  final residentsById = <String, ManagerResidentRecord>{
    for (final resident in residents) resident.id: resident,
  };
  final selected = <ManagerResidentRecord>[];

  void addResident(ManagerResidentRecord? resident) {
    if (resident == null) {
      return;
    }
    if (selected.any((entry) => entry.id == resident.id)) {
      return;
    }
    selected.add(resident);
  }

  for (final resident in residents.where(
    (entry) => entry.activeIncidentCount > 0,
  )) {
    addResident(resident);
  }

  for (final exception
      in dashboard?.medicationOverview?.exceptions ??
          const <ManagerMedicationException>[]) {
    addResident(residentsById[exception.residentId]);
  }

  for (final resident in residents) {
    if (selected.length >= maxResidents) {
      break;
    }
    addResident(resident);
  }

  return selected.take(maxResidents).toList(growable: false);
}

String buildCqcEvidencePackSummaryCsv({
  required DateTime generatedAt,
  required List<ManagerShiftSummary> activeShifts,
  required List<ManagerResidentRecord> residents,
  ManagerDashboardSnapshot? dashboard,
  String? dashboardError,
  String? residentsError,
}) {
  final activeResidents = residents
      .where((resident) => resident.isActive)
      .toList(growable: false);
  final residentsWithAboutMe = activeResidents
      .where((resident) => resident.aboutMe.trim().isNotEmpty)
      .length;
  final incidentFeed =
      (dashboard?.exceptionFeed ?? const <ManagerExceptionFeedItem>[])
          .where((entry) => entry.isIncident)
          .toList(growable: false);
  final medicationExceptionCount =
      dashboard?.medicationOverview?.exceptions.length ?? 0;
  final highlightedResidents = _selectEvidencePackResidents(
    residents: activeResidents,
    dashboard: dashboard,
  );

  final rows = <List<String>>[
    ['Section', 'Metric', 'Value', 'Note'],
    [
      'Metadata',
      'Generated at',
      generatedAt.toIso8601String(),
      'Lightweight operational CQC evidence pack generated from current manager data.',
    ],
    [
      'Metadata',
      'Scope',
      activeShifts.isEmpty
          ? 'No active shifts'
          : '${activeShifts.length} active shift(s)',
      activeShifts.isEmpty
          ? 'Shift scope is not currently available.'
          : activeShifts
                .map((shift) => '${shift.name} (${shift.unitLabel})')
                .join('; '),
    ],
    [
      'Metadata',
      'Pack status',
      'Operational evidence only',
      'This pack is suitable for a demo or inspection-prep walkthrough, not as a full compliance binder.',
    ],
    [
      'Safe',
      'Active incidents',
      incidentFeed.length.toString(),
      dashboard == null
          ? dashboardError ?? 'Dashboard data not loaded.'
          : 'Live incidents currently visible in the manager dashboard.',
    ],
    [
      'Safe',
      'Incident register CSV',
      'Available',
      dashboard == null
          ? dashboardError ??
                'Dashboard data is not loaded, so the incident register export may currently be empty.'
          : incidentFeed.isEmpty
          ? 'No live incidents are currently visible, but the incident register export remains available.'
          : '${incidentFeed.length} incident(s) are currently visible and can be exported as a CSV register.',
    ],
    [
      'Safe',
      'Unread handovers',
      dashboard?.metrics.unreadHandovers.toString() ?? 'Unavailable',
      'Medication actions are controlled through handover acknowledgement workflow.',
    ],
    [
      'Safe',
      'Medication exceptions',
      medicationExceptionCount.toString(),
      'Current medication exceptions visible in manager medication overview.',
    ],
    [
      'Effective',
      'Active residents',
      activeResidents.length.toString(),
      residentsError ??
          'Resident records currently available in manager workspace.',
    ],
    [
      'Effective',
      'Residents with personal context',
      residentsWithAboutMe.toString(),
      'Resident About Me context supports person-specific handover and care continuity.',
    ],
    [
      'Effective',
      'Resident eMAR export',
      activeResidents.isEmpty ? 'Unavailable' : 'Available',
      'Resident-level medication administration history can be exported as CSV.',
    ],
    [
      'Effective',
      'Downtime pack export',
      activeResidents.isEmpty ? 'Unavailable' : 'Available',
      'Resident-level paper-friendly downtime packs can be exported as CSV.',
    ],
    [
      'Caring',
      'Resident personal context',
      residentsWithAboutMe.toString(),
      'This pack includes person-centred context counts, but not qualitative feedback or family experience records.',
    ],
    [
      'Responsive',
      'Residents with active incidents',
      activeResidents
          .where((resident) => resident.activeIncidentCount > 0)
          .length
          .toString(),
      'Resident list currently shows which people are affected by active incidents.',
    ],
    [
      'Responsive',
      'Overdue tasks',
      dashboard?.metrics.overdueTasks.toString() ?? 'Unavailable',
      'Overdue care activity visible in current manager dashboard snapshot.',
    ],
    [
      'Responsive',
      'Escalated items',
      dashboard?.metrics.escalatedItems.toString() ?? 'Unavailable',
      'Escalations currently visible in the manager dashboard.',
    ],
    [
      'Responsive',
      'Active shifts',
      activeShifts.length.toString(),
      'Operational scope currently live in the workspace.',
    ],
    [
      'Well-led',
      'Medication audit CSV',
      'Available',
      'Manager medication audit export is available from the reporting pack.',
    ],
    [
      'Well-led',
      'Current round CSV',
      activeShifts.isEmpty ? 'Unavailable' : 'Available',
      'Current medication round export is available when an active shift exists.',
    ],
  ];

  for (final resident in highlightedResidents) {
    rows.add([
      'Resident exports',
      resident.fullName,
      resident.roomLabel,
      'eMAR CSV and downtime-pack CSV available for this resident.',
    ]);
  }

  return rows
      .map((row) => row.map(escapeCsvCellForExport).join(','))
      .join('\n');
}

String buildIncidentRegisterCsv({
  required DateTime generatedAt,
  ManagerDashboardSnapshot? dashboard,
}) {
  final incidents =
      (dashboard?.exceptionFeed ?? const <ManagerExceptionFeedItem>[])
          .where((entry) => entry.isIncident)
          .toList(growable: false);

  final rows = <List<String>>[
    [
      'Exported at',
      'Incident ID',
      'Title',
      'Resident',
      'Unit',
      'Floor',
      'Room',
      'Shift ID',
      'Status',
      'Severity',
      'Badge',
      'Occurred at',
      'Due at',
      'Description',
    ],
  ];

  if (incidents.isEmpty) {
    rows.add([
      generatedAt.toIso8601String(),
      '',
      'No live incidents in scope',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'Incident register exported without any active incidents in the current dashboard snapshot.',
    ]);
  } else {
    for (final incident in incidents) {
      rows.add([
        generatedAt.toIso8601String(),
        incident.id,
        incident.title,
        incident.residentName,
        incident.unitLabel,
        incident.floorNumber?.toString() ?? '',
        incident.roomLabel,
        incident.shiftId,
        incident.status.label,
        incident.severity?.label ?? '',
        incident.badge,
        incident.occurredAt?.toIso8601String() ?? '',
        incident.dueAt?.toIso8601String() ?? '',
        incident.description,
      ]);
    }
  }

  return rows
      .map((row) => row.map(escapeCsvCellForExport).join(','))
      .join('\n');
}

String escapeCsvCellForExport(String value) {
  final normalizedValue =
      value.isNotEmpty && RegExp(r'^[=+\-@]').hasMatch(value)
      ? "'$value"
      : value;
  final normalized = normalizedValue.replaceAll('"', '""');
  return '"$normalized"';
}
