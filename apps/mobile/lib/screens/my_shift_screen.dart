import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/handover.dart';
import '../models/user.dart';
import '../models/workspace_models.dart';
import '../theme/app_theme.dart';

class MyShiftScreen extends StatefulWidget {
  const MyShiftScreen({
    super.key,
    required this.user,
    required this.snapshot,
    required this.apiClient,
    required this.accessToken,
    required this.onLogout,
  });

  final LoginUser user;
  final HandoverSnapshot snapshot;
  final SerceSyncApiClient apiClient;
  final String accessToken;
  final VoidCallback onLogout;

  @override
  State<MyShiftScreen> createState() => _MyShiftScreenState();
}

class _MyShiftScreenState extends State<MyShiftScreen> {
  ShiftOverview? _overview;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShiftOverview();
  }

  Future<void> _loadShiftOverview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final overview = await widget.apiClient.getShiftOverview(
        accessToken: widget.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load shift assignments.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentShift = _overview?.currentShift;
    final assignments = _overview?.assignments ?? const <ShiftAssignment>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'My Shift',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadShiftOverview,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadShiftOverview,
          color: AppTheme.primaryBlue,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              _SectionCard(
                title: 'Current Shift',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Carer', value: widget.user.displayName),
                    _InfoRow(label: 'Role', value: widget.user.role),
                    _InfoRow(
                      label: 'Assignment',
                      value: currentShift != null
                          ? '${currentShift.unitLabel} · Floor ${currentShift.floorNumber}'
                          : '${widget.snapshot.shift.unitLabel} · Floor ${widget.snapshot.shift.floorNumber}',
                    ),
                    _InfoRow(
                      label: 'Shift',
                      value: currentShift != null
                          ? '${_time(currentShift.startsAt)} - ${_time(currentShift.endsAt)}'
                          : '${_time(widget.snapshot.shift.startsAt)} - ${_time(widget.snapshot.shift.endsAt)}',
                    ),
                    _InfoRow(
                      label: 'Handover',
                      value: _handoverValue(currentShift),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.errorRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Assigned Shifts',
                child: _AssignmentsList(
                  isLoading: _isLoading,
                  assignments: assignments,
                  fallbackShift: widget.snapshot.shift,
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Settings',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline_rounded),
                      title: const Text('BYOD and privacy controls'),
                      subtitle: const Text(
                        'Future place for device policy, notifications, and secure access settings.',
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Settings will grow here once device-policy controls are wired in.',
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: AppTheme.errorRed,
                      ),
                      title: const Text('Log Out'),
                      subtitle: const Text('Return to the sign-in screen.'),
                      onTap: widget.onLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _handoverValue(ShiftAssignment? currentShift) {
    if (currentShift != null) {
      if (currentShift.handoverAcknowledged) {
        return 'Acknowledged at ${_time(currentShift.handoverAcknowledgedAt ?? currentShift.startsAt)}';
      }
      return 'Pending acknowledgement';
    }

    return widget.snapshot.acknowledged
        ? 'Acknowledged at ${_time(widget.snapshot.acknowledgedAt ?? widget.snapshot.shift.startsAt)}'
        : 'Pending acknowledgement';
  }

  static String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _AssignmentsList extends StatelessWidget {
  const _AssignmentsList({
    required this.isLoading,
    required this.assignments,
    required this.fallbackShift,
  });

  final bool isLoading;
  final List<ShiftAssignment> assignments;
  final ShiftSummary fallbackShift;

  @override
  Widget build(BuildContext context) {
    if (isLoading && assignments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    final visibleAssignments = assignments.isEmpty
        ? [
            ShiftAssignment(
              id: fallbackShift.id,
              name: fallbackShift.name,
              startsAt: fallbackShift.startsAt,
              endsAt: fallbackShift.endsAt,
              status: fallbackShift.status,
              floorNumber: fallbackShift.floorNumber,
              unitLabel: fallbackShift.unitLabel,
            ),
          ]
        : assignments;

    return Column(
      children: visibleAssignments
          .map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: entry.status == 'ACTIVE'
                          ? AppTheme.primaryBlueLight
                          : const Color(0xFFE8EEF5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      entry.status == 'ACTIVE'
                          ? Icons.play_circle_outline_rounded
                          : Icons.calendar_month_outlined,
                      color: AppTheme.primaryBlueDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_assignmentLabel(entry)} · ${entry.unitLabel} · Floor ${entry.floorNumber}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_time(entry.startsAt)} - ${_time(entry.endsAt)} · ${entry.status}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _assignmentLabel(ShiftAssignment assignment) {
    final now = DateTime.now();
    final startDay = DateTime(
      assignment.startsAt.year,
      assignment.startsAt.month,
      assignment.startsAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (startDay == today) return 'Today';
    if (startDay == tomorrow) return 'Tomorrow';
    return 'Next Scheduled';
  }

  static String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
