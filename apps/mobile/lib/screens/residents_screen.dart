import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/workspace_models.dart';
import '../theme/app_theme.dart';
import 'resident_detail_screen.dart';
import '../widgets/resident_priority_badge.dart';
import '../widgets/screen_message_state.dart';

class ResidentsScreen extends StatefulWidget {
  const ResidentsScreen({
    super.key,
    required this.apiClient,
    required this.accessToken,
    required this.currentCarerName,
  });

  final SerceSyncApiClient apiClient;
  final String accessToken;
  final String currentCarerName;

  @override
  State<ResidentsScreen> createState() => ResidentsScreenState();
}

class ResidentsScreenState extends State<ResidentsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ResidentListItem> _residents = const [];

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final residents = await widget.apiClient.getResidents(
        accessToken: widget.accessToken,
      );
      if (!mounted) return;
      setState(() => _residents = residents);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void openResidentById(String residentId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResidentDetailScreen(
          residentId: residentId,
          apiClient: widget.apiClient,
          accessToken: widget.accessToken,
          currentCarerName: widget.currentCarerName,
        ),
      ),
    );
  }

  void _openResident(ResidentListItem resident) {
    openResidentById(resident.id);
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = _residents.isNotEmpty ? _residents.first.unitLabel : null;
    final floorNumber = _residents.isNotEmpty
        ? _residents.first.floorNumber
        : null;

    return Container(
      decoration: AppTheme.atmosphericBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
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
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                )
              : _errorMessage != null && _residents.isEmpty
              ? ScreenMessageState(
                  imageAssetPath: 'assets/images/Resident.png',
                  title: 'Residents couldn\'t be loaded',
                  message: _errorMessage!,
                  actionLabel: 'Try Again',
                  onAction: _loadResidents,
                )
              : _residents.isEmpty
              ? const ScreenMessageState(
                  imageAssetPath: 'assets/images/Resident.png',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.premiumShadow,
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
                        ResidentPriorityBadge(
                          priority: resident.effectivePriority,
                          source: resident.prioritySource,
                        ),
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
                    if (resident.alerts.isNotEmpty) ...[
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
                          resident.alerts.first,
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
