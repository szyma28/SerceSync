import 'package:flutter/material.dart';
import '../models/shared_models.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final TaskStatus status;
  final bool compact;

  Color get _color {
    switch (status) {
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

  IconData? get _icon {
    switch (status) {
      case TaskStatus.overdue:
        return Icons.timer_off_outlined;
      case TaskStatus.escalated:
        return Icons.warning_amber_rounded;
      case TaskStatus.deferred:
        return Icons.schedule;
      case TaskStatus.completed:
        return Icons.check_circle_outline;
      case TaskStatus.pending:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final icon = _icon;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: color),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            status.apiValue,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
