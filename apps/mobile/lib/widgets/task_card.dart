import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import 'status_chip.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.onTap});

  final ShiftTask task;
  final VoidCallback? onTap;

  Color get _borderColor {
    switch (task.status.toLowerCase()) {
      case 'overdue':
      case 'escalated':
        return AppTheme.errorRed;
      case 'deferred':
        return AppTheme.warningYellow;
      case 'completed':
        return AppTheme.successGreen;
      case 'routine':
      case 'pending':
      default:
        return AppTheme.primaryBlue;
    }
  }

  bool get _isMeds =>
      task.title.toLowerCase().contains('med') ||
      task.title.toLowerCase().contains('pill');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(
          color: task.status.toLowerCase() == 'completed'
              ? AppTheme.borderLight
              : _borderColor.withAlpha(80),
          width: 1.5,
        ),
      ),
      clipBehavior:
          Clip.antiAlias, // To clip the inkwell and potential watermark
      child: Stack(
        children: [
          if (_isMeds)
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
                  // Status icon or indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _borderColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      task.status.toLowerCase() == 'completed'
                          ? Icons.task_alt_rounded
                          : _isMeds
                          ? Icons.medical_services_outlined
                          : Icons.assignment_outlined,
                      color: _borderColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Task details
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
                                    '${task.dueAt!.hour.toString().padLeft(2, '0')}:${task.dueAt!.minute.toString().padLeft(2, '0')}',
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
