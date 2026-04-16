part of '../../manager_app.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key, required this.apiClient});

  final SerceSyncManagerApiClient apiClient;

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  ManagerSession? _session;
  bool _isRestoringSession = true;
  String? _restoreErrorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreSession());
  }

  Future<void> _restoreSession() async {
    try {
      final session = await widget.apiClient.restoreSession();
      if (!mounted) return;
      setState(() {
        _session = session;
        _restoreErrorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _session = null;
        _restoreErrorMessage = error.statusCode == 401 ? null : error.message;
      });
    } finally {
      if (mounted) {
        setState(() => _isRestoringSession = false);
      }
    }
  }

  void _handleSessionCreated(ManagerSession session) {
    setState(() => _session = session);
  }

  void _handleLogout() {
    unawaited(_logout());
  }

  Future<void> _logout() async {
    try {
      await widget.apiClient.logout();
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
        return;
      }
    }

    if (!mounted) return;
    setState(() => _session = null);
  }

  void _retrySessionRestore() {
    setState(() {
      _isRestoringSession = true;
      _restoreErrorMessage = null;
    });
    unawaited(_restoreSession());
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringSession) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.8),
          ),
        ),
      );
    }

    if (_restoreErrorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Unable to restore manager session',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(_restoreErrorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _retrySessionRestore,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
