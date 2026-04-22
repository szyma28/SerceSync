import 'package:flutter/material.dart';

import 'src/manager/manager_api_client.dart';
import 'src/manager/manager_file_download.dart';
import 'src/manager/manager_file_download_api.dart';
import 'src/manager/manager_shell.dart';
import 'src/manager/manager_theme.dart';

export 'src/manager/manager_api_client.dart';
export 'src/manager/manager_dashboard_live_updates.dart';
export 'src/manager/manager_dashboard_live_updates_api.dart';
export 'src/manager/manager_file_download_api.dart';
export 'src/manager/manager_models.dart';

class SerceSyncWebApp extends StatelessWidget {
  const SerceSyncWebApp({super.key, this.apiClient, this.fileDownloader});

  final SerceSyncManagerApiClient? apiClient;
  final ManagerFileDownloader? fileDownloader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SerceSync Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: managerCanvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: managerPrimary,
          surface: managerCanvas,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontSize: 14, height: 1.45),
          bodyMedium: TextStyle(fontSize: 13, height: 1.45),
          labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ).apply(bodyColor: managerInk, displayColor: managerInk),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FBFE),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: const TextStyle(
            color: managerMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: managerBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: managerBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: managerPrimary, width: 1.4),
          ),
        ),
      ),
      home: ManagerShell(
        apiClient: apiClient ??
            SerceSyncManagerApiClient(
              baseUrl: const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'http://localhost:3000',
              ),
            ),
        fileDownloader: fileDownloader ?? buildManagerFileDownloader(),
      ),
    );
  }
}
