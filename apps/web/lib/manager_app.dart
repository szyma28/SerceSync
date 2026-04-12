
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

part 'src/manager/manager_shell.dart';
part 'src/manager/manager_login.dart';
part 'src/manager/manager_workspace.dart';
part 'src/manager/manager_sidebar.dart';
part 'src/manager/manager_shared.dart';
part 'src/manager/manager_dashboard.dart';
part 'src/manager/manager_residents.dart';
part 'src/manager/manager_api_client.dart';
part 'src/manager/manager_models.dart';

const _managerCanvas = Color(0xFFEFF4FA);
const _managerShell = Color(0xFFF8FBFE);
const _managerPanel = Colors.white;
const _managerBackground = Color(0xFFF5F8FC);
const _managerBorder = Color(0xFFE3EBF3);
const _managerInk = Color(0xFF1A2740);
const _managerMuted = Color(0xFF6F7F90);
const _managerPrimary = Color(0xFF4B78FF);
const _managerPrimarySoft = Color(0xFFEAF1FF);
const _managerShadow = Color(0x180F172A);
const _managerSuccess = Color(0xFF25B26B);
const _managerSuccessSoft = Color(0xFFE9FFF2);
const _managerWarning = Color(0xFFFFB84D);
const _managerWarningSoft = Color(0xFFFFF3DF);
const _managerCritical = Color(0xFFFF6E66);
const _managerCriticalSoft = Color(0xFFFFEEEC);
const _managerInfo = Color(0xFF6F8FFF);
const _managerInfoSoft = Color(0xFFEEF2FF);

enum WorkspaceTab { dashboard, residents, staff, compliance, console }

class SerceSyncWebApp extends StatelessWidget {
  const SerceSyncWebApp({super.key, this.apiClient});

  final SerceSyncManagerApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SerceSync Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _managerCanvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _managerPrimary,
          surface: _managerCanvas,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontSize: 14, height: 1.45),
          bodyMedium: TextStyle(fontSize: 13, height: 1.45),
          labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ).apply(bodyColor: _managerInk, displayColor: _managerInk),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FBFE),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: const TextStyle(
            color: _managerMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _managerBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _managerBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _managerPrimary, width: 1.4),
          ),
        ),
      ),
      home: ManagerShell(
        apiClient:
            apiClient ??
            SerceSyncManagerApiClient(
              baseUrl: const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'http://localhost:3000',
              ),
            ),
      ),
    );
  }
}
