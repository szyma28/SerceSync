import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../theme/app_theme.dart';
import 'handover_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiBaseUrlController = TextEditingController(
    text: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ),
  );
  final _emailController = TextEditingController(text: 'carer@sercesync.local');
  final _passwordController = TextEditingController(text: 'Password123!');

  bool _isBusy = false;
  String? _errorMessage;

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
      final client = SerceSyncApiClient(
        baseUrl: _apiBaseUrlController.text.trim(),
      );
      final response = await client.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HandoverScreen(
            apiClient: client,
            accessToken: response.accessToken,
            user: response.user,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'An unexpected error occurred.');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. ATMOSPHERIC BACKGROUND TIER
          // Spans exactly 75% of screen height to create a deeply blended transition into the white
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
                  colors: [
                    Color(0xFFE0F2FE), // Light sky blue top
                    Color(0xFFCCFBF1), // Soft teal body
                    Colors
                        .white, // Seamless fade into the lower white background
                  ],
                  stops: [
                    0.0,
                    0.6,
                    1.0,
                  ], // Gradient fades to white over the bottom 40%
                ),
              ),
            ),
          ),

          // 2. DOMINANT HERO ILLUSTRATION
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.65, // Extends far down
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 24.0),
                // First ShaderMask: Fade the horizontal edges so it doesn't look like a solid box
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
                  // Second ShaderMask: Fade the bottom edge so the drawing seamlessly merges into the gradient
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
                      scale:
                          1.15, // Dialed back scale slightly for better balance
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

          // 3. SECONDARY COMPACT LOGIN BOX
          // Uses CustomScrollView to guarantee it is anchored securely at the bottom of the screen while preserving keyboard scrolling safety
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment
                          .end, // Force anchoring to the bottom
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            36.0,
                            0,
                            36.0,
                            32.0,
                          ), // Compact horizontal limits, extremely tight bottom constraint
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
                                // Compact Email Field
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
                                    enabled: !_isBusy,
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

                                // Compact Password Field
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
                                    enabled: !_isBusy,
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

                                if (_errorMessage != null) ...[
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
                                            _errorMessage!,
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

                                // Primary Button
                                FilledButton(
                                  onPressed: _isBusy ? null : _login,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: AppTheme.primaryBlue,
                                  ),
                                  child: _isBusy
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
