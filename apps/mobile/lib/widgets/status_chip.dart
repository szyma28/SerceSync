import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  Color get _color {
    switch (status.toLowerCase()) {
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

  IconData? get _icon {
    switch (status.toLowerCase()) {
      case 'overdue':
        return Icons.timer_off_outlined;
      case 'escalated':
        return Icons.warning_amber_rounded;
      case 'deferred':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle_outline;
      case 'routine':
      case 'pending':
      default:
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
            status.toUpperCase(),
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
