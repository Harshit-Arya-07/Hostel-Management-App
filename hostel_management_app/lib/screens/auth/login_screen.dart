import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../student/student_dashboard.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_redirectIfAlreadyLoggedIn);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _redirectIfAlreadyLoggedIn() async {
    final authService = context.read<AuthService>();
    if (!authService.isLoggedIn || !mounted) return;

    final role = await authService.getUserRole();
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      role == 'admin' ? AdminDashboard.routeName : StudentDashboard.routeName,
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      await Future.microtask(
        () => authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );

      if (!mounted) return;
      final role = await authService.getUserRole();
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        role == 'admin' ? AdminDashboard.routeName : StudentDashboard.routeName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_parseError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }

    try {
      final authService = context.read<AuthService>();
      await Future.microtask(
        () => authService.resetPassword(email),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_parseError(e.toString()))),
      );
    }
  }

  String _parseError(String error) {
    if (error.contains('user-not-found')) return 'No account found with this email.';
    if (error.contains('wrong-password') || error.contains('invalid-credential')) return 'Incorrect password.';
    if (error.contains('invalid-email')) return 'Please enter a valid email.';
    if (error.contains('too-many-requests')) return 'Too many attempts. Try again later.';
    if (error.contains('user-disabled')) return 'This account has been disabled.';
    return 'Login failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Hostel Manager',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Sign in', textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: Text(_isLoading ? 'Please wait' : 'Login'),
                      ),
                    ),
                    TextButton(
                      onPressed: _handleForgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, SignupScreen.routeName),
                      child: const Text('Create account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}