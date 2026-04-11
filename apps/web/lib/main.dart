import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SerceSyncWebApp());
}

class SerceSyncWebApp extends StatelessWidget {
  const SerceSyncWebApp({super.key, this.apiClient});

  final SerceSyncManagerApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SerceSync Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF335C81)),
        useMaterial3: true,
      ),
      home: ManagerShell(
        apiClient: apiClient ??
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

    return ResidentsWorkspaceScreen(
      apiClient: widget.apiClient,
      session: _session!,
      onLogout: _handleLogout,
    );
  }
}

class ManagerLoginScreen extends StatefulWidget {
  const ManagerLoginScreen({
    super.key,
    required this.apiClient,
    required this.onLoggedIn,
  });

  final SerceSyncManagerApiClient apiClient;
  final ValueChanged<ManagerSession> onLoggedIn;

  @override
  State<ManagerLoginScreen> createState() => _ManagerLoginScreenState();
}

class _ManagerLoginScreenState extends State<ManagerLoginScreen> {
  final _emailController = TextEditingController(text: 'manager@sercesync.local');
  final _passwordController = TextEditingController(text: 'Password123!');

  bool _isBusy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final session = await widget.apiClient.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      widget.onLoggedIn(session);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to sign in right now.');
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Manager Sign In',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use the seeded manager account to manage residents on top of the shared backend directory.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isBusy,
                    decoration: const InputDecoration(labelText: 'Email Address'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isBusy,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isBusy ? null : _login,
                    child: _isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Open Residents Workspace'),
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

class ResidentsWorkspaceScreen extends StatefulWidget {
  const ResidentsWorkspaceScreen({
    super.key,
    required this.apiClient,
    required this.session,
    required this.onLogout,
  });

  final SerceSyncManagerApiClient apiClient;
  final ManagerSession session;
  final VoidCallback onLogout;

  @override
  State<ResidentsWorkspaceScreen> createState() => _ResidentsWorkspaceScreenState();
}

class _ResidentsWorkspaceScreenState extends State<ResidentsWorkspaceScreen> {
  List<ManagerResidentRecord> _residents = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _editingResidentId;

  final _fullNameController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _floorNumberController = TextEditingController(text: '1');
  final _unitLabelController = TextEditingController(text: 'Willow Floor');
  final _careSummaryController = TextEditingController();

  String _recognitionImageKey = 'resident-a';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _roomNumberController.dispose();
    _floorNumberController.dispose();
    _unitLabelController.dispose();
    _careSummaryController.dispose();
    super.dispose();
  }

  Future<void> _loadResidents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final residents = await widget.apiClient.getResidents(
        accessToken: widget.session.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _residents = residents;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load residents.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startCreate() {
    setState(() {
      _editingResidentId = null;
      _fullNameController.clear();
      _roomNumberController.clear();
      _floorNumberController.text = '1';
      _unitLabelController.text = 'Willow Floor';
      _careSummaryController.clear();
      _recognitionImageKey = 'resident-a';
      _isActive = true;
    });
  }

  void _startEdit(ManagerResidentRecord resident) {
    setState(() {
      _editingResidentId = resident.id;
      _fullNameController.text = resident.fullName;
      _roomNumberController.text = resident.roomNumber.toString();
      _floorNumberController.text = resident.floorNumber.toString();
      _unitLabelController.text = resident.unitLabel;
      _careSummaryController.text = resident.careSummary;
      _recognitionImageKey = resident.recognitionImageKey;
      _isActive = resident.isActive;
    });
  }

  Future<void> _saveResident() async {
    final roomNumber = int.tryParse(_roomNumberController.text.trim());
    final floorNumber = int.tryParse(_floorNumberController.text.trim());

    if (_fullNameController.text.trim().isEmpty ||
        roomNumber == null ||
        floorNumber == null ||
        _unitLabelController.text.trim().isEmpty ||
        _careSummaryController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please complete every resident field before saving.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final draft = ManagerResidentDraft(
      fullName: _fullNameController.text.trim(),
      roomNumber: roomNumber,
      floorNumber: floorNumber,
      unitLabel: _unitLabelController.text.trim(),
      recognitionImageKey: _recognitionImageKey,
      careSummary: _careSummaryController.text.trim(),
      isActive: _isActive,
    );

    try {
      if (_editingResidentId == null) {
        await widget.apiClient.createResident(
          accessToken: widget.session.accessToken,
          draft: draft,
        );
      } else {
        await widget.apiClient.updateResident(
          accessToken: widget.session.accessToken,
          residentId: _editingResidentId!,
          draft: draft,
        );
      }

      await _loadResidents();
      if (!mounted) return;
      _startCreate();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Workspace'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadResidents,
            icon: const Icon(Icons.refresh_rounded),
          ),
          TextButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Residents Directory',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manager view across all floors. Seeded records and manager-created residents live together here.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _residents.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final resident = _residents[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 0,
                                      vertical: 8,
                                    ),
                                    title: Text(resident.fullName),
                                    subtitle: Text(
                                      '${resident.roomLabel} · ${resident.unitLabel} · Floor ${resident.floorNumber}',
                                    ),
                                    trailing: FilledButton.tonal(
                                      onPressed: () => _startEdit(resident),
                                      child: const Text('Edit'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          Text(
                            _editingResidentId == null ? 'Create Resident' : 'Edit Resident',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          TextButton(
                            onPressed: _startCreate,
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _roomNumberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Room Number'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _floorNumberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Floor Number'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _unitLabelController,
                        decoration: const InputDecoration(labelText: 'Unit Label'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _recognitionImageKey,
                        decoration: const InputDecoration(labelText: 'Recognition Image Key'),
                        items: const [
                          DropdownMenuItem(value: 'resident-a', child: Text('resident-a')),
                          DropdownMenuItem(value: 'resident-b', child: Text('resident-b')),
                          DropdownMenuItem(value: 'resident-c', child: Text('resident-c')),
                          DropdownMenuItem(value: 'resident-d', child: Text('resident-d')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _recognitionImageKey = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _careSummaryController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Care Summary',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Resident Active'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _isSaving ? null : _saveResident,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Resident'),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SerceSyncManagerApiClient {
  SerceSyncManagerApiClient({required this.baseUrl});

  final String baseUrl;

  Uri _uri(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl$path');
  }

  Future<ManagerSession> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return ManagerSession.fromJson(_decodeJson(response));
  }

  Future<List<ManagerResidentRecord>> getResidents({
    required String accessToken,
  }) async {
    final response = await http.get(
      _uri('/manager/residents'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final decoded = _decodeJson(response);
    return (decoded['residents'] as List<dynamic>? ?? const [])
        .map(
          (entry) => ManagerResidentRecord.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ManagerResidentRecord> createResident({
    required String accessToken,
    required ManagerResidentDraft draft,
  }) async {
    final response = await http.post(
      _uri('/manager/residents'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(draft.toJson()),
    );

    final decoded = _decodeJson(response);
    return ManagerResidentRecord.fromJson(
      decoded['resident'] as Map<String, dynamic>,
    );
  }

  Future<ManagerResidentRecord> updateResident({
    required String accessToken,
    required String residentId,
    required ManagerResidentDraft draft,
  }) async {
    final response = await http.patch(
      _uri('/manager/residents/$residentId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(draft.toJson()),
    );

    final decoded = _decodeJson(response);
    return ManagerResidentRecord.fromJson(
      decoded['resident'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String) {
          throw ApiException(message);
        }
        if (message is List && message.isNotEmpty) {
          throw ApiException(message.join(', '));
        }
      }
      throw ApiException('Request failed with status ${response.statusCode}.');
    }
    return decoded as Map<String, dynamic>;
  }
}

class ManagerUser {
  const ManagerUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  factory ManagerUser.fromJson(Map<String, dynamic> json) {
    return ManagerUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
    );
  }

  final String id;
  final String email;
  final String displayName;
  final String role;
}

class ManagerSession {
  const ManagerSession({required this.accessToken, required this.user});

  factory ManagerSession.fromJson(Map<String, dynamic> json) {
    return ManagerSession(
      accessToken: json['accessToken'] as String,
      user: ManagerUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final ManagerUser user;
}

class ManagerResidentRecord {
  const ManagerResidentRecord({
    required this.id,
    required this.fullName,
    required this.roomNumber,
    required this.roomLabel,
    required this.floorNumber,
    required this.unitLabel,
    required this.recognitionImageKey,
    required this.careSummary,
    required this.isActive,
  });

  factory ManagerResidentRecord.fromJson(Map<String, dynamic> json) {
    return ManagerResidentRecord(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      roomNumber: json['roomNumber'] as int,
      roomLabel: json['roomLabel'] as String,
      floorNumber: json['floorNumber'] as int,
      unitLabel: json['unitLabel'] as String,
      recognitionImageKey: json['recognitionImageKey'] as String,
      careSummary: json['careSummary'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  final String id;
  final String fullName;
  final int roomNumber;
  final String roomLabel;
  final int floorNumber;
  final String unitLabel;
  final String recognitionImageKey;
  final String careSummary;
  final bool isActive;
}

class ManagerResidentDraft {
  const ManagerResidentDraft({
    required this.fullName,
    required this.roomNumber,
    required this.floorNumber,
    required this.unitLabel,
    required this.recognitionImageKey,
    required this.careSummary,
    required this.isActive,
  });

  final String fullName;
  final int roomNumber;
  final int floorNumber;
  final String unitLabel;
  final String recognitionImageKey;
  final String careSummary;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'roomNumber': roomNumber,
      'floorNumber': floorNumber,
      'unitLabel': unitLabel,
      'recognitionImageKey': recognitionImageKey,
      'careSummary': careSummary,
      'isActive': isActive,
    };
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
