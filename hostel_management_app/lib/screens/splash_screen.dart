import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'admin/admin_dashboard.dart';
import 'auth/login_screen.dart';
import 'student/student_dashboard.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_goNext);
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final authService = context.read<AuthService>();
    if (!authService.isLoggedIn) {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      return;
    }

    final role = await authService.getUserRole();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      role == 'admin' ? AdminDashboard.routeName : StudentDashboard.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Loading...'),
      ),
    );
  }
}