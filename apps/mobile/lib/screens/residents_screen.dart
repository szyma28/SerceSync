import 'package:flutter/material.dart';

import '../models/workspace_models.dart';
import '../theme/app_theme.dart';
import 'resident_detail_screen.dart';

class ResidentsScreen extends StatefulWidget {
  const ResidentsScreen({super.key, required this.currentCarerName});

  final String currentCarerName;

  @override
  State<ResidentsScreen> createState() => ResidentsScreenState();
}

class ResidentsScreenState extends State<ResidentsScreen> {
  late List<ResidentProfile> _residents;

  @override
  void initState() {
    super.initState();
    _residents = buildDemoResidents();
  }

  void openResidentByName(String residentName) {
    final profile = _residents.cast<ResidentProfile?>().firstWhere(
      (candidate) => candidate?.name == residentName,
      orElse: () => null,
    );
    if (profile == null) return;
    _openResident(profile);
  }

  void _replaceProfile(ResidentProfile updated) {
    setState(() {
      _residents = _residents
          .map((profile) => profile.id == updated.id ? updated : profile)
          .toList();
    });
  }

  void _openResident(ResidentProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResidentDetailScreen(
          profile: profile,
          currentCarerName: widget.currentCarerName,
          onProfileChanged: _replaceProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Residents',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(220),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Your floor assignment is visible here as a live resident workspace. Open a resident to review today\'s care context, add structured notes, and prepare for future governed photo evidence features.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ..._residents.map(
              (profile) => _ResidentListCard(
                profile: profile,
                onTap: () => _openResident(profile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResidentListCard extends StatelessWidget {
  const _ResidentListCard({required this.profile, required this.onTap});

  final ResidentProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  profile.photoAssetPath,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.room,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryBlueDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.contextLine,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.alerts
                          .take(2)
                          .map(
                            (alert) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceBackground,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                alert,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                          .toList(),
                    ),
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
