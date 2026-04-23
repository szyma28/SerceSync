import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/mobile_session_controller.dart';
import '../models/workspace_models.dart';
import '../theme/app_theme.dart';
import '../widgets/data_freshness_indicator.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/resume_refresh_mixin.dart';
import '../widgets/screen_message_state.dart';
import '../widgets/status_banner.dart';
import 'resident_detail_screen.dart';

class ResidentsScreen extends StatefulWidget {
  const ResidentsScreen({super.key});

  @override
  State<ResidentsScreen> createState() => ResidentsScreenState();
}

class ResidentsScreenState extends State<ResidentsScreen>
    with WidgetsBindingObserver, ResumeRefreshStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<ResidentListItem> _residents = const [];
  DateTime? _lastUpdatedAt;
  bool _showingCachedData = false;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    final sessionController = context.read<MobileSessionController>();
    final session = await sessionController.resolveSession(
      refreshIfNeeded: true,
    );
    if (session == null) {
      return;
    }

    final workspaceRepository = sessionController.workspaceRepository;
    final cachedResidents = await workspaceRepository.readCachedResidents(
      session,
    );
    if (cachedResidents != null && mounted) {
      setState(() {
        _residents = cachedResidents.data;
        _lastUpdatedAt = cachedResidents.fetchedAt;
        _showingCachedData = true;
        _errorMessage = null;
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final refreshedResidents = await workspaceRepository.refreshResidents(
        session,
      );
      if (!mounted) return;
      setState(() {
        _residents = refreshedResidents.data;
        _lastUpdatedAt = refreshedResidents.fetchedAt;
        _showingCachedData = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void openResidentById(String residentId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResidentDetailScreen(residentId: residentId),
      ),
    );
  }

  void _openResident(ResidentListItem resident) {
    openResidentById(resident.id);
  }

  @override
  bool get canTriggerResumeRefresh =>
      context.read<MobileSessionController>().hasActiveSession;

  @override
  bool get hasVisibleContentForResumeRefresh => _residents.isNotEmpty;

  @override
  Future<void> refreshAfterResume() => _loadResidents();

  @override
  Widget build(BuildContext context) {
    final unitLabel = _residents.isNotEmpty ? _residents.first.unitLabel : null;
    final floorNumber = _residents.isNotEmpty
        ? _residents.first.floorNumber
        : null;
    final showStatusBanner = _showingCachedData || _errorMessage != null;
    final freshnessIndicator = !showStatusBanner && _residents.isNotEmpty
        ? DataFreshnessIndicator(
            lastUpdatedAt: _lastUpdatedAt,
            isRefreshing: _isLoading,
            label: 'Resident list is live',
          )
        : const SizedBox.shrink();

    return Container(
      decoration: AppTheme.atmosphericBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Residents',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          actions: [
            IconButton(
              onPressed: _isLoading ? null : _loadResidents,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading && _residents.isEmpty
              ? const _ResidentsLoadingSkeleton()
              : _errorMessage != null && _residents.isEmpty
              ? ScreenMessageState(
                  imageAssetPath: 'assets/images/resident_profile_01.png',
                  title: 'Residents couldn\'t be loaded',
                  message: _errorMessage!,
                  actionLabel: 'Try Again',
                  onAction: _loadResidents,
                )
              : _residents.isEmpty
              ? const ScreenMessageState(
                  imageAssetPath: 'assets/images/resident_profile_01.png',
                  title: 'No residents assigned',
                  message:
                      'Residents will appear here when the shift is active.',
                )
              : RefreshIndicator(
                  onRefresh: _loadResidents,
                  color: AppTheme.primaryBlue,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 112),
                    children: [
                      if (showStatusBanner)
                        StatusBanner(
                          icon: _errorMessage == null
                              ? Icons.cloud_off_outlined
                              : Icons.wifi_tethering_error_rounded,
                          title: _errorMessage == null
                              ? 'Showing cached residents'
                              : 'Using cached residents',
                          message:
                              _errorMessage ??
                              'This list will refresh when the connection comes back.',
                          lastUpdatedAt: _lastUpdatedAt,
                          actionLabel: 'Retry',
                          onAction: _isLoading ? null : _loadResidents,
                        ),
                      freshnessIndicator,
                      _ResidentsScopeCard(
                        residentCount: _residents.length,
                        unitLabel: unitLabel ?? 'Assigned floor',
                        floorNumber: floorNumber ?? 1,
                      ),
                      const SizedBox(height: 16),
                      ..._residents.map(
                        (resident) => _ResidentListCard(
                          resident: resident,
                          onTap: () => _openResident(resident),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _ResidentsLoadingSkeleton extends StatelessWidget {
  const _ResidentsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 112),
      children: const [
        SkeletonCard(
          child: Row(
            children: [
              SkeletonBlock(height: 42, width: 42, radius: 12),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(height: 18, width: 120, radius: 10),
                    SizedBox(height: 8),
                    SkeletonBlock(height: 14, width: 180, radius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
        SkeletonCard(
          child: Row(
            children: [
              SkeletonAvatar(),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(height: 16, width: 140, radius: 10),
                    SizedBox(height: 8),
                    SkeletonBlock(height: 14, width: 200, radius: 10),
                    SizedBox(height: 8),
                    SkeletonBlock(height: 12, width: 120, radius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
        SkeletonCard(
          child: Row(
            children: [
              SkeletonAvatar(),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBlock(height: 16, width: 132, radius: 10),
                    SizedBox(height: 8),
                    SkeletonBlock(height: 14, width: 180, radius: 10),
                    SizedBox(height: 8),
                    SkeletonBlock(height: 12, width: 110, radius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResidentsScopeCard extends StatelessWidget {
  const _ResidentsScopeCard({
    required this.residentCount,
    required this.unitLabel,
    required this.floorNumber,
  });

  final int residentCount;
  final String unitLabel;
  final int floorNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(225),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlueDark.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: AppTheme.primaryBlueDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$residentCount ${residentCount == 1 ? 'resident' : 'residents'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '$unitLabel · Floor $floorNumber',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
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

class _ResidentListCard extends StatelessWidget {
  const _ResidentListCard({required this.resident, required this.onTap});

  final ResidentListItem resident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _residentCardToneFor(resident.effectivePriority);
    final showPriorityHue =
        resident.effectivePriority != ResidentPriorityLevel.green;
    final visibleAlert = _residentListAlertText(resident.alerts);

    return Container(
      key: ValueKey(
        'resident-card-${resident.id}-${resident.effectivePriority.apiValue}',
      ),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: showPriorityHue ? tone.background : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: showPriorityHue ? tone.border : AppTheme.borderLight,
          width: showPriorityHue ? 1.5 : 1,
        ),
        boxShadow: showPriorityHue ? tone.shadow : AppTheme.premiumShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  resident.photoAssetPath,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resident.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resident.roomLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryBlueDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (resident.activeIncidentCount > 0)
                          _ResidentIncidentCountPill(
                            count: resident.activeIncidentCount,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      resident.contextLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    if (visibleAlert != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Text(
                          visibleAlert,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _residentListAlertText(List<String> alerts) {
  for (final alert in alerts) {
    final normalizedAlert = alert.trim().toLowerCase();
    if (normalizedAlert == 'due this shift') {
      continue;
    }
    return alert;
  }
  return null;
}

class _ResidentCardTone {
  const _ResidentCardTone({
    required this.background,
    required this.border,
    required this.shadow,
  });

  final Color background;
  final Color border;
  final List<BoxShadow> shadow;
}

_ResidentCardTone _residentCardToneFor(ResidentPriorityLevel priority) {
  switch (priority) {
    case ResidentPriorityLevel.red:
      return _ResidentCardTone(
        background: Color.alphaBlend(
          AppTheme.errorRed.withAlpha(20),
          AppTheme.surfaceCard,
        ),
        border: AppTheme.errorRed.withAlpha(110),
        shadow: [
          BoxShadow(
            color: AppTheme.errorRed.withAlpha(20),
            blurRadius: 26,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.errorRed.withAlpha(10),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      );
    case ResidentPriorityLevel.amber:
      return _ResidentCardTone(
        background: Color.alphaBlend(
          AppTheme.warningYellow.withAlpha(20),
          AppTheme.surfaceCard,
        ),
        border: AppTheme.warningYellow.withAlpha(130),
        shadow: [
          BoxShadow(
            color: AppTheme.warningYellow.withAlpha(22),
            blurRadius: 26,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.warningYellow.withAlpha(12),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      );
    case ResidentPriorityLevel.green:
      return const _ResidentCardTone(
        background: AppTheme.surfaceCard,
        border: AppTheme.borderLight,
        shadow: [],
      );
  }
}

class _ResidentIncidentCountPill extends StatelessWidget {
  const _ResidentIncidentCountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Text(
        '$count active incident${count == 1 ? '' : 's'}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.primaryBlueDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
