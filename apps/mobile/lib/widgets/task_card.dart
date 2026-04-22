import 'package:flutter/material.dart';
import '../models/shared_models.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import 'date_time_formatters.dart';
import 'status_chip.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap});

  final ShiftTask task;
  final VoidCallback? onTap;

  Color get _borderColor {
    switch (task.status) {
      case TaskStatus.overdue:
      case TaskStatus.escalated:
        return AppTheme.errorRed;
      case TaskStatus.deferred:
        return AppTheme.warningYellow;
      case TaskStatus.completed:
        return AppTheme.successGreen;
      case TaskStatus.pending:
        return AppTheme.primaryBlue;
    }
  }

  bool get _isMedicationTask => task.focus == TaskFocus.medication;

  IconData get _taskIcon {
    switch (task.focus) {
      case TaskFocus.medication:
        return Icons.medical_services_outlined;
      case TaskFocus.observation:
        return Icons.visibility_outlined;
      case TaskFocus.hydration:
        return Icons.local_drink_outlined;
      case TaskFocus.personalCare:
        return Icons.shower_outlined;
      case TaskFocus.mobility:
        return Icons.accessibility_new_outlined;
      case TaskFocus.general:
        return task.status == TaskStatus.completed
            ? Icons.task_alt_rounded
            : Icons.assignment_outlined;
    }
  }

  Color get _clinicalPriorityColor {
    switch (task.clinicalPriority) {
      case TaskClinicalPriority.timeCritical:
        return AppTheme.errorRed;
      case TaskClinicalPriority.priority:
        return AppTheme.warningYellow;
      case TaskClinicalPriority.routine:
        return AppTheme.primaryBlueDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(
          color: task.status == TaskStatus.completed
              ? AppTheme.borderLight
              : _borderColor.withAlpha(80),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_isMedicationTask)
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/images/Medication.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),

          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _borderColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_taskIcon, color: _borderColor, size: 24),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (task.dueAt != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formatHourMinute(task.dueAt!),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              )
                            else
                              const SizedBox.shrink(),

                            StatusChip(status: task.status, compact: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          task.title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 18),
                        ),
                        if (task.focus != TaskFocus.general ||
                            task.clinicalPriority !=
                                TaskClinicalPriority.routine) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (task.focus != TaskFocus.general)
                                _TaskMetaPill(
                                  icon: _taskIcon,
                                  label: task.focus.label,
                                  foregroundColor: AppTheme.primaryBlueDark,
                                  backgroundColor: AppTheme.primaryBlueLight,
                                ),
                              if (task.clinicalPriority !=
                                  TaskClinicalPriority.routine)
                                _TaskMetaPill(
                                  icon: Icons.priority_high_rounded,
                                  label: task.clinicalPriority.label,
                                  foregroundColor: _clinicalPriorityColor,
                                  backgroundColor: _clinicalPriorityColor
                                      .withAlpha(18),
                                ),
                            ],
                          ),
                        ],
                        if (task.residentName != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_pin_circle_outlined,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${task.residentName} ${task.room != null ? '• ${task.room}' : ''}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (task.note != null && task.note!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            task.note!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (task.actionRestrictionReason != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    task.actionRestrictionReason!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskMetaPill extends StatelessWidget {
  const _TaskMetaPill({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
