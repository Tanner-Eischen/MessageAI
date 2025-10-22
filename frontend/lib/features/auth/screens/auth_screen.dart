import 'package:flutter/material.dart';
import 'package:messageai/services/auth_service.dart';

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

class _AuthScreenState extends State<AuthScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  String? _errorMessage;
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
      setState(() => _errorMessage = 'Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        widget.onAuthSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Sign in failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password');
      return;
    }

    // Validate email format
    if (!_isValidEmail(_emailController.text.trim())) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(
        () => _errorMessage = 'Password must be at least 6 characters',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // If email confirmation is disabled in Supabase, auto sign in
        // Otherwise show confirmation message
        setState(() =>
            _errorMessage =
                'Sign up successful! You can now sign in.');
        // Auto sign in after signup
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          await _handleSignIn();
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        // Parse common Supabase errors
        if (errorMsg.contains('already registered')) {
          errorMsg = 'Email is already registered. Try signing in instead.';
        } else if (errorMsg.contains('Password')) {
          errorMsg = 'Password must be at least 6 characters.';
        }
        setState(() => _errorMessage = errorMsg);
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
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _errorMessage!.contains('successful')
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: _errorMessage!.contains('successful')
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                ),
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
                              _errorMessage = null;
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
