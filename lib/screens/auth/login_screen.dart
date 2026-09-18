import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/game_state_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/game_2d_button.dart';
import '../dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await DatabaseService.instance.loginUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final userId = result['userId'] as int;
      final username = result['username'] as String;

      // Load player data into GameStateManager
      await GameStateManager.instance.loginWithUser(userId, username);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handlePlayAsGuest() {
    GameStateManager.instance.loginAsGuest();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Logo & Title
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.neonLime, AppTheme.pickleGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonLime.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sports_tennis,
                            color: Colors.black,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'PICKLEBALL SMASH',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in to sync progression, challenges, & tournament trophies',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error message banner if any
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.fireOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.fireOrange.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppTheme.fireOrange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: AppTheme.fireOrange, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Username field
                      TextFormField(
                        key: const ValueKey('login_username_field'),
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: const TextStyle(color: AppTheme.textMuted),
                          prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.electricCyan),
                          filled: true,
                          fillColor: AppTheme.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.neonLime, width: 2),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        key: const ValueKey('login_password_field'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: AppTheme.textMuted),
                          prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.electricCyan),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.neonLime, width: 2),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button (2D Arcade Button)
                      Game2DButton(
                        key: const ValueKey('login_submit_btn'),
                        onPressed: _isLoading ? null : _handleLogin,
                        text: 'SIGN IN',
                        icon: Icons.login_rounded,
                        variant: GameButtonVariant.primary,
                        size: GameButtonSize.large,
                        isFullWidth: true,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Register Navigation Link
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                          TextButton(
                            key: const ValueKey('nav_to_register_btn'),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.electricCyan,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppTheme.surfaceBorder)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppTheme.surfaceBorder)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Play as Guest Button (2D Arcade Button)
                      Game2DButton(
                        key: const ValueKey('play_as_guest_btn'),
                        onPressed: _handlePlayAsGuest,
                        text: 'PLAY AS GUEST',
                        icon: Icons.sports_tennis_rounded,
                        variant: GameButtonVariant.dark,
                        size: GameButtonSize.medium,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
