import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'manager_api_client.dart';
import 'manager_file_download_api.dart';
import 'manager_login.dart';
import 'manager_shared.dart';
import 'manager_session_controller.dart';
import 'manager_theme.dart';
import 'manager_workspace.dart';

class ManagerShell extends StatelessWidget {
  const ManagerShell({
    super.key,
    required this.apiClient,
    required this.fileDownloader,
  });

  final SerceSyncManagerApiClient apiClient;
  final ManagerFileDownloader fileDownloader;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManagerSessionController(apiClient: apiClient)
        ..restoreSession(),
      child: _ManagerShellView(
        apiClient: apiClient,
        fileDownloader: fileDownloader,
      ),
    );
  }
}

class _ManagerShellView extends StatelessWidget {
  const _ManagerShellView({
    required this.apiClient,
    required this.fileDownloader,
  });

  final SerceSyncManagerApiClient apiClient;
  final ManagerFileDownloader fileDownloader;

  Future<void> _handleLogout(BuildContext context) async {
    final errorMessage = await context.read<ManagerSessionController>().logout();
    if (!context.mounted || errorMessage == null) {
      return;
    }

    showManagerNotice(context, message: errorMessage, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final sessionController = context.watch<ManagerSessionController>();

    if (sessionController.isRestoringSession) {
      return Scaffold(
        backgroundColor: managerCanvas,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ManagerSkeletonCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ManagerSkeletonBlock(height: 20, width: 180),
                  SizedBox(height: 14),
                  ManagerSkeletonBlock(height: 14, width: double.infinity),
                  SizedBox(height: 8),
                  ManagerSkeletonBlock(height: 14, width: 260),
                  SizedBox(height: 22),
                  ManagerSkeletonBlock(height: 48, width: double.infinity, radius: 16),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (sessionController.restoreErrorMessage != null) {
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
                  Text(
                    sessionController.restoreErrorMessage!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      unawaited(
                        context.read<ManagerSessionController>().restoreSession(),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (sessionController.session == null) {
      return const ManagerLoginScreen();
    }

    return ManagerWorkspaceScreen(
      apiClient: apiClient,
      fileDownloader: fileDownloader,
      session: sessionController.session!,
      onLogout: () => unawaited(_handleLogout(context)),
    );
  }
}
