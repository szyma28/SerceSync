part of '../../manager_app.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key, required this.apiClient});

  final SerceSyncManagerApiClient apiClient;

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  ManagerSession? _session;

  void _handleSessionCreated(ManagerSession session) {
    setState(() => _session = session);
  }

  void _handleLogout() {
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return ManagerLoginScreen(
        apiClient: widget.apiClient,
        onLoggedIn: _handleSessionCreated,
      );
    }

    return ManagerWorkspaceScreen(
      apiClient: widget.apiClient,
      session: _session!,
      onLogout: _handleLogout,
    );
  }
}
