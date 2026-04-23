import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/mobile_session_controller.dart';
import '../theme/app_theme.dart';

const _enableDemoLoginPrefill = bool.fromEnvironment(
  'ENABLE_DEMO_LOGIN_PREFILL',
  defaultValue: false,
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _hasAppliedSavedBaseUrl = false;
  final _apiBaseUrlController = TextEditingController(
    text: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ),
  );
  final _emailController = TextEditingController(
    text: _enableDemoLoginPrefill ? 'carer@sercesync.local' : '',
  );
  final _passwordController = TextEditingController(
    text: _enableDemoLoginPrefill ? 'Password123!' : '',
  );

  @override
  void dispose() {
    _apiBaseUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final sessionController = context.read<MobileSessionController>();
    await sessionController.login(
      baseUrl: _apiBaseUrlController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sessionController = context.watch<MobileSessionController>();
    if (!_hasAppliedSavedBaseUrl &&
        sessionController.lastBaseUrl != null &&
        sessionController.lastBaseUrl!.trim().isNotEmpty) {
      _apiBaseUrlController.text = sessionController.lastBaseUrl!;
      _hasAppliedSavedBaseUrl = true;
    }
    final isBusy = sessionController.isAuthenticating;
    final errorMessage = sessionController.authErrorMessage;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.75,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE0F2FE), Color(0xFFCCFBF1), Colors.white],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.65,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.15, 0.85, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black,
                          Colors.black,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.85, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Transform.scale(
                      scale: 1.15,
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/images/NurseThumbsUp_Logo.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            36.0,
                            0,
                            36.0,
                            32.0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlueDark.withAlpha(20),
                                  blurRadius: 40,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.borderLight.withAlpha(
                                        150,
                                      ),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _emailController,
                                    enabled: !isBusy,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(fontSize: 15),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                      labelText: 'Email Address',
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                      fillColor: Colors.transparent,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.borderLight.withAlpha(
                                        150,
                                      ),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _passwordController,
                                    enabled: !isBusy,
                                    obscureText: true,
                                    style: const TextStyle(fontSize: 15),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                      labelText: 'Password',
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                      fillColor: Colors.transparent,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                  ),
                                ),

                                if (errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRed.withAlpha(15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: AppTheme.errorRed,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            errorMessage,
                                            style: const TextStyle(
                                              color: AppTheme.errorRed,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 24),

                                FilledButton(
                                  onPressed: isBusy ? null : _login,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: AppTheme.primaryBlue,
                                  ),
                                  child: isBusy
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Log In',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
