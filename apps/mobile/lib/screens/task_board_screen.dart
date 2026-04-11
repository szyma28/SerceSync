import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/handover.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
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
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to load tasks.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTaskActionSheet(ShiftTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Important for our custom modal background
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              isAllTasks
                  ? 'assets/images/Resident.png'
                  : 'assets/images/Nurse03.png',
              height: 200,
            ),
            const SizedBox(height: 32),
            Text(
              isAllTasks ? 'No Tasks Assigned' : 'All Caught Up!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryBlueDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isAllTasks
                  ? 'There are currently no tasks assigned for this shift yet. Enjoy the quiet moment.'
                  : 'You have no pending tasks in the "$filter" view.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
            const SizedBox(height: 32),
            Text(
              'Couldn\'t load tasks',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.errorRed),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error occurred.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(boxShadow: AppTheme.premiumShadow),
              child: FilledButton.icon(
                onPressed: _fetchTasks,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<ShiftTask> displayedTasks = _tasks;
    if (_filter == 'To Do') {
      displayedTasks = _tasks
          .where(
            (t) =>
                t.status.toLowerCase() != 'completed' &&
                t.status.toLowerCase() != 'deferred',
          )
          .toList();
    } else if (_filter == 'Priority') {
      displayedTasks = _tasks
          .where(
            (t) =>
                t.status.toLowerCase() == 'overdue' ||
                t.status.toLowerCase() == 'escalated',
          )
          .toList();
    }

    return Container(
      decoration: AppTheme.atmosphericBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 70, // Slightly taller for breathing room
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
              // Filter Pills nested inside transparency
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

              // Task List
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
              elevation: 0, // Elevation is handled by container shadow
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

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _performAction(String action) async {
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
    } catch (e) {
      if (mounted) setState(() => _error = 'An error occurred.');
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
            margin: EdgeInsets.only(
              top: showReasonInput ? 90 : 0,
            ), // Push card down if illustration active
            decoration: const BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            padding: EdgeInsets.fromLTRB(
              32,
              showReasonInput ? 80 : 32,
              32,
              40,
            ), // Padding accounts for overlap
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
                        fillColor:
                            Colors.transparent, // Inherited from Container
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
                      onPressed: widget.task.status.toLowerCase() == 'completed'
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
                          onPressed: () =>
                              setState(() => _actionType = 'defer'),
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
                          onPressed: () =>
                              setState(() => _actionType = 'escalate'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Floating Illustration Context
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
