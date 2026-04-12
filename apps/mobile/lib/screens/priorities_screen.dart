import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/task.dart';
import '../models/workspace_models.dart';
import '../screens/resident_detail_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/priority_card.dart';

class PrioritiesScreen extends StatefulWidget {
  const PrioritiesScreen({
    super.key,
    required this.apiClient,
    required this.accessToken,
    required this.shiftName,
    required this.currentCarerName,
  });

  final SerceSyncApiClient apiClient;
  final String accessToken;
  final String shiftName;
  final String currentCarerName;

  @override
  State<PrioritiesScreen> createState() => _PrioritiesScreenState();
}

class _PrioritiesScreenState extends State<PrioritiesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ShiftTask> _tasks = const [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await widget.apiClient.getCurrentTasks(
        accessToken: widget.accessToken,
      );
      if (mounted) {
        setState(() => _tasks = tasks);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Failed to load priorities.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PriorityItem> _buildPriorityItems() {
    final now = DateTime.now();
    return _tasks.map((task) => PriorityItem.fromTask(task, now)).toList();
  }

  Future<void> _openPriorityItem(PriorityItem item) async {
    if (item.residentId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This priority is not linked to a resident.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResidentDetailScreen(
          residentId: item.residentId!,
          apiClient: widget.apiClient,
          accessToken: widget.accessToken,
          currentCarerName: widget.currentCarerName,
          highlightTaskId: item.sourceTask?.id,
        ),
      ),
    );

    if (!mounted) return;
    await _fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    final priorities = _buildPriorityItems();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 74,
        title: Column(
          children: [
            Text(
              'Priorities',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              widget.shiftName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _fetchTasks,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading && _tasks.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              )
            : _errorMessage != null && _tasks.isEmpty
            ? _PrioritiesErrorState(
                message: _errorMessage!,
                onRetry: _fetchTasks,
              )
            : RefreshIndicator(
                onRefresh: _fetchTasks,
                color: AppTheme.primaryBlue,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 112),
                  children: [
                    _PriorityBandSection(
                      title: 'Urgent',
                      items: priorities
                          .where((item) => item.band == PriorityBand.urgentNow)
                          .toList(),
                      onTap: _openPriorityItem,
                      emptyTitle: 'Nothing urgent right now.',
                    ),
                    const SizedBox(height: 16),
                    _PriorityBandSection(
                      title: 'Next hour',
                      items: priorities
                          .where(
                            (item) => item.band == PriorityBand.dueWithinHour,
                          )
                          .toList(),
                      onTap: _openPriorityItem,
                      emptyTitle: 'Nothing due in the next hour.',
                    ),
                    const SizedBox(height: 16),
                    _PriorityBandSection(
                      title: 'Later this shift',
                      items: priorities
                          .where((item) => item.band == PriorityBand.reminders)
                          .toList(),
                      onTap: _openPriorityItem,
                      emptyTitle: 'Nothing else is due this shift.',
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PriorityBandSection extends StatelessWidget {
  const _PriorityBandSection({
    required this.title,
    required this.items,
    required this.onTap,
    this.emptyTitle,
  });

  final String title;
  final List<PriorityItem> items;
  final ValueChanged<PriorityItem> onTap;
  final String? emptyTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Text(
              emptyTitle ?? 'Nothing here right now.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          )
        else
          ...items.map(
            (item) => PriorityCard(item: item, onTap: () => onTap(item)),
          ),
      ],
    );
  }
}

class _PrioritiesErrorState extends StatelessWidget {
  const _PrioritiesErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(
                    child: Container(
                      width: 240,
                      height: 170,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryBlueLight.withAlpha(120),
                            AppTheme.primaryBlueLight.withAlpha(24),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: 0.96,
                    child: Image.asset(
                      'assets/images/404error_transparent.png',
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Couldn\'t load priorities',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.errorRed),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
