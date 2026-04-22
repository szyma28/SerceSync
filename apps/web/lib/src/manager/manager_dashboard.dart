import 'package:flutter/material.dart';

import 'manager_api_client.dart';
import 'manager_file_download_api.dart';
import 'manager_models.dart';
import 'manager_shared.dart';
import 'manager_theme.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({
    super.key,
    required this.apiClient,
    required this.fileDownloader,
    required this.accessToken,
    required this.dashboard,
    required this.activeShifts,
    required this.isLoading,
    required this.errorMessage,
    required this.pendingIncidentIds,
    required this.onAcknowledgeIncident,
    required this.onResolveIncident,
  });

  final SerceSyncManagerApiClient apiClient;
  final ManagerFileDownloader fileDownloader;
  final String accessToken;
  final ManagerDashboardSnapshot? dashboard;
  final List<ManagerShiftSummary> activeShifts;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> pendingIncidentIds;
  final Future<void> Function(String incidentId, String shiftId)
  onAcknowledgeIncident;
  final Future<void> Function(String incidentId, String shiftId)
  onResolveIncident;

  Future<void> _downloadMedicationAuditCsv(BuildContext context) async {
    try {
      final csv = await apiClient.exportMedicationAuditCsv(
        accessToken: accessToken,
      );
      if (!context.mounted) {
        return;
      }
      await downloadCsvExport(
        context,
        downloader: fileDownloader,
        fileName: 'medication-audit.csv',
        csv: csv,
      );
    } on ApiException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _downloadMedicationRoundCsv(
    BuildContext context,
    String shiftId,
  ) async {
    try {
      final csv = await apiClient.exportMedicationRoundCsv(
        accessToken: accessToken,
        shiftId: shiftId,
      );
      if (!context.mounted) {
        return;
      }
      await downloadCsvExport(
        context,
        downloader: fileDownloader,
        fileName: 'shift-$shiftId-medication-round.csv',
        csv: csv,
      );
    } on ApiException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && dashboard == null) {
      return const SizedBox(
        height: 380,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null && dashboard == null) {
      return ErrorSurface(message: errorMessage!);
    }

    if (activeShifts.isEmpty) {
      return const _DashboardEmptyState();
    }

    final data = dashboard;
    if (data == null) {
      return const ErrorSurface(
        message: 'The dashboard returned without any overview data.',
      );
    }

    final scopeLabel = activeShifts.length == 1
        ? activeShifts.first.unitLabel
        : 'all active floors';

    return LayoutBuilder(
      builder: (context, constraints) {
        final metricColumns = constraints.maxWidth >= 1120
            ? 5
            : constraints.maxWidth >= 760
            ? 2
            : 1;
        final metricSpacing = 16.0;
        final metricCardWidth =
            (constraints.maxWidth - (metricSpacing * (metricColumns - 1))) /
            metricColumns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardStaffOnDutyCard(activeShifts: activeShifts),
            const SizedBox(height: 18),
            Wrap(
              spacing: metricSpacing,
              runSpacing: metricSpacing,
              children: [
                SizedBox(
                  width: metricCardWidth,
                  child: _MetricCard(
                    icon: Icons.emergency_outlined,
                    toneColor: managerCritical,
                    toneBackground: managerCriticalSoft,
                    label: 'ACTIVE INCIDENTS',
                    value: data.metrics.activeIncidents.toString(),
                    note: data.metrics.activeIncidents == 0
                        ? 'No unresolved incidents'
                        : 'Immediate follow-up required',
                  ),
                ),
                SizedBox(
                  width: metricCardWidth,
                  child: _MetricCard(
                    icon: Icons.schedule_rounded,
                    toneColor: managerCritical,
                    toneBackground: managerCriticalSoft,
                    label: 'OVERDUE TASKS',
                    value: data.metrics.overdueTasks.toString(),
                    note: data.metrics.overdueTasks == 0
                        ? 'No missed care windows'
                        : 'Need review now',
                  ),
                ),
                SizedBox(
                  width: metricCardWidth,
                  child: _MetricCard(
                    icon: Icons.priority_high_rounded,
                    toneColor: managerWarning,
                    toneBackground: managerWarningSoft,
                    label: 'ESCALATED ITEMS',
                    value: data.metrics.escalatedItems.toString(),
                    note: data.metrics.escalatedItems == 0
                        ? 'No escalations logged'
                        : 'Requires attention',
                  ),
                ),
                SizedBox(
                  width: metricCardWidth,
                  child: _MetricCard(
                    icon: Icons.groups_2_outlined,
                    toneColor: managerInfo,
                    toneBackground: managerInfoSoft,
                    label: 'UNREAD HANDOVERS',
                    value: data.metrics.unreadHandovers.toString(),
                    note: data.metrics.unreadHandovers == 0
                        ? 'All staff confirmed'
                        : 'Awaiting confirmation',
                  ),
                ),
                SizedBox(
                  width: metricCardWidth,
                  child: _MetricCard(
                    icon: Icons.check_circle_outline_rounded,
                    toneColor: managerSuccess,
                    toneBackground: managerSuccessSoft,
                    label: 'SHIFT COMPLETION',
                    value: '${data.metrics.shiftCompletionPercent}%',
                    note:
                        'On track for ${formatTimeOfDay(data.activeShift.endsAt)}',
                  ),
                ),
              ],
            ),
            if (data.medicationOverview != null) ...[
              const SizedBox(height: 18),
              _MedicationOverviewCard(
                overview: data.medicationOverview!,
                activeShifts: activeShifts,
                activeShift: data.activeShift,
                onPreviewMedicationAudit: () =>
                    _downloadMedicationAuditCsv(context),
                onPreviewMedicationRound: () =>
                    _downloadMedicationRoundCsv(context, data.activeShift.id),
              ),
            ],
            const SizedBox(height: 18),
            _LiveExceptionFeedCard(
              items: data.exceptionFeed,
              scopeLabel: scopeLabel,
              pendingIncidentIds: pendingIncidentIds,
              onAcknowledgeIncident: onAcknowledgeIncident,
              onResolveIncident: onResolveIncident,
            ),
            const SizedBox(height: 18),
            _LiveActivityFeedCard(
              items: data.activityFeed,
              scopeLabel: scopeLabel,
            ),
            const SizedBox(height: 18),
            _ComplianceCard(points: data.complianceSeries),
          ],
        );
      },
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

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
        children: const [
          Text(
            'No active shifts available yet.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            'Start an active shift for a unit to open live oversight, incident follow-up, and medication review.',
            style: TextStyle(color: managerMuted, height: 1.55),
          ),
        ],
      ),
    );
  }
}

class _DashboardStaffOnDutyCard extends StatelessWidget {
  const _DashboardStaffOnDutyCard({required this.activeShifts});

  final List<ManagerShiftSummary> activeShifts;

  @override
  Widget build(BuildContext context) {
    final uniqueStaff =
        {
          for (final member in activeShifts.expand(
            (shift) => shift.assignedUsers,
          ))
            member.id: member,
        }.values.toList(growable: false)..sort((left, right) {
          final roleOrder = _staffRoleSortIndex(
            left.role,
          ).compareTo(_staffRoleSortIndex(right.role));
          if (roleOrder != 0) {
            return roleOrder;
          }
          return left.displayName.compareTo(right.displayName);
        });

    final carerCount = uniqueStaff
        .where((member) => member.role == ManagerUserRole.carer)
        .length;
    final nurseCount = uniqueStaff
        .where((member) => member.role == ManagerUserRole.nurse)
        .length;
    final managerCount = uniqueStaff
        .where((member) => member.role == ManagerUserRole.manager)
        .length;
    final staffingSummary = [
      if (carerCount > 0)
        _formatStaffRoleCount(ManagerUserRole.carer, carerCount),
      if (nurseCount > 0)
        _formatStaffRoleCount(ManagerUserRole.nurse, nurseCount),
      if (managerCount > 0)
        _formatStaffRoleCount(ManagerUserRole.manager, managerCount),
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF4F8FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: managerBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isUniformDesktop =
              constraints.maxWidth >= 1320 && activeShifts.length <= 3;

          if (isUniformDesktop) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _StaffOnDutySummaryPanel(
                      totalStaffCount: uniqueStaff.length,
                      activeFloorCount: activeShifts.length,
                      staffingSummary: staffingSummary,
                      carerCount: carerCount,
                      nurseCount: nurseCount,
                      managerCount: managerCount,
                    ),
                  ),
                  for (final shift in activeShifts) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _ShiftStaffRosterCard(shift: shift)),
                  ],
                ],
              ),
            );
          }

          final isTwoColumn = constraints.maxWidth >= 860;
          final cardWidth = isTwoColumn
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;

          final summaryPanel = SizedBox(
            width: isTwoColumn ? constraints.maxWidth : cardWidth,
            child: _StaffOnDutySummaryPanel(
              totalStaffCount: uniqueStaff.length,
              activeFloorCount: activeShifts.length,
              staffingSummary: staffingSummary,
              carerCount: carerCount,
              nurseCount: nurseCount,
              managerCount: managerCount,
            ),
          );

          final rosterPanels = activeShifts
              .map(
                (shift) => SizedBox(
                  width: cardWidth,
                  child: _ShiftStaffRosterCard(shift: shift),
                ),
              )
              .toList(growable: false);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summaryPanel,
              if (rosterPanels.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (!isTwoColumn)
                  for (final panel in rosterPanels) ...[
                    panel,
                    if (panel != rosterPanels.last) const SizedBox(height: 12),
                  ]
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: rosterPanels,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StaffOnDutySummaryPanel extends StatelessWidget {
  const _StaffOnDutySummaryPanel({
    required this.totalStaffCount,
    required this.activeFloorCount,
    required this.staffingSummary,
    required this.carerCount,
    required this.nurseCount,
    required this.managerCount,
  });

  final int totalStaffCount;
  final int activeFloorCount;
  final String staffingSummary;
  final int carerCount;
  final int nurseCount;
  final int managerCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE7F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: managerPrimarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: managerPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Staff on duty',
                  style: TextStyle(
                    color: managerMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            totalStaffCount.toString(),
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            totalStaffCount == 1
                ? 'team member live now'
                : 'team members live now',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            staffingSummary.isEmpty
                ? 'No assigned staff have been published for the live shifts.'
                : staffingSummary,
            style: const TextStyle(color: managerMuted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            activeFloorCount == 1
                ? 'One active floor is currently staffed.'
                : '$activeFloorCount live floors are currently staffed.',
            style: const TextStyle(color: managerMuted, height: 1.5),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StaffOnDutyMetricCard(
                value: activeFloorCount.toString(),
                label: activeFloorCount == 1 ? 'Floor' : 'Floors',
                tone: const _StaffRoleTone(
                  foreground: managerInk,
                  background: managerPanel,
                ),
              ),
              _StaffOnDutyMetricCard(
                value: carerCount.toString(),
                label: carerCount == 1 ? 'Carer' : 'Carers',
                tone: _staffRoleToneFor(ManagerUserRole.carer),
              ),
              _StaffOnDutyMetricCard(
                value: nurseCount.toString(),
                label: nurseCount == 1 ? 'Nurse' : 'Nurses',
                tone: _staffRoleToneFor(ManagerUserRole.nurse),
              ),
              if (managerCount > 0)
                _StaffOnDutyMetricCard(
                  value: managerCount.toString(),
                  label: managerCount == 1 ? 'Manager' : 'Managers',
                  tone: _staffRoleToneFor(ManagerUserRole.manager),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StaffOnDutyMetricCard extends StatelessWidget {
  const _StaffOnDutyMetricCard({
    required this.value,
    required this.label,
    required this.tone,
  });

  final String value;
  final String label;
  final _StaffRoleTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: tone.foreground,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: managerMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftStaffRosterCard extends StatelessWidget {
  const _ShiftStaffRosterCard({required this.shift});

  final ManagerShiftSummary shift;

  @override
  Widget build(BuildContext context) {
    final assignedUsers = [...shift.assignedUsers]
      ..sort((left, right) {
        final roleOrder = _staffRoleSortIndex(
          left.role,
        ).compareTo(_staffRoleSortIndex(right.role));
        if (roleOrder != 0) {
          return roleOrder;
        }
        return left.displayName.compareTo(right.displayName);
      });
    final carerCount = assignedUsers
        .where((member) => member.role == ManagerUserRole.carer)
        .length;
    final nurseCount = assignedUsers
        .where((member) => member.role == ManagerUserRole.nurse)
        .length;
    final managerCount = assignedUsers
        .where((member) => member.role == ManagerUserRole.manager)
        .length;
    final nurses = assignedUsers
        .where((member) => member.role == ManagerUserRole.nurse)
        .toList(growable: false);
    final carers = assignedUsers
        .where((member) => member.role == ManagerUserRole.carer)
        .toList(growable: false);
    final managers = assignedUsers
        .where((member) => member.role == ManagerUserRole.manager)
        .toList(growable: false);

    return Container(
      key: ValueKey('staff-roster-${shift.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: managerBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: managerPrimarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  shift.floorNumber.toString(),
                  style: const TextStyle(
                    color: managerPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.unitLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatTimeOfDay(shift.startsAt)} - ${formatTimeOfDay(shift.endsAt)}',
                      style: const TextStyle(
                        color: managerMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                assignedUsers.length.toString(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: managerBorder),
          const SizedBox(height: 14),
          _StaffRosterLine(
            icon: Icons.local_hospital_outlined,
            label: nurseCount == 1 ? 'Nurse' : 'Nurses',
            members: nurses,
            tone: _staffRoleToneFor(ManagerUserRole.nurse),
          ),
          const SizedBox(height: 12),
          _StaffRosterLine(
            icon: Icons.groups_2_outlined,
            label: carerCount == 1 ? 'Carer' : 'Carers',
            members: carers,
            tone: _staffRoleToneFor(ManagerUserRole.carer),
          ),
          if (managerCount > 0) ...[
            const SizedBox(height: 12),
            _StaffRosterLine(
              icon: Icons.admin_panel_settings_outlined,
              label: managerCount == 1 ? 'Manager' : 'Managers',
              members: managers,
              tone: _staffRoleToneFor(ManagerUserRole.manager),
            ),
          ],
        ],
      ),
    );
  }
}

class _StaffRosterLine extends StatelessWidget {
  const _StaffRosterLine({
    required this.icon,
    required this.label,
    required this.members,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final List<ManagerUser> members;
  final _StaffRoleTone tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: tone.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: tone.foreground),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: managerMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              if (members.isEmpty)
                const Text(
                  'Not assigned',
                  style: TextStyle(
                    color: managerMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: members
                      .map(
                        (member) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _compactStaffName(member.displayName),
                            style: const TextStyle(
                              color: managerInk,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StaffRoleTone {
  const _StaffRoleTone({required this.foreground, required this.background});

  final Color foreground;
  final Color background;
}

_StaffRoleTone _staffRoleToneFor(ManagerUserRole role) {
  return switch (role) {
    ManagerUserRole.carer => const _StaffRoleTone(
      foreground: managerPrimary,
      background: managerPrimarySoft,
    ),
    ManagerUserRole.nurse => const _StaffRoleTone(
      foreground: managerInfo,
      background: managerInfoSoft,
    ),
    ManagerUserRole.manager => const _StaffRoleTone(
      foreground: managerWarning,
      background: managerWarningSoft,
    ),
  };
}

int _staffRoleSortIndex(ManagerUserRole role) {
  return switch (role) {
    ManagerUserRole.nurse => 0,
    ManagerUserRole.carer => 1,
    ManagerUserRole.manager => 2,
  };
}

String _formatStaffRoleCount(ManagerUserRole role, int count) {
  final label = switch (role) {
    ManagerUserRole.carer => 'carer',
    ManagerUserRole.nurse => 'nurse',
    ManagerUserRole.manager => 'manager',
  };

  return '$count $label${count == 1 ? '' : 's'}';
}

String _compactStaffName(String displayName) {
  final parts = displayName.trim().split(RegExp(r'\s+'));
  if (parts.length <= 1) {
    return displayName.trim();
  }

  final firstName = parts.first;
  final lastName = parts.last;
  return '$firstName ${lastName.substring(0, 1)}.';
}

class _MedicationOverviewCard extends StatelessWidget {
  const _MedicationOverviewCard({
    required this.overview,
    required this.activeShifts,
    required this.activeShift,
    required this.onPreviewMedicationAudit,
    required this.onPreviewMedicationRound,
  });

  final ManagerMedicationOverview overview;
  final List<ManagerShiftSummary> activeShifts;
  final ManagerShiftSummary activeShift;
  final VoidCallback onPreviewMedicationAudit;
  final VoidCallback onPreviewMedicationRound;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medication review',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Review missed or varied medication outcomes across active shifts and export the audit trail when needed.',
                      style: TextStyle(color: managerMuted, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (activeShifts.length == 1)
                    OutlinedButton.icon(
                      onPressed: onPreviewMedicationRound,
                      icon: const Icon(Icons.table_chart_outlined),
                      label: Text('Round CSV • ${activeShift.name}'),
                    ),
                  OutlinedButton.icon(
                    onPressed: onPreviewMedicationAudit,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Audit CSV'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MedicationOverviewPill(
                label: 'Overdue',
                value: overview.totals.overdue,
                foreground: managerCritical,
                background: managerCriticalSoft,
              ),
              _MedicationOverviewPill(
                label: 'Refused',
                value: overview.totals.refused,
                foreground: managerWarning,
                background: managerWarningSoft,
              ),
              _MedicationOverviewPill(
                label: 'Omitted',
                value: overview.totals.omitted,
                foreground: managerCritical,
                background: managerCriticalSoft,
              ),
              _MedicationOverviewPill(
                label: 'Delayed',
                value: overview.totals.delayed,
                foreground: managerWarning,
                background: managerWarningSoft,
              ),
              _MedicationOverviewPill(
                label: 'Held',
                value: overview.totals.held,
                foreground: managerWarning,
                background: managerWarningSoft,
              ),
              _MedicationOverviewPill(
                label: 'Not available',
                value: overview.totals.notAvailable,
                foreground: managerCritical,
                background: managerCriticalSoft,
              ),
              _MedicationOverviewPill(
                label: 'Recent PRN',
                value: overview.totals.recentPrnAdministrations,
                foreground: managerInfo,
                background: managerInfoSoft,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (overview.exceptions.isEmpty)
            const EmptySurface(
              title: 'No medication follow-up right now',
              body:
                  'Overdue, refused, omitted, delayed, held, and unavailable outcomes will appear here for follow-up.',
            )
          else
            Column(
              children: [
                for (final item in overview.exceptions.take(5)) ...[
                  _MedicationExceptionRow(exception: item),
                  if (item != overview.exceptions.take(5).last)
                    const Divider(height: 18, color: managerBorder),
                ],
              ],
            ),
          if (overview.recentPrnEvents.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Recent PRN activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (final event in overview.recentPrnEvents.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${event.residentName} • ${event.medicationLabel} • ${formatMedicationEventLabel(event.eventType)} at ${formatManagerDateTime(event.recordedAt)}',
                  style: const TextStyle(color: managerMuted, height: 1.5),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MedicationOverviewPill extends StatelessWidget {
  const _MedicationOverviewPill({
    required this.label,
    required this.value,
    required this.foreground,
    required this.background,
  });

  final String label;
  final int value;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MedicationExceptionRow extends StatelessWidget {
  const _MedicationExceptionRow({required this.exception});

  final ManagerMedicationException exception;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(
            color: managerCritical,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${exception.residentName} • ${exception.roomLabel}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${exception.medicationLabel} • ${formatRoundLabel(exception.roundLabel)} • ${exception.status.toLowerCase().replaceAll('_', ' ')}',
                style: const TextStyle(color: managerMuted),
              ),
              const SizedBox(height: 4),
              Text(
                'Due ${formatManagerDateTime(exception.dueWindowStart)} to ${formatTimeOfDay(exception.dueWindowEnd)}'
                '${(exception.reason ?? '').isEmpty ? '' : ' • ${exception.reason}'}',
                style: const TextStyle(color: managerMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.toneColor,
    required this.toneBackground,
    required this.label,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final Color toneColor;
  final Color toneBackground;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: managerBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: toneBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: toneColor, size: 18),
              ),
              const Spacer(),
              Icon(Icons.arrow_outward_rounded, size: 16, color: toneColor),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: const TextStyle(
              color: managerMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(
              color: managerMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveExceptionFeedCard extends StatelessWidget {
  const _LiveExceptionFeedCard({
    required this.items,
    required this.scopeLabel,
    required this.pendingIncidentIds,
    required this.onAcknowledgeIncident,
    required this.onResolveIncident,
  });

  final List<ManagerExceptionFeedItem> items;
  final String scopeLabel;
  final Set<String> pendingIncidentIds;
  final Future<void> Function(String incidentId, String shiftId)
  onAcknowledgeIncident;
  final Future<void> Function(String incidentId, String shiftId)
  onResolveIncident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  'Current follow-up',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFD),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: managerBorder),
              ),
              child: Text(
                'No incidents, overdue tasks, escalations, or due-soon care actions need follow-up across $scopeLabel right now.',
                style: const TextStyle(color: managerMuted, height: 1.55),
              ),
            )
          else
            Column(
              children: [
                for (final item in items) ...[
                  _ExceptionFeedRow(
                    key: ValueKey('exception-row-${item.id}'),
                    item: item,
                    isActionPending: pendingIncidentIds.contains(item.id),
                    onAcknowledgeIncident: onAcknowledgeIncident,
                    onResolveIncident: onResolveIncident,
                  ),
                  if (item != items.last) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _LiveActivityFeedCard extends StatelessWidget {
  const _LiveActivityFeedCard({required this.items, required this.scopeLabel});

  final List<ManagerActivityFeedItem> items;
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: managerPanel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: managerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent care activity',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFD),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: managerBorder),
              ),
              child: Text(
                'Recent notes, task updates, and incident actions will appear here across $scopeLabel as the shift progresses.',
                style: const TextStyle(color: managerMuted, height: 1.55),
              ),
            )
          else
            Column(
              children: [
                for (final item in items) ...[
                  _ActivityFeedRow(
                    key: ValueKey('activity-row-${item.id}'),
                    item: item,
                  ),
                  if (item != items.last) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ExceptionFeedRow extends StatelessWidget {
  const _ExceptionFeedRow({
    super.key,
    required this.item,
    required this.isActionPending,
    required this.onAcknowledgeIncident,
    required this.onResolveIncident,
  });

  final ManagerExceptionFeedItem item;
  final bool isActionPending;
  final Future<void> Function(String incidentId, String shiftId)
  onAcknowledgeIncident;
  final Future<void> Function(String incidentId, String shiftId)
  onResolveIncident;

  @override
  Widget build(BuildContext context) {
    final tone = _exceptionToneFor(item.badgeTone);
    final kindTone = _feedKindToneFor(item.kind);
    final timeLabel = formatTimeOfDay(item.occurredAt ?? item.dueAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: managerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tone.icon, size: 18, color: tone.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        color: managerMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.residentName} • ${item.locationLabel}',
                  style: const TextStyle(color: managerMuted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: managerInk,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FeedBadge(
                      label: item.kind == ManagerExceptionKind.incident
                          ? 'INCIDENT'
                          : 'TASK',
                      foreground: kindTone.foreground,
                      background: kindTone.background,
                    ),
                    _FeedBadge(
                      label: item.badge,
                      foreground: tone.foreground,
                      background: tone.background,
                    ),
                    _FeedBadge(
                      label: item.status.label.toUpperCase(),
                      foreground: managerMuted,
                      background: const Color(0xFFF0F4F8),
                    ),
                    if (item.isIncident && item.severity != null)
                      _FeedBadge(
                        label: item.severity!.label.toUpperCase(),
                        foreground: item.severity == ManagerIncidentSeverity.red
                            ? managerCritical
                            : managerWarning,
                        background: item.severity == ManagerIncidentSeverity.red
                            ? managerCriticalSoft
                            : managerWarningSoft,
                      ),
                  ],
                ),
                if (item.isIncident &&
                    (item.canAcknowledge || item.canResolve)) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (item.canAcknowledge)
                        OutlinedButton(
                          onPressed: isActionPending
                              ? null
                              : () => onAcknowledgeIncident(
                                  item.id,
                                  item.shiftId,
                                ),
                          child: isActionPending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Acknowledge'),
                        ),
                      if (item.canResolve)
                        FilledButton.tonal(
                          onPressed: isActionPending
                              ? null
                              : () => onResolveIncident(item.id, item.shiftId),
                          style: FilledButton.styleFrom(
                            foregroundColor: managerPrimary,
                            backgroundColor: managerPrimarySoft,
                          ),
                          child: isActionPending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Resolve'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityFeedRow extends StatelessWidget {
  const _ActivityFeedRow({super.key, required this.item});

  final ManagerActivityFeedItem item;

  @override
  Widget build(BuildContext context) {
    final tone = _exceptionToneFor(item.badgeTone);
    final kindTone = _activityKindToneFor(item.kind);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: managerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tone.icon, size: 18, color: tone.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatTimeOfDay(item.occurredAt),
                      style: const TextStyle(
                        color: managerMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.residentName} • ${item.locationLabel}',
                  style: const TextStyle(color: managerMuted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: managerInk,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FeedBadge(
                      label: switch (item.kind) {
                        ManagerActivityKind.note => 'NOTE',
                        ManagerActivityKind.task => 'TASK',
                        ManagerActivityKind.incident => 'INCIDENT',
                      },
                      foreground: kindTone.foreground,
                      background: kindTone.background,
                    ),
                    _FeedBadge(
                      label: item.badge,
                      foreground: tone.foreground,
                      background: tone.background,
                    ),
                    Text(
                      'Updated by ${item.actorName}',
                      style: const TextStyle(
                        color: managerMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedBadge extends StatelessWidget {
  const _FeedBadge({
    required this.label,
    required this.foreground,
    required this.background,
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
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({required this.points});

  final List<ManagerCompliancePoint> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  'Task Compliance %',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const Icon(Icons.timeline_rounded, color: managerMuted),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '100',
                      style: TextStyle(color: managerMuted, fontSize: 11),
                    ),
                    Text(
                      '90',
                      style: TextStyle(color: managerMuted, fontSize: 11),
                    ),
                    Text(
                      '80',
                      style: TextStyle(color: managerMuted, fontSize: 11),
                    ),
                    Text(
                      '70',
                      style: TextStyle(color: managerMuted, fontSize: 11),
                    ),
                    Text(
                      '60',
                      style: TextStyle(color: managerMuted, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          painter: _ComplianceChartPainter(points: points),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final point in points)
                            Text(
                              formatChartLabel(point.timestamp),
                              style: const TextStyle(
                                color: managerMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
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

class _ComplianceChartPainter extends CustomPainter {
  const _ComplianceChartPainter({required this.points});

  final List<ManagerCompliancePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const minValue = 60.0;
    const maxValue = 100.0;

    final gridPaint = Paint()
      ..color = managerBorder
      ..strokeWidth = 1;

    for (var index = 0; index < 5; index++) {
      final y = size.height * (index / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) {
      return;
    }

    final spacing = points.length == 1 ? 0.0 : size.width / (points.length - 1);
    final chartPoints = <Offset>[];

    for (var index = 0; index < points.length; index++) {
      final value = points[index].value.toDouble();
      final normalized = ((value - minValue) / (maxValue - minValue)).clamp(
        0.0,
        1.0,
      );
      final dx = spacing * index;
      final dy = size.height - (normalized * size.height);
      chartPoints.add(Offset(dx, dy));
    }

    final linePath = Path()..moveTo(chartPoints.first.dx, chartPoints.first.dy);
    for (var index = 1; index < chartPoints.length; index++) {
      final previous = chartPoints[index - 1];
      final current = chartPoints[index];
      final controlPoint1 = Offset((previous.dx + current.dx) / 2, previous.dy);
      final controlPoint2 = Offset((previous.dx + current.dx) / 2, current.dy);
      linePath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        current.dx,
        current.dy,
      );
    }

    final areaPath = Path.from(linePath)
      ..lineTo(chartPoints.last.dx, size.height)
      ..lineTo(chartPoints.first.dx, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x554B78FF), Color(0x004B78FF)],
      ).createShader(Offset.zero & size);

    final linePaint = Paint()
      ..color = managerPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(linePath, linePaint);

    final markerPaint = Paint()..color = managerPrimary;
    final markerFillPaint = Paint()..color = Colors.white;
    for (final point in chartPoints) {
      canvas.drawCircle(point, 4.5, markerFillPaint);
      canvas.drawCircle(point, 3.0, markerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ComplianceChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _ExceptionTone {
  const _ExceptionTone({
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final Color foreground;
  final Color background;
  final IconData icon;
}

_ExceptionTone _feedKindToneFor(ManagerExceptionKind kind) {
  switch (kind) {
    case ManagerExceptionKind.incident:
      return const _ExceptionTone(
        foreground: managerPrimary,
        background: managerPrimarySoft,
        icon: Icons.emergency_outlined,
      );
    case ManagerExceptionKind.task:
      return const _ExceptionTone(
        foreground: managerInfo,
        background: managerInfoSoft,
        icon: Icons.checklist_rounded,
      );
  }
}

_ExceptionTone _activityKindToneFor(ManagerActivityKind kind) {
  switch (kind) {
    case ManagerActivityKind.note:
      return const _ExceptionTone(
        foreground: managerInfo,
        background: managerInfoSoft,
        icon: Icons.sticky_note_2_outlined,
      );
    case ManagerActivityKind.task:
      return const _ExceptionTone(
        foreground: managerSuccess,
        background: managerSuccessSoft,
        icon: Icons.task_alt_rounded,
      );
    case ManagerActivityKind.incident:
      return const _ExceptionTone(
        foreground: managerWarning,
        background: managerWarningSoft,
        icon: Icons.health_and_safety_outlined,
      );
  }
}

_ExceptionTone _exceptionToneFor(String tone) {
  switch (tone) {
    case 'critical':
      return const _ExceptionTone(
        foreground: managerCritical,
        background: managerCriticalSoft,
        icon: Icons.warning_amber_rounded,
      );
    case 'warning':
      return const _ExceptionTone(
        foreground: managerWarning,
        background: managerWarningSoft,
        icon: Icons.priority_high_rounded,
      );
    case 'success':
      return const _ExceptionTone(
        foreground: managerSuccess,
        background: managerSuccessSoft,
        icon: Icons.check_circle_outline_rounded,
      );
    case 'info':
    default:
      return const _ExceptionTone(
        foreground: managerInfo,
        background: managerInfoSoft,
        icon: Icons.schedule_rounded,
      );
  }
}
