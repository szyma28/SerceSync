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
    final title = item.title.toLowerCase();
    if (title.contains('med')) return Icons.medication_outlined;
    if (title.contains('reposition') || title.contains('mobility')) {
      return Icons.accessibility_new_outlined;
    }
    if (title.contains('observation')) return Icons.visibility_outlined;
    return Icons.priority_high_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accentColor.withAlpha(90), width: 1.4),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      color: _accentColor.withAlpha(18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_icon, color: _accentColor),
                  ),
                  const SizedBox(width: 16),
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
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
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
