import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../student/student_dashboard.dart';

class SignupScreen extends StatefulWidget {
  static const routeName = '/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminCodeController = TextEditingController();

  String _selectedRole = 'student';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminCodeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthService>().signUp(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: _selectedRole,
            adminCode: _adminCodeController.text.trim(),
          );

      if (!mounted) return;
      final role = await context.read<AuthService>().getUserRole();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        role == 'admin' ? AdminDashboard.routeName : StudentDashboard.routeName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_parseError(e.toString())),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'This email is already registered.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Use 6+ characters.';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    return 'Signup failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.75),
              colorScheme.secondary.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      const Icon(Icons.person_add_rounded,
                          size: 56, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        'Create Account',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign up to manage your hostel',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                      ),
                      const SizedBox(height: 28),

                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon:
                                        Icon(Icons.person_outline),
                                  ),
                                  validator: (v) => v == null ||
                                          v.trim().length < 2
                                      ? 'Enter your full name'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon:
                                        Icon(Icons.email_outlined),
                                  ),
                                  validator: (v) {
                                    if (v == null || !v.contains('@') || !v.contains('.')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.school,
                                          color: colorScheme.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            isExpanded: true,
                                            value: _selectedRole,
                                            items: const [
                                              DropdownMenuItem<String>(
                                                value: 'student',
                                                child: Text('student'),
                                              ),
                                              DropdownMenuItem<String>(
                                                value: 'admin',
                                                child: Text('admin'),
                                              ),
                                            ],
                                            onChanged: _isLoading
                                                ? null
                                                : (value) {
                                                    if (value == null) return;
                                                    setState(() {
                                                      _selectedRole = value;
                                                      if (_selectedRole !=
                                                          'admin') {
                                                        _adminCodeController
                                                            .clear();
                                                      }
                                                    });
                                                  },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_selectedRole == 'admin') ...[
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _adminCodeController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Admin Code (if required)',
                                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon:
                                        const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword),
                                    ),
                                  ),
                                  validator: (v) =>
                                      v == null || v.length < 6
                                          ? 'Minimum 6 characters'
                                          : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller:
                                      _confirmPasswordController,
                                  obscureText: _obscureConfirm,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    prefixIcon: const Icon(
                                        Icons.lock_person_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirm
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () => setState(() =>
                                          _obscureConfirm =
                                              !_obscureConfirm),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleSignup,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Sign Up'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Already have an account? Sign In',
                          style: TextStyle(color: Colors.white),
                        ),
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
