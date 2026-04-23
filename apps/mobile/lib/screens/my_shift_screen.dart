import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/mobile_session_controller.dart';
import '../controllers/shift_workspace_controller.dart';
import '../models/workspace_models.dart';
import '../theme/app_theme.dart';
import '../widgets/data_freshness_indicator.dart';
import '../widgets/date_time_formatters.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/status_banner.dart';

class MyShiftScreen extends StatelessWidget {
  const MyShiftScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final workspaceController = context.watch<ShiftWorkspaceController>();
    final sessionController = context.watch<MobileSessionController>();
    final currentShift = workspaceController.currentShift;
    final snapshot = workspaceController.snapshot;
    final showStatusBanner =
        workspaceController.showingCachedOverviewData ||
        workspaceController.overviewErrorMessage != null;
    final freshnessIndicator =
        !showStatusBanner &&
            (workspaceController.overviewLastUpdatedAt != null ||
                currentShift != null ||
                snapshot != null)
        ? DataFreshnessIndicator(
            lastUpdatedAt: workspaceController.overviewLastUpdatedAt,
            isRefreshing: workspaceController.isOverviewLoading,
            label: 'Live shift overview',
          )
        : const SizedBox.shrink();

    if (workspaceController.isOverviewLoading &&
        currentShift == null &&
        snapshot == null &&
        workspaceController.overview == null) {
      return Container(
        decoration: AppTheme.atmosphericBackground,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'My Shift',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          body: const SafeArea(child: _MyShiftLoadingSkeleton()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'My Shift',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          IconButton(
            onPressed: workspaceController.isOverviewLoading
                ? null
                : () => context
                      .read<ShiftWorkspaceController>()
                      .refreshOverview(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              context.read<ShiftWorkspaceController>().refreshOverview(),
          color: AppTheme.primaryBlue,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
            children: [
              if (showStatusBanner)
                StatusBanner(
                  icon: workspaceController.overviewErrorMessage == null
                      ? Icons.cloud_off_outlined
                      : Icons.wifi_tethering_error_rounded,
                  title: workspaceController.overviewErrorMessage == null
                      ? 'Showing cached shift overview'
                      : 'Using cached shift overview',
                  message:
                      workspaceController.overviewErrorMessage ??
                      'Shift details will refresh when the connection comes back.',
                  lastUpdatedAt: workspaceController.overviewLastUpdatedAt,
                  actionLabel: 'Retry',
                  onAction: () => context
                      .read<ShiftWorkspaceController>()
                      .refreshOverview(),
                ),
              freshnessIndicator,
              if (sessionController.syncSummary.hasPendingWork)
                StatusBanner(
                  icon: sessionController.syncSummary.hasFailures
                      ? Icons.sync_problem_rounded
                      : Icons.sync_rounded,
                  title: sessionController.syncSummary.headline,
                  message:
                      'Saved notes and incidents from this device are still waiting to sync.',
                  actionLabel: sessionController.syncSummary.hasFailures
                      ? 'Retry'
                      : null,
                  onAction: sessionController.syncSummary.hasFailures
                      ? () =>
                            sessionController.syncService.retryFailedMutations()
                      : null,
                ),
              _SectionCard(
                title: 'Current Shift',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Carer',
                      value: workspaceController.currentCarerName,
                    ),
                    _InfoRow(
                      label: 'Role',
                      value: workspaceController.currentUserRole.label,
                    ),
                    _InfoRow(
                      label: 'Assignment',
                      value: currentShift != null
                          ? '${currentShift.unitLabel} · Floor ${currentShift.floorNumber}'
                          : snapshot != null
                          ? '${snapshot.shift.unitLabel} · Floor ${snapshot.shift.floorNumber}'
                          : 'Awaiting shift assignment',
                    ),
                    _InfoRow(
                      label: 'Shift',
                      value: currentShift != null
                          ? formatHourMinuteRange(
                              currentShift.startsAt,
                              currentShift.endsAt,
                            )
                          : snapshot != null
                          ? formatHourMinuteRange(
                              snapshot.shift.startsAt,
                              snapshot.shift.endsAt,
                            )
                          : 'Shift time not loaded yet',
                    ),
                    _InfoRow(
                      label: 'Handover',
                      value: _handoverValue(workspaceController, currentShift),
                    ),
                  ],
                ),
              ),
              if (workspaceController.currentUserRole == AppUserRole.nurse) ...[
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Medication Safety',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MedicationSummaryPanel(
                        summary:
                            workspaceController.overview?.medicationSummary ??
                            const MedicationTaskSummary(),
                        isLoading:
                            workspaceController.isOverviewLoading &&
                            workspaceController.overview == null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Use Priorities to open the shift medication round and see what needs recording now.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Settings',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline_rounded),
                      title: const Text('Privacy and device'),
                      subtitle: const Text(
                        'Notifications, privacy, and device access.',
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings are not available yet.'),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: AppTheme.errorRed,
                      ),
                      title: const Text('Log Out'),
                      subtitle: const Text('Back to sign in.'),
                      onTap: onLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _handoverValue(
    ShiftWorkspaceController workspaceController,
    ShiftAssignment? currentShift,
  ) {
    if (currentShift != null) {
      if (currentShift.handoverAcknowledged) {
        return 'Acknowledged at ${formatHourMinute(currentShift.handoverAcknowledgedAt ?? currentShift.startsAt)}';
      }
      return 'Pending acknowledgement';
    }

    final snapshot = workspaceController.snapshot;
    if (snapshot == null) {
      return 'Pending acknowledgement';
    }

    return snapshot.acknowledged
        ? 'Acknowledged at ${formatHourMinute(snapshot.acknowledgedAt ?? snapshot.shift.startsAt)}'
        : 'Pending acknowledgement';
  }
}

class _MedicationSummaryPanel extends StatelessWidget {
  const _MedicationSummaryPanel({
    required this.summary,
    required this.isLoading,
  });

  final MedicationTaskSummary summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(height: 18, width: 190, radius: 10),
            SizedBox(height: 12),
            SkeletonBlock(height: 48, width: double.infinity, radius: 16),
            SizedBox(height: 10),
            SkeletonBlock(height: 48, width: double.infinity, radius: 16),
          ],
        ),
      );
    }

    if (!summary.hasActiveMedicationTasks) {
      return Text(
        'No active medication tasks on this shift right now.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          summary.headline ?? 'Medication tasks need active monitoring.',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppTheme.primaryBlueDark),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MedicationMetricChip(
              label: 'Open meds',
              value: summary.total,
              foreground: AppTheme.primaryBlueDark,
              background: AppTheme.primaryBlueLight,
            ),
            _MedicationMetricChip(
              label: 'Overdue',
              value: summary.overdue,
              foreground: AppTheme.errorRed,
              background: AppTheme.errorRed.withAlpha(14),
            ),
            _MedicationMetricChip(
              label: 'Next hour',
              value: summary.dueWithinHour,
              foreground: const Color(0xFF9A6700),
              background: AppTheme.warningYellow.withAlpha(26),
            ),
            _MedicationMetricChip(
              label: 'High priority',
              value: summary.highPriority,
              foreground: AppTheme.errorRed,
              background: AppTheme.errorRed.withAlpha(10),
            ),
          ],
        ),
        if (summary.warnings.isNotEmpty) ...[
          const SizedBox(height: 14),
          ...summary.warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppTheme.errorRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MyShiftLoadingSkeleton extends StatelessWidget {
  const _MyShiftLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
      children: const [
        SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(height: 20, width: 120, radius: 12),
              SizedBox(height: 16),
              SkeletonBlock(height: 14, width: double.infinity, radius: 10),
              SizedBox(height: 10),
              SkeletonBlock(height: 14, width: 230, radius: 10),
              SizedBox(height: 10),
              SkeletonBlock(height: 14, width: 210, radius: 10),
              SizedBox(height: 10),
              SkeletonBlock(height: 14, width: 180, radius: 10),
            ],
          ),
        ),
        SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(height: 20, width: 150, radius: 12),
              SizedBox(height: 16),
              SkeletonBlock(height: 18, width: 170, radius: 10),
              SizedBox(height: 12),
              SkeletonBlock(height: 48, width: double.infinity, radius: 16),
              SizedBox(height: 10),
              SkeletonBlock(height: 48, width: double.infinity, radius: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _MedicationMetricChip extends StatelessWidget {
  const _MedicationMetricChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
