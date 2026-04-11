import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/handover.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'my_shift_screen.dart';
import 'priorities_screen.dart';
import 'residents_screen.dart';

class ShiftWorkspaceScreen extends StatefulWidget {
  const ShiftWorkspaceScreen({
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
  State<ShiftWorkspaceScreen> createState() => _ShiftWorkspaceScreenState();
}

class _ShiftWorkspaceScreenState extends State<ShiftWorkspaceScreen> {
  final GlobalKey<ResidentsScreenState> _residentsKey =
      GlobalKey<ResidentsScreenState>();
  late final List<Widget> _pages;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pages = [
      PrioritiesScreen(
        apiClient: widget.apiClient,
        accessToken: widget.accessToken,
        shiftName: widget.snapshot.shift.name,
        onOpenResident: _openResidentFromPriority,
      ),
      ResidentsScreen(
        key: _residentsKey,
        currentCarerName: widget.user.displayName,
      ),
      MyShiftScreen(
        user: widget.user,
        snapshot: widget.snapshot,
        onLogout: _logout,
      ),
    ];
  }

  void _openResidentFromPriority(String residentName) {
    setState(() => _currentIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _residentsKey.currentState?.openResidentByName(residentName);
    });
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.atmosphericBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: _currentIndex, children: _pages),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
    );
  }
}
