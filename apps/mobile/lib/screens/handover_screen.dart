import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/mobile_session_controller.dart';
import '../models/handover.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../widgets/date_time_formatters.dart';
import '../widgets/screen_message_state.dart';
import 'shift_workspace_screen.dart';

class HandoverScreen extends StatefulWidget {
  const HandoverScreen({super.key});

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<MobileSessionController>().loadCurrentHandover());
  }

  void _goToWorkspace() {
    final sessionController = context.read<MobileSessionController>();
    if (!sessionController.hasActiveSession ||
        sessionController.apiClient == null ||
        sessionController.accessToken == null ||
        sessionController.user == null ||
        sessionController.handoverSnapshot == null) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ShiftWorkspaceScreen(
          apiClient: sessionController.apiClient!,
          accessToken: sessionController.accessToken!,
          user: sessionController.user!,
          snapshot: sessionController.handoverSnapshot!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionController = context.watch<MobileSessionController>();

    return Container(
      decoration: AppTheme.atmosphericBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Handover'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: sessionController.isHandoverLoading
                  ? null
                  : () => unawaited(
                      context.read<MobileSessionController>().loadCurrentHandover(
                        forceRefresh: true,
                      ),
                    ),
            ),
          ],
        ),
        body: SafeArea(
          child: sessionController.isHandoverLoading &&
                  sessionController.handoverSnapshot == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                )
              : _buildContent(
                  isLoading: sessionController.isHandoverLoading,
                  errorMessage: sessionController.handoverErrorMessage,
                  snapshot: sessionController.handoverSnapshot,
                  user: sessionController.user,
                ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required bool isLoading,
    required String? errorMessage,
    required HandoverSnapshot? snapshot,
    required LoginUser? user,
  }) {
    if (errorMessage != null && snapshot == null) {
      return ScreenMessageState(
        imageAssetPath: 'assets/images/NoConnection.png',
        imageHeight: 200,
        title: 'Something went wrong',
        message: errorMessage,
        messageStyle: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
        actionLabel: 'Try Again',
        onAction: () => context.read<MobileSessionController>().loadCurrentHandover(
          forceRefresh: true,
        ),
      );
    }

    if (snapshot == null || user == null) {
      return const SizedBox.shrink();
    }

    final isAcknowledged = snapshot.acknowledged;

    if (isAcknowledged) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Handover complete',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryBlueDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your workspace is ready.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withAlpha(70),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: _goToWorkspace,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Open workspace'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 12),
              Center(
                child: Hero(
                  tag: 'handover_icon',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.premiumShadow,
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_rounded,
                      size: 40,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '${user.displayName.split(' ').first},',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  letterSpacing: -1,
                  fontSize: 36,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Review the handover before you start.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: AppTheme.premiumShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      color: AppTheme.primaryBlueLight.withAlpha(100),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_city_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snapshot.shift.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: AppTheme.primaryBlueDark,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatHourMinuteRange(
                                    snapshot.shift.startsAt,
                                    snapshot.shift.endsAt,
                                    separator: ' — ',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppTheme.warningYellow,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SHIFT NOTES',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            snapshot.handover.summary,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  height: 1.6,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlueDark.withAlpha(10),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withAlpha(50),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: isLoading
                  ? null
                  : () => context
                      .read<MobileSessionController>()
                      .acknowledgeCurrentHandover(),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Acknowledge and start'),
            ),
          ),
        ),
      ],
    );
  }
}
