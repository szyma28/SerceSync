import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);
const _demoEmail = 'carer@sercesync.local';
const _demoPassword = 'Password123!';

void main() {
  runApp(const SerceSyncMobileApp());
}

class SerceSyncMobileApp extends StatelessWidget {
  const SerceSyncMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SerceSync Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6B62)),
      ),
      home: const _HandoverFeatureScreen(),
    );
  }
}

class _HandoverFeatureScreen extends StatefulWidget {
  const _HandoverFeatureScreen();

  @override
  State<_HandoverFeatureScreen> createState() => _HandoverFeatureScreenState();
}

class _HandoverFeatureScreenState extends State<_HandoverFeatureScreen> {
  final _apiBaseUrlController = TextEditingController(text: _defaultApiBaseUrl);
  final _emailController = TextEditingController(text: _demoEmail);
  final _passwordController = TextEditingController(text: _demoPassword);

  bool _isBusy = false;
  String? _errorMessage;
  String? _accessToken;
  LoginUser? _user;
  HandoverSnapshot? _snapshot;

  SerceSyncApiClient get _apiClient =>
      SerceSyncApiClient(baseUrl: _apiBaseUrlController.text.trim());

  @override
  void dispose() {
    _apiBaseUrlController.dispose();
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
      final response = await _apiClient.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final snapshot = await _apiClient.getCurrentHandover(
        accessToken: response.accessToken,
      );

      setState(() {
        _accessToken = response.accessToken;
        _user = response.user;
        _snapshot = snapshot;
      });
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _refresh() async {
    final accessToken = _accessToken;
    if (accessToken == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _apiClient.getCurrentHandover(
        accessToken: accessToken,
      );
      setState(() {
        _snapshot = snapshot;
      });
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _acknowledge() async {
    final accessToken = _accessToken;
    if (accessToken == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _apiClient.acknowledgeCurrentHandover(
        accessToken: accessToken,
      );
      setState(() {
        _snapshot = snapshot;
      });
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  void _logout() {
    setState(() {
      _accessToken = null;
      _user = null;
      _snapshot = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SerceSync Mobile'),
        actions: [
          if (_accessToken != null)
            IconButton(
              onPressed: _isBusy ? null : _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _accessToken == null
              ? _buildLoginView(context)
              : _buildHandoverView(context),
        ),
      ),
    );
  }

  Widget _buildLoginView(BuildContext context) {
    return ListView(
      key: const ValueKey('login-view'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Login to start shift',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'This first vertical slice demonstrates the mandatory handover acknowledgement workflow.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _apiBaseUrlController,
          enabled: !_isBusy,
          decoration: const InputDecoration(
            labelText: 'API base URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          enabled: !_isBusy,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          enabled: !_isBusy,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seeded demo credentials'),
              SizedBox(height: 8),
              Text('Email: carer@sercesync.local'),
              Text('Password: Password123!'),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isBusy ? null : _login,
          icon: _isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.login),
          label: const Text('Sign in'),
        ),
      ],
    );
  }

  Widget _buildHandoverView(BuildContext context) {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final acknowledgedText = snapshot.acknowledged
        ? 'Acknowledged at ${snapshot.acknowledgedAt?.toLocal().toString() ?? 'unknown time'}'
        : 'Pending acknowledgement';

    return ListView(
      key: const ValueKey('handover-view'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Current shift',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          '${_user?.displayName ?? snapshot.currentUser.displayName} • ${snapshot.currentUser.role}',
        ),
        const SizedBox(height: 24),
        _InfoCard(
          title: snapshot.shift.name,
          body:
              'Start: ${snapshot.shift.startsAt.toLocal()}\nEnd: ${snapshot.shift.endsAt.toLocal()}\nStatus: ${snapshot.shift.status}',
        ),
        const SizedBox(height: 16),
        _InfoCard(title: 'Handover summary', body: snapshot.handover.summary),
        const SizedBox(height: 16),
        _InfoCard(title: 'Acknowledgement state', body: acknowledgedText),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isBusy || snapshot.acknowledged ? null : _acknowledge,
          icon: snapshot.acknowledged
              ? const Icon(Icons.check_circle)
              : const Icon(Icons.assignment_turned_in),
          label: Text(
            snapshot.acknowledged
                ? 'Handover acknowledged'
                : 'Acknowledge handover',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isBusy ? null : _refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class SerceSyncApiClient {
  SerceSyncApiClient({required this.baseUrl});

  final String baseUrl;

  Uri _uri(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl$path');
  }

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return LoginResponse.fromJson(_decodeJson(response));
  }

  Future<HandoverSnapshot> getCurrentHandover({
    required String accessToken,
  }) async {
    final response = await http.get(
      _uri('/handovers/current'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    return HandoverSnapshot.fromJson(_decodeJson(response));
  }

  Future<HandoverSnapshot> acknowledgeCurrentHandover({
    required String accessToken,
  }) async {
    final response = await http.post(
      _uri('/handovers/current/acknowledge'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    return HandoverSnapshot.fromJson(_decodeJson(response));
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    final dynamic decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

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

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;
}

class LoginResponse {
  const LoginResponse({required this.accessToken, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      user: LoginUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final LoginUser user;
}

class LoginUser {
  const LoginUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
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

class HandoverSnapshot {
  const HandoverSnapshot({
    required this.shift,
    required this.handover,
    required this.currentUser,
    required this.acknowledged,
    required this.acknowledgedAt,
  });

  factory HandoverSnapshot.fromJson(Map<String, dynamic> json) {
    return HandoverSnapshot(
      shift: ShiftSummary.fromJson(json['shift'] as Map<String, dynamic>),
      handover: HandoverSummary.fromJson(
        json['handover'] as Map<String, dynamic>,
      ),
      currentUser: LoginUser.fromJson(
        json['currentUser'] as Map<String, dynamic>,
      ),
      acknowledged: json['acknowledged'] as bool,
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedAt'] as String),
    );
  }

  final ShiftSummary shift;
  final HandoverSummary handover;
  final LoginUser currentUser;
  final bool acknowledged;
  final DateTime? acknowledgedAt;
}

class ShiftSummary {
  const ShiftSummary({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  factory ShiftSummary.fromJson(Map<String, dynamic> json) {
    return ShiftSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      status: json['status'] as String,
    );
  }

  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
}

class HandoverSummary {
  const HandoverSummary({
    required this.id,
    required this.summary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HandoverSummary.fromJson(Map<String, dynamic> json) {
    return HandoverSummary(
      id: json['id'] as String,
      summary: json['summary'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String summary;
  final DateTime createdAt;
  final DateTime updatedAt;
}
