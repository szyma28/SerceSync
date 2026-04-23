import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/mobile_session_controller.dart';
import '../controllers/shift_workspace_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/resume_refresh_mixin.dart';
import 'my_shift_screen.dart';
import 'priorities_screen.dart';
import 'residents_screen.dart';

class ShiftWorkspaceScreen extends StatefulWidget {
  const ShiftWorkspaceScreen({super.key});

  @override
  State<ShiftWorkspaceScreen> createState() => _ShiftWorkspaceScreenState();
}

class _ShiftWorkspaceScreenState extends State<ShiftWorkspaceScreen>
    with WidgetsBindingObserver, ResumeRefreshStateMixin {
  late final ShiftWorkspaceController _workspaceController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _workspaceController = ShiftWorkspaceController(
      sessionController: context.read<MobileSessionController>(),
    );
  }

  @override
  void dispose() {
    _workspaceController.dispose();
    super.dispose();
  }

  void _logout() {
    context.read<MobileSessionController>().clearSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  bool get canTriggerResumeRefresh =>
      context.read<MobileSessionController>().hasActiveSession;

  @override
  bool get hasVisibleContentForResumeRefresh =>
      _workspaceController.tasks.isNotEmpty ||
      _workspaceController.overview != null;

  @override
  Future<void> refreshAfterResume() async {
    await Future.wait([
      _workspaceController.refreshPriorities(),
      _workspaceController.refreshOverview(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _workspaceController,
      child: Container(
        decoration: AppTheme.atmosphericBackground,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              const PrioritiesScreen(),
              const ResidentsScreen(),
              MyShiftScreen(onLogout: _logout),
            ],
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: AppTheme.primaryBlue,
                unselectedItemColor: AppTheme.textSecondary.withAlpha(160),
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
                      child: Icon(Icons.monitor_heart_outlined),
                    ),
                    label: 'Priorities',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.people_outline_rounded),
                    ),
                    label: 'Residents',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.badge_outlined),
                    ),
                    label: 'My Shift',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
