import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'manager_session_controller.dart';
import 'manager_theme.dart';

const _enableDemoLoginPrefill = bool.fromEnvironment(
  'ENABLE_DEMO_LOGIN_PREFILL',
  defaultValue: false,
);

class ManagerLoginScreen extends StatefulWidget {
  const ManagerLoginScreen({super.key});

  @override
  State<ManagerLoginScreen> createState() => _ManagerLoginScreenState();
}

class _ManagerLoginScreenState extends State<ManagerLoginScreen> {
  final _emailController = TextEditingController(
    text: _enableDemoLoginPrefill ? 'manager@sercesync.local' : '',
  );
  final _passwordController = TextEditingController(
    text: _enableDemoLoginPrefill ? 'Password123!' : '',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await context.read<ManagerSessionController>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionController = context.watch<ManagerSessionController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F8FD), Color(0xFFE9F1FB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: managerShell,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: managerBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: managerShadow,
                            blurRadius: 40,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: managerPrimarySoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.favorite_border_rounded,
                                  color: managerPrimary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'SerceSync',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'Manager workspace',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Open the desktop oversight view for live exceptions, handover readiness, and resident records across the unit.',
                            style: TextStyle(
                              color: managerMuted,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: const [
                              _LoginFeatureChip(
                                icon: Icons.warning_amber_rounded,
                                label: 'Exception tracking',
                              ),
                              _LoginFeatureChip(
                                icon: Icons.groups_2_outlined,
                                label: 'Resident directory',
                              ),
                              _LoginFeatureChip(
                                icon: Icons.assignment_turned_in_outlined,
                                label: 'Shift visibility',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 360,
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: managerPanel,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: managerBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: managerShadow,
                            blurRadius: 36,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign in',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Use the seeded manager account to open the live dashboard workspace.',
                            style: TextStyle(color: managerMuted, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            enabled: !sessionController.isAuthenticating,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            enabled: !sessionController.isAuthenticating,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                          ),
                          if (sessionController.authErrorMessage != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              sessionController.authErrorMessage!,
                              style: const TextStyle(
                                color: managerCritical,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: sessionController.isAuthenticating
                                ? null
                                : _login,
                            style: FilledButton.styleFrom(
                              backgroundColor: managerPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: sessionController.isAuthenticating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Open manager dashboard'),
                          ),
                        ],
                      ),
                    ),
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

class _LoginFeatureChip extends StatelessWidget {
  const _LoginFeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: managerBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: managerPrimary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
