part of '../resident_detail_screen.dart';

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.resident,
    required this.taskNoteController,
    required this.onCompleteTask,
    required this.highlightTaskKey,
    required this.collapsingTaskIds,
    required this.successStateTaskIds,
    this.highlightTaskId,
    this.taskBeingUpdatedId,
  });

  final ResidentDetail resident;
  final String? highlightTaskId;
  final String? taskBeingUpdatedId;
  final GlobalKey highlightTaskKey;
  final Set<String> collapsingTaskIds;
  final Set<String> successStateTaskIds;
  final TextEditingController Function(String taskId) taskNoteController;
  final Future<void> Function(ResidentTaskSummary task) onCompleteTask;

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
            color: AppTheme.primaryBlueDark.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shift summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            resident.todaySummary,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Active priorities',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (resident.currentTasks.isEmpty)
            Text(
              'No active priorities right now.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            )
          else
            ...resident.currentTasks.map((task) {
              final isCollapsing = collapsingTaskIds.contains(task.id);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: child,
                  ),
                ),
                child: isCollapsing
                    ? SizedBox(key: ValueKey('collapsed-${task.id}'))
                    : _ResidentTaskCard(
                        key: task.id == highlightTaskId
                            ? highlightTaskKey
                            : ValueKey(task.id),
                        task: task,
                        isHighlighted: task.id == highlightTaskId,
                        isSaving: task.id == taskBeingUpdatedId,
                        isSuccessState: successStateTaskIds.contains(task.id),
                        noteController: taskNoteController(task.id),
                        onComplete: () => onCompleteTask(task),
                      ),
              );
            }),
        ],
      ),
    );
  }
}

class _ResidentTaskCard extends StatelessWidget {
  const _ResidentTaskCard({
    super.key,
    required this.task,
    required this.isHighlighted,
    required this.isSaving,
    required this.isSuccessState,
    required this.noteController,
    required this.onComplete,
  });

  final ResidentTaskSummary task;
  final bool isHighlighted;
  final bool isSaving;
  final bool isSuccessState;
  final TextEditingController noteController;
  final VoidCallback onComplete;

  bool get _isCompletable {
    return task.status == TaskStatus.pending ||
        task.status == TaskStatus.overdue;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isSuccessState
        ? AppTheme.successGreen
        : task.status == TaskStatus.overdue
        ? AppTheme.errorRed
        : AppTheme.primaryBlue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccessState
            ? AppTheme.successGreen.withAlpha(14)
            : isHighlighted
            ? accentColor.withAlpha(12)
            : AppTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: isSuccessState || isHighlighted
            ? Border.all(color: accentColor.withAlpha(150), width: 1.6)
            : Border.all(color: AppTheme.borderLight),
        boxShadow: isSuccessState || isHighlighted
            ? [
                BoxShadow(
                  color: accentColor.withAlpha(22),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isSuccessState ? 'Done' : _statusLabel(task.status),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (task.description != null) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            task.dueAt == null
                ? 'Due this shift'
                : 'Due ${formatHourMinute(task.dueAt!)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlueDark,
            ),
          ),
          if (_isCompletable) ...[
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isSuccessState
                  ? Container(
                      key: ValueKey('success-${task.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withAlpha(16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.successGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Marked complete and added to the record.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.successGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      key: ValueKey('entry-${task.id}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: noteController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Completion note',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: isSaving ? null : onComplete,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.task_alt_rounded),
                            label: Text(isSaving ? 'Completing…' : 'Complete'),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.overdue:
        return 'Overdue';
      case TaskStatus.escalated:
        return 'Escalated';
      case TaskStatus.deferred:
        return 'Deferred';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.pending:
        return 'Due';
    }
  }
}
