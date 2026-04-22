import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/shift_workspace_controller.dart';
import '../models/workspace_models.dart';
import '../screens/resident_detail_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/priority_card.dart';
import '../widgets/screen_message_state.dart';
import 'medication_round_screen.dart';

class PrioritiesScreen extends StatefulWidget {
  const PrioritiesScreen({super.key});

  @override
  State<PrioritiesScreen> createState() => _PrioritiesScreenState();
}

class _PrioritiesScreenState extends State<PrioritiesScreen> {
  ShiftWorkspaceController get _workspaceController =>
      context.read<ShiftWorkspaceController>();

  Future<void> _loadPriorities() {
    return _workspaceController.refreshPriorities();
  }

  List<PriorityItem> _buildPriorityItems(ShiftWorkspaceController controller) {
    final now = DateTime.now();
    final visibleTasks = controller.currentUserRole == AppUserRole.nurse
        ? controller.tasks
              .where((task) => task.focus != TaskFocus.medication)
              .toList()
        : controller.tasks;
    final items = visibleTasks
        .map((task) => PriorityItem.fromTask(task, now))
        .toList();

    if (controller.currentUserRole == AppUserRole.nurse) {
      items.addAll(_buildMedicationPriorityItems(controller, now));
    }

    items.sort((left, right) {
      final bandDelta =
          _priorityBandSortOrder(left.band) -
          _priorityBandSortOrder(right.band);
      if (bandDelta != 0) {
        return bandDelta;
      }

      final leftDueAt =
          left.sourceTask?.dueAt?.millisecondsSinceEpoch ?? 1 << 62;
      final rightDueAt =
          right.sourceTask?.dueAt?.millisecondsSinceEpoch ?? 1 << 62;

      if (leftDueAt != rightDueAt) {
        return leftDueAt.compareTo(rightDueAt);
      }

      return left.title.compareTo(right.title);
    });

    return items;
  }

  int _priorityBandSortOrder(PriorityBand band) {
    switch (band) {
      case PriorityBand.urgentNow:
        return 0;
      case PriorityBand.dueWithinHour:
        return 1;
      case PriorityBand.reminders:
        return 2;
    }
  }

  List<PriorityItem> _buildMedicationPriorityItems(
    ShiftWorkspaceController controller,
    DateTime now,
  ) {
    final summaries =
        controller.overview?.medicationOperationalSummary?.residents ??
        const [];

    return summaries
        .where((summary) => summary.hasSignal)
        .map(
          (summary) => PriorityItem.fromMedicationResidentSummary(summary, now),
        )
        .toList();
  }

  Future<void> _openPriorityItem(PriorityItem item) async {
    if (item.opensMedicationRound) {
      await _openMedicationRound();
      return;
    }

    if (item.residentId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This priority is not linked to a resident.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResidentDetailScreen(
          residentId: item.residentId!,
          apiClient: _workspaceController.apiClient,
          accessToken: _workspaceController.accessToken,
          currentCarerName: _workspaceController.currentCarerName,
          currentUserRole: _workspaceController.currentUserRole,
          highlightTaskId: item.sourceTask?.id,
        ),
      ),
    );

    if (!mounted) return;
    await _loadPriorities();
  }

  Future<void> _openMedicationRound() async {
    if (!_workspaceController.handoverAcknowledged) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Acknowledge the current handover before opening the shift medication round.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MedicationRoundScreen(
          apiClient: _workspaceController.apiClient,
          accessToken: _workspaceController.accessToken,
          shiftId: _workspaceController.shiftId,
        ),
      ),
    );

    if (!mounted) return;
    await _loadPriorities();
  }

  @override
  Widget build(BuildContext context) {
    final workspaceController = context.watch<ShiftWorkspaceController>();
    final priorities = _buildPriorityItems(workspaceController);
    final medicationSummary =
        workspaceController.overview?.medicationSummary ??
        const MedicationTaskSummary();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 74,
        title: Column(
          children: [
            Text(
              'Priorities',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              workspaceController.shiftName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: workspaceController.isPrioritiesLoading
                ? null
                : _loadPriorities,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child:
            workspaceController.isPrioritiesLoading &&
                workspaceController.tasks.isEmpty &&
                workspaceController.overview == null
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              )
            : workspaceController.prioritiesErrorMessage != null &&
                  workspaceController.tasks.isEmpty &&
                  workspaceController.overview == null
            ? ScreenMessageState(
                imageAssetPath: 'assets/images/404error_transparent.png',
                imageHeight: 200,
                title: 'Couldn\'t load priorities',
                titleStyle: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: AppTheme.errorRed),
                message: workspaceController.prioritiesErrorMessage!,
                onAction: _loadPriorities,
                actionLabel: 'Try Again',
              )
            : RefreshIndicator(
                onRefresh: _loadPriorities,
                color: AppTheme.primaryBlue,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 112),
                  children: [
                    if (workspaceController.currentUserRole ==
                        AppUserRole.nurse) ...[
                      _MedicationRoundQuickAccessCard(
                        shiftName: workspaceController.shiftName,
                        handoverAcknowledged:
                            workspaceController.handoverAcknowledged,
                        summary: medicationSummary,
                        onOpenMedicationRound: _openMedicationRound,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _PriorityBandSection(
                      title: 'Urgent',
                      items: priorities
                          .where((item) => item.band == PriorityBand.urgentNow)
                          .toList(),
                      onTap: _openPriorityItem,
                      emptyTitle: 'Nothing urgent right now.',
                    ),
                    const SizedBox(height: 16),
                    _PriorityBandSection(
                      title: 'Next hour',
                      items: priorities
                          .where(
                            (item) => item.band == PriorityBand.dueWithinHour,
                          )
                          .toList(),
                      onTap: _openPriorityItem,
                      emptyTitle: 'Nothing due in the next hour.',
                    ),
                    const SizedBox(height: 16),
                    _PriorityBandSection(
                      title: 'Later this shift',
                      items: priorities
                          .where((item) => item.band == PriorityBand.reminders)
                          .toList(),
                      onTap: _openPriorityItem,
                      emptyTitle: 'Nothing else is due this shift.',
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PriorityBandSection extends StatelessWidget {
  const _PriorityBandSection({
    required this.title,
    required this.items,
    required this.onTap,
    this.emptyTitle,
  });

  final String title;
  final List<PriorityItem> items;
  final ValueChanged<PriorityItem> onTap;
  final String? emptyTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Text(
              emptyTitle ?? 'Nothing here right now.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          )
        else
          ...items.map(
            (item) => PriorityCard(item: item, onTap: () => onTap(item)),
          ),
      ],
    );
  }
}

class _MedicationRoundQuickAccessCard extends StatelessWidget {
  const _MedicationRoundQuickAccessCard({
    required this.shiftName,
    required this.handoverAcknowledged,
    required this.summary,
    required this.onOpenMedicationRound,
  });

  final String shiftName;
  final bool handoverAcknowledged;
  final MedicationTaskSummary summary;
  final VoidCallback onOpenMedicationRound;

  @override
  Widget build(BuildContext context) {
    final accentColor = handoverAcknowledged
        ? AppTheme.primaryBlueDark
        : const Color(0xFF9A6700);
    final helperText = !handoverAcknowledged
        ? 'Acknowledge the current handover before opening the shift-wide medication round.'
        : summary.hasActiveMedicationTasks
        ? summary.headline ??
              'Use priorities to jump into the shift medication round before anything drifts overdue.'
        : 'No medication priorities are active right now, but you can still open the full shift round from here.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withAlpha(36)),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.medication_liquid_outlined,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shift medication round',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryBlueDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shiftName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MedicationRoundStatPill(
                label: 'Medication priorities',
                value: summary.total.toString(),
              ),
              _MedicationRoundStatPill(
                label: 'Urgent',
                value: summary.overdue.toString(),
                accentColor: AppTheme.errorRed,
              ),
              _MedicationRoundStatPill(
                label: 'Next hour',
                value: summary.dueWithinHour.toString(),
                accentColor: AppTheme.warningYellow,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            helperText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: handoverAcknowledged
                  ? AppTheme.textSecondary
                  : const Color(0xFF9A6700),
              height: 1.4,
              fontWeight: handoverAcknowledged
                  ? FontWeight.w500
                  : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: handoverAcknowledged ? onOpenMedicationRound : null,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open shift medication round'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationRoundStatPill extends StatelessWidget {
  const _MedicationRoundStatPill({
    required this.label,
    required this.value,
    this.accentColor,
  });

  final String label;
  final String value;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final foreground = accentColor ?? AppTheme.primaryBlueDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: foreground.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withAlpha(22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
