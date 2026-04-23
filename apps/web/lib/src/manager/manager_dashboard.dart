import 'package:flutter/material.dart';

import 'manager_api_client.dart';
import 'manager_file_download_api.dart';
import 'manager_models.dart';
import 'manager_shared.dart';
import 'manager_theme.dart';

part 'manager_dashboard_sections.dart';

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
      showManagerNotice(context, message: error.message, isError: true);
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
      showManagerNotice(context, message: error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && dashboard == null) {
      return const _DashboardLoadingSkeleton();
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
                        ? 'Nothing open right now'
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
                        : 'Care windows need checking',
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
                        : 'Staff still need to confirm',
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
