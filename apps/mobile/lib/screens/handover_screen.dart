import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/handover.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import 'shift_workspace_screen.dart';

class HandoverScreen extends StatefulWidget {
  const HandoverScreen({
    super.key,
    required this.apiClient,
    required this.accessToken,
    required this.user,
  });

  final SerceSyncApiClient apiClient;
  final String accessToken;
  final LoginUser user;

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  HandoverSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _fetchHandover();
  }

  Future<void> _fetchHandover() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await widget.apiClient.getCurrentHandover(
        accessToken: widget.accessToken,
      );
      setState(() => _snapshot = snapshot);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load handover details.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acknowledge() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await widget.apiClient.acknowledgeCurrentHandover(
        accessToken: widget.accessToken,
      );
      if (mounted) setState(() => _snapshot = snapshot);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to acknowledge handover.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToWorkspace() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ShiftWorkspaceScreen(
          apiClient: widget.apiClient,
          accessToken: widget.accessToken,
          user: widget.user,
          snapshot: _snapshot!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.atmosphericBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Handover'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _fetchHandover,
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading && _snapshot == null
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null && _snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/NoConnection.png', height: 200),
              const SizedBox(height: 32),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _fetchHandover,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final snap = _snapshot!;
    final isAcknowledged = snap.acknowledged;

    if (isAcknowledged) {
      // Success State
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

    // Pending Ritual State
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
                '${widget.user.displayName.split(' ').first},',
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

              // Dossier Ticket
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
                                  snap.shift.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: AppTheme.primaryBlueDark,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${snap.shift.startsAt.hour}:${snap.shift.startsAt.minute.toString().padLeft(2, '0')} — ${snap.shift.endsAt.hour}:${snap.shift.endsAt.minute.toString().padLeft(2, '0')}',
                                  style: Theme.of(context).textTheme.bodyMedium
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
                                style: Theme.of(context).textTheme.labelLarge
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
                            snap.handover.summary,
                            style: Theme.of(context).textTheme.bodyLarge
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

              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _errorMessage!,
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

        // Deeply shadowed bottom action
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
              onPressed: _isLoading ? null : _acknowledge,
              child: _isLoading
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
