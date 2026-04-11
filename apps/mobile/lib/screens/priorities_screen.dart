import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/task.dart';
import '../models/workspace_models.dart';
import '../theme/app_theme.dart';
import '../widgets/priority_card.dart';

class PrioritiesScreen extends StatefulWidget {
  const PrioritiesScreen({
    super.key,
    required this.apiClient,
    required this.accessToken,
    required this.shiftName,
    required this.onOpenResident,
  });

  final SerceSyncApiClient apiClient;
  final String accessToken;
  final String shiftName;
  final ValueChanged<String> onOpenResident;

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

  Future<void> _handleMarkSeen(PriorityItem item, String? note) async {
    final task = item.sourceTask;
    if (task == null) return;
    await widget.apiClient.completeTask(
      accessToken: widget.accessToken,
      taskId: task.id,
      note: note,
    );
    await _fetchTasks();
  }

  Future<void> _handleEscalate(PriorityItem item, String reason) async {
    final task = item.sourceTask;
    if (task == null) return;
    await widget.apiClient.escalateTask(
      accessToken: widget.accessToken,
      taskId: task.id,
      reason: reason,
    );
    await _fetchTasks();
  }

  void _openPriorityActions(PriorityItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PriorityActionSheet(
          item: item,
          onOpenResident: item.residentId == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  widget.onOpenResident(item.residentId!);
                },
          onMarkSeen: (note) async {
            Navigator.of(context).pop();
            try {
              await _handleMarkSeen(item, note);
            } on ApiException catch (error) {
              if (!mounted) return;
              ScaffoldMessenger.of(
                this.context,
              ).showSnackBar(SnackBar(content: Text(error.message)));
            }
          },
          onEscalate: (reason) async {
            Navigator.of(context).pop();
            try {
              await _handleEscalate(item, reason);
            } on ApiException catch (error) {
              if (!mounted) return;
              ScaffoldMessenger.of(
                this.context,
              ).showSnackBar(SnackBar(content: Text(error.message)));
            }
          },
        );
      },
    );
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
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
                  children: [
                    _IntroStrip(itemCount: priorities.length),
                    const SizedBox(height: 20),
                    _PriorityBandSection(
                      title: 'Urgent Now',
                      description:
                          'Time-sensitive items and anything that now needs immediate attention.',
                      items: priorities
                          .where((item) => item.band == PriorityBand.urgentNow)
                          .toList(),
                      onTap: _openPriorityActions,
                    ),
                    const SizedBox(height: 20),
                    _PriorityBandSection(
                      title: 'Due Within 1 Hour',
                      description:
                          'The next care actions coming up soon, with countdown-style prompts to keep the shift calm and visible.',
                      items: priorities
                          .where(
                            (item) => item.band == PriorityBand.dueWithinHour,
                          )
                          .toList(),
                      onTap: _openPriorityActions,
                    ),
                    const SizedBox(height: 20),
                    _PriorityBandSection(
                      title: 'Reminders',
                      description:
                          'Softer prompts that keep continuity and resident comfort visible without turning the shift into a tick list.',
                      items: priorities
                          .where((item) => item.band == PriorityBand.reminders)
                          .toList(),
                      onTap: _openPriorityActions,
                      emptyTitle: 'No reminders are surfacing right now',
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _IntroStrip extends StatelessWidget {
  const _IntroStrip({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.monitor_heart_outlined,
              color: AppTheme.primaryBlueDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$itemCount live priorities are shaping this shift. Open any card to mark it seen, escalate it, or jump straight into the resident workspace.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBandSection extends StatelessWidget {
  const _PriorityBandSection({
    required this.title,
    required this.description,
    required this.items,
    required this.onTap,
    this.emptyTitle,
  });

  final String title;
  final String description;
  final List<PriorityItem> items;
  final ValueChanged<PriorityItem> onTap;
  final String? emptyTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 18),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(200),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Text(
              emptyTitle ?? 'Nothing is surfacing in this band right now.',
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

class _PriorityActionSheet extends StatefulWidget {
  const _PriorityActionSheet({
    required this.item,
    required this.onMarkSeen,
    required this.onEscalate,
    this.onOpenResident,
  });

  final PriorityItem item;
  final VoidCallback? onOpenResident;
  final ValueChanged<String?> onMarkSeen;
  final ValueChanged<String> onEscalate;

  @override
  State<_PriorityActionSheet> createState() => _PriorityActionSheetState();
}

class _PriorityActionSheetState extends State<_PriorityActionSheet> {
  final _noteController = TextEditingController();
  final _escalationController = TextEditingController();
  bool _showEscalate = false;

  @override
  void dispose() {
    _noteController.dispose();
    _escalationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.item.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              '${widget.item.residentName} · ${widget.item.room} · ${widget.item.timeStateLabel}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Add note for mark seen (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: widget.item.sourceTask == null
                  ? null
                  : () => widget.onMarkSeen(
                      _noteController.text.trim().isEmpty
                          ? null
                          : _noteController.text.trim(),
                    ),
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('Mark Seen'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onOpenResident,
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('Open Resident'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showEscalate = !_showEscalate),
              icon: const Icon(Icons.trending_up),
              label: Text(_showEscalate ? 'Hide Escalation' : 'Escalate'),
            ),
            if (_showEscalate) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _escalationController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Escalation reason',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                ),
                onPressed:
                    widget.item.sourceTask == null ||
                        _escalationController.text.trim().isEmpty
                    ? null
                    : () =>
                          widget.onEscalate(_escalationController.text.trim()),
                child: const Text('Send Escalation'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
