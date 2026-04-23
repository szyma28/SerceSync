import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'date_time_formatters.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.lastUpdatedAt,
    this.foreground = AppTheme.primaryBlueDark,
    this.background,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final DateTime? lastUpdatedAt;
  final Color foreground;
  final Color? background;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background ?? AppTheme.primaryBlueLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground.withAlpha(190),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (lastUpdatedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Last updated ${formatDayMonthHourMinute(lastUpdatedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foreground.withAlpha(190),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
