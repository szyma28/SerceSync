import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/handover.dart';
import '../models/shared_models.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_message_state.dart';
import '../widgets/task_card.dart';

class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({
    super.key,
    required this.apiClient,
    required this.accessToken,
    required this.user,
    required this.snapshot,
  });

  final SerceSyncApiClient apiClient;
  final String accessToken;
  final LoginUser user;
  final HandoverSnapshot snapshot;

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ShiftTask> _tasks = [];
  String _filter = 'All Tasks';

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
      if (mounted) setState(() => _tasks = tasks);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTaskActionSheet(ShiftTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskActionSheet(
        task: task,
        apiClient: widget.apiClient,
        accessToken: widget.accessToken,
        onActionCompleted: () {
          Navigator.of(context).pop();
          _fetchTasks();
        },
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    final bool isAllTasks = filter == 'All Tasks';
    return ScreenMessageState(
      imageAssetPath: isAllTasks
          ? 'assets/images/resident_profile_01.png'
          : 'assets/images/Nurse03.png',
      imageHeight: 200,
      title: isAllTasks ? 'No Tasks Assigned' : 'All Caught Up!',
      titleStyle: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(color: AppTheme.primaryBlueDark),
      message: isAllTasks
          ? 'There are currently no tasks assigned for this shift yet. Enjoy the quiet moment.'
          : 'You have no pending tasks in the "$filter" view.',
      messageStyle: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
    );
  }

  Widget _buildErrorState() {
    return ScreenMessageState(
      imageAssetPath: 'assets/images/404error_transparent.png',
      imageHeight: 200,
      title: 'Couldn\'t load tasks',
      titleStyle: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(color: AppTheme.errorRed),
      message: _errorMessage ?? 'Unknown error occurred.',
      messageStyle: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
      actionLabel: 'Try Again',
      onAction: _fetchTasks,
    );
  }

  List<ShiftTask> _visibleTasksForCurrentUser(List<ShiftTask> tasks) {
    if (widget.user.role == AppUserRole.nurse) {
      return tasks;
    }

    return tasks.where((task) => task.focus != TaskFocus.medication).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<ShiftTask> displayedTasks = _visibleTasksForCurrentUser(_tasks);
    if (_filter == 'To Do') {
      displayedTasks = _tasks
          .where(
            (t) =>
                t.status != TaskStatus.completed &&
                t.status != TaskStatus.deferred,
          )
          .toList();
    } else if (_filter == 'Priority') {
      displayedTasks = _tasks
          .where(
            (t) =>
                t.status == TaskStatus.overdue ||
                t.status == TaskStatus.escalated,
          )
          .toList();
    }

    return Container(
      decoration: AppTheme.atmosphericBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 70,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'My Tasks',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                widget.snapshot.shift.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: ['All Tasks', 'To Do', 'Priority'].map((f) {
                      final isSelected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _filter = f);
                          },
                          selectedColor: AppTheme.primaryBlue,
                          backgroundColor: Colors.white.withAlpha(200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : Colors.white.withAlpha(100),
                              width: 1.5,
                            ),
                          ),
                          elevation: isSelected ? 4 : 0,
                          shadowColor: AppTheme.primaryBlue.withAlpha(60),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              Expanded(
                child: _isLoading && _tasks.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryBlue,
                        ),
                      )
                    : _errorMessage != null && _tasks.isEmpty
                    ? _buildErrorState()
                    : displayedTasks.isEmpty
                    ? _buildEmptyState(_filter)
                    : RefreshIndicator(
                        onRefresh: _fetchTasks,
                        color: AppTheme.primaryBlue,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                          itemCount: displayedTasks.length,
                          itemBuilder: (context, index) {
                            return TaskCard(
                              task: displayedTasks[index],
                              onTap: () =>
                                  _showTaskActionSheet(displayedTasks[index]),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlueDark.withAlpha(15),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BottomNavigationBar(
              selectedItemColor: AppTheme.primaryBlue,
              unselectedItemColor: AppTheme.textSecondary.withAlpha(150),
              currentIndex: 0,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.assignment),
                  ),
                  label: 'Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.favorite_border),
                  ),
                  label: 'Obs',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.medication_outlined),
                  ),
                  label: 'Meds',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.person_outline),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskActionSheet extends StatefulWidget {
  const _TaskActionSheet({
    required this.task,
    required this.apiClient,
    required this.accessToken,
    required this.onActionCompleted,
  });

  final ShiftTask task;
  final SerceSyncApiClient apiClient;
  final String accessToken;
  final VoidCallback onActionCompleted;

  @override
  State<_TaskActionSheet> createState() => _TaskActionSheetState();
}

class _TaskActionSheetState extends State<_TaskActionSheet> {
  final _reasonController = TextEditingController();
  bool _isBusy = false;
  String? _error;
  String? _actionType;

  bool get _canComplete => widget.task.canComplete;
  bool get _canDefer => widget.task.canDefer;
  bool get _canEscalate => widget.task.canEscalate;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _performAction(String action) async {
    final actionAllowed = switch (action) {
      'complete' => _canComplete,
      'defer' => _canDefer,
      'escalate' => _canEscalate,
      _ => false,
    };

    if (!actionAllowed) {
      setState(() {
        _error =
            widget.task.actionRestrictionReason ??
            'This task action is not available right now.';
      });
      return;
    }

    if (action != 'complete' && _reasonController.text.trim().isEmpty) {
      setState(() => _error = 'Please provide a reason to $action this task.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      if (action == 'complete') {
        await widget.apiClient.completeTask(
          accessToken: widget.accessToken,
          taskId: widget.task.id,
          note: _reasonController.text.trim().isNotEmpty
              ? _reasonController.text.trim()
              : null,
        );
      } else if (action == 'defer') {
        await widget.apiClient.deferTask(
          accessToken: widget.accessToken,
          taskId: widget.task.id,
          reason: _reasonController.text.trim(),
        );
      } else if (action == 'escalate') {
        await widget.apiClient.escalateTask(
          accessToken: widget.accessToken,
          taskId: widget.task.id,
          reason: _reasonController.text.trim(),
        );
      }
      widget.onActionCompleted();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showReasonInput = _actionType != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: EdgeInsets.only(top: showReasonInput ? 90 : 0),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            padding: EdgeInsets.fromLTRB(32, showReasonInput ? 80 : 32, 32, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!showReasonInput)
                  Center(
                    child: Container(
                      width: 56,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                Text(
                  widget.task.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryBlueDark,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.task.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.task.description!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 32),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (widget.task.actionRestrictionReason != null &&
                    !showReasonInput) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.task.actionRestrictionReason!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (showReasonInput) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _reasonController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: _actionType == 'complete'
                            ? 'Note (optional)'
                            : 'Reason for ${_actionType}ing (required)',
                        alignLabelWithHint: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isBusy
                              ? null
                              : () => setState(() {
                                  _actionType = null;
                                  _error = null;
                                }),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_actionType == 'escalate'
                                            ? AppTheme.errorRed
                                            : AppTheme.warningYellow)
                                        .withAlpha(60),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _actionType == 'escalate'
                                  ? AppTheme.errorRed
                                  : AppTheme.warningYellow,
                            ),
                            onPressed: _isBusy
                                ? null
                                : () => _performAction(_actionType!),
                            child: _isBusy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Confirm ${_actionType![0].toUpperCase()}${_actionType!.substring(1)}',
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successGreen.withAlpha(50),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark as Complete'),
                      onPressed:
                          widget.task.status == TaskStatus.completed ||
                              !_canComplete
                          ? null
                          : () => _performAction('complete'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.schedule),
                          label: const Text('Defer'),
                          onPressed: !_canDefer
                              ? null
                              : () => setState(() => _actionType = 'defer'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorRed,
                            side: BorderSide(
                              color: AppTheme.errorRed.withAlpha(80),
                              width: 1.5,
                            ),
                            backgroundColor: AppTheme.errorRed.withAlpha(10),
                          ),
                          icon: const Icon(Icons.trending_up),
                          label: const Text('Escalate'),
                          onPressed: !_canEscalate
                              ? null
                              : () => setState(() => _actionType = 'escalate'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (showReasonInput)
            Positioned(
              top: 0,
              child: Image.asset(
                _actionType == 'escalate'
                    ? 'assets/images/Interruption.png'
                    : 'assets/images/DelegateTask.png',
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}
