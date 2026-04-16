import 'package:flutter/material.dart';

import '../models/workspace_models.dart';
import '../theme/app_theme.dart';

class ResidentPriorityBadge extends StatelessWidget {
  const ResidentPriorityBadge({
    super.key,
    required this.priority,
    required this.source,
    this.overrideLabel,
  });

  final ResidentPriorityLevel priority;
  final ResidentPrioritySource source;
  final String? overrideLabel;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (priority) {
      ResidentPriorityLevel.green => AppTheme.successGreen,
      ResidentPriorityLevel.amber => const Color(0xFF9A6700),
      ResidentPriorityLevel.red => AppTheme.errorRed,
    };
    final background = switch (priority) {
      ResidentPriorityLevel.green => AppTheme.successGreen.withAlpha(18),
      ResidentPriorityLevel.amber => AppTheme.warningYellow.withAlpha(36),
      ResidentPriorityLevel.red => AppTheme.errorRed.withAlpha(18),
    };
    final icon = switch (priority) {
      ResidentPriorityLevel.green => Icons.health_and_safety_outlined,
      ResidentPriorityLevel.amber => Icons.priority_high_rounded,
      ResidentPriorityLevel.red => Icons.emergency_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            '${priority.label} priority',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (source == ResidentPrioritySource.incidentOverride) ...[
            const SizedBox(width: 6),
            if (overrideLabel == null)
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: foreground,
                  borderRadius: BorderRadius.circular(999),
                ),
              )
            else
              Text(
                overrideLabel!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
