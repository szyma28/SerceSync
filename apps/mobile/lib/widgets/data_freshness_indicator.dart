import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'date_time_formatters.dart';

class DataFreshnessIndicator extends StatelessWidget {
  const DataFreshnessIndicator({
    super.key,
    required this.lastUpdatedAt,
    this.isRefreshing = false,
    this.label = 'Live view',
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final DateTime? lastUpdatedAt;
  final bool isRefreshing;
  final String label;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final lastUpdatedAt = this.lastUpdatedAt;
    if (lastUpdatedAt == null && !isRefreshing) {
      return const SizedBox.shrink();
    }

    final foreground = isRefreshing
        ? AppTheme.primaryBlueDark
        : AppTheme.textSecondary;
    final icon = isRefreshing ? Icons.sync_rounded : Icons.schedule_rounded;
    final statusLabel = isRefreshing ? 'Refreshing…' : label;
    final detail = lastUpdatedAt == null
        ? 'Checking for the latest update now.'
        : 'Updated ${formatDayMonthHourMinute(lastUpdatedAt)}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(210),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.surfaceBackground,
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
                  statusLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground.withAlpha(190),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isRefreshing)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryBlue,
              ),
            ),
        ],
      ),
    );
  }
}
