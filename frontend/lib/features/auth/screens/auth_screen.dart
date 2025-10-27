import 'package:flutter/material.dart';
import 'package:messageai/services/auth_service.dart';
import 'package:messageai/core/errors/app_error.dart';
import 'package:messageai/core/errors/error_ui.dart';

/// Authentication screen for login/signup
class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;

  const AuthScreen({
    Key? key,
    required this.onAuthSuccess,
  }) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with ErrorHandlerMixin {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  bool _isSignUp = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ErrorUI.showErrorSnackbar(
        context,
        AppError(
          category: ErrorCategory.validation,
          severity: ErrorSeverity.warning,
          code: 'VAL001',
          message: 'Please enter email and password',
          userMessage: 'Please enter both email and password',
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        widget.onAuthSuccess();
      }
    } on AppError catch (error) {
      if (mounted) {
        showError(error, onRetry: _handleSignIn);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignUp() async {
    // Validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ErrorUI.showErrorSnackbar(
        context,
        AppError(
          category: ErrorCategory.validation,
          severity: ErrorSeverity.warning,
          code: 'VAL001',
          message: 'Please enter email and password',
          userMessage: 'Please enter both email and password',
        ),
      );
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      ErrorUI.showErrorSnackbar(
        context,
        AuthError.invalidEmail(),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ErrorUI.showErrorSnackbar(
        context,
        AuthError.weakPassword(),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.verified_outlined, color: Colors.white),
                SizedBox(width: 12),
                Text('Sign up successful! Signing you in...'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Auto sign in after signup
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          await _handleSignIn();
        }
      }
    } on AppError catch (error) {
      if (mounted) {
        showError(error, onRetry: _handleSignUp);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z0-9]+',
    );
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MessageAI'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _isSignUp ? 'Create Account' : 'Welcome to MessageAI',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_isSignUp ? _handleSignUp : _handleSignIn),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isSignUp
                      ? 'Already have an account? '
                      : "Don't have an account? "),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                              // Clear any previous error messages when switching modes
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            });
                          },
                    child: Text(_isSignUp ? 'Sign In' : 'Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
