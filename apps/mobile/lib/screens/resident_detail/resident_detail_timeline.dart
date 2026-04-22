part of '../resident_detail_screen.dart';

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.entry,
    required this.apiClient,
    required this.accessToken,
  });

  final ResidentTimelineEntry entry;
  final SerceSyncApiClient apiClient;
  final String accessToken;

  IconData get _icon {
    switch (entry.type) {
      case ResidentEntryType.observation:
        return Icons.visibility_outlined;
      case ResidentEntryType.personalCare:
        return Icons.shower_outlined;
      case ResidentEntryType.nutritionHydration:
        return Icons.local_drink_outlined;
      case ResidentEntryType.mobilityRepositioning:
        return Icons.accessibility_new_outlined;
      case ResidentEntryType.medicationNote:
        return Icons.medication_outlined;
      case ResidentEntryType.escalation:
        return Icons.trending_up;
      case ResidentEntryType.careGiven:
        return Icons.task_alt_rounded;
    }
  }

  List<Widget> _buildMetadataPills() {
    final pills = <Widget>[];

    if (entry.personalCareSubtype != null) {
      pills.add(
        _TimelineMetaPill(
          icon: Icons.shower_outlined,
          label: entry.personalCareSubtype!.label,
          foreground: AppTheme.primaryBlueDark,
          background: AppTheme.primaryBlueLight,
        ),
      );
    }

    if (entry.mealType != null) {
      pills.add(
        _TimelineMetaPill(
          icon: Icons.restaurant_outlined,
          label: entry.mealType!.label,
          foreground: AppTheme.primaryBlueDark,
          background: AppTheme.primaryBlueLight,
        ),
      );
    }

    if (entry.mealIntakeAmount != null) {
      pills.add(
        _TimelineMetaPill(
          icon: Icons.monitor_heart_outlined,
          label: entry.mealIntakeAmount!.label,
          foreground: const Color(0xFF9A6700),
          background: AppTheme.warningYellow.withAlpha(26),
        ),
      );
    }

    return pills;
  }

  @override
  Widget build(BuildContext context) {
    final metadataPills = _buildMetadataPills();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: AppTheme.primaryBlueDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (metadataPills.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 8, children: metadataPills),
                ],
                const SizedBox(height: 6),
                Text(
                  entry.details,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.38,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${entry.authorName} · ${formatDayMonthHourMinute(entry.timestamp)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
                if (entry.media.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${entry.media.length} attachment${entry.media.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...entry.media.map(
                    (media) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              apiClient.resolveMediaUrl(media.downloadPath),
                              headers: {'Authorization': 'Bearer $accessToken'},
                              fit: BoxFit.cover,
                              height: 160,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: AppTheme.textSecondary,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            media.originalFileName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineMetaPill extends StatelessWidget {
  const _TimelineMetaPill({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
