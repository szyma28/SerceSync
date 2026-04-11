import 'package:flutter/material.dart';

import '../models/handover.dart';
import '../models/user.dart';
import '../models/workspace_models.dart';
import '../theme/app_theme.dart';

class MyShiftScreen extends StatelessWidget {
  const MyShiftScreen({
    super.key,
    required this.user,
    required this.snapshot,
    required this.onLogout,
  });

  final LoginUser user;
  final HandoverSnapshot snapshot;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final rota = buildDemoRota(snapshot.shift.startsAt);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'My Shift',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            _SectionCard(
              title: 'Current Shift',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Carer', value: user.displayName),
                  _InfoRow(label: 'Role', value: user.role),
                  _InfoRow(label: 'Assignment', value: 'Willow Floor'),
                  _InfoRow(
                    label: 'Shift',
                    value:
                        '${_time(snapshot.shift.startsAt)} - ${_time(snapshot.shift.endsAt)}',
                  ),
                  _InfoRow(
                    label: 'Handover',
                    value: snapshot.acknowledged
                        ? 'Acknowledged at ${_time(snapshot.acknowledgedAt ?? snapshot.shift.startsAt)}'
                        : 'Pending acknowledgement',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Rota',
              child: Column(
                children: rota
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
                                color: AppTheme.primaryBlueLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.calendar_month_outlined,
                                color: AppTheme.primaryBlueDark,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_time(entry.startsAt)} - ${_time(entry.endsAt)} · ${entry.unit}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
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
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
