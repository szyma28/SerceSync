part of '../resident_detail_screen.dart';

class _ResidentHeader extends StatelessWidget {
  const _ResidentHeader({required this.resident});

  final ResidentDetail resident;

  String get _aboutMeText {
    return resident.aboutMe.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  resident.photoAssetPath,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resident.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlueLight.withAlpha(80),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        resident.roomLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primaryBlueDark,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_stories_outlined,
                      color: AppTheme.primaryBlueDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'About me',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryBlueDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _aboutMeText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResidentActionDock extends StatelessWidget {
  const _ResidentActionDock({
    required this.isSaving,
    required this.noteSaveConfirmed,
    required this.onAddNote,
    required this.onReportIncident,
  });

  final bool isSaving;
  final bool noteSaveConfirmed;
  final VoidCallback? onAddNote;
  final VoidCallback? onReportIncident;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(244),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: AppTheme.premiumShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReportIncident,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    side: BorderSide(
                      color: AppTheme.errorRed.withAlpha(70),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.emergency_outlined),
                  label: Text(isSaving ? 'Saving…' : 'Report incident'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddNote,
                  style: FilledButton.styleFrom(
                    backgroundColor: noteSaveConfirmed
                        ? AppTheme.successGreen
                        : AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isSaving
                        ? const SizedBox(
                            key: ValueKey('saving-note'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            noteSaveConfirmed
                                ? Icons.check_circle_rounded
                                : Icons.edit_note_rounded,
                            key: ValueKey(noteSaveConfirmed),
                          ),
                  ),
                  label: Text(
                    isSaving
                        ? 'Saving…'
                        : noteSaveConfirmed
                        ? 'Saved'
                        : 'Add note',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveIncidentSummaryCard extends StatelessWidget {
  const _ActiveIncidentSummaryCard({required this.incidents});

  final List<ResidentIncident> incidents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(224),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorRed.withAlpha(12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Active incident summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${incidents.length} active incident${incidents.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryBlueDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'These incidents are currently driving the live priority signal for this resident.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          ...incidents.map(
            (incident) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IncidentSummaryRow(incident: incident),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentSummaryRow extends StatelessWidget {
  const _IncidentSummaryRow({required this.incident});

  final ResidentIncident incident;

  @override
  Widget build(BuildContext context) {
    final foreground = incident.severity == IncidentSeverity.red
        ? AppTheme.errorRed
        : const Color(0xFF9A6700);
    final background = incident.severity == IncidentSeverity.red
        ? AppTheme.errorRed.withAlpha(14)
        : AppTheme.warningYellow.withAlpha(28);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(170),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  incident.severity.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(170),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  incident.status.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                incident.categoryLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            incident.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            incident.details,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Raised by ${incident.createdByName} · ${formatDayMonthHourMinute(incident.occurredAt)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryBlueDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (incident.evidence.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${incident.evidence.length} evidence file${incident.evidence.length == 1 ? '' : 's'} attached',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
