import 'package:flutter/material.dart';

import '../models/workspace_models.dart';
import '../theme/app_theme.dart';

class PriorityCard extends StatelessWidget {
  const PriorityCard({super.key, required this.item, required this.onTap});

  final PriorityItem item;
  final VoidCallback onTap;

  Color get _accentColor {
    switch (item.band) {
      case PriorityBand.urgentNow:
        return AppTheme.errorRed;
      case PriorityBand.dueWithinHour:
        return AppTheme.warningYellow;
      case PriorityBand.reminders:
        return AppTheme.primaryBlue;
    }
  }

  IconData get _icon {
    switch (item.sourceTask?.focus) {
      case TaskFocus.medication:
        return Icons.medication_outlined;
      case TaskFocus.mobility:
        return Icons.accessibility_new_outlined;
      case TaskFocus.observation:
        return Icons.visibility_outlined;
      case TaskFocus.personalCare:
        return Icons.shower_outlined;
      case TaskFocus.hydration:
        return Icons.local_drink_outlined;
      case TaskFocus.general:
      case null:
        return Icons.priority_high_rounded;
    }
  }

  Color get _clinicalPriorityColor {
    switch (item.sourceTask?.clinicalPriority) {
      case TaskClinicalPriority.timeCritical:
        return AppTheme.errorRed;
      case TaskClinicalPriority.priority:
        return AppTheme.warningYellow;
      case TaskClinicalPriority.routine:
      case null:
        return AppTheme.primaryBlueDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withAlpha(70), width: 1.2),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      color: _accentColor.withAlpha(18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_icon, color: _accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.summary,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    icon: Icons.person_pin_circle_outlined,
                    label: '${item.residentName} · ${item.room}',
                  ),
                  _Pill(
                    icon: Icons.schedule,
                    label: item.timeStateLabel,
                    accentColor: _accentColor,
                  ),
                  if (item.sourceTask?.focus != null &&
                      item.sourceTask!.focus != TaskFocus.general)
                    _Pill(
                      icon: _icon,
                      label: item.sourceTask!.focus.label,
                      accentColor: AppTheme.primaryBlueDark,
                    ),
                  if (item.sourceTask?.clinicalPriority != null &&
                      item.sourceTask!.clinicalPriority !=
                          TaskClinicalPriority.routine)
                    _Pill(
                      icon: Icons.priority_high_rounded,
                      label: item.sourceTask!.clinicalPriority.label,
                      accentColor: _clinicalPriorityColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.accentColor});

  final IconData icon;
  final String label;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final foreground = accentColor ?? AppTheme.textPrimary;
    final background = accentColor == null
        ? AppTheme.surfaceBackground
        : accentColor!.withAlpha(18);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withAlpha(18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
