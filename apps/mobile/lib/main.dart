import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/mobile_session_controller.dart';
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
      create: (_) => MobileSessionController(),
      child: MaterialApp(
        title: 'SerceSync Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
