import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/mobile_session_controller.dart';
import 'screens/handover_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SerceSyncMobileApp());
}

class SerceSyncMobileApp extends StatelessWidget {
  const SerceSyncMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MobileSessionController()..initialize(),
      child: MaterialApp(
        title: 'SerceSync Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final sessionController = context.watch<MobileSessionController>();

    if (sessionController.isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    if (sessionController.hasActiveSession) {
      return const HandoverScreen();
    }

    return const LoginScreen();
  }
}
